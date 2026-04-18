package database

import (
    "context"
    "fmt"
    "log"

    "github.com/golang-migrate/migrate/v4"
    _ "github.com/golang-migrate/migrate/v4/database/postgres"
    _ "github.com/golang-migrate/migrate/v4/source/file"
    "github.com/jackc/pgx/v5/pgxpool"
    "github.com/TgkCapture/openair/pkg/config"
)

func Connect(cfg *config.Config) (*pgxpool.Pool, error) {
    dsn := fmt.Sprintf(
        "host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
        cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPass, cfg.DBName,
    )

    pool, err := pgxpool.New(context.Background(), dsn)
    if err != nil {
        return nil, fmt.Errorf("unable to create connection pool: %w", err)
    }

    if err := pool.Ping(context.Background()); err != nil {
        return nil, fmt.Errorf("unable to ping database: %w", err)
    }

    return pool, nil
}

func RunMigrations(cfg *config.Config) error {
    dsn := fmt.Sprintf(
        "postgres://%s:%s@%s:%s/%s?sslmode=disable",
        cfg.DBUser, cfg.DBPass, cfg.DBHost, cfg.DBPort, cfg.DBName,
    )

    m, err := migrate.New("file://migrations", dsn)
    if err != nil {
        return fmt.Errorf("migration init failed: %w", err)
    }
    defer m.Close()

    if err := m.Up(); err != nil && err != migrate.ErrNoChange {
        return fmt.Errorf("migration failed: %w", err)
    }

    log.Println("database migrations applied successfully")
    return nil
}