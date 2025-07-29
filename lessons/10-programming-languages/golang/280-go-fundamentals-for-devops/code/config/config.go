package config

import (
    "os"
    "strconv"
    "time"
)

type AppConfig struct {
    Port        int
    Environment string
    Debug       bool
    Timeout     time.Duration
    LogLevel    string
}

func Load() *AppConfig {
    return &AppConfig{
        Port:        getEnvAsInt("PORT", 8080),
        Environment: getEnv("ENVIRONMENT", "development"),
        Debug:       getEnvAsBool("DEBUG", false),
        Timeout:     getEnvAsDuration("TIMEOUT", 30*time.Second),
        LogLevel:    getEnv("LOG_LEVEL", "info"),
    }
}

func getEnv(key, defaultVal string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultVal
}

func getEnvAsInt(key string, defaultVal int) int {
    if value := os.Getenv(key); value != "" {
        if intVal, err := strconv.Atoi(value); err == nil {
            return intVal
        }
    }
    return defaultVal
}

func getEnvAsBool(key string, defaultVal bool) bool {
    if value := os.Getenv(key); value != "" {
        if boolVal, err := strconv.ParseBool(value); err == nil {
            return boolVal
        }
    }
    return defaultVal
}

func getEnvAsDuration(key string, defaultVal time.Duration) time.Duration {
    if value := os.Getenv(key); value != "" {
        if duration, err := time.ParseDuration(value); err == nil {
            return duration
        }
    }
    return defaultVal
}
