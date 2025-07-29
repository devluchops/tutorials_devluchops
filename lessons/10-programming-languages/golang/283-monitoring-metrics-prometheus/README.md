# Tutorial 283: Monitoring and Metrics with Prometheus in Go

## 🎯 Overview

Learn to build production-ready monitoring systems using Go and Prometheus. Create custom metrics, exporters, and monitoring dashboards for your applications and infrastructure.

### What You'll Learn
- ✅ Prometheus client library fundamentals
- ✅ Creating custom metrics (counters, gauges, histograms)
- ✅ Building Prometheus exporters
- ✅ HTTP middleware for automatic monitoring
- ✅ Service discovery and health checks
- ✅ Alerting and notification systems

### Prerequisites
- Go installed (1.21+)
- Docker and Docker Compose
- Basic understanding of Prometheus
- Completed previous Go tutorials (280-282)

### Time to Complete
⏱️ Approximately 75 minutes

## 🏗️ Architecture

We'll build a comprehensive monitoring system:

```
Monitoring System
├── Application Metrics
│   ├── HTTP Request Metrics
│   ├── Business Logic Metrics
│   └── Custom Gauges & Counters
├── Infrastructure Exporter
│   ├── System Metrics
│   ├── Database Metrics
│   └── External Service Checks
├── Prometheus Server
│   ├── Metric Collection
│   ├── Alert Rules
│   └── Service Discovery
└── Alerting & Dashboards
    ├── Grafana Dashboard
    ├── Webhook Notifications
    └── Slack Integration
```

## 🛠️ Setup

### Step 1: Initialize Project
```bash
mkdir go-prometheus-monitoring
cd go-prometheus-monitoring
go mod init monitoring-system
```

### Step 2: Install Dependencies
```bash
# Prometheus client library
go get github.com/prometheus/client_golang@v1.17.0

# HTTP router
go get github.com/gorilla/mux@v1.8.0

# Configuration
go get gopkg.in/yaml.v3@v3.0.1

# Logging
go get github.com/sirupsen/logrus@v1.9.3

# HTTP client with metrics
go get github.com/prometheus/common@v0.45.0
```

### Step 3: Docker Compose Setup
```bash
mkdir -p docker/{prometheus,grafana}
```

## 📋 Implementation

### Phase 1: Application with Built-in Metrics

**main.go:**
```go
package main

import (
    "context"
    "fmt"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gorilla/mux"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
    "github.com/sirupsen/logrus"

    "monitoring-system/internal/metrics"
    "monitoring-system/internal/middleware"
    "monitoring-system/internal/handlers"
    "monitoring-system/internal/exporter"
)

func main() {
    logger := logrus.New()
    logger.SetFormatter(&logrus.JSONFormatter{})
    
    // Initialize metrics
    metricsCollector := metrics.NewCollector()
    prometheus.MustRegister(metricsCollector)
    
    // Initialize custom metrics
    appMetrics := metrics.NewAppMetrics()
    prometheus.MustRegister(appMetrics)
    
    // Create router with middleware
    router := mux.NewRouter()
    
    // Add metrics middleware
    router.Use(middleware.PrometheusMiddleware(appMetrics))
    router.Use(middleware.LoggingMiddleware(logger))
    
    // Application routes
    apiRouter := router.PathPrefix("/api/v1").Subrouter()
    apiRouter.HandleFunc("/users", handlers.ListUsers(appMetrics)).Methods("GET")
    apiRouter.HandleFunc("/users", handlers.CreateUser(appMetrics)).Methods("POST")
    apiRouter.HandleFunc("/users/{id}", handlers.GetUser(appMetrics)).Methods("GET")
    apiRouter.HandleFunc("/health", handlers.HealthCheck(appMetrics)).Methods("GET")
    
    // Metrics endpoint
    router.Handle("/metrics", promhttp.Handler())
    
    // Start custom exporter
    customExporter := exporter.NewCustomExporter()
    go customExporter.Start()
    
    // HTTP server
    server := &http.Server{
        Addr:         ":8080",
        Handler:      router,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }
    
    // Start server
    go func() {
        logger.Info("Starting server on :8080")
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            logger.Fatal("Server failed to start: ", err)
        }
    }()
    
    // Graceful shutdown
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit
    
    logger.Info("Shutting down server...")
    
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    
    if err := server.Shutdown(ctx); err != nil {
        logger.Fatal("Server forced to shutdown: ", err)
    }
    
    logger.Info("Server stopped")
}
```

