# Application Performance Benchmarking & Optimization

Complete guide to performance testing, profiling, monitoring, and optimization techniques for web applications, APIs, and system infrastructure.

## What You'll Learn

- **Load Testing** - JMeter, Artillery, k6 for stress testing
- **Profiling Tools** - CPU, memory, and I/O profiling
- **Frontend Performance** - Lighthouse, WebPageTest, Core Web Vitals
- **Backend Optimization** - Database tuning, caching strategies
- **Monitoring & Alerting** - Real-time performance tracking
- **Benchmarking Methodologies** - Scientific performance measurement

## Load Testing & Stress Testing

### **🚀 k6 Load Testing**
```javascript
// load-test-basic.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up to 100 users
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 200 }, // Ramp up to 200 users
    { duration: '5m', target: 200 }, // Stay at 200 users
    { duration: '2m', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
    http_req_failed: ['rate<0.1'],    // Error rate under 10%
    errors: ['rate<0.1'],             // Custom error rate under 10%
  },
};

// Test data
const baseUrl = 'https://api.example.com';
const users = [
  { id: 1, email: 'user1@example.com', password: 'password123' },
  { id: 2, email: 'user2@example.com', password: 'password123' },
  { id: 3, email: 'user3@example.com', password: 'password123' },
];

// Setup function (runs once per VU)
export function setup() {
  console.log('Starting load test setup...');
  return { baseUrl, users };
}

// Main test function
export default function (data) {
  const user = data.users[Math.floor(Math.random() * data.users.length)];
  
  // Test 1: Login
  const loginResponse = http.post(`${data.baseUrl}/auth/login`, {
    email: user.email,
    password: user.password,
  }, {
    headers: {
      'Content-Type': 'application/json',
    },
  });
  
  const loginSuccess = check(loginResponse, {
    'login status is 200': (r) => r.status === 200,
    'login response time < 500ms': (r) => r.timings.duration < 500,
    'login contains token': (r) => r.json('token') !== undefined,
  });
  
  errorRate.add(!loginSuccess);
  
  if (loginSuccess) {
    const token = loginResponse.json('token');
    
    // Test 2: Get user profile
    const profileResponse = http.get(`${data.baseUrl}/users/profile`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });
    
    const profileSuccess = check(profileResponse, {
      'profile status is 200': (r) => r.status === 200,
      'profile response time < 300ms': (r) => r.timings.duration < 300,
      'profile contains user data': (r) => r.json('id') !== undefined,
    });
    
    errorRate.add(!profileSuccess);
    
    // Test 3: Create a post
    const postData = {
      title: `Test Post ${Math.random()}`,
      content: 'This is a test post created during load testing',
      tags: ['test', 'performance'],
    };
    
    const createPostResponse = http.post(`${data.baseUrl}/posts`, 
      JSON.stringify(postData), {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });
    
    const postSuccess = check(createPostResponse, {
      'create post status is 201': (r) => r.status === 201,
      'create post response time < 1s': (r) => r.timings.duration < 1000,
      'post contains id': (r) => r.json('id') !== undefined,
    });
    
    errorRate.add(!postSuccess);
    
    // Test 4: Get posts list
    const postsResponse = http.get(`${data.baseUrl}/posts?limit=10`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });
    
    check(postsResponse, {
      'posts list status is 200': (r) => r.status === 200,
      'posts list response time < 400ms': (r) => r.timings.duration < 400,
      'posts list contains data': (r) => r.json('data') !== undefined,
    });
  }
  
  // Random sleep between 1-3 seconds
  sleep(Math.random() * 2 + 1);
}

// Teardown function (runs once after all VUs finish)
export function teardown(data) {
  console.log('Load test completed');
}
```

