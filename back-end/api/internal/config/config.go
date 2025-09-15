package config

import (
	"log"
	"os"
)

// Config holds application configuration values
type Config struct {
	Port         string
	DBHost       string
	DBPort       string
	DBUser       string
	DBPassword   string
	DBName       string
	RedisAddr    string
	RedisPass    string
	JWTSecret    string
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func Load() Config {
	cfg := Config{
		Port:       getenv("PORT", "8080"),
		DBHost:     getenv("DB_HOST", "localhost"),
		DBPort:     getenv("DB_PORT", "5432"),
		DBUser:     getenv("DB_USER", "postgres"),
		DBPassword: getenv("DB_PASSWORD", "postgres"),
		DBName:     getenv("DB_NAME", "timebeam"),
		RedisAddr:  getenv("REDIS_ADDR", "localhost:6379"),
		RedisPass:  getenv("REDIS_PASSWORD", ""),
		JWTSecret:  getenv("JWT_SECRET", "dev-secret-change-me"),
	}
	if cfg.JWTSecret == "dev-secret-change-me" {
		log.Println("[WARN] Using default JWT secret; set JWT_SECRET in environment for production")
	}
	return cfg
}