### Phase 2: Custom Metrics Collector

**internal/metrics/app_metrics.go:**
```go
package metrics

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

type AppMetrics struct {
    // HTTP metrics
    HTTPRequestsTotal     *prometheus.CounterVec
    HTTPRequestDuration   *prometheus.HistogramVec
    HTTPResponseSize      *prometheus.HistogramVec
    
    // Business logic metrics
    UserRegistrations     prometheus.Counter
    ActiveUsers          prometheus.Gauge
    DatabaseConnections  prometheus.Gauge
    
    // Application metrics
    ErrorsTotal          *prometheus.CounterVec
    ProcessingTime       *prometheus.HistogramVec
    QueueSize           prometheus.Gauge
    
    // Custom metrics
    FeatureUsage        *prometheus.CounterVec
    BackgroundJobs      *prometheus.GaugeVec
}

func NewAppMetrics() *AppMetrics {
    return &AppMetrics{
        HTTPRequestsTotal: promauto.NewCounterVec(
            prometheus.CounterOpts{
                Name: "http_requests_total",
                Help: "Total number of HTTP requests",
            },
            []string{"method", "endpoint", "status_code"},
        ),
        
        HTTPRequestDuration: promauto.NewHistogramVec(
            prometheus.HistogramOpts{
                Name:    "http_request_duration_seconds",
                Help:    "Duration of HTTP requests in seconds",
                Buckets: prometheus.DefBuckets,
            },
            []string{"method", "endpoint"},
        ),
        
        HTTPResponseSize: promauto.NewHistogramVec(
            prometheus.HistogramOpts{
                Name:    "http_response_size_bytes",
                Help:    "Size of HTTP responses in bytes",
                Buckets: []float64{100, 1000, 10000, 100000, 1000000},
            },
            []string{"method", "endpoint"},
        ),
        
        UserRegistrations: promauto.NewCounter(
            prometheus.CounterOpts{
                Name: "user_registrations_total",
                Help: "Total number of user registrations",
            },
        ),
        
        ActiveUsers: promauto.NewGauge(
            prometheus.GaugeOpts{
                Name: "active_users",
                Help: "Number of currently active users",
            },
        ),
        
        DatabaseConnections: promauto.NewGauge(
            prometheus.GaugeOpts{
                Name: "database_connections",
                Help: "Number of active database connections",
            },
        ),
        
        ErrorsTotal: promauto.NewCounterVec(
            prometheus.CounterOpts{
                Name: "errors_total",
                Help: "Total number of errors by type",
            },
            []string{"type", "service"},
        ),
        
        ProcessingTime: promauto.NewHistogramVec(
            prometheus.HistogramOpts{
                Name:    "processing_time_seconds",
                Help:    "Time spent processing requests",
                Buckets: []float64{0.1, 0.5, 1.0, 2.5, 5.0, 10.0},
            },
            []string{"operation", "status"},
        ),
        
        QueueSize: promauto.NewGauge(
            prometheus.GaugeOpts{
                Name: "queue_size",
                Help: "Current size of the processing queue",
            },
        ),
        
        FeatureUsage: promauto.NewCounterVec(
            prometheus.CounterOpts{
                Name: "feature_usage_total",
                Help: "Total usage count for application features",
            },
            []string{"feature", "user_type"},
        ),
        
        BackgroundJobs: promauto.NewGaugeVec(
            prometheus.GaugeOpts{
                Name: "background_jobs",
                Help: "Number of background jobs by status",
            },
            []string{"job_type", "status"},
        ),
    }
}

// Increment user registration counter
func (m *AppMetrics) IncrementUserRegistrations() {
    m.UserRegistrations.Inc()
}

// Set active users count
func (m *AppMetrics) SetActiveUsers(count float64) {
    m.ActiveUsers.Set(count)
}

// Set database connections
func (m *AppMetrics) SetDatabaseConnections(count float64) {
    m.DatabaseConnections.Set(count)
}

// Record error
func (m *AppMetrics) RecordError(errorType, service string) {
    m.ErrorsTotal.WithLabelValues(errorType, service).Inc()
}

// Record processing time
func (m *AppMetrics) RecordProcessingTime(operation, status string, duration float64) {
    m.ProcessingTime.WithLabelValues(operation, status).Observe(duration)
}

// Record feature usage
func (m *AppMetrics) RecordFeatureUsage(feature, userType string) {
    m.FeatureUsage.WithLabelValues(feature, userType).Inc()
}

// Set background job count
func (m *AppMetrics) SetBackgroundJobs(jobType, status string, count float64) {
    m.BackgroundJobs.WithLabelValues(jobType, status).Set(count)
}
```

