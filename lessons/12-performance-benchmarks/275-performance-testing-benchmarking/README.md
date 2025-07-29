# Performance Testing & Benchmarking Complete Guide

Master performance testing, load testing, profiling, and optimization techniques for web applications and systems using modern tools and best practices.

## What You'll Learn

- **Load Testing** - Apache JMeter, k6, Artillery performance testing
- **Profiling Tools** - CPU, memory, and application profiling
- **Benchmark Frameworks** - Performance measurement and comparison
- **Web Performance** - Core Web Vitals, Lighthouse optimization
- **Database Performance** - Query optimization, index tuning
- **System Monitoring** - APM tools, metrics collection

## Load Testing Frameworks

### **🚀 k6 Performance Testing**
```javascript
// basic_load_test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const responseTimeTrend = new Trend('response_time_trend');

// Test configuration
export const options = {
  stages: [
    { duration: '2m', target: 10 },   // Ramp up to 10 users
    { duration: '5m', target: 10 },   // Stay at 10 users
    { duration: '2m', target: 50 },   // Ramp up to 50 users
    { duration: '5m', target: 50 },   // Stay at 50 users
    { duration: '2m', target: 0 },    // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(90) < 500', 'p(95) < 1000', 'p(99) < 2000'],
    http_req_failed: ['rate < 0.1'],
    errors: ['rate < 0.1'],
  },
};

// Setup function (runs once)
export function setup() {
  console.log('Starting load test...');
  const response = http.get('https://test-api.k6.io/public/crocodiles/');
  return { baseUrl: 'https://test-api.k6.io' };
}

// Main test function
export default function (data) {
  const baseUrl = data.baseUrl;
  
  // Test scenario 1: Get all crocodiles
  let response = http.get(`${baseUrl}/public/crocodiles/`);
  
  const isSuccessful = check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has crocodiles': (r) => JSON.parse(r.body).length > 0,
  });
  
  errorRate.add(!isSuccessful);
  responseTimeTrend.add(response.timings.duration);
  
  sleep(1);
  
  // Test scenario 2: Get specific crocodile
  const crocodileId = Math.floor(Math.random() * 10) + 1;
  response = http.get(`${baseUrl}/public/crocodiles/${crocodileId}/`);
  
  check(response, {
    'crocodile detail status is 200': (r) => r.status === 200,
    'crocodile has name': (r) => JSON.parse(r.body).name !== undefined,
  });
  
  sleep(2);
  
  // Test scenario 3: Create new crocodile (authenticated)
  const payload = JSON.stringify({
    name: `Test Crocodile ${Date.now()}`,
    sex: 'M',
    date_of_birth: '2020-01-01',
  });
  
  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer your-token-here',
    },
  };
  
  response = http.post(`${baseUrl}/my/crocodiles/`, payload, params);
  
  check(response, {
    'create crocodile status': (r) => r.status === 201 || r.status === 401,
  });
  
  sleep(1);
}

// Teardown function (runs once)
export function teardown(data) {
  console.log('Load test completed');
}
```

