package server

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/TgkCapture/openair/internal/auth"
	"github.com/TgkCapture/openair/internal/channels"
	"github.com/TgkCapture/openair/internal/content"
	"github.com/TgkCapture/openair/internal/notifications"
	"github.com/TgkCapture/openair/internal/podcasts"
	"github.com/TgkCapture/openair/internal/schedule"
	"github.com/TgkCapture/openair/pkg/config"
	"github.com/TgkCapture/openair/pkg/middleware"
	"github.com/TgkCapture/openair/pkg/token"
	"github.com/TgkCapture/openair/pkg/utils"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

type Server struct {
	cfg          *config.Config
	db           *pgxpool.Pool
	rdb          *redis.Client
	router       *gin.Engine
	tokenManager *token.Manager
}

func New(cfg *config.Config, db *pgxpool.Pool, rdb *redis.Client, tm *token.Manager) *Server {
	if cfg.AppEnv == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	s := &Server{
		cfg:          cfg,
		db:           db,
		rdb:          rdb,
		router:       gin.New(),
		tokenManager: tm,
	}

	s.setupMiddleware()
	s.setupRoutes()
	return s
}

func (s *Server) Router() http.Handler {
	return s.router
}

func (s *Server) setupMiddleware() {
	s.router.Use(gin.Logger())
	s.router.Use(gin.Recovery())
	s.router.Use(corsMiddleware())
}