### Phase 3: HTTP Middleware for Automatic Metrics

**internal/middleware/prometheus.go:**
```go
package middleware

import (
    "net/http"
    "strconv"
    "strings"
    "time"
    
    "github.com/gorilla/mux"
    "monitoring-system/internal/metrics"
)

type responseWriter struct {
    http.ResponseWriter
    statusCode int
    size       int
}

func (rw *responseWriter) WriteHeader(code int) {
    rw.statusCode = code
    rw.ResponseWriter.WriteHeader(code)
}

func (rw *responseWriter) Write(b []byte) (int, error) {
    size, err := rw.ResponseWriter.Write(b)
    rw.size += size
    return size, err
}

func PrometheusMiddleware(appMetrics *metrics.AppMetrics) mux.MiddlewareFunc {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            
            // Wrap response writer to capture status code and size
            rw := &responseWriter{
                ResponseWriter: w,
                statusCode:     200,
            }
            
            // Get route pattern for better grouping
            route := mux.CurrentRoute(r)
            var endpoint string
            if route != nil {
                if template, err := route.GetPathTemplate(); err == nil {
                    endpoint = template
                } else {
                    endpoint = r.URL.Path
                }
            } else {
                endpoint = r.URL.Path
            }
            
            // Clean endpoint for metrics (remove query params, normalize)
            endpoint = normalizeEndpoint(endpoint)
            
            // Process request
            next.ServeHTTP(rw, r)
            
            // Record metrics
            duration := time.Since(start).Seconds()
            method := r.Method
            statusCode := strconv.Itoa(rw.statusCode)
            
            // HTTP request counter
            appMetrics.HTTPRequestsTotal.WithLabelValues(
                method, endpoint, statusCode,
            ).Inc()
            
            // HTTP request duration
            appMetrics.HTTPRequestDuration.WithLabelValues(
                method, endpoint,
            ).Observe(duration)
            
            // HTTP response size
            appMetrics.HTTPResponseSize.WithLabelValues(
                method, endpoint,
            ).Observe(float64(rw.size))
            
            // Record errors for 4xx and 5xx status codes
            if rw.statusCode >= 400 {
                errorType := "client_error"
                if rw.statusCode >= 500 {
                    errorType = "server_error"
                }
                appMetrics.RecordError(errorType, "http")
            }
        })
    }
}

func normalizeEndpoint(endpoint string) string {
    // Remove query parameters
    if idx := strings.Index(endpoint, "?"); idx != -1 {
        endpoint = endpoint[:idx]
    }
    
    // Normalize common patterns
    endpoint = strings.TrimSuffix(endpoint, "/")
    if endpoint == "" {
        endpoint = "/"
    }
    
    return endpoint
}
```

**internal/middleware/logging.go:**
```go
package middleware

import (
    "net/http"
    "time"
    
    "github.com/sirupsen/logrus"
)

func LoggingMiddleware(logger *logrus.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            
            rw := &responseWriter{
                ResponseWriter: w,
                statusCode:     200,
            }
            
            next.ServeHTTP(rw, r)
            
            duration := time.Since(start)
            
            logger.WithFields(logrus.Fields{
                "method":       r.Method,
                "path":         r.URL.Path,
                "status_code":  rw.statusCode,
                "duration_ms":  duration.Milliseconds(),
                "size":         rw.size,
                "remote_addr":  r.RemoteAddr,
                "user_agent":   r.UserAgent(),
            }).Info("HTTP request completed")
        })
    }
}
```