### **⚡ Advanced k6 Scenarios**
```javascript
// advanced_scenarios.js
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

// Shared test data
const testData = new SharedArray('test data', function () {
  return JSON.parse(open('./test-data.json'));
});

// Configuration with multiple scenarios
export const options = {
  scenarios: {
    // Constant load test
    constant_load: {
      executor: 'constant-vus',
      vus: 20,
      duration: '5m',
      tags: { test_type: 'constant_load' },
    },
    
    // Spike test
    spike_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 0 },
        { duration: '1m', target: 100 },
        { duration: '10s', target: 0 },
      ],
      gracefulRampDown: '30s',
      tags: { test_type: 'spike' },
    },
    
    // Stress test
    stress_test: {
      executor: 'ramping-arrival-rate',
      startRate: 1,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 200,
      stages: [
        { duration: '2m', target: 10 },
        { duration: '5m', target: 50 },
        { duration: '2m', target: 100 },
        { duration: '5m', target: 100 },
        { duration: '2m', target: 0 },
      ],
      tags: { test_type: 'stress' },
    },
  },
  
  thresholds: {
    http_req_duration: ['p(95) < 2000'],
    http_req_failed: ['rate < 0.05'],
    'http_req_duration{test_type:constant_load}': ['p(90) < 500'],
    'http_req_duration{test_type:spike}': ['p(95) < 3000'],
    'http_req_duration{test_type:stress}': ['p(99) < 5000'],
  },
};

export default function () {
  // Use shared test data
  const userData = testData[Math.floor(Math.random() * testData.length)];
  
  group('API Authentication', function () {
    const loginResponse = http.post('https://api.example.com/auth/login', {
      username: userData.username,
      password: userData.password,
    });
    
    check(loginResponse, {
      'login successful': (r) => r.status === 200,
      'received token': (r) => r.json('token') !== undefined,
    });
    
    const token = loginResponse.json('token');
    
    group('Protected API Calls', function () {
      const headers = { Authorization: `Bearer ${token}` };
      
      // Get user profile
      const profileResponse = http.get('https://api.example.com/profile', { headers });
      check(profileResponse, {
        'profile loaded': (r) => r.status === 200,
      });
      
      // Update user data
      const updateResponse = http.put(
        'https://api.example.com/profile',
        JSON.stringify({ name: userData.name }),
        { headers: { ...headers, 'Content-Type': 'application/json' } }
      );
      
      check(updateResponse, {
        'profile updated': (r) => r.status === 200,
      });
    });
  });
  
  sleep(Math.random() * 3 + 1); // Random sleep between 1-4 seconds
}

// Custom summary report
export function handleSummary(data) {
  return {
    'summary.html': htmlReport(data),
    'summary.json': JSON.stringify(data),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function htmlReport(data) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Load Test Results</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .metric { margin: 10px 0; }
            .passed { color: green; }
            .failed { color: red; }
        </style>
    </head>
    <body>
        <h1>Load Test Summary</h1>
        <div class="metric">
            <strong>Total Requests:</strong> ${data.metrics.http_reqs.count}
        </div>
        <div class="metric">
            <strong>Failed Requests:</strong> ${data.metrics.http_req_failed.count}
        </div>
        <div class="metric">
            <strong>Average Response Time:</strong> ${data.metrics.http_req_duration.avg.toFixed(2)}ms
        </div>
        <div class="metric">
            <strong>95th Percentile:</strong> ${data.metrics.http_req_duration['p(95)'].toFixed(2)}ms
        </div>
    </body>
    </html>
  `;
}
```

### **🔨 Apache JMeter Configuration**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0" jmeter="5.5">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="API Performance Test">
      <stringProp name="TestPlan.comments">Comprehensive API performance test</stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.tearDown_on_shutdown">true</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <elementProp name="TestPlan.arguments" elementType="Arguments" guiclass="ArgumentsPanel">
        <collectionProp name="Arguments.arguments">
          <elementProp name="base_url" elementType="Argument">
            <stringProp name="Argument.name">base_url</stringProp>
            <stringProp name="Argument.value">https://api.example.com</stringProp>
          </elementProp>
          <elementProp name="users" elementType="Argument">
            <stringProp name="Argument.name">users</stringProp>
            <stringProp name="Argument.value">50</stringProp>
          </elementProp>
          <elementProp name="ramp_period" elementType="Argument">
            <stringProp name="Argument.name">ramp_period</stringProp>
            <stringProp name="Argument.value">300</stringProp>
          </elementProp>
        </collectionProp>
      </elementProp>
    </TestPlan>
    <hashTree>
      <!-- Thread Group Configuration -->
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="API Users">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <stringProp name="LoopController.loops">10</stringProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">${users}</stringProp>
        <stringProp name="ThreadGroup.ramp_time">${ramp_period}</stringProp>
        <boolProp name="ThreadGroup.scheduler">false</boolProp>
      </ThreadGroup>
      <hashTree>
        <!-- HTTP Request Defaults -->
        <ConfigTestElement guiclass="HttpDefaultsGui" testclass="ConfigTestElement" testname="HTTP Request Defaults">
          <elementProp name="HTTPsampler.Arguments" elementType="Arguments" guiclass="HTTPArgumentsPanel">
            <collectionProp name="Arguments.arguments"/>
          </elementProp>
          <stringProp name="HTTPSampler.domain">${base_url}</stringProp>
          <stringProp name="HTTPSampler.protocol">https</stringProp>
          <stringProp name="HTTPSampler.contentEncoding">UTF-8</stringProp>
          <stringProp name="HTTPSampler.path"></stringProp>
          <stringProp name="HTTPSampler.connect_timeout">10000</stringProp>
          <stringProp name="HTTPSampler.response_timeout">30000</stringProp>
        </ConfigTestElement>
        
        <!-- Cookie Manager -->
        <CookieManager guiclass="CookiePanel" testclass="CookieManager" testname="HTTP Cookie Manager">
          <collectionProp name="CookieManager.cookies"/>
          <boolProp name="CookieManager.clearEachIteration">false</boolProp>
          <boolProp name="CookieManager.controlledByThreadGroup">false</boolProp>
        </CookieManager>
        
        <!-- Cache Manager -->
        <CacheManager guiclass="CacheManagerGui" testclass="CacheManager" testname="HTTP Cache Manager">
          <boolProp name="clearEachIteration">true</boolProp>
          <boolProp name="useExpires">true</boolProp>
          <boolProp name="CacheManager.controlledByThread">false</boolProp>
        </CacheManager>
      </hashTree>
    </hashTree>
  </hashTree>
</jmeterTestPlan>
```