### **🎯 Artillery Configuration**
```yaml
# artillery-config.yml
config:
  target: 'https://api.example.com'
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Ramp up load"
    - duration: 300
      arrivalRate: 100
      name: "Sustained load"
    - duration: 60
      arrivalRate: 200
      name: "Peak load"
  processor: "./processor.js"
  payload:
    path: "./users.csv"
    fields:
      - "email"
      - "password"
  defaults:
    headers:
      Content-Type: "application/json"
      User-Agent: "Artillery Load Test"

scenarios:
  - name: "User Journey"
    weight: 70
    flow:
      - post:
          url: "/auth/login"
          json:
            email: "{{ email }}"
            password: "{{ password }}"
          capture:
            - json: "$.token"
              as: "authToken"
      - get:
          url: "/users/profile"
          headers:
            Authorization: "Bearer {{ authToken }}"
      - post:
          url: "/posts"
          headers:
            Authorization: "Bearer {{ authToken }}"
          json:
            title: "Test Post {{ $randomString() }}"
            content: "Load test content"
            tags: ["test", "performance"]
      - get:
          url: "/posts"
          headers:
            Authorization: "Bearer {{ authToken }}"
          qs:
            limit: 10

  - name: "Anonymous Browsing"
    weight: 30
    flow:
      - get:
          url: "/posts/public"
      - get:
          url: "/posts/{{ $randomInt(1, 1000) }}"
      - get:
          url: "/search?q={{ $randomString() }}"

# processor.js functions
functions:
  generateRandomData: "generateRandomData"
  logResponse: "logResponse"
```

### **🔧 JMeter Test Plan (XML)**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="API Performance Test">
      <stringProp name="TestPlan.comments">Comprehensive API performance test</stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <elementProp name="TestPlan.arguments" elementType="Arguments" guiclass="ArgumentsPanel">
        <collectionProp name="Arguments.arguments"/>
      </elementProp>
      <stringProp name="TestPlan.user_define_classpath"></stringProp>
    </TestPlan>
    <hashTree>
      <!-- Thread Group Configuration -->
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="User Load">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <intProp name="LoopController.loops">-1</intProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">100</stringProp>
        <stringProp name="ThreadGroup.ramp_time">300</stringProp>
        <longProp name="ThreadGroup.start_time">1640995200000</longProp>
        <longProp name="ThreadGroup.end_time">1640998800000</longProp>
        <boolProp name="ThreadGroup.scheduler">true</boolProp>
        <stringProp name="ThreadGroup.duration">3600</stringProp>
        <stringProp name="ThreadGroup.delay">0</stringProp>
      </ThreadGroup>
      
      <!-- HTTP Request Defaults -->
      <ConfigTestElement guiclass="HttpDefaultsGui" testclass="ConfigTestElement" testname="HTTP Request Defaults">
        <elementProp name="HTTPsampler.Arguments" elementType="Arguments" guiclass="HTTPArgumentsPanel">
          <collectionProp name="Arguments.arguments"/>
        </elementProp>
        <stringProp name="HTTPSampler.domain">api.example.com</stringProp>
        <stringProp name="HTTPSampler.port">443</stringProp>
        <stringProp name="HTTPSampler.protocol">https</stringProp>
        <stringProp name="HTTPSampler.contentEncoding"></stringProp>
        <stringProp name="HTTPSampler.path"></stringProp>
      </ConfigTestElement>
    </hashTree>
  </hashTree>
</jmeterTestPlan>
```

## Frontend Performance Testing

### **⚡ Lighthouse CI Configuration**
```javascript
// lighthouse-ci.js
const lighthouse = require('lighthouse');
const chromeLauncher = require('chrome-launcher');
const fs = require('fs');

async function runLighthouseAudit(url, options = {}) {
  const chrome = await chromeLauncher.launch({
    chromeFlags: ['--headless', '--disable-gpu', '--no-sandbox']
  });
  
  const opts = {
    logLevel: 'info',
    output: 'html',
    onlyCategories: ['performance', 'accessibility', 'best-practices', 'seo'],
    port: chrome.port,
    ...options
  };
  
  const runnerResult = await lighthouse(url, opts);
  
  // Generate report
  const reportHtml = runnerResult.report;
  const score = runnerResult.lhr.categories.performance.score * 100;
  
  console.log(`Performance score: ${score}`);
  
  // Save report
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  fs.writeFileSync(`lighthouse-report-${timestamp}.html`, reportHtml);
  
  await chrome.kill();
  
  return {
    score,
    metrics: runnerResult.lhr.audits,
    reportPath: `lighthouse-report-${timestamp}.html`
  };
}