### Phase 4: Application Handlers with Metrics

**internal/handlers/users.go:**
```go
package handlers

import (
    "encoding/json"
    "fmt"
    "math/rand"
    "net/http"
    "strconv"
    "time"
    
    "github.com/gorilla/mux"
    "monitoring-system/internal/metrics"
)

type User struct {
    ID       int    `json:"id"`
    Name     string `json:"name"`
    Email    string `json:"email"`
    Status   string `json:"status"`
    Created  time.Time `json:"created"`
}

var users = []User{
    {ID: 1, Name: "John Doe", Email: "john@example.com", Status: "active", Created: time.Now()},
    {ID: 2, Name: "Jane Smith", Email: "jane@example.com", Status: "active", Created: time.Now()},
    {ID: 3, Name: "Bob Wilson", Email: "bob@example.com", Status: "inactive", Created: time.Now()},
}

func ListUsers(appMetrics *metrics.AppMetrics) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        // Simulate processing time
        time.Sleep(time.Duration(rand.Intn(100)) * time.Millisecond)
        
        // Record feature usage
        appMetrics.RecordFeatureUsage("list_users", "api")
        
        // Simulate database connections
        appMetrics.SetDatabaseConnections(float64(rand.Intn(10) + 5))
        
        // Filter active users
        activeUsers := make([]User, 0)
        for _, user := range users {
            if user.Status == "active" {
                activeUsers = append(activeUsers, user)
            }
        }
        
        // Update active users metric
        appMetrics.SetActiveUsers(float64(len(activeUsers)))
        
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(map[string]interface{}{
            "users": users,
            "total": len(users),
            "active": len(activeUsers),
        })
        
        // Record processing time
        duration := time.Since(start).Seconds()
        appMetrics.RecordProcessingTime("list_users", "success", duration)
    }
}

func CreateUser(appMetrics *metrics.AppMetrics) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        var user User
        if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
            appMetrics.RecordError("validation_error", "user_service")
            appMetrics.RecordProcessingTime("create_user", "error", time.Since(start).Seconds())
            http.Error(w, "Invalid request body", http.StatusBadRequest)
            return
        }
        
        // Simulate processing
        time.Sleep(time.Duration(rand.Intn(200)) * time.Millisecond)
        
        // Assign ID and timestamp
        user.ID = len(users) + 1
        user.Created = time.Now()
        user.Status = "active"
        
        users = append(users, user)
        
        // Record metrics
        appMetrics.IncrementUserRegistrations()
        appMetrics.RecordFeatureUsage("create_user", "api")
        appMetrics.SetActiveUsers(float64(len(users)))
        
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusCreated)
        json.NewEncoder(w).Encode(user)
        
        duration := time.Since(start).Seconds()
        appMetrics.RecordProcessingTime("create_user", "success", duration)
    }
}

func GetUser(appMetrics *metrics.AppMetrics) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        vars := mux.Vars(r)
        idStr := vars["id"]
        
        id, err := strconv.Atoi(idStr)
        if err != nil {
            appMetrics.RecordError("validation_error", "user_service")
            appMetrics.RecordProcessingTime("get_user", "error", time.Since(start).Seconds())
            http.Error(w, "Invalid user ID", http.StatusBadRequest)
            return
        }
        
        // Simulate database lookup time
        time.Sleep(time.Duration(rand.Intn(50)) * time.Millisecond)
        
        // Find user
        for _, user := range users {
            if user.ID == id {
                appMetrics.RecordFeatureUsage("get_user", "api")
                
                w.Header().Set("Content-Type", "application/json")
                json.NewEncoder(w).Encode(user)
                
                duration := time.Since(start).Seconds()
                appMetrics.RecordProcessingTime("get_user", "success", duration)
                return
            }
        }
        
        // User not found
        appMetrics.RecordError("not_found", "user_service")
        appMetrics.RecordProcessingTime("get_user", "error", time.Since(start).Seconds())
        http.Error(w, "User not found", http.StatusNotFound)
    }
}

func HealthCheck(appMetrics *metrics.AppMetrics) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        // Simulate health checks
        dbHealthy := rand.Float32() > 0.1 // 90% healthy
        cacheHealthy := rand.Float32() > 0.05 // 95% healthy
        
        status := "healthy"
        statusCode := http.StatusOK
        
        if !dbHealthy || !cacheHealthy {
            status = "unhealthy"
            statusCode = http.StatusServiceUnavailable
            appMetrics.RecordError("health_check_failed", "system")
        }
        
        health := map[string]interface{}{
            "status": status,
            "timestamp": time.Now(),
            "checks": map[string]bool{
                "database": dbHealthy,
                "cache": cacheHealthy,
            },
            "uptime": time.Since(start).Seconds(),
        }
        
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(statusCode)
        json.NewEncoder(w).Encode(health)
        
        appMetrics.RecordFeatureUsage("health_check", "system")
        duration := time.Since(start).Seconds()
        
        if statusCode == http.StatusOK {
            appMetrics.RecordProcessingTime("health_check", "success", duration)
        } else {
            appMetrics.RecordProcessingTime("health_check", "error", duration)
        }
    }
}
```