## Web Performance Testing

### **📊 Lighthouse Performance Automation**
```javascript
// lighthouse_automation.js
const lighthouse = require('lighthouse');
const chromeLauncher = require('chrome-launcher');
const fs = require('fs');

async function runLighthouseAudit(url, options = {}) {
  const chrome = await chromeLauncher.launch({
    chromeFlags: ['--headless', '--no-sandbox', '--disable-gpu']
  });
  
  const lighthouseOptions = {
    logLevel: 'info',
    output: 'html',
    onlyCategories: ['performance', 'accessibility', 'best-practices', 'seo'],
    port: chrome.port,
    ...options
  };
  
  const runnerResult = await lighthouse(url, lighthouseOptions);
  
  await chrome.kill();
  
  return runnerResult;
}

async function performanceMonitoring() {
  const urls = [
    'https://example.com',
    'https://example.com/products',
    'https://example.com/about',
  ];
  
  const results = [];
  
  for (const url of urls) {
    console.log(`Testing ${url}...`);
    
    try {
      const result = await runLighthouseAudit(url);
      const scores = result.report.categories;
      
      const urlResult = {
        url,
        timestamp: new Date().toISOString(),
        performance: scores.performance.score * 100,
        accessibility: scores.accessibility.score * 100,
        bestPractices: scores['best-practices'].score * 100,
        seo: scores.seo.score * 100,
        metrics: {
          firstContentfulPaint: result.report.audits['first-contentful-paint'].numericValue,
          largestContentfulPaint: result.report.audits['largest-contentful-paint'].numericValue,
          cumulativeLayoutShift: result.report.audits['cumulative-layout-shift'].numericValue,
          totalBlockingTime: result.report.audits['total-blocking-time'].numericValue,
        }
      };
      
      results.push(urlResult);
      
      // Save individual report
      fs.writeFileSync(
        `lighthouse-${url.replace(/[^a-z0-9]/gi, '_')}-${Date.now()}.html`,
        result.report
      );
      
    } catch (error) {
      console.error(`Error testing ${url}:`, error);
    }
  }
  
  // Generate summary report
  generateSummaryReport(results);
  
  return results;
}

function generateSummaryReport(results) {
  const summary = {
    testDate: new Date().toISOString(),
    totalUrls: results.length,
    averageScores: {
      performance: results.reduce((sum, r) => sum + r.performance, 0) / results.length,
      accessibility: results.reduce((sum, r) => sum + r.accessibility, 0) / results.length,
      bestPractices: results.reduce((sum, r) => sum + r.bestPractices, 0) / results.length,
      seo: results.reduce((sum, r) => sum + r.seo, 0) / results.length,
    },
    results
  };
  
  fs.writeFileSync('lighthouse-summary.json', JSON.stringify(summary, null, 2));
  
  console.log('Performance Summary:');
  console.log(`Average Performance Score: ${summary.averageScores.performance.toFixed(1)}`);
  console.log(`Average Accessibility Score: ${summary.averageScores.accessibility.toFixed(1)}`);
  console.log(`Average Best Practices Score: ${summary.averageScores.bestPractices.toFixed(1)}`);
  console.log(`Average SEO Score: ${summary.averageScores.seo.toFixed(1)}`);
}

// Core Web Vitals monitoring
async function monitorCoreWebVitals(url) {
  const result = await runLighthouseAudit(url);
  const audits = result.report.audits;
  
  const vitals = {
    lcp: audits['largest-contentful-paint'].numericValue,
    fid: audits['max-potential-fid'].numericValue,
    cls: audits['cumulative-layout-shift'].numericValue,
    fcp: audits['first-contentful-paint'].numericValue,
    ttfb: audits['server-response-time'].numericValue,
  };
  
  // Check against thresholds
  const thresholds = {
    lcp: { good: 2500, poor: 4000 },
    fid: { good: 100, poor: 300 },
    cls: { good: 0.1, poor: 0.25 },
    fcp: { good: 1800, poor: 3000 },
    ttfb: { good: 200, poor: 600 },
  };
  
  const assessment = {};
  for (const [metric, value] of Object.entries(vitals)) {
    const threshold = thresholds[metric];
    if (value <= threshold.good) {
      assessment[metric] = 'good';
    } else if (value <= threshold.poor) {
      assessment[metric] = 'needs-improvement';
    } else {
      assessment[metric] = 'poor';
    }
  }
  
  return { vitals, assessment };
}

// Run monitoring
if (require.main === module) {
  performanceMonitoring().catch(console.error);
}

module.exports = {
  runLighthouseAudit,
  performanceMonitoring,
  monitorCoreWebVitals,
};
```