func (s *Server) setupRoutes() {
	s.router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "openair-api",
			"version": "1.0.0",
		})
	})

	s.router.Static("/uploads", "./uploads")

	v1 := s.router.Group("/api/v1")

	// Auth
	authRepo := auth.NewRepository(s.db)
	authSvc := auth.NewService(authRepo, s.tokenManager, s.cfg)
	authHandler := auth.NewHandler(authSvc)

	authRoutes := v1.Group("/auth")
	{
		authRoutes.POST("/register", authHandler.Register)
		authRoutes.POST("/login", authHandler.Login)
		authRoutes.POST("/refresh", authHandler.RefreshToken)
		authRoutes.POST("/forgot-password", authHandler.ForgotPassword)
		authRoutes.POST("/reset-password", authHandler.ResetPassword)
	}

	// Channels — public
	channelRepo := channels.NewRepository(s.db)
	channelSvc := channels.NewService(channelRepo, s.cfg)
	channelHandler := channels.NewHandler(channelSvc)

	v1.GET("/channels", channelHandler.GetAll)
	v1.GET("/channels/:id", channelHandler.GetByID)
	v1.GET("/channels/:id/stream", channelHandler.GetPublicStreamURL)

	// Content / VOD
	contentRepo := content.NewRepository(s.db)
	contentSvc := content.NewService(contentRepo, s.cfg)
	contentHandler := content.NewHandler(contentSvc)

	v1.GET("/vod", contentHandler.GetAll)
	v1.GET("/vod/categories", contentHandler.GetCategories)
	v1.GET("/vod/:id", contentHandler.GetByID)
	v1.GET("/vod/:id/stream", contentHandler.GetPublicStreamURL)

	podcastRepo := podcasts.NewRepository(s.db)
	podcastSvc := podcasts.NewService(podcastRepo)
	podcastHandler := podcasts.NewHandler(podcastSvc)

	v1.GET("/podcasts", podcastHandler.GetAll)
	v1.GET("/podcasts/:id", podcastHandler.GetByID)
	v1.GET("/podcasts/:id/episodes", podcastHandler.GetEpisodes)

	v1.GET("/config", func(c *gin.Context) {
		type Config struct {
			Broadcaster    string  `json:"broadcaster"`
			PrimaryColor   string  `json:"primary_color"`
			LogoURL        *string `json:"logo_url"`
			EnableVod      bool    `json:"enable_vod"`
			EnablePodcasts bool    `json:"enable_podcasts"`
			EnableRadio    bool    `json:"enable_radio"`
		}
		var cfg Config
		err := s.db.QueryRow(c.Request.Context(), `
			SELECT broadcaster, primary_color, logo_url,
				enable_vod, enable_podcasts, enable_radio
			FROM app_config LIMIT 1`).Scan(
			&cfg.Broadcaster, &cfg.PrimaryColor, &cfg.LogoURL,
			&cfg.EnableVod, &cfg.EnablePodcasts, &cfg.EnableRadio,
		)
		if err != nil {
			utils.InternalError(c)
			return
		}
		utils.OK(c, cfg)
	})

	// Schedule
	scheduleRepo := schedule.NewRepository(s.db)
	scheduleHandler := schedule.NewHandler(scheduleRepo)

	v1.GET("/schedule/now", scheduleHandler.GetAllNowAndNext)
	v1.GET("/schedule/:channelId", scheduleHandler.GetByChannel)
	v1.GET("/schedule/:channelId/now", scheduleHandler.GetNowAndNext)

	// Notifications
	notifRepo := notifications.NewRepository(s.db)
	notifSvc := notifications.NewService(notifRepo, s.cfg)
	notifHandler := notifications.NewHandler(notifSvc)

	// Protected routes
	protected := v1.Group("")
	protected.Use(middleware.Auth(s.tokenManager))
	{
		protected.POST("/auth/logout", authHandler.Logout)
		protected.GET("/users/me", authHandler.GetProfile)
		protected.PUT("/users/me", authHandler.UpdateProfile)

		// Channels — authenticated stream URL
		protected.GET("/channels/:id/stream/secure", channelHandler.GetStreamURL)

		protected.GET("/vod/:id/stream/secure", contentHandler.GetStreamURL)
		protected.POST("/watch-history", contentHandler.SaveWatchHistory)
		protected.GET("/watch-history", contentHandler.GetWatchHistory)

		protected.GET("/podcasts/:id/episodes/:episodeId/stream", podcastHandler.GetEpisodeStreamURL)

		// Admin only
		admin := protected.Group("/admin")
		admin.Use(middleware.RequireRole("admin"))
		{
			admin.POST("/channels", channelHandler.Create)
			admin.PUT("/channels/:id", channelHandler.Update)
			admin.DELETE("/channels/:id", channelHandler.Delete)
			admin.PATCH("/channels/:id/access", channelHandler.ToggleAccess)

			admin.POST("/vod", contentHandler.Create)
			admin.PUT("/vod/:id", contentHandler.Update)
			admin.PATCH("/vod/:id/access", contentHandler.ToggleAccess)

			admin.POST("/podcasts", podcastHandler.CreatePodcast)
			admin.POST("/podcasts/episodes", podcastHandler.CreateEpisode)

			admin.POST("/notify", notifHandler.Send)

			admin.GET("/users", func(c *gin.Context) {
				rows, err := s.db.Query(c.Request.Context(), `
					SELECT id, email, full_name, role, is_active, created_at
					FROM users ORDER BY created_at DESC`)
				if err != nil {
					utils.InternalError(c)
					return
				}
				defer rows.Close()

				type UserRow struct {
					ID        string    `json:"id"`
					Email     string    `json:"email"`
					FullName  string    `json:"full_name"`
					Role      string    `json:"role"`
					IsActive  bool      `json:"is_active"`
					CreatedAt time.Time `json:"created_at"`
				}

				var users []UserRow
				for rows.Next() {
					var u UserRow
					if err := rows.Scan(&u.ID, &u.Email, &u.FullName, &u.Role, &u.IsActive, &u.CreatedAt); err != nil {
						continue
					}
					users = append(users, u)
				}
				if users == nil {
					users = []UserRow{}
				}
				utils.OK(c, users)
			})

			admin.PATCH("/users/:id/status", func(c *gin.Context) {
				var body struct {
					IsActive bool `json:"is_active"`
				}
				if err := c.ShouldBindJSON(&body); err != nil {
					utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
					return
				}
				_, err := s.db.Exec(c.Request.Context(),
					`UPDATE users SET is_active=$2, updated_at=NOW() WHERE id=$1`,
					c.Param("id"), body.IsActive)
				if err != nil {
					utils.InternalError(c)
					return
				}
				utils.OK(c, gin.H{"message": "updated"})
			})

			admin.GET("/analytics", func(c *gin.Context) {
				type Analytics struct {
					TotalUsers    int `json:"total_users"`
					TotalChannels int `json:"total_channels"`
					TotalVod      int `json:"total_vod"`
					TotalPodcasts int `json:"total_podcasts"`
					TotalViews    int `json:"total_views"`
					TopContent    []struct {
						Title     string `json:"title"`
						ViewCount int    `json:"view_count"`
					} `json:"top_content"`
				}

				var a Analytics
				ctx := c.Request.Context()

				s.db.QueryRow(ctx, `SELECT COUNT(*) FROM users`).Scan(&a.TotalUsers)
				s.db.QueryRow(ctx, `SELECT COUNT(*) FROM channels WHERE is_active=true`).Scan(&a.TotalChannels)
				s.db.QueryRow(ctx, `SELECT COUNT(*) FROM content WHERE type='vod' AND is_published=true`).Scan(&a.TotalVod)
				s.db.QueryRow(ctx, `SELECT COUNT(*) FROM podcasts WHERE is_active=true`).Scan(&a.TotalPodcasts)
				s.db.QueryRow(ctx, `SELECT COALESCE(SUM(view_count),0) FROM content`).Scan(&a.TotalViews)

				rows, err := s.db.Query(ctx,
					`SELECT title, view_count FROM content WHERE is_published=true ORDER BY view_count DESC LIMIT 5`)
				if err == nil {
					defer rows.Close()
					for rows.Next() {
						var item struct {
							Title     string `json:"title"`
							ViewCount int    `json:"view_count"`
						}
						rows.Scan(&item.Title, &item.ViewCount)
						a.TopContent = append(a.TopContent, item)
					}
				}
				if a.TopContent == nil {
					a.TopContent = []struct {
						Title     string `json:"title"`
						ViewCount int    `json:"view_count"`
					}{}
				}
				utils.OK(c, a)
			})

			admin.PUT("/config", func(c *gin.Context) {
				type Config struct {
					Broadcaster    string  `json:"broadcaster"`
					PrimaryColor   string  `json:"primary_color"`
					LogoURL        *string `json:"logo_url"`
					EnableVod      bool    `json:"enable_vod"`
					EnablePodcasts bool    `json:"enable_podcasts"`
					EnableRadio    bool    `json:"enable_radio"`
				}
				var cfg Config
				if err := c.ShouldBindJSON(&cfg); err != nil {
					utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
					return
				}
				_, err := s.db.Exec(c.Request.Context(), `
					UPDATE app_config SET broadcaster=$1, primary_color=$2, logo_url=$3,
						enable_vod=$4, enable_podcasts=$5, enable_radio=$6, updated_at=NOW()`,
					cfg.Broadcaster, cfg.PrimaryColor, cfg.LogoURL,
					cfg.EnableVod, cfg.EnablePodcasts, cfg.EnableRadio,
				)
				if err != nil {
					utils.InternalError(c)
					return
				}
				utils.OK(c, cfg)
			})

			admin.POST("/upload", func(c *gin.Context) {
				file, header, err := c.Request.FormFile("file")
				if err != nil {
					utils.BadRequest(c, "VALIDATION_ERROR", "no file provided")
					return
				}
				defer file.Close()

				// For now save locally to uploads/ dir — swap for S3 in production
				uploadDir := "./uploads"
				os.MkdirAll(uploadDir, 0755)

				filename := fmt.Sprintf("%d_%s", time.Now().UnixMilli(), header.Filename)
				dst := filepath.Join(uploadDir, filename)

				out, err := os.Create(dst)
				if err != nil {
					utils.InternalError(c)
					return
				}
				defer out.Close()
				io.Copy(out, file)

				// Return URL — in prod this would be S3/CDN URL
				url := fmt.Sprintf("%s/uploads/%s",
					getEnv("APP_BASE_URL", "http://localhost:8000"), filename)
				utils.OK(c, gin.H{"url": url})
			})

			admin.POST("/schedule", scheduleHandler.Create)
			admin.PUT("/schedule/:id", scheduleHandler.Update)
			admin.DELETE("/schedule/:id", scheduleHandler.Delete)

			
		}
	}
}

func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Authorization,Content-Type")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}

func getEnv(key, fallback string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return fallback
}