package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/TgkCapture/openair/internal/server"
    "github.com/TgkCapture/openair/pkg/config"
    "github.com/TgkCapture/openair/pkg/database"
    "github.com/TgkCapture/openair/pkg/cache"
)

func main() {
    cfg := config.Load()

    db, err := database.Connect(cfg)
    if err != nil {
        log.Fatalf("failed to connect to database: %v", err)
    }
    defer db.Close()

    rdb, err := cache.Connect(cfg)
    if err != nil {
        log.Fatalf("failed to connect to redis: %v", err)
    }
    defer rdb.Close()

    srv := server.New(cfg, db, rdb)

    httpServer := &http.Server{
        Addr:         ":" + cfg.AppPort,
        Handler:      srv.Router(),
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    go func() {
        log.Printf("OpenAir API starting on port %s (env: %s)", cfg.AppPort, cfg.AppEnv)
        if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("server error: %v", err)
        }
    }()

    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    log.Println("Shutting down server...")
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    if err := httpServer.Shutdown(ctx); err != nil {
        log.Fatalf("forced shutdown: %v", err)
    }
    log.Println("Server stopped cleanly")
}