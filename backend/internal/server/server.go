package server

import (
	"net/http"

	"github.com/TgkCapture/openair/internal/auth"
	"github.com/TgkCapture/openair/internal/channels"
	"github.com/TgkCapture/openair/internal/content"
	"github.com/TgkCapture/openair/internal/podcasts"
	"github.com/TgkCapture/openair/pkg/config"
	"github.com/TgkCapture/openair/pkg/middleware"
	"github.com/TgkCapture/openair/pkg/token"
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