package server

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"github.com/TgkCapture/openair/internal/auth"
	"github.com/TgkCapture/openair/pkg/config"
	"github.com/TgkCapture/openair/pkg/middleware"
	"github.com/TgkCapture/openair/pkg/token"
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

	authRepo := auth.NewRepository(s.db)
	authSvc := auth.NewService(authRepo, s.tokenManager, s.cfg)
	authHandler := auth.NewHandler(authSvc)

	// Public auth routes
	authRoutes := v1.Group("/auth")
	{
		authRoutes.POST("/register", authHandler.Register)
		authRoutes.POST("/login", authHandler.Login)
		authRoutes.POST("/refresh", authHandler.RefreshToken)
		authRoutes.POST("/forgot-password", authHandler.ForgotPassword)
		authRoutes.POST("/reset-password", authHandler.ResetPassword)
	}

	// Protected routes
	protected := v1.Group("")
	protected.Use(middleware.Auth(s.tokenManager))
	{
		protected.POST("/auth/logout", authHandler.Logout)
		protected.GET("/users/me", authHandler.GetProfile)
		protected.PUT("/users/me", authHandler.UpdateProfile)
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