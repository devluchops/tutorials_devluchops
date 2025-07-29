package main

import (
    "context"
    "fmt"
    "strings"
    "time"
    
    "devops-tutorial/config"
    "devops-tutorial/monitor"
)

func main() {
    // Load configuration
    cfg := config.Load()
    
    fmt.Printf("🚀 DevOps Health Monitor Starting...\n")
    fmt.Printf("Environment: %s\n", cfg.Environment)
    fmt.Printf("Debug Mode: %t\n", cfg.Debug)
    fmt.Printf("Timeout: %v\n", cfg.Timeout)
    fmt.Printf("Log Level: %s\n", cfg.LogLevel)
    
    // Create health checker
    healthChecker := monitor.NewHealthChecker(cfg.Timeout)
    
    // Example endpoints to monitor
    endpoints := []string{
        "https://httpbin.org/status/200",
        "https://httpbin.org/status/500",
        "https://httpbin.org/delay/1",
        "https://invalid-url-that-does-not-exist.com",
    }
    
    fmt.Println("\n🔍 Running health checks...")
    
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    
    statuses := healthChecker.CheckMultiple(ctx, endpoints)
    
    fmt.Println("\n📊 Health Check Results:")
    fmt.Println(strings.Repeat("=", 50))
    
    for _, status := range statuses {
        emoji := "✅"
        if status.Error != nil {
            emoji = "❌"
        }
        
        fmt.Printf("%s %s\n", emoji, status.Endpoint)
        fmt.Printf("   Status: %s\n", status.Status)
        fmt.Printf("   Duration: %v\n", status.Duration)
        if status.Error != nil {
            fmt.Printf("   Error: %v\n", status.Error)
        }
        fmt.Println()
    }
    
    fmt.Println("✨ Health check completed!")
}
