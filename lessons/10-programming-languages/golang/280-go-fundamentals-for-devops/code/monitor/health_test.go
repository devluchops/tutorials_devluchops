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
