package server

import (
	"net/http"
	"time"

	"github.com/TgkCapture/openair/internal/auth"
	"github.com/TgkCapture/openair/internal/channels"
	"github.com/TgkCapture/openair/internal/content"
	"github.com/TgkCapture/openair/internal/notifications"
	"github.com/TgkCapture/openair/internal/podcasts"
	"github.com/TgkCapture/openair/internal/schedule"
	"github.com/TgkCapture/openair/internal/upload"
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

// New creates a new server instance
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

// Router returns the HTTP handler
func (s *Server) Router() http.Handler {
	return s.router
}

// setupMiddleware configures global middleware
func (s *Server) setupMiddleware() {
	s.router.Use(gin.Logger())
	s.router.Use(gin.Recovery())
	s.router.Use(corsMiddleware(s.cfg.CORSAllowedOrigins))
}

// setupRoutes configures all API routes
func (s *Server) setupRoutes() {
	// Health check endpoint
	s.router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "openair-api",
			"version": "1.0.0",
		})
	})

	// Static files for uploads
	s.router.Static("/uploads", "./uploads")

	// API v1 group
	v1 := s.router.Group("/api/v1")

	// ==================== PUBLIC ROUTES ====================
	s.setupPublicRoutes(v1)

	// ==================== PROTECTED ROUTES ====================
	protected := v1.Group("")
	protected.Use(middleware.Auth(s.tokenManager))
	s.setupProtectedRoutes(protected)

	// ==================== ADMIN ROUTES ====================
	admin := protected.Group("/admin")
	admin.Use(middleware.RequireRole("admin"))
	s.setupAdminRoutes(admin)
}

// setupPublicRoutes configures publicly accessible endpoints
func (s *Server) setupPublicRoutes(v1 *gin.RouterGroup) {
	// Auth endpoints
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

	// Channels endpoints
	channelRepo := channels.NewRepository(s.db)
	channelSvc := channels.NewService(channelRepo, s.cfg)
	channelHandler := channels.NewHandler(channelSvc)

	v1.GET("/channels", channelHandler.GetAll)
	v1.GET("/channels/:id", channelHandler.GetByID)
	v1.GET("/channels/:id/stream", channelHandler.GetPublicStreamURL)

	// VOD/Content endpoints
	contentRepo := content.NewRepository(s.db)
	contentSvc := content.NewService(contentRepo, s.cfg)
	contentHandler := content.NewHandler(contentSvc)

	v1.GET("/vod", contentHandler.GetAll)
	v1.GET("/vod/categories", contentHandler.GetCategories)
	v1.GET("/vod/:id", contentHandler.GetByID)
	v1.GET("/vod/:id/stream", contentHandler.GetPublicStreamURL)

	// Podcasts endpoints
	podcastRepo := podcasts.NewRepository(s.db)
	podcastSvc := podcasts.NewService(podcastRepo)
	podcastHandler := podcasts.NewHandler(podcastSvc)

	v1.GET("/podcasts", podcastHandler.GetAll)
	v1.GET("/podcasts/:id", podcastHandler.GetByID)
	v1.GET("/podcasts/:id/episodes", podcastHandler.GetEpisodes)
	// Guests can play free episodes; premium episodes need a signed-in subscriber.
	v1.GET("/podcasts/:id/episodes/:episodeId/stream",
		middleware.OptionalAuth(s.tokenManager), podcastHandler.GetEpisodeStreamURL)

	// App configuration endpoint
	v1.GET("/config", s.getAppConfig)

	// Schedule endpoints
	scheduleRepo := schedule.NewRepository(s.db)
	scheduleHandler := schedule.NewHandler(scheduleRepo)

	v1.GET("/schedule/now", scheduleHandler.GetAllNowAndNext)
	v1.GET("/schedule/:channelId", scheduleHandler.GetByChannel)
	v1.GET("/schedule/:channelId/now", scheduleHandler.GetNowAndNext)
}

