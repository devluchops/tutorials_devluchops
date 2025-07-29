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