### **⚡ Browser Performance Profiling**
```javascript
// browser_profiling.js
const puppeteer = require('puppeteer');

class PerformanceProfiler {
  constructor() {
    this.browser = null;
    this.page = null;
  }
  
  async init() {
    this.browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-dev-shm-usage']
    });
    this.page = await this.browser.newPage();
    
    // Enable performance monitoring
    await this.page.coverage.startJSCoverage();
    await this.page.coverage.startCSSCoverage();
    
    // Set viewport
    await this.page.setViewport({ width: 1920, height: 1080 });
  }
  
  async profilePageLoad(url) {
    console.log(`Profiling page load for: ${url}`);
    
    // Start performance monitoring
    await this.page.tracing.start({
      path: `trace-${Date.now()}.json`,
      screenshots: true
    });
    
    const startTime = Date.now();
    
    // Navigate to page
    const response = await this.page.goto(url, {
      waitUntil: 'networkidle2',
      timeout: 30000
    });
    
    const loadTime = Date.now() - startTime;
    
    // Get performance metrics
    const metrics = await this.page.metrics();
    const performanceTiming = JSON.parse(
      await this.page.evaluate(() => JSON.stringify(window.performance.timing))
    );
    
    // Get resource timing
    const resourceTiming = await this.page.evaluate(() => {
      return JSON.stringify(window.performance.getEntriesByType('resource'));
    });
    
    // Stop tracing
    await this.page.tracing.stop();
    
    // Get code coverage
    const jsCoverage = await this.page.coverage.stopJSCoverage();
    const cssCoverage = await this.page.coverage.stopCSSCoverage();
    
    // Calculate coverage percentages
    const jsUsedBytes = jsCoverage.reduce((sum, entry) => {
      return sum + entry.ranges.reduce((rangeSum, range) => {
        return rangeSum + range.end - range.start;
      }, 0);
    }, 0);
    
    const jsTotalBytes = jsCoverage.reduce((sum, entry) => sum + entry.text.length, 0);
    const jsUsagePercentage = jsTotalBytes > 0 ? (jsUsedBytes / jsTotalBytes) * 100 : 0;
    
    const cssUsedBytes = cssCoverage.reduce((sum, entry) => {
      return sum + entry.ranges.reduce((rangeSum, range) => {
        return rangeSum + range.end - range.start;
      }, 0);
    }, 0);
    
    const cssTotalBytes = cssCoverage.reduce((sum, entry) => sum + entry.text.length, 0);
    const cssUsagePercentage = cssTotalBytes > 0 ? (cssUsedBytes / cssTotalBytes) * 100 : 0;
    
    return {
      url,
      timestamp: new Date().toISOString(),
      loadTime,
      statusCode: response.status(),
      metrics: {
        ...metrics,
        domContentLoaded: performanceTiming.domContentLoadedEventEnd - performanceTiming.navigationStart,
        firstPaint: performanceTiming.responseStart - performanceTiming.navigationStart,
        domComplete: performanceTiming.domComplete - performanceTiming.navigationStart,
      },
      resources: JSON.parse(resourceTiming),
      coverage: {
        js: {
          used: jsUsedBytes,
          total: jsTotalBytes,
          percentage: jsUsagePercentage
        },
        css: {
          used: cssUsedBytes,
          total: cssTotalBytes,
          percentage: cssUsagePercentage
        }
      }
    };
  }
  
  async profileUserJourney(steps) {
    const results = [];
    
    for (const step of steps) {
      console.log(`Executing step: ${step.name}`);
      const stepStartTime = Date.now();
      
      try {
        await step.action(this.page);
        const stepEndTime = Date.now();
        
        const metrics = await this.page.metrics();
        
        results.push({
          step: step.name,
          duration: stepEndTime - stepStartTime,
          metrics,
          success: true
        });
      } catch (error) {
        results.push({
          step: step.name,
          error: error.message,
          success: false
        });
      }
    }
    
    return results;
  }
  
  async close() {
    if (this.browser) {
      await this.browser.close();
    }
  }
}

// Example usage
async function runPerformanceTest() {
  const profiler = new PerformanceProfiler();
  await profiler.init();
  
  try {
    // Test page load performance
    const loadResults = await profiler.profilePageLoad('https://example.com');
    console.log('Load Performance:', loadResults);
    
    // Test user journey
    const userJourneySteps = [
      {
        name: 'Navigate to homepage',
        action: async (page) => {
          await page.goto('https://example.com');
          await page.waitForSelector('h1');
        }
      },
      {
        name: 'Search for product',
        action: async (page) => {
          await page.type('input[type="search"]', 'laptop');
          await page.click('button[type="submit"]');
          await page.waitForSelector('.search-results');
        }
      },
      {
        name: 'Click on first result',
        action: async (page) => {
          await page.click('.search-results .product:first-child a');
          await page.waitForSelector('.product-details');
        }
      }
    ];
    
    const journeyResults = await profiler.profileUserJourney(userJourneySteps);
    console.log('User Journey Performance:', journeyResults);
    
  } finally {
    await profiler.close();
  }
}

module.exports = { PerformanceProfiler, runPerformanceTest };
```