### Phase 5: Custom Infrastructure Exporter

**internal/exporter/custom_exporter.go:**
```go
package exporter

import (
    "context"
    "math/rand"
    "net/http"
    "runtime"
    "time"
    
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
    "github.com/sirupsen/logrus"
)

type CustomExporter struct {
    logger *logrus.Logger
    
    // System metrics
    cpuUsage     prometheus.Gauge
    memoryUsage  prometheus.Gauge
    diskUsage    *prometheus.GaugeVec
    
    // Application metrics
    goroutines   prometheus.Gauge
    gcDuration   prometheus.Gauge
    
    // Business metrics
    salesTotal       prometheus.Counter
    revenue         prometheus.Gauge
    customerSatisfaction *prometheus.GaugeVec
    
    // External service metrics
    externalServiceUp    *prometheus.GaugeVec
    externalServiceLatency *prometheus.GaugeVec
}

func NewCustomExporter() *CustomExporter {
    logger := logrus.New()
    
    return &CustomExporter{
        logger: logger,
        
        cpuUsage: prometheus.NewGauge(prometheus.GaugeOpts{
            Name: "system_cpu_usage_percent",
            Help: "Current CPU usage percentage",
        }),
        
        memoryUsage: prometheus.NewGauge(prometheus.GaugeOpts{
            Name: "system_memory_usage_bytes",
            Help: "Current memory usage in bytes",
        }),
        
        diskUsage: prometheus.NewGaugeVec(prometheus.GaugeOpts{
            Name: "system_disk_usage_bytes",
            Help: "Disk usage by mount point",
        }, []string{"mount_point", "device"}),
        
        goroutines: prometheus.NewGauge(prometheus.GaugeOpts{
            Name: "go_goroutines_current",
            Help: "Current number of goroutines",
        }),
        
        gcDuration: prometheus.NewGauge(prometheus.GaugeOpts{
            Name: "go_gc_duration_seconds",
            Help: "Time spent in garbage collection",
        }),
        
        salesTotal: prometheus.NewCounter(prometheus.CounterOpts{
            Name: "business_sales_total",
            Help: "Total number of sales",
        }),
        
        revenue: prometheus.NewGauge(prometheus.GaugeOpts{
            Name: "business_revenue_dollars",
            Help: "Current revenue in dollars",
        }),
        
        customerSatisfaction: prometheus.NewGaugeVec(prometheus.GaugeOpts{
            Name: "business_customer_satisfaction_score",
            Help: "Customer satisfaction score by region",
        }, []string{"region", "product"}),
        
        externalServiceUp: prometheus.NewGaugeVec(prometheus.GaugeOpts{
            Name: "external_service_up",
            Help: "External service availability (1 = up, 0 = down)",
        }, []string{"service", "endpoint"}),
        
        externalServiceLatency: prometheus.NewGaugeVec(prometheus.GaugeOpts{
            Name: "external_service_latency_seconds",
            Help: "External service response latency",
        }, []string{"service", "endpoint"}),
    }
}

func (e *CustomExporter) Start() {
    // Register metrics
    prometheus.MustRegister(
        e.cpuUsage,
        e.memoryUsage,
        e.diskUsage,
        e.goroutines,
        e.gcDuration,
        e.salesTotal,
        e.revenue,
        e.customerSatisfaction,
        e.externalServiceUp,
        e.externalServiceLatency,
    )
    
    // Start metrics collection goroutines
    go e.collectSystemMetrics()
    go e.collectBusinessMetrics()
    go e.collectExternalServiceMetrics()
    
    // Start metrics server on different port
    http.Handle("/custom-metrics", promhttp.Handler())
    e.logger.Info("Custom exporter started on :9090/custom-metrics")
    
    server := &http.Server{
        Addr: ":9090",
    }
    
    if err := server.ListenAndServe(); err != nil {
        e.logger.Error("Custom exporter server failed: ", err)
    }
}

func (e *CustomExporter) collectSystemMetrics() {
    ticker := time.NewTicker(10 * time.Second)
    defer ticker.Stop()
    
    for {
        select {
        case <-ticker.C:
            // Simulate CPU usage
            cpuPercent := 20 + rand.Float64()*60 // 20-80%
            e.cpuUsage.Set(cpuPercent)
            
            // Get actual memory stats
            var m runtime.MemStats
            runtime.ReadMemStats(&m)
            e.memoryUsage.Set(float64(m.Alloc))
            e.goroutines.Set(float64(runtime.NumGoroutine()))
            
            // Simulate disk usage
            e.diskUsage.WithLabelValues("/", "/dev/sda1").Set(1024*1024*1024*50) // 50GB
            e.diskUsage.WithLabelValues("/tmp", "/dev/sda2").Set(1024*1024*1024*10) // 10GB
            
            e.logger.Debug("System metrics collected")
        }
    }
}

func (e *CustomExporter) collectBusinessMetrics() {
    ticker := time.NewTicker(30 * time.Second)
    defer ticker.Stop()
    
    for {
        select {
        case <-ticker.C:
            // Simulate business metrics
            if rand.Float32() > 0.7 { // 30% chance of new sale
                e.salesTotal.Inc()
            }
            
            // Update revenue (simulate growth)
            currentRevenue := 100000 + rand.Float64()*50000
            e.revenue.Set(currentRevenue)
            
            // Update customer satisfaction by region
            regions := []string{"us-east", "us-west", "europe", "asia"}
            products := []string{"premium", "standard", "basic"}
            
            for _, region := range regions {
                for _, product := range products {
                    score := 3.5 + rand.Float64()*1.5 // 3.5-5.0
                    e.customerSatisfaction.WithLabelValues(region, product).Set(score)
                }
            }
            
            e.logger.Debug("Business metrics collected")
        }
    }
}

func (e *CustomExporter) collectExternalServiceMetrics() {
    ticker := time.NewTicker(20 * time.Second)
    defer ticker.Stop()
    
    services := map[string]string{
        "payment-gateway": "https://api.stripe.com/health",
        "email-service":   "https://api.sendgrid.com/health", 
        "cdn":            "https://cdn.example.com/health",
        "database":       "postgres://localhost:5432/health",
    }
    
    for {
        select {
        case <-ticker.C:
            for service, endpoint := range services {
                // Simulate health check
                start := time.Now()
                up := rand.Float32() > 0.05 // 95% uptime
                latency := time.Since(start).Seconds()
                
                if up {
                    e.externalServiceUp.WithLabelValues(service, endpoint).Set(1)
                    // Simulate realistic latency
                    latency = 0.05 + rand.Float64()*0.2 // 50-250ms
                } else {
                    e.externalServiceUp.WithLabelValues(service, endpoint).Set(0)
                    latency = 5.0 // Timeout
                }
                
                e.externalServiceLatency.WithLabelValues(service, endpoint).Set(latency)
            }
            
            e.logger.Debug("External service metrics collected")
        }
    }
}

// Health check for the exporter itself
func (e *CustomExporter) HealthCheck(ctx context.Context) error {
    // Perform health checks here
    return nil
}
```

