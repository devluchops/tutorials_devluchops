# Tutorial 280: Go Fundamentals for DevOps Engineers

## 🎯 Overview

Learn Go programming fundamentals specifically tailored for DevOps engineers. This tutorial covers essential Go concepts, syntax, and patterns commonly used in infrastructure tools and cloud-native applications.

### What You'll Learn
- ✅ Go basics: variables, functions, and control structures
- ✅ Working with packages and modules
- ✅ Error handling and best practices
- ✅ Concurrency with goroutines and channels
- ✅ Building and deploying Go applications
- ✅ Testing and debugging Go code

### Prerequisites
- Basic programming knowledge (any language)
- Command line familiarity
- Go installed (1.21+)

### Time to Complete
⏱️ Approximately 60 minutes

## 🏗️ Architecture

This tutorial focuses on core Go concepts that are essential for DevOps tooling:

```
Go DevOps Foundation
├── Language Basics
├── Package Management
├── Error Handling
├── Concurrency
├── HTTP/REST APIs
└── Testing & Deployment
```

## 🛠️ Setup

### Step 1: Install Go

**macOS:**
```bash
brew install go
```

**Linux:**
```bash
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

**Windows:**
Download from https://go.dev/dl/

### Step 2: Verify Installation
```bash
go version
```

### Step 3: Set Up Workspace
```bash
mkdir go-devops-tutorial
cd go-devops-tutorial
go mod init devops-tutorial
```

## 📋 Implementation

### Phase 1: Go Basics

Create `main.go`:
```go
package main

import (
    "fmt"
    "log"
    "os"
    "time"
)

// DevOps tool configuration
type Config struct {
    Environment string
    Debug       bool
    Timeout     time.Duration
}

// Health check function
func healthCheck(endpoint string) error {
    fmt.Printf("Checking health of %s...\n", endpoint)
    
    // Simulate health check
    time.Sleep(100 * time.Millisecond)
    
    if endpoint == "" {
        return fmt.Errorf("endpoint cannot be empty")
    }
    
    return nil
}

// Process multiple endpoints concurrently
func checkMultipleEndpoints(endpoints []string) {
    results := make(chan string, len(endpoints))
    
    // Launch goroutines
    for _, endpoint := range endpoints {
        go func(ep string) {
            if err := healthCheck(ep); err != nil {
                results <- fmt.Sprintf("❌ %s: %v", ep, err)
            } else {
                results <- fmt.Sprintf("✅ %s: healthy", ep)
            }
        }(endpoint)
    }
    
    // Collect results
    for i := 0; i < len(endpoints); i++ {
        fmt.Println(<-results)
    }
}

func main() {
    // Configuration
    config := Config{
        Environment: getEnv("ENVIRONMENT", "development"),
        Debug:       getEnv("DEBUG", "false") == "true",
        Timeout:     5 * time.Second,
    }
    
    fmt.Printf("🚀 DevOps Tool Starting...\n")
    fmt.Printf("Environment: %s\n", config.Environment)
    fmt.Printf("Debug Mode: %t\n", config.Debug)
    fmt.Printf("Timeout: %v\n", config.Timeout)
    
    // Example endpoints to monitor
    endpoints := []string{
        "https://api.example.com/health",
        "https://database.example.com/ping",
        "https://cache.example.com/status",
        "", // This will cause an error
    }
    
    fmt.Println("\n🔍 Running health checks...")
    checkMultipleEndpoints(endpoints)
    
    fmt.Println("\n✨ Health check completed!")
}

// Helper function to get environment variables with defaults
func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
```

### Phase 2: Package Structure

Create a proper package structure:

**config/config.go:**
```go
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
```

**monitor/health.go:**
```go
package monitor

import (
    "context"
    "fmt"
    "net/http"
    "time"
)

type HealthChecker struct {
    client  *http.Client
    timeout time.Duration
}

type HealthStatus struct {
    Endpoint string
    Status   string
    Error    error
    Duration time.Duration
}

func NewHealthChecker(timeout time.Duration) *HealthChecker {
    return &HealthChecker{
        client: &http.Client{
            Timeout: timeout,
        },
        timeout: timeout,
    }
}

func (hc *HealthChecker) Check(ctx context.Context, endpoint string) HealthStatus {
    start := time.Now()
    
    req, err := http.NewRequestWithContext(ctx, "GET", endpoint, nil)
    if err != nil {
        return HealthStatus{
            Endpoint: endpoint,
            Status:   "error",
            Error:    fmt.Errorf("failed to create request: %w", err),
            Duration: time.Since(start),
        }
    }
    
    resp, err := hc.client.Do(req)
    if err != nil {
        return HealthStatus{
            Endpoint: endpoint,
            Status:   "down",
            Error:    err,
            Duration: time.Since(start),
        }
    }
    defer resp.Body.Close()
    
    status := "up"
    if resp.StatusCode >= 400 {
        status = "unhealthy"
        err = fmt.Errorf("HTTP %d", resp.StatusCode)
    }
    
    return HealthStatus{
        Endpoint: endpoint,
        Status:   status,
        Error:    err,
        Duration: time.Since(start),
    }
}