// setupProtectedRoutes configures authenticated endpoints
func (s *Server) setupProtectedRoutes(protected *gin.RouterGroup) {
	authRepo := auth.NewRepository(s.db)
	authSvc := auth.NewService(authRepo, s.tokenManager, s.cfg)
	authHandler := auth.NewHandler(authSvc)

	// User endpoints
	protected.POST("/auth/logout", authHandler.Logout)
	protected.GET("/users/me", authHandler.GetProfile)
	protected.PUT("/users/me", authHandler.UpdateProfile)

	// Channels
	channelRepo := channels.NewRepository(s.db)
	channelSvc := channels.NewService(channelRepo, s.cfg)
	channelHandler := channels.NewHandler(channelSvc)

	protected.GET("/channels/:id/stream/secure", channelHandler.GetStreamURL)

	// VOD/Content
	contentRepo := content.NewRepository(s.db)
	contentSvc := content.NewService(contentRepo, s.cfg)
	contentHandler := content.NewHandler(contentSvc)

	protected.GET("/vod/:id/stream/secure", contentHandler.GetStreamURL)
	protected.POST("/watch-history", contentHandler.SaveWatchHistory)
	protected.GET("/watch-history", contentHandler.GetWatchHistory)

	// Notifications
	notifRepo := notifications.NewRepository(s.db)
	notifSvc := notifications.NewService(notifRepo, s.cfg)
	notifHandler := notifications.NewHandler(notifSvc)

	protected.GET("/notifications", notifHandler.GetNotifications)
	protected.POST("/notifications/read", notifHandler.MarkAllRead)
	protected.POST("/notifications/token", notifHandler.RegisterToken)
	protected.DELETE("/notifications/token", notifHandler.UnregisterToken)
}

// setupAdminRoutes configures administrator-only endpoints
func (s *Server) setupAdminRoutes(admin *gin.RouterGroup) {
	// Repositories and handlers
	channelRepo := channels.NewRepository(s.db)
	channelSvc := channels.NewService(channelRepo, s.cfg)
	channelHandler := channels.NewHandler(channelSvc)

	contentRepo := content.NewRepository(s.db)
	contentSvc := content.NewService(contentRepo, s.cfg)
	contentHandler := content.NewHandler(contentSvc)

	podcastRepo := podcasts.NewRepository(s.db)
	podcastSvc := podcasts.NewService(podcastRepo)
	podcastHandler := podcasts.NewHandler(podcastSvc)

	notifRepo := notifications.NewRepository(s.db)
	notifSvc := notifications.NewService(notifRepo, s.cfg)
	notifHandler := notifications.NewHandler(notifSvc)

	scheduleRepo := schedule.NewRepository(s.db)
	scheduleHandler := schedule.NewHandler(scheduleRepo)

	// Channel management
	admin.GET("/channels", channelHandler.AdminGetAll)
	admin.POST("/channels", channelHandler.Create)
	admin.PUT("/channels/:id", channelHandler.Update)
	admin.DELETE("/channels/:id", channelHandler.Delete)
	admin.PATCH("/channels/:id/access", channelHandler.ToggleAccess)

	// VOD management
	admin.GET("/vod", contentHandler.AdminGetAll)
	admin.POST("/vod", contentHandler.Create)
	admin.PUT("/vod/:id", contentHandler.Update)
	admin.DELETE("/vod/:id", contentHandler.Delete)
	admin.PATCH("/vod/:id/access", contentHandler.ToggleAccess)

	// Podcast management
	admin.GET("/podcasts", podcastHandler.AdminGetAll)
	admin.POST("/podcasts", podcastHandler.CreatePodcast)
	admin.DELETE("/podcasts/:id", podcastHandler.DeletePodcast)
	admin.POST("/podcasts/episodes", podcastHandler.CreateEpisode)
	admin.DELETE("/podcasts/episodes/:episodeId", podcastHandler.DeleteEpisode)

	// Notifications
	admin.POST("/notify", notifHandler.Send)

	// File upload
	admin.POST("/upload", upload.Handler(upload.Config{
		Dir:           "./uploads",
		PublicBaseURL: s.cfg.PublicBaseURL,
		MaxBytes:      s.cfg.UploadMaxMB << 20,
	}))

	// Schedule management
	admin.POST("/schedule", scheduleHandler.Create)
	admin.PUT("/schedule/:id", scheduleHandler.Update)
	admin.DELETE("/schedule/:id", scheduleHandler.Delete)

	// User management
	admin.GET("/users", s.listUsers)
	admin.PATCH("/users/:id/status", s.updateUserStatus)

	// Analytics
	admin.GET("/analytics", s.getAnalytics)

	// App configuration
	admin.PUT("/config", s.updateAppConfig)
}

// ==================== HANDLER FUNCTIONS ====================