## Database Performance Testing

### **📊 Database Benchmark Scripts**
```sql
-- PostgreSQL Performance Testing
-- performance_tests.sql

-- Create test tables
CREATE TABLE IF NOT EXISTS performance_test_users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'active',
    metadata JSONB
);

CREATE TABLE IF NOT EXISTS performance_test_orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES performance_test_users(id),
    order_date TIMESTAMP DEFAULT NOW(),
    total_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    items JSONB
);

-- Insert test data
INSERT INTO performance_test_users (name, email, metadata)
SELECT 
    'User ' || generate_series,
    'user' || generate_series || '@example.com',
    jsonb_build_object(
        'age', 18 + (random() * 50)::int,
        'city', (ARRAY['New York', 'London', 'Tokyo', 'Paris', 'Berlin'])[ceil(random() * 5)],
        'preferences', jsonb_build_object('theme', (ARRAY['light', 'dark'])[ceil(random() * 2)])
    )
FROM generate_series(1, 100000);

INSERT INTO performance_test_orders (user_id, total_amount, items)
SELECT 
    (random() * 100000)::int + 1,
    (random() * 1000 + 10)::decimal(10,2),
    jsonb_build_array(
        jsonb_build_object('product_id', (random() * 1000)::int, 'quantity', (random() * 5)::int + 1),
        jsonb_build_object('product_id', (random() * 1000)::int, 'quantity', (random() * 5)::int + 1)
    )
FROM generate_series(1, 500000);

-- Performance test queries
\timing on

-- Test 1: Simple SELECT with WHERE clause
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM performance_test_users WHERE email = 'user50000@example.com';

-- Test 2: JOIN query
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.name, u.email, COUNT(o.id) as order_count, SUM(o.total_amount) as total_spent
FROM performance_test_users u
LEFT JOIN performance_test_orders o ON u.id = o.user_id
WHERE u.created_at >= NOW() - INTERVAL '30 days'
GROUP BY u.id, u.name, u.email
HAVING COUNT(o.id) > 5
ORDER BY total_spent DESC
LIMIT 100;

-- Test 3: JSON query
EXPLAIN (ANALYZE, BUFFERS)
SELECT name, email, metadata->>'city' as city
FROM performance_test_users 
WHERE metadata->>'age' > '30'
AND metadata->>'city' = 'New York';

-- Test 4: Aggregation query
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    DATE_TRUNC('day', order_date) as order_day,
    COUNT(*) as order_count,
    SUM(total_amount) as daily_revenue,
    AVG(total_amount) as avg_order_value
FROM performance_test_orders
WHERE order_date >= NOW() - INTERVAL '90 days'
GROUP BY DATE_TRUNC('day', order_date)
ORDER BY order_day;

-- Create indexes for optimization
CREATE INDEX CONCURRENTLY idx_users_email ON performance_test_users(email);
CREATE INDEX CONCURRENTLY idx_users_created_at ON performance_test_users(created_at);
CREATE INDEX CONCURRENTLY idx_users_metadata_city ON performance_test_users USING GIN((metadata->>'city'));
CREATE INDEX CONCURRENTLY idx_orders_user_id ON performance_test_orders(user_id);
CREATE INDEX CONCURRENTLY idx_orders_date ON performance_test_orders(order_date);
CREATE INDEX CONCURRENTLY idx_orders_status ON performance_test_orders(status);

-- Re-run tests after indexing
-- Test the same queries again to see performance improvement

-- Performance monitoring queries
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats 
WHERE tablename IN ('performance_test_users', 'performance_test_orders');

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE tablename IN ('performance_test_users', 'performance_test_orders');

-- Cleanup
-- DROP TABLE IF EXISTS performance_test_orders;
-- DROP TABLE IF EXISTS performance_test_users;
```

