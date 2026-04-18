package cache

import (
    "context"
    "fmt"

    "github.com/redis/go-redis/v9"
    "github.com/TgkCapture/openair/pkg/config"
)

func Connect(cfg *config.Config) (*redis.Client, error) {
    rdb := redis.NewClient(&redis.Options{
        Addr: fmt.Sprintf("%s:%s", cfg.RedisHost, cfg.RedisPort),
    })

    if err := rdb.Ping(context.Background()).Err(); err != nil {
        return nil, fmt.Errorf("unable to connect to redis: %w", err)
    }

    return rdb, nil
}