func (hc *HealthChecker) CheckMultiple(ctx context.Context, endpoints []string) []HealthStatus {
    results := make(chan HealthStatus, len(endpoints))
    
    // Launch goroutines for concurrent checks
    for _, endpoint := range endpoints {
        go func(ep string) {
            results <- hc.Check(ctx, ep)
        }(endpoint)
    }
    
    // Collect results
    var statuses []HealthStatus
    for i := 0; i < len(endpoints); i++ {
        statuses = append(statuses, <-results)
    }
    
    return statuses
}
```

### Phase 3: Updated Main Application

**main.go:**
```go
package main

import (
    "context"
    "fmt"
    "log"
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
    fmt.Println("=" * 50)
    
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
```

### Phase 4: Testing

**monitor/health_test.go:**
```go
package monitor

import (
    "context"
    "net/http"
    "net/http/httptest"
    "testing"
    "time"
)

func TestHealthChecker_Check(t *testing.T) {
    // Create a test server
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("OK"))
    }))
    defer server.Close()
    
    // Create health checker
    hc := NewHealthChecker(5 * time.Second)
    
    // Test successful check
    ctx := context.Background()
    status := hc.Check(ctx, server.URL)
    
    if status.Status != "up" {
        t.Errorf("Expected status 'up', got '%s'", status.Status)
    }
    
    if status.Error != nil {
        t.Errorf("Expected no error, got %v", status.Error)
    }
    
    if status.Duration <= 0 {
        t.Error("Expected positive duration")
    }
}

func TestHealthChecker_CheckMultiple(t *testing.T) {
    // Create test servers
    server1 := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
    }))
    defer server1.Close()
    
    server2 := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusInternalServerError)
    }))
    defer server2.Close()
    
    hc := NewHealthChecker(5 * time.Second)
    endpoints := []string{server1.URL, server2.URL}
    
    ctx := context.Background()
    statuses := hc.CheckMultiple(ctx, endpoints)
    
    if len(statuses) != 2 {
        t.Errorf("Expected 2 statuses, got %d", len(statuses))
    }
    
    // Check first endpoint (should be up)
    if statuses[0].Status != "up" && statuses[1].Status != "up" {
        t.Error("Expected at least one endpoint to be up")
    }
    
    // Check second endpoint (should be unhealthy)
    hasUnhealthy := false
    for _, status := range statuses {
        if status.Status == "unhealthy" {
            hasUnhealthy = true
            break
        }
    }
    if !hasUnhealthy {
        t.Error("Expected at least one endpoint to be unhealthy")
    }
}
```

## ✅ Verification

### Run the Application
```bash
# Run with default settings
go run main.go

# Run with custom environment variables
ENVIRONMENT=production DEBUG=true TIMEOUT=10s go run main.go
```

Expected output:
```
🚀 DevOps Health Monitor Starting...
Environment: development
Debug Mode: false
Timeout: 30s
Log Level: info

🔍 Running health checks...

📊 Health Check Results:
==================================================
✅ https://httpbin.org/status/200
   Status: up
   Duration: 245ms

❌ https://httpbin.org/status/500
   Status: unhealthy
   Duration: 187ms
   Error: HTTP 500

✅ https://httpbin.org/delay/1
   Status: up
   Duration: 1.123s

❌ https://invalid-url-that-does-not-exist.com
   Status: down
   Duration: 2.456s
   Error: dial tcp: lookup invalid-url-that-does-not-exist.com: no such host

✨ Health check completed!
```

### Run Tests
```bash
go test ./...
```

### Build Binary
```bash
# Build for current platform
go build -o health-monitor

# Build for Linux
GOOS=linux GOARCH=amd64 go build -o health-monitor-linux

# Build for Windows
GOOS=windows GOARCH=amd64 go build -o health-monitor.exe
```

## 🧹 Cleanup

Remove the project directory:
```bash
cd ..
rm -rf go-devops-tutorial
```

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| `go: command not found` | Install Go from https://go.dev/dl/ |
| Import cycle error | Reorganize packages to avoid circular dependencies |
| Context deadline exceeded | Increase timeout values |
| Permission denied on binary | Run `chmod +x health-monitor` |

## 📚 Additional Resources

- [Go Official Documentation](https://go.dev/doc/)
- [Effective Go](https://go.dev/doc/effective_go)
- [Go by Example](https://gobyexample.com/)
- [Kubernetes Client-Go](https://github.com/kubernetes/client-go)

## 🏆 Challenge

Extend the health monitor to:
1. Save results to a JSON file
2. Add metrics endpoint for Prometheus
3. Send alerts to Slack/email
4. Support configuration file (YAML/JSON)
5. Add retry logic with exponential backoff

## 📝 Notes

- Go is excellent for DevOps tools due to its simplicity and performance
- Single binary deployment makes distribution easy
- Built-in concurrency is perfect for monitoring multiple services
- Strong standard library reduces external dependencies

---

### 🔗 Navigation
- [→ Next Tutorial: Building CLI Tools with Cobra](../281-building-cli-tools-with-cobra/)
- [📚 Programming Languages Index](../README.md)
- [🏠 Main Index](../../README.md)