### **🔧 Database Load Testing Script**
```python
# database_load_test.py
import asyncio
import asyncpg
import time
import statistics
from concurrent.futures import ThreadPoolExecutor
import matplotlib.pyplot as plt
import json

class DatabaseLoadTester:
    def __init__(self, connection_string, max_connections=10):
        self.connection_string = connection_string
        self.max_connections = max_connections
        self.pool = None
        self.results = []
    
    async def setup_pool(self):
        """Initialize connection pool"""
        self.pool = await asyncpg.create_pool(
            self.connection_string,
            min_size=1,
            max_size=self.max_connections
        )
    
    async def execute_query(self, query, params=None):
        """Execute a single query and measure performance"""
        start_time = time.time()
        
        async with self.pool.acquire() as connection:
            try:
                if params:
                    result = await connection.fetch(query, *params)
                else:
                    result = await connection.fetch(query)
                
                end_time = time.time()
                execution_time = (end_time - start_time) * 1000  # Convert to milliseconds
                
                return {
                    'success': True,
                    'execution_time': execution_time,
                    'row_count': len(result),
                    'query': query[:50] + '...' if len(query) > 50 else query
                }
            except Exception as e:
                end_time = time.time()
                execution_time = (end_time - start_time) * 1000
                
                return {
                    'success': False,
                    'execution_time': execution_time,
                    'error': str(e),
                    'query': query[:50] + '...' if len(query) > 50 else query
                }
    
    async def run_concurrent_queries(self, queries, concurrent_users=5, iterations=10):
        """Run queries concurrently to simulate load"""
        print(f"Running {len(queries)} queries with {concurrent_users} concurrent users for {iterations} iterations")
        
        tasks = []
        for _ in range(iterations):
            for _ in range(concurrent_users):
                for query_info in queries:
                    task = self.execute_query(query_info['query'], query_info.get('params'))
                    tasks.append(task)
        
        results = await asyncio.gather(*tasks)
        return results
    
    def analyze_results(self, results):
        """Analyze test results and generate statistics"""
        successful_queries = [r for r in results if r['success']]
        failed_queries = [r for r in results if not r['success']]
        
        if not successful_queries:
            return {
                'total_queries': len(results),
                'successful_queries': 0,
                'failed_queries': len(failed_queries),
                'success_rate': 0,
                'error': 'No successful queries'
            }
        
        execution_times = [r['execution_time'] for r in successful_queries]
        
        analysis = {
            'total_queries': len(results),
            'successful_queries': len(successful_queries),
            'failed_queries': len(failed_queries),
            'success_rate': len(successful_queries) / len(results) * 100,
            'execution_time_stats': {
                'min': min(execution_times),
                'max': max(execution_times),
                'mean': statistics.mean(execution_times),
                'median': statistics.median(execution_times),
                'p95': self.percentile(execution_times, 95),
                'p99': self.percentile(execution_times, 99),
                'std_dev': statistics.stdev(execution_times) if len(execution_times) > 1 else 0
            },
            'errors': {}
        }
        
        # Categorize errors
        for failed_query in failed_queries:
            error_type = failed_query['error']
            if error_type not in analysis['errors']:
                analysis['errors'][error_type] = 0
            analysis['errors'][error_type] += 1
        
        return analysis
    
    def percentile(self, data, percentile):
        """Calculate percentile"""
        sorted_data = sorted(data)
        index = (percentile / 100) * (len(sorted_data) - 1)
        if index.is_integer():
            return sorted_data[int(index)]
        else:
            lower = sorted_data[int(index)]
            upper = sorted_data[int(index) + 1]
            return lower + (upper - lower) * (index - int(index))
    
    def generate_report(self, analysis, output_file='load_test_report.json'):
        """Generate detailed report"""
        report = {
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
            'test_configuration': {
                'max_connections': self.max_connections,
                'connection_string': self.connection_string.split('@')[1] if '@' in self.connection_string else 'hidden'
            },
            'results': analysis
        }
        
        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\nLoad Test Report:")
        print(f"Total Queries: {analysis['total_queries']}")
        print(f"Successful: {analysis['successful_queries']}")
        print(f"Failed: {analysis['failed_queries']}")
        print(f"Success Rate: {analysis['success_rate']:.2f}%")
        print(f"\nExecution Time Statistics (ms):")
        print(f"  Min: {analysis['execution_time_stats']['min']:.2f}")
        print(f"  Max: {analysis['execution_time_stats']['max']:.2f}")
        print(f"  Mean: {analysis['execution_time_stats']['mean']:.2f}")
        print(f"  Median: {analysis['execution_time_stats']['median']:.2f}")
        print(f"  95th Percentile: {analysis['execution_time_stats']['p95']:.2f}")
        print(f"  99th Percentile: {analysis['execution_time_stats']['p99']:.2f}")
        
        if analysis['errors']:
            print(f"\nErrors:")
            for error, count in analysis['errors'].items():
                print(f"  {error}: {count}")
    
    async def close(self):
        """Close connection pool"""
        if self.pool:
            await self.pool.close()

async def main():
    # Database connection configuration
    connection_string = "postgresql://username:password@localhost:5432/testdb"
    
    # Test queries
    test_queries = [
        {
            'query': 'SELECT * FROM performance_test_users WHERE id = $1',
            'params': [12345]
        },
        {
            'query': '''
                SELECT u.name, COUNT(o.id) as order_count 
                FROM performance_test_users u 
                LEFT JOIN performance_test_orders o ON u.id = o.user_id 
                WHERE u.id = $1 
                GROUP BY u.id, u.name
            ''',
            'params': [12345]
        },
        {
            'query': '''
                SELECT DATE_TRUNC('day', order_date) as day, 
                       COUNT(*) as orders, 
                       SUM(total_amount) as revenue
                FROM performance_test_orders 
                WHERE order_date >= NOW() - INTERVAL '7 days'
                GROUP BY DATE_TRUNC('day', order_date)
                ORDER BY day
            '''
        },
        {
            'query': '''
                SELECT metadata->>'city' as city, COUNT(*) as user_count
                FROM performance_test_users
                WHERE metadata->>'city' IS NOT NULL
                GROUP BY metadata->>'city'
                ORDER BY user_count DESC
                LIMIT 10
            '''
        }
    ]
    
    # Initialize load tester
    tester = DatabaseLoadTester(connection_string, max_connections=20)
    
    try:
        await tester.setup_pool()
        
        # Run load test
        results = await tester.run_concurrent_queries(
            test_queries,
            concurrent_users=10,
            iterations=5
        )
        
        # Analyze and report results
        analysis = tester.analyze_results(results)
        tester.generate_report(analysis)
        
    finally:
        await tester.close()

if __name__ == "__main__":
    asyncio.run(main())
```

## System Monitoring & APM

### **📈 Custom APM Implementation**
```python
# apm_monitor.py
import time
import psutil
import json
import threading
from collections import deque, defaultdict
import statistics

class ApplicationPerformanceMonitor:
    def __init__(self, collection_interval=5, retention_minutes=60):
        self.collection_interval = collection_interval
        self.retention_minutes = retention_minutes
        self.max_data_points = retention_minutes * 60 // collection_interval
        
        # Data storage
        self.metrics = defaultdict(lambda: deque(maxlen=self.max_data_points))
        self.alerts = deque(maxlen=1000)
        
        # Monitoring state
        self.monitoring = False
        self.monitor_thread = None
        
        # Thresholds
        self.thresholds = {
            'cpu_percent': 80,
            'memory_percent': 85,
            'disk_usage_percent': 90,
            'response_time_ms': 1000
        }
    
    def start_monitoring(self):
        """Start the monitoring thread"""
        if not self.monitoring:
            self.monitoring = True
            self.monitor_thread = threading.Thread(target=self._monitoring_loop, daemon=True)
            self.monitor_thread.start()
            print("APM monitoring started")
    
    def stop_monitoring(self):
        """Stop the monitoring thread"""
        self.monitoring = False
        if self.monitor_thread:
            self.monitor_thread.join()
        print("APM monitoring stopped")
    
    def _monitoring_loop(self):
        """Main monitoring loop"""
        while self.monitoring:
            try:
                self._collect_system_metrics()
                time.sleep(self.collection_interval)
            except Exception as e:
                print(f"Error in monitoring loop: {e}")
    
    def _collect_system_metrics(self):
        """Collect system performance metrics"""
        timestamp = time.time()
        
        # CPU metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        cpu_count = psutil.cpu_count()
        load_avg = psutil.getloadavg() if hasattr(psutil, 'getloadavg') else (0, 0, 0)
        
        # Memory metrics
        memory = psutil.virtual_memory()
        swap = psutil.swap_memory()
        
        # Disk metrics
        disk_usage = psutil.disk_usage('/')
        disk_io = psutil.disk_io_counters()
        
        # Network metrics
        network_io = psutil.net_io_counters()
        
        # Process metrics
        process_count = len(psutil.pids())
        
        # Store metrics
        metrics_data = {
            'timestamp': timestamp,
            'cpu_percent': cpu_percent,
            'cpu_count': cpu_count,
            'load_avg_1m': load_avg[0],
            'load_avg_5m': load_avg[1],
            'load_avg_15m': load_avg[2],
            'memory_total': memory.total,
            'memory_available': memory.available,
            'memory_percent': memory.percent,
            'memory_used': memory.used,
            'swap_total': swap.total,
            'swap_used': swap.used,
            'swap_percent': swap.percent,
            'disk_total': disk_usage.total,
            'disk_used': disk_usage.used,
            'disk_free': disk_usage.free,
            'disk_usage_percent': disk_usage.percent,
            'disk_read_bytes': disk_io.read_bytes if disk_io else 0,
            'disk_write_bytes': disk_io.write_bytes if disk_io else 0,
            'network_bytes_sent': network_io.bytes_sent,
            'network_bytes_recv': network_io.bytes_recv,
            'process_count': process_count
        }
        
        # Add to metrics storage
        for key, value in metrics_data.items():
            if key != 'timestamp':
                self.metrics[key].append({'timestamp': timestamp, 'value': value})
        
        # Check thresholds and generate alerts
        self._check_thresholds(metrics_data)
    
    def _check_thresholds(self, metrics_data):
        """Check if any metrics exceed thresholds"""
        alerts_generated = []
        
        for metric, threshold in self.thresholds.items():
            if metric in metrics_data and metrics_data[metric] > threshold:
                alert = {
                    'timestamp': metrics_data['timestamp'],
                    'metric': metric,
                    'value': metrics_data[metric],
                    'threshold': threshold,
                    'severity': 'critical' if metrics_data[metric] > threshold * 1.2 else 'warning'
                }
                self.alerts.append(alert)
                alerts_generated.append(alert)
        
        if alerts_generated:
            print(f"Alerts generated: {len(alerts_generated)}")
            for alert in alerts_generated:
                print(f"  {alert['severity'].upper()}: {alert['metric']} = {alert['value']:.2f} (threshold: {alert['threshold']})")
    
    def get_metrics_summary(self, metric_name, minutes=10):
        """Get statistical summary for a metric over the last N minutes"""
        if metric_name not in self.metrics:
            return None
        
        cutoff_time = time.time() - (minutes * 60)
        recent_data = [
            point['value'] for point in self.metrics[metric_name]
            if point['timestamp'] > cutoff_time
        ]
        
        if not recent_data:
            return None
        
        return {
            'count': len(recent_data),
            'min': min(recent_data),
            'max': max(recent_data),
            'mean': statistics.mean(recent_data),
            'median': statistics.median(recent_data),
            'std_dev': statistics.stdev(recent_data) if len(recent_data) > 1 else 0
        }
    
    def get_recent_alerts(self, minutes=10):
        """Get recent alerts"""
        cutoff_time = time.time() - (minutes * 60)
        return [
            alert for alert in self.alerts
            if alert['timestamp'] > cutoff_time
        ]
    
    def export_metrics(self, filename=None):
        """Export metrics to JSON file"""
        if filename is None:
            filename = f"apm_metrics_{int(time.time())}.json"
        
        export_data = {
            'export_timestamp': time.time(),
            'thresholds': self.thresholds,
            'metrics': {
                name: list(data) for name, data in self.metrics.items()
            },
            'alerts': list(self.alerts)
        }
        
        with open(filename, 'w') as f:
            json.dump(export_data, f, indent=2)
        
        print(f"Metrics exported to {filename}")
        return filename
    
    def generate_dashboard_data(self):
        """Generate data for dashboard display"""
        current_time = time.time()
        
        # Get current values
        current_metrics = {}
        for metric_name, data in self.metrics.items():
            if data:
                current_metrics[metric_name] = data[-1]['value']
        
        # Get recent summaries
        summaries = {}
        for metric_name in ['cpu_percent', 'memory_percent', 'disk_usage_percent']:
            summary = self.get_metrics_summary(metric_name, minutes=10)
            if summary:
                summaries[metric_name] = summary
        
        # Get recent alerts
        recent_alerts = self.get_recent_alerts(minutes=30)
        
        return {
            'timestamp': current_time,
            'current_metrics': current_metrics,
            'summaries': summaries,
            'recent_alerts': recent_alerts,
            'alert_count': len(recent_alerts)
        }

# Example usage
def main():
    monitor = ApplicationPerformanceMonitor(collection_interval=2, retention_minutes=30)
    
    try:
        monitor.start_monitoring()
        
        # Simulate some application load
        for i in range(60):  # Run for 2 minutes
            time.sleep(2)
            
            # Every 10 iterations, print dashboard data
            if i % 10 == 0:
                dashboard = monitor.generate_dashboard_data()
                print(f"\nDashboard Update {i//10 + 1}:")
                print(f"CPU: {dashboard['current_metrics'].get('cpu_percent', 0):.1f}%")
                print(f"Memory: {dashboard['current_metrics'].get('memory_percent', 0):.1f}%")
                print(f"Disk: {dashboard['current_metrics'].get('disk_usage_percent', 0):.1f}%")
                print(f"Recent Alerts: {dashboard['alert_count']}")
        
        # Export final metrics
        monitor.export_metrics()
        
    finally:
        monitor.stop_monitoring()

if __name__ == "__main__":
    main()
```

## Useful Links

- [k6 Documentation](https://k6.io/docs/)
- [Apache JMeter](https://jmeter.apache.org/)
- [Lighthouse Performance](https://developers.google.com/web/tools/lighthouse)
- [Web Performance Metrics](https://web.dev/metrics/)
- [Database Performance Tuning](https://www.postgresql.org/docs/current/performance-tips.html)