// Performance budget checks
function checkPerformanceBudget(metrics) {
  const budget = {
    'first-contentful-paint': 2000,    // 2 seconds
    'largest-contentful-paint': 4000,  // 4 seconds
    'cumulative-layout-shift': 0.1,    // CLS threshold
    'total-blocking-time': 300,        // 300ms
    'speed-index': 4000                // 4 seconds
  };
  
  const results = {};
  
  for (const [metric, threshold] of Object.entries(budget)) {
    const actual = metrics[metric]?.numericValue || 0;
    const passed = actual <= threshold;
    
    results[metric] = {
      actual,
      threshold,
      passed,
      difference: actual - threshold
    };
    
    console.log(
      `${metric}: ${actual}ms (${passed ? 'PASS' : 'FAIL'}) - ` +
      `Budget: ${threshold}ms`
    );
  }
  
  return results;
}

// Automated performance testing
async function runPerformanceTests() {
  const urls = [
    'https://example.com',
    'https://example.com/products',
    'https://example.com/checkout',
    'https://example.com/profile'
  ];
  
  const results = [];
  
  for (const url of urls) {
    console.log(`Testing ${url}...`);
    
    try {
      const result = await runLighthouseAudit(url);
      const budgetResults = checkPerformanceBudget(result.metrics);
      
      results.push({
        url,
        score: result.score,
        budgetResults,
        reportPath: result.reportPath
      });
      
    } catch (error) {
      console.error(`Failed to test ${url}:`, error);
      results.push({
        url,
        error: error.message
      });
    }
  }
  
  // Generate summary report
  const summary = {
    timestamp: new Date().toISOString(),
    totalTests: urls.length,
    passed: results.filter(r => r.score && r.score >= 90).length,
    averageScore: results.reduce((sum, r) => sum + (r.score || 0), 0) / results.length,
    results
  };
  
  fs.writeFileSync('performance-summary.json', JSON.stringify(summary, null, 2));
  console.log('Performance testing completed. Summary saved to performance-summary.json');
  
  return summary;
}

module.exports = {
  runLighthouseAudit,
  checkPerformanceBudget,
  runPerformanceTests
};
```

### **📊 Web Vitals Monitoring**
```javascript
// web-vitals-monitor.js
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

// Usage
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
```

## Database Performance Testing

### **🗄️ Database Benchmark Scripts**
```python
# database_benchmark.py
import time
import statistics
import asyncio
import psycopg2
import mysql.connector
import pymongo
from concurrent.futures import ThreadPoolExecutor
import matplotlib.pyplot as plt
import pandas as pd