### Phase 6: Docker Compose Configuration

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    networks:
      - monitoring
    labels:
      - "prometheus.io/scrape=true"
      - "prometheus.io/port=8080"
      - "prometheus.io/path=/metrics"

  custom-exporter:
    build: .
    command: ["./exporter"]
    ports:
      - "9090:9090"
    networks:
      - monitoring
    labels:
      - "prometheus.io/scrape=true"
      - "prometheus.io/port=9090"
      - "prometheus.io/path=/custom-metrics"

  prometheus:
    image: prom/prometheus:v2.47.0
    ports:
      - "9091:9090"
    volumes:
      - ./docker/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./docker/prometheus/alerts.yml:/etc/prometheus/alerts.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:10.1.0
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - ./docker/grafana/provisioning:/etc/grafana/provisioning
      - ./docker/grafana/dashboards:/var/lib/grafana/dashboards
      - grafana_data:/var/lib/grafana
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:v0.26.0
    ports:
      - "9093:9093"
    volumes:
      - ./docker/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
```

**docker/prometheus/prometheus.yml:**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'app'
    static_configs:
      - targets: ['app:8080']
    metrics_path: '/metrics'
    scrape_interval: 10s

  - job_name: 'custom-exporter'
    static_configs:
      - targets: ['custom-exporter:9090']
    metrics_path: '/custom-metrics'
    scrape_interval: 15s

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

**docker/prometheus/alerts.yml:**
```yaml
groups:
  - name: application_alerts
    rules:
      - alert: HighErrorRate
        expr: rate(errors_total[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} errors per second"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High response time"
          description: "95th percentile response time is {{ $value }}s"

      - alert: ServiceDown
        expr: external_service_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "External service is down"
          description: "Service {{ $labels.service }} is unreachable"

      - alert: HighCPUUsage
        expr: system_cpu_usage_percent > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage"
          description: "CPU usage is {{ $value }}%"
```

## ✅ Verification

### Build and Run the System

```bash
# Build the application
go build -o app main.go

# Build the custom exporter
go build -o exporter internal/exporter/main.go

# Create Dockerfile
cat > Dockerfile << EOF
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod tidy && go build -o app main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/app .
EXPOSE 8080
CMD ["./app"]
EOF

# Start the monitoring stack
docker-compose up -d

# Check services
docker-compose ps
```

### Test the Application and Metrics

```bash
# Generate some traffic
curl http://localhost:8080/api/v1/health
curl http://localhost:8080/api/v1/users
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'

# Check metrics endpoints
curl http://localhost:8080/metrics
curl http://localhost:9090/custom-metrics

# Access monitoring interfaces
echo "Prometheus: http://localhost:9091"
echo "Grafana: http://localhost:3000 (admin/admin123)"
echo "Alertmanager: http://localhost:9093"
```

### Verify Metrics in Prometheus

Navigate to http://localhost:9091 and query:

```promql
# HTTP request rate
rate(http_requests_total[5m])

# Response time percentiles
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rate
rate(errors_total[5m])

# Custom business metrics
business_revenue_dollars
business_customer_satisfaction_score

# System metrics
system_cpu_usage_percent
go_goroutines_current
```

## 🧹 Cleanup

```bash
docker-compose down -v
docker system prune -f
```

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| Metrics not appearing | Check `/metrics` endpoint and Prometheus config |
| High cardinality warnings | Reduce label combinations, use label limits |
| Grafana connection errors | Verify Prometheus datasource configuration |
| Memory issues | Tune Prometheus retention and sample rates |

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Four Golden Signals](https://sre.google/sre-book/monitoring-distributed-systems/)

## 🏆 Challenge

Enhance the monitoring system with:
1. **Custom Dashboards** - Create Grafana dashboards for different teams
2. **SLI/SLO Tracking** - Implement service level indicators
3. **Multi-dimensional Metrics** - Add more sophisticated label strategies
4. **Alert Routing** - Configure different notification channels
5. **Metrics Federation** - Set up multi-cluster monitoring
6. **Cost Optimization** - Implement metric sampling and retention policies

## 📝 Notes

- Keep metric cardinality under control
- Use histograms for timing data
- Implement proper error handling in metric collection
- Consider metric naming conventions
- Monitor the monitoring system itself

---

### 🔗 Navigation
- [← Previous Tutorial: Kubernetes Client and Operators](../282-kubernetes-client-and-operators/)
- [→ Next Tutorial: Infrastructure Automation Tools](../284-infrastructure-automation-tools/)
- [📚 Programming Languages Index](../README.md)
- [🏠 Main Index](../../README.md)
