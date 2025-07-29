// scripts/web-vitals-monitor.js
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

class WebVitalsMonitor {
  constructor(options = {}) {
    this.metrics = {};
    this.thresholds = {
      LCP: 2500,    // Largest Contentful Paint
      FID: 100,     // First Input Delay
      CLS: 0.1,     // Cumulative Layout Shift
      FCP: 1800,    // First Contentful Paint
      TTFB: 800,    // Time to First Byte
      ...options.thresholds
    };
    this.callbacks = options.callbacks || {};
    
    this.initializeTracking();
  }
  
  initializeTracking() {
    // Track Core Web Vitals
    getCLS(this.handleMetric.bind(this, 'CLS'));
    getFID(this.handleMetric.bind(this, 'FID'));
    getFCP(this.handleMetric.bind(this, 'FCP'));
    getLCP(this.handleMetric.bind(this, 'LCP'));
    getTTFB(this.handleMetric.bind(this, 'TTFB'));
    
    // Track custom metrics
    this.trackResourceTiming();
    this.trackNavigationTiming();
    this.trackUserInteractions();
  }
  
  handleMetric(name, metric) {
    const value = metric.value;
    const threshold = this.thresholds[name];
    const rating = this.getRating(name, value, threshold);
    
    this.metrics[name] = {
      value,
      threshold,
      rating,
      timestamp: Date.now(),
      id: metric.id,
      delta: metric.delta,
      entries: metric.entries
    };
    
    // Log metric
    console.log(`${name}: ${value} (${rating})`);
    
    // Send to analytics
    this.sendToAnalytics(name, metric);
    
    // Execute callback if provided
    if (this.callbacks[name]) {
      this.callbacks[name](metric);
    }
    
    // Check if metric exceeds threshold
    if (rating === 'poor') {
      this.handlePoorMetric(name, metric);
    }
  }
  
  getRating(name, value, threshold) {
    const thresholds = {
      LCP: { good: 2500, poor: 4000 },
      FID: { good: 100, poor: 300 },
      CLS: { good: 0.1, poor: 0.25 },
      FCP: { good: 1800, poor: 3000 },
      TTFB: { good: 800, poor: 1800 }
    };
    
    const metricThresholds = thresholds[name];
    if (!metricThresholds) return 'unknown';
    
    if (value <= metricThresholds.good) return 'good';
    if (value <= metricThresholds.poor) return 'needs-improvement';
    return 'poor';
  }
  
  trackResourceTiming() {
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (entry.transferSize > 1024 * 1024) { // Resources > 1MB
          console.warn(`Large resource detected: ${entry.name} (${entry.transferSize} bytes)`);
        }
        
        if (entry.duration > 1000) { // Slow resources > 1s
          console.warn(`Slow resource detected: ${entry.name} (${entry.duration}ms)`);
        }
      }
    });
    
    observer.observe({ entryTypes: ['resource'] });
  }
  
  trackNavigationTiming() {
    window.addEventListener('load', () => {
      const navigation = performance.getEntriesByType('navigation')[0];
      
      const metrics = {
        'DNS Lookup': navigation.domainLookupEnd - navigation.domainLookupStart,
        'TCP Connection': navigation.connectEnd - navigation.connectStart,
        'SSL Handshake': navigation.secureConnectionStart > 0 ? 
          navigation.connectEnd - navigation.secureConnectionStart : 0,
        'Time to First Byte': navigation.responseStart - navigation.requestStart,
        'Content Download': navigation.responseEnd - navigation.responseStart,
        'DOM Processing': navigation.domContentLoadedEventEnd - navigation.responseEnd,
        'Load Complete': navigation.loadEventEnd - navigation.loadEventStart
      };
      
      console.table(metrics);
      this.sendNavigationMetrics(metrics);
    });
  }
  
  trackUserInteractions() {
    let interactionCount = 0;
    
    ['click', 'keydown', 'scroll'].forEach(eventType => {
      document.addEventListener(eventType, () => {
        interactionCount++;
      }, { passive: true });
    });
    
    // Report interaction count periodically
    setInterval(() => {
      if (interactionCount > 0) {
        this.sendToAnalytics('user-interactions', {
          count: interactionCount,
          period: '30s'
        });
        interactionCount = 0;
      }
    }, 30000);
  }
  
  sendToAnalytics(name, metric) {
    // Send to Google Analytics 4
    if (typeof gtag !== 'undefined') {
      gtag('event', name, {
        event_category: 'Web Vitals',
        value: Math.round(metric.value),
        custom_parameter_1: metric.rating || 'unknown'
      });
    }
    
    // Send to custom analytics endpoint
    fetch('/api/analytics/web-vitals', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        metric: name,
        value: metric.value,
        rating: this.getRating(name, metric.value),
        timestamp: Date.now(),
        url: window.location.href,
        userAgent: navigator.userAgent
      })
    }).catch(console.error);
  }
  
  sendNavigationMetrics(metrics) {
    fetch('/api/analytics/navigation', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        metrics,
        timestamp: Date.now(),
        url: window.location.href
      })
    }).catch(console.error);
  }
  
  handlePoorMetric(name, metric) {
    console.warn(`Poor ${name} detected:`, metric);
    
    // Send alert
    if (this.callbacks.onPoorMetric) {
      this.callbacks.onPoorMetric(name, metric);
    }
    
    // Log detailed information for debugging
    if (name === 'LCP') {
      console.log('LCP element:', metric.entries[metric.entries.length - 1]?.element);
    }
    
    if (name === 'CLS') {
      console.log('Layout shift sources:', metric.entries);
    }
  }
  
  getMetricsSummary() {
    const summary = {};
    
    for (const [name, data] of Object.entries(this.metrics)) {
      summary[name] = {
        value: data.value,
        rating: data.rating,
        threshold: data.threshold,
        passed: data.rating !== 'poor'
      };
    }
    
    return summary;
  }
  
  generateReport() {
    const summary = this.getMetricsSummary();
    const overallScore = Object.values(summary).filter(m => m.passed).length / 
                        Object.keys(summary).length * 100;
    
    return {
      timestamp: new Date().toISOString(),
      url: window.location.href,
      overallScore: Math.round(overallScore),
      metrics: summary,
      userAgent: navigator.userAgent,
      viewport: {
        width: window.innerWidth,
        height: window.innerHeight
      },
      connection: navigator.connection ? {
        effectiveType: navigator.connection.effectiveType,
        downlink: navigator.connection.downlink,
        rtt: navigator.connection.rtt
      } : null
    };
  }
}

// Usage example
const monitor = new WebVitalsMonitor({
  thresholds: {
    LCP: 2000,  // Custom threshold
    FID: 80,    // Custom threshold
  },
  callbacks: {
    LCP: (metric) => console.log('LCP callback:', metric),
    onPoorMetric: (name, metric) => {
      // Send alert to monitoring service
      console.error(`ALERT: Poor ${name} performance detected`);
    }
  }
});

// Export metrics after page interaction
window.addEventListener('beforeunload', () => {
  const report = monitor.generateReport();
  navigator.sendBeacon('/api/analytics/final-report', JSON.stringify(report));
});

export default WebVitalsMonitor;