class DatabaseBenchmark:
    def __init__(self, db_type, connection_params):
        self.db_type = db_type
        self.connection_params = connection_params
        self.results = []
        
    def connect(self):
        """Create database connection based on type"""
        if self.db_type == 'postgresql':
            return psycopg2.connect(**self.connection_params)
        elif self.db_type == 'mysql':
            return mysql.connector.connect(**self.connection_params)
        elif self.db_type == 'mongodb':
            client = pymongo.MongoClient(**self.connection_params)
            return client[self.connection_params.get('database', 'test')]
        else:
            raise ValueError(f"Unsupported database type: {self.db_type}")
    
    def execute_query(self, query, params=None):
        """Execute a single query and measure time"""
        start_time = time.time()
        
        try:
            if self.db_type in ['postgresql', 'mysql']:
                conn = self.connect()
                cursor = conn.cursor()
                cursor.execute(query, params or [])
                result = cursor.fetchall()
                cursor.close()
                conn.close()
            elif self.db_type == 'mongodb':
                db = self.connect()
                collection = db[query['collection']]
                if query['operation'] == 'find':
                    result = list(collection.find(query.get('filter', {})))
                elif query['operation'] == 'insert':
                    result = collection.insert_many(query['documents'])
                elif query['operation'] == 'update':
                    result = collection.update_many(
                        query['filter'], 
                        query['update']
                    )
            
            execution_time = time.time() - start_time
            return {
                'success': True,
                'execution_time': execution_time,
                'result_count': len(result) if hasattr(result, '__len__') else 1
            }
            
        except Exception as e:
            execution_time = time.time() - start_time
            return {
                'success': False,
                'execution_time': execution_time,
                'error': str(e)
            }
    
    def benchmark_query(self, query, iterations=100, params=None):
        """Benchmark a query with multiple iterations"""
        results = []
        
        print(f"Benchmarking query: {iterations} iterations")
        
        for i in range(iterations):
            result = self.execute_query(query, params)
            results.append(result)
            
            if i % 10 == 0:
                print(f"Progress: {i}/{iterations}")
        
        # Calculate statistics
        execution_times = [r['execution_time'] for r in results if r['success']]
        error_count = len([r for r in results if not r['success']])
        
        if execution_times:
            stats = {
                'query': str(query)[:100],
                'iterations': iterations,
                'success_rate': (len(execution_times) / iterations) * 100,
                'error_count': error_count,
                'min_time': min(execution_times),
                'max_time': max(execution_times),
                'avg_time': statistics.mean(execution_times),
                'median_time': statistics.median(execution_times),
                'p95_time': self.percentile(execution_times, 95),
                'p99_time': self.percentile(execution_times, 99),
                'std_dev': statistics.stdev(execution_times) if len(execution_times) > 1 else 0
            }
        else:
            stats = {
                'query': str(query)[:100],
                'iterations': iterations,
                'success_rate': 0,
                'error_count': error_count,
                'error': 'All queries failed'
            }
        
        self.results.append(stats)
        return stats
    
    def percentile(self, data, percentile):
        """Calculate percentile"""
        sorted_data = sorted(data)
        index = int((percentile / 100) * len(sorted_data))
        return sorted_data[min(index, len(sorted_data) - 1)]
    
    def concurrent_benchmark(self, query, total_queries=1000, concurrent_users=10):
        """Run concurrent queries to test database under load"""
        queries_per_user = total_queries // concurrent_users
        
        def run_user_queries(user_id):
            user_results = []
            for _ in range(queries_per_user):
                result = self.execute_query(query)
                user_results.append(result)
            return user_results
        
        print(f"Running {total_queries} queries with {concurrent_users} concurrent users")
        
        start_time = time.time()
        
        with ThreadPoolExecutor(max_workers=concurrent_users) as executor:
            futures = [
                executor.submit(run_user_queries, i) 
                for i in range(concurrent_users)
            ]
            
            all_results = []
            for future in futures:
                all_results.extend(future.result())
        
        total_time = time.time() - start_time
        
        # Calculate statistics
        execution_times = [r['execution_time'] for r in all_results if r['success']]
        error_count = len([r for r in all_results if not r['success']])
        
        stats = {
            'query': str(query)[:100],
            'total_queries': total_queries,
            'concurrent_users': concurrent_users,
            'total_time': total_time,
            'queries_per_second': total_queries / total_time,
            'success_rate': (len(execution_times) / total_queries) * 100,
            'error_count': error_count,
            'avg_response_time': statistics.mean(execution_times) if execution_times else 0,
            'p95_response_time': self.percentile(execution_times, 95) if execution_times else 0,
            'p99_response_time': self.percentile(execution_times, 99) if execution_times else 0
        }
        
        return stats
    
    def create_test_data(self, table_name, record_count=10000):
        """Create test data for benchmarking"""
        print(f"Creating {record_count} test records...")
        
        if self.db_type == 'postgresql':
            conn = self.connect()
            cursor = conn.cursor()
            
            # Create table
            cursor.execute(f"""
                CREATE TABLE IF NOT EXISTS {table_name} (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(100),
                    email VARCHAR(100),
                    age INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    score DECIMAL(10,2)
                )
            """)
            
            # Insert test data
            for i in range(record_count):
                cursor.execute(f"""
                    INSERT INTO {table_name} (name, email, age, score) 
                    VALUES (%s, %s, %s, %s)
                """, (
                    f"User {i}",
                    f"user{i}@example.com",
                    20 + (i % 50),
                    round(i * 0.1, 2)
                ))
            
            conn.commit()
            cursor.close()
            conn.close()
            
        elif self.db_type == 'mongodb':
            db = self.connect()
            collection = db[table_name]
            
            documents = []
            for i in range(record_count):
                documents.append({
                    'name': f"User {i}",
                    'email': f"user{i}@example.com",
                    'age': 20 + (i % 50),
                    'score': round(i * 0.1, 2),
                    'created_at': time.time()
                })
            
            # Insert in batches
            batch_size = 1000
            for i in range(0, len(documents), batch_size):
                batch = documents[i:i + batch_size]
                collection.insert_many(batch)
    
    def run_benchmark_suite(self, table_name):
        """Run a comprehensive benchmark suite"""
        print("Starting comprehensive database benchmark...")
        
        # Create test data
        self.create_test_data(table_name, 50000)
        
        if self.db_type in ['postgresql', 'mysql']:
            queries = [
                f"SELECT * FROM {table_name} LIMIT 100",
                f"SELECT * FROM {table_name} WHERE age > 30 LIMIT 100",
                f"SELECT COUNT(*) FROM {table_name}",
                f"SELECT AVG(score) FROM {table_name}",
                f"SELECT * FROM {table_name} WHERE email LIKE '%example.com' LIMIT 100",
                f"SELECT * FROM {table_name} ORDER BY score DESC LIMIT 100"
            ]
        elif self.db_type == 'mongodb':
            queries = [
                {'collection': table_name, 'operation': 'find', 'filter': {}},
                {'collection': table_name, 'operation': 'find', 'filter': {'age': {'$gt': 30}}},
                {'collection': table_name, 'operation': 'find', 'filter': {'email': {'$regex': 'example.com'}}},
            ]
        
        # Run benchmarks
        for query in queries:
            print(f"\n{'='*50}")
            print(f"Benchmarking: {query}")
            print('='*50)
            
            # Single-threaded benchmark
            result = self.benchmark_query(query, iterations=100)
            print(f"Single-threaded results:")
            self.print_results(result)
            
            # Concurrent benchmark
            concurrent_result = self.concurrent_benchmark(query, 500, 10)
            print(f"\nConcurrent results:")
            self.print_concurrent_results(concurrent_result)
    
    def print_results(self, result):
        """Print benchmark results in a formatted way"""
        print(f"Success Rate: {result.get('success_rate', 0):.2f}%")
        print(f"Average Time: {result.get('avg_time', 0)*1000:.2f}ms")
        print(f"Median Time: {result.get('median_time', 0)*1000:.2f}ms")
        print(f"P95 Time: {result.get('p95_time', 0)*1000:.2f}ms")
        print(f"P99 Time: {result.get('p99_time', 0)*1000:.2f}ms")
        print(f"Min Time: {result.get('min_time', 0)*1000:.2f}ms")
        print(f"Max Time: {result.get('max_time', 0)*1000:.2f}ms")
        print(f"Std Dev: {result.get('std_dev', 0)*1000:.2f}ms")
    
    def print_concurrent_results(self, result):
        """Print concurrent benchmark results"""
        print(f"Total Queries: {result['total_queries']}")
        print(f"Concurrent Users: {result['concurrent_users']}")
        print(f"Total Time: {result['total_time']:.2f}s")
        print(f"Queries/Second: {result['queries_per_second']:.2f}")
        print(f"Success Rate: {result['success_rate']:.2f}%")
        print(f"Avg Response Time: {result['avg_response_time']*1000:.2f}ms")
        print(f"P95 Response Time: {result['p95_response_time']*1000:.2f}ms")
        print(f"P99 Response Time: {result['p99_response_time']*1000:.2f}ms")
    
    def generate_report(self, output_file='benchmark_report.html'):
        """Generate HTML report with charts"""
        if not self.results:
            print("No benchmark results to report")
            return
        
        # Create DataFrame
        df = pd.DataFrame(self.results)
        
        # Create visualizations
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        
        # Average response time chart
        if 'avg_time' in df.columns:
            df['avg_time_ms'] = df['avg_time'] * 1000
            axes[0, 0].bar(range(len(df)), df['avg_time_ms'])
            axes[0, 0].set_title('Average Response Time (ms)')
            axes[0, 0].set_ylabel('Milliseconds')
        
        # Success rate chart
        if 'success_rate' in df.columns:
            axes[0, 1].bar(range(len(df)), df['success_rate'])
            axes[0, 1].set_title('Success Rate (%)')
            axes[0, 1].set_ylabel('Percentage')
        
        # P95 vs P99 comparison
        if 'p95_time' in df.columns and 'p99_time' in df.columns:
            df['p95_time_ms'] = df['p95_time'] * 1000
            df['p99_time_ms'] = df['p99_time'] * 1000
            x = range(len(df))
            axes[1, 0].bar([i - 0.2 for i in x], df['p95_time_ms'], width=0.4, label='P95')
            axes[1, 0].bar([i + 0.2 for i in x], df['p99_time_ms'], width=0.4, label='P99')
            axes[1, 0].set_title('P95 vs P99 Response Times')
            axes[1, 0].legend()
        
        # Error count chart
        if 'error_count' in df.columns:
            axes[1, 1].bar(range(len(df)), df['error_count'])
            axes[1, 1].set_title('Error Count')
            axes[1, 1].set_ylabel('Number of Errors')
        
        plt.tight_layout()
        plt.savefig('benchmark_charts.png', dpi=300, bbox_inches='tight')
        
        # Generate HTML report
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Database Benchmark Report</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 40px; }}
                table {{ border-collapse: collapse; width: 100%; }}
                th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
                th {{ background-color: #f2f2f2; }}
                .chart {{ text-align: center; margin: 20px 0; }}
            </style>
        </head>
        <body>
            <h1>Database Benchmark Report</h1>
            <p>Generated on: {time.strftime('%Y-%m-%d %H:%M:%S')}</p>
            <p>Database Type: {self.db_type}</p>
            
            <div class="chart">
                <img src="benchmark_charts.png" alt="Benchmark Charts">
            </div>
            
            <h2>Detailed Results</h2>
            {df.to_html(table_id='benchmark-table')}
        </body>
        </html>
        """
        
        with open(output_file, 'w') as f:
            f.write(html_content)
        
        print(f"Report generated: {output_file}")

# Example usage
if __name__ == "__main__":
    # PostgreSQL benchmark
    pg_params = {
        'host': 'localhost',
        'database': 'testdb',
        'user': 'testuser',
        'password': 'testpass'
    }
    
    pg_benchmark = DatabaseBenchmark('postgresql', pg_params)
    pg_benchmark.run_benchmark_suite('benchmark_table')
    pg_benchmark.generate_report('postgresql_benchmark.html')
```

## System Resource Monitoring

### **📈 Resource Monitor Script**
```bash
#!/bin/bash
# system_performance_monitor.sh
# Comprehensive system performance monitoring script

# Configuration
MONITOR_DURATION=3600  # 1 hour
SAMPLE_INTERVAL=5      # 5 seconds
OUTPUT_DIR="/var/log/performance"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Initialize log files
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
CPU_LOG="$OUTPUT_DIR/cpu_usage_$TIMESTAMP.log"
MEMORY_LOG="$OUTPUT_DIR/memory_usage_$TIMESTAMP.log"
DISK_LOG="$OUTPUT_DIR/disk_usage_$TIMESTAMP.log"
NETWORK_LOG="$OUTPUT_DIR/network_usage_$TIMESTAMP.log"
PROCESS_LOG="$OUTPUT_DIR/top_processes_$TIMESTAMP.log"

# Logging function
log_message() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$OUTPUT_DIR/monitor.log"
}

# CPU monitoring function
monitor_cpu() {
    while true; do
        # Get CPU usage
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        cpu_usage=${cpu_usage%.*}
        
        # Get load average
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | sed 's/^ *//')
        
        # Get CPU per core
        cpu_per_core=$(mpstat -P ALL 1 1 | awk '/Average/ && /[0-9]/ {print $3}' | tr '\n' ' ')
        
        # Log data
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$cpu_usage,$load_avg,$cpu_per_core" >> "$CPU_LOG"
        
        # Check threshold
        if [ "$cpu_usage" -gt "$ALERT_THRESHOLD_CPU" ]; then
            log_message "ALERT" "High CPU usage: ${cpu_usage}%"
            
            # Get top CPU processes
            echo "$(date '+%Y-%m-%d %H:%M:%S') - High CPU Alert" >> "$PROCESS_LOG"
            ps aux --sort=-%cpu --no-headers | head -10 >> "$PROCESS_LOG"
            echo "---" >> "$PROCESS_LOG"
        fi
        
        sleep "$SAMPLE_INTERVAL"
    done
}

# Memory monitoring function
monitor_memory() {
    while true; do
        # Get memory info
        memory_info=$(free -m)
        total_mem=$(echo "$memory_info" | awk '/^Mem:/ {print $2}')
        used_mem=$(echo "$memory_info" | awk '/^Mem:/ {print $3}')
        free_mem=$(echo "$memory_info" | awk '/^Mem:/ {print $4}')
        available_mem=$(echo "$memory_info" | awk '/^Mem:/ {print $7}')
        
        # Calculate percentage
        mem_usage_percent=$(( (used_mem * 100) / total_mem ))
        
        # Get swap info
        swap_total=$(echo "$memory_info" | awk '/^Swap:/ {print $2}')
        swap_used=$(echo "$memory_info" | awk '/^Swap:/ {print $3}')
        swap_percent=0
        if [ "$swap_total" -gt 0 ]; then
            swap_percent=$(( (swap_used * 100) / swap_total ))
        fi
        
        # Log data
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$total_mem,$used_mem,$free_mem,$available_mem,$mem_usage_percent,$swap_used,$swap_percent" >> "$MEMORY_LOG"
        
        # Check threshold
        if [ "$mem_usage_percent" -gt "$ALERT_THRESHOLD_MEMORY" ]; then
            log_message "ALERT" "High memory usage: ${mem_usage_percent}%"
            
            # Get top memory processes
            echo "$(date '+%Y-%m-%d %H:%M:%S') - High Memory Alert" >> "$PROCESS_LOG"
            ps aux --sort=-%mem --no-headers | head -10 >> "$PROCESS_LOG"
            echo "---" >> "$PROCESS_LOG"
        fi
        
        sleep "$SAMPLE_INTERVAL"
    done
}

# Disk monitoring function
monitor_disk() {
    while true; do
        # Monitor all mounted filesystems
        df -h | grep -vE '^Filesystem|tmpfs|cdrom|udev' | while read output; do
            partition=$(echo "$output" | awk '{print $1}')
            usage_percent=$(echo "$output" | awk '{print $5}' | sed 's/%//')
            mount_point=$(echo "$output" | awk '{print $6}')
            size=$(echo "$output" | awk '{print $2}')
            used=$(echo "$output" | awk '{print $3}')
            available=$(echo "$output" | awk '{print $4}')
            
            # Log data
            echo "$(date '+%Y-%m-%d %H:%M:%S'),$partition,$mount_point,$size,$used,$available,$usage_percent" >> "$DISK_LOG"
            
            # Check threshold
            if [ "$usage_percent" -gt "$ALERT_THRESHOLD_DISK" ]; then
                log_message "ALERT" "High disk usage on $mount_point: ${usage_percent}%"
                
                # Find largest directories
                echo "$(date '+%Y-%m-%d %H:%M:%S') - High Disk Usage Alert for $mount_point" >> "$PROCESS_LOG"
                du -sh "$mount_point"/* 2>/dev/null | sort -hr | head -10 >> "$PROCESS_LOG"
                echo "---" >> "$PROCESS_LOG"
            fi
        done
        
        sleep "$SAMPLE_INTERVAL"
    done
}

# Network monitoring function
monitor_network() {
    # Get initial values
    prev_rx_bytes=$(cat /sys/class/net/*/statistics/rx_bytes | awk '{sum+=$1} END {print sum}')
    prev_tx_bytes=$(cat /sys/class/net/*/statistics/tx_bytes | awk '{sum+=$1} END {print sum}')
    prev_time=$(date +%s)
    
    sleep "$SAMPLE_INTERVAL"
    
    while true; do
        # Get current values
        curr_rx_bytes=$(cat /sys/class/net/*/statistics/rx_bytes | awk '{sum+=$1} END {print sum}')
        curr_tx_bytes=$(cat /sys/class/net/*/statistics/tx_bytes | awk '{sum+=$1} END {print sum}')
        curr_time=$(date +%s)
        
        # Calculate rates
        time_diff=$((curr_time - prev_time))
        rx_rate=$(( (curr_rx_bytes - prev_rx_bytes) / time_diff ))
        tx_rate=$(( (curr_tx_bytes - prev_tx_bytes) / time_diff ))
        
        # Convert to human readable
        rx_rate_mb=$(echo "scale=2; $rx_rate / 1024 / 1024" | bc)
        tx_rate_mb=$(echo "scale=2; $tx_rate / 1024 / 1024" | bc)
        
        # Get connection counts
        tcp_connections=$(netstat -tn | grep ESTABLISHED | wc -l)
        listening_ports=$(netstat -tln | grep LISTEN | wc -l)
        
        # Log data
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$rx_rate,$tx_rate,$rx_rate_mb,$tx_rate_mb,$tcp_connections,$listening_ports" >> "$NETWORK_LOG"
        
        # Update previous values
        prev_rx_bytes=$curr_rx_bytes
        prev_tx_bytes=$curr_tx_bytes
        prev_time=$curr_time
        
        sleep "$SAMPLE_INTERVAL"
    done
}

# I/O monitoring function
monitor_io() {
    while true; do
        # Get I/O statistics
        iostat -x 1 1 | awk '/^[a-z]/ && !/^avg-cpu/ {
            printf "%s,%s,%s,%s,%s,%s,%s\n", 
            strftime("%Y-%m-%d %H:%M:%S"), $1, $4, $5, $6, $9, $10
        }' >> "$OUTPUT_DIR/io_usage_$TIMESTAMP.log"
        
        sleep "$SAMPLE_INTERVAL"
    done
}

# Generate performance report
generate_report() {
    local report_file="$OUTPUT_DIR/performance_report_$TIMESTAMP.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>System Performance Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .metric { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .alert { background: #ffebee; border-left: 5px solid #f44336; }
        .good { background: #e8f5e8; border-left: 5px solid #4caf50; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>System Performance Report</h1>
    <p>Generated: $(date)</p>
    <p>Duration: $MONITOR_DURATION seconds</p>
    
    <h2>Summary</h2>
    <div class="metric">
        <h3>CPU Usage</h3>
        <p>Average: $(awk -F',' '{sum+=$2; count++} END {printf "%.2f", sum/count}' "$CPU_LOG")%</p>
        <p>Peak: $(awk -F',' 'BEGIN{max=0} {if($2>max) max=$2} END {print max}' "$CPU_LOG")%</p>
    </div>
    
    <div class="metric">
        <h3>Memory Usage</h3>
        <p>Average: $(awk -F',' '{sum+=$6; count++} END {printf "%.2f", sum/count}' "$MEMORY_LOG")%</p>
        <p>Peak: $(awk -F',' 'BEGIN{max=0} {if($6>max) max=$6} END {print max}' "$MEMORY_LOG")%</p>
    </div>
    
    <h2>Detailed Logs</h2>
    <p>CPU Log: <a href="$(basename "$CPU_LOG")">$(basename "$CPU_LOG")</a></p>
    <p>Memory Log: <a href="$(basename "$MEMORY_LOG")">$(basename "$MEMORY_LOG")</a></p>
    <p>Disk Log: <a href="$(basename "$DISK_LOG")">$(basename "$DISK_LOG")</a></p>
    <p>Network Log: <a href="$(basename "$NETWORK_LOG")">$(basename "$NETWORK_LOG")</a></p>
    <p>Process Log: <a href="$(basename "$PROCESS_LOG")">$(basename "$PROCESS_LOG")</a></p>
    
</body>
</html>
EOF

    log_message "INFO" "Performance report generated: $report_file"
}

# Signal handlers
cleanup() {
    log_message "INFO" "Stopping performance monitoring..."
    kill $(jobs -p) 2>/dev/null
    generate_report
    exit 0
}

trap cleanup SIGINT SIGTERM

# Main execution
main() {
    log_message "INFO" "Starting system performance monitoring for $MONITOR_DURATION seconds"
    
    # Start monitoring functions in background
    monitor_cpu &
    monitor_memory &
    monitor_disk &
    monitor_network &
    monitor_io &
    
    # Wait for specified duration
    sleep "$MONITOR_DURATION"
    
    # Generate final report
    cleanup
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## Useful Links

- [k6 Documentation](https://k6.io/docs/)
- [Artillery Documentation](https://artillery.io/docs/)
- [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci)
- [Web Vitals](https://web.dev/vitals/)
- [JMeter User Manual](https://jmeter.apache.org/usermanual/index.html)
