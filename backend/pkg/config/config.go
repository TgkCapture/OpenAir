package config

import (
    "log"
    "os"

    "github.com/joho/godotenv"
)

type Config struct {
    AppPort  string
    AppEnv   string
    DBHost   string
    DBPort   string
    DBUser   string
    DBPass   string
    DBName   string
    RedisHost string
    RedisPort string
    JWTPrivateKeyPath string
    JWTPublicKeyPath  string
    S3Bucket   string
    S3Region   string
    S3Endpoint string
    S3AccessKey string
    S3SecretKey string
    RTMPSecret    string
    HLSBaseURL    string
    FCMServerKey  string
    SMTPHost string
    SMTPPort string
    SMTPUser string
    SMTPPass string
    StripeSecretKey      string
    StripeWebhookSecret  string
    AirtelAPIURL         string
    AirtelClientID       string
    AirtelClientSecret   string
    MpambaAPIURL         string
    MpambaAPIKey         string
}

func Load() *Config {
    if err := godotenv.Load(); err != nil {
        log.Println("no .env file found, reading from environment")
    }

    return &Config{
        AppPort:  getEnv("APP_PORT", "8000"),
        AppEnv:   getEnv("APP_ENV", "development"),
        DBHost:   getEnv("DB_HOST", "localhost"),
        DBPort:   getEnv("DB_PORT", "5432"),
        DBUser:   getEnv("DB_USER", "openair"),
        DBPass:   getEnv("DB_PASSWORD", "changeme"),
        DBName:   getEnv("DB_NAME", "openair_db"),
        RedisHost: getEnv("REDIS_HOST", "localhost"),
        RedisPort: getEnv("REDIS_PORT", "6379"),
        JWTPrivateKeyPath: getEnv("JWT_PRIVATE_KEY_PATH", "./config/keys/private.pem"),
        JWTPublicKeyPath:  getEnv("JWT_PUBLIC_KEY_PATH", "./config/keys/public.pem"),
        S3Bucket:    getEnv("S3_BUCKET", ""),
        S3Region:    getEnv("S3_REGION", "us-east-1"),
        S3Endpoint:  getEnv("S3_ENDPOINT", ""),
        S3AccessKey: getEnv("S3_ACCESS_KEY", ""),
        S3SecretKey: getEnv("S3_SECRET_KEY", ""),
        RTMPSecret:   getEnv("RTMP_SECRET", "changeme"),
        HLSBaseURL:   getEnv("HLS_BASE_URL", "http://localhost:8080/hls"),
        FCMServerKey: getEnv("FCM_SERVER_KEY", ""),
        SMTPHost: getEnv("SMTP_HOST", ""),
        SMTPPort: getEnv("SMTP_PORT", "587"),
        SMTPUser: getEnv("SMTP_USER", ""),
        SMTPPass: getEnv("SMTP_PASS", ""),
        StripeSecretKey:     getEnv("STRIPE_SECRET_KEY", ""),
        StripeWebhookSecret: getEnv("STRIPE_WEBHOOK_SECRET", ""),
        AirtelAPIURL:        getEnv("AIRTEL_API_URL", ""),
        AirtelClientID:      getEnv("AIRTEL_CLIENT_ID", ""),
        AirtelClientSecret:  getEnv("AIRTEL_CLIENT_SECRET", ""),
        MpambaAPIURL: getEnv("MPAMBA_API_URL", ""),
        MpambaAPIKey: getEnv("MPAMBA_API_KEY", ""),
    }
}

func getEnv(key, fallback string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return fallback
}