// getAppConfig returns the current application configuration
func (s *Server) getAppConfig(c *gin.Context) {
	type Config struct {
		Broadcaster    string  `json:"broadcaster"`
		PrimaryColor   string  `json:"primary_color"`
		LogoURL        *string `json:"logo_url"`
		EnableVod      bool    `json:"enable_vod"`
		EnablePodcasts bool    `json:"enable_podcasts"`
		EnableRadio    bool    `json:"enable_radio"`
		Timezone       string  `json:"timezone"`
	}

	var cfg Config
	err := s.db.QueryRow(c.Request.Context(), `
		SELECT broadcaster, primary_color, logo_url,
			enable_vod, enable_podcasts, enable_radio, timezone
		FROM app_config ORDER BY updated_at DESC, id LIMIT 1`).Scan(
		&cfg.Broadcaster, &cfg.PrimaryColor, &cfg.LogoURL,
		&cfg.EnableVod, &cfg.EnablePodcasts, &cfg.EnableRadio, &cfg.Timezone,
	)

	if err != nil {
		utils.InternalError(c)
		return
	}

	utils.OK(c, cfg)
}

// updateAppConfig updates the application configuration
func (s *Server) updateAppConfig(c *gin.Context) {
	type Config struct {
		Broadcaster    string  `json:"broadcaster"`
		PrimaryColor   string  `json:"primary_color"`
		LogoURL        *string `json:"logo_url"`
		EnableVod      bool    `json:"enable_vod"`
		EnablePodcasts bool    `json:"enable_podcasts"`
		EnableRadio    bool    `json:"enable_radio"`
		Timezone       string  `json:"timezone"`
	}

	var cfg Config
	if err := c.ShouldBindJSON(&cfg); err != nil {
		utils.BadRequest(c, "VALIDATION_ERROR", err.Error())
		return
	}

	// An empty timezone leaves the stored one unchanged.
	if cfg.Timezone != "" {
		if _, err := time.LoadLocation(cfg.Timezone); err != nil {
			utils.BadRequest(c, "VALIDATION_ERROR", "unknown timezone; use a name such as Africa/Blantyre")
			return
		}
	}

	err := s.db.QueryRow(c.Request.Context(), `
		UPDATE app_config SET
			broadcaster=$1,
			primary_color=$2,
			logo_url=$3,
			enable_vod=$4,
			enable_podcasts=$5,
			enable_radio=$6,
			timezone=COALESCE(NULLIF($7, ''), timezone),
			updated_at=NOW()
		WHERE id = (SELECT id FROM app_config ORDER BY updated_at, id LIMIT 1)
		RETURNING timezone`,
		cfg.Broadcaster, cfg.PrimaryColor, cfg.LogoURL,
		cfg.EnableVod, cfg.EnablePodcasts, cfg.EnableRadio, cfg.Timezone,
	).Scan(&cfg.Timezone)

	if err != nil {
		utils.InternalError(c)
		return
	}

	utils.OK(c, cfg)
}

// listUsers returns all users (admin only)
func (s *Server) listUsers(c *gin.Context) {
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
}

// updateUserStatus activates or deactivates a user
func (s *Server) updateUserStatus(c *gin.Context) {
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
}

// getAnalytics returns platform analytics (admin only)
func (s *Server) getAnalytics(c *gin.Context) {
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

	// Get counts
	s.db.QueryRow(ctx, `SELECT COUNT(*) FROM users`).Scan(&a.TotalUsers)
	s.db.QueryRow(ctx, `SELECT COUNT(*) FROM channels WHERE is_active=true`).Scan(&a.TotalChannels)
	s.db.QueryRow(ctx, `SELECT COUNT(*) FROM content WHERE type='vod' AND is_published=true`).Scan(&a.TotalVod)
	s.db.QueryRow(ctx, `SELECT COUNT(*) FROM podcasts WHERE is_active=true`).Scan(&a.TotalPodcasts)
	s.db.QueryRow(ctx, `SELECT COALESCE(SUM(view_count),0) FROM content`).Scan(&a.TotalViews)

	// Get top content
	rows, err := s.db.Query(ctx,
		`SELECT title, view_count FROM content 
		WHERE is_published=true 
		ORDER BY view_count DESC 
		LIMIT 5`)

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
}

// ==================== MIDDLEWARE ====================

// corsMiddleware handles Cross-Origin Resource Sharing
// corsMiddleware lets browser apps on the allowed origins call the API. The
// mobile apps are not browsers and are unaffected. An entry of "*" allows any
// origin, which is the development default.
func corsMiddleware(allowedOrigins []string) gin.HandlerFunc {
	allowAll := false
	allowed := make(map[string]bool, len(allowedOrigins))
	for _, origin := range allowedOrigins {
		if origin == "*" {
			allowAll = true
		}
		allowed[origin] = true
	}

	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		switch {
		case allowAll:
			c.Header("Access-Control-Allow-Origin", "*")
		case origin != "" && allowed[origin]:
			c.Header("Access-Control-Allow-Origin", origin)
			c.Header("Vary", "Origin")
		}
		c.Header("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Authorization,Content-Type")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}