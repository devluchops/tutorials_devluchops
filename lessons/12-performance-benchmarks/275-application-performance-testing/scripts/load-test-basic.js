// scripts/load-test-basic.js
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
const baseUrl = __ENV.BASE_URL || 'https://httpbin.org';
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
  
  // Test 1: HTTP GET request
  const getResponse = http.get(`${data.baseUrl}/get`);
  
  const getSuccess = check(getResponse, {
    'GET status is 200': (r) => r.status === 200,
    'GET response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  errorRate.add(!getSuccess);
  
  // Test 2: HTTP POST request
  const postData = {
    email: user.email,
    password: user.password,
    timestamp: new Date().toISOString(),
  };
  
  const postResponse = http.post(`${data.baseUrl}/post`, JSON.stringify(postData), {
    headers: {
      'Content-Type': 'application/json',
    },
  });
  
  const postSuccess = check(postResponse, {
    'POST status is 200': (r) => r.status === 200,
    'POST response time < 1000ms': (r) => r.timings.duration < 1000,
    'POST contains data': (r) => r.json('json') !== undefined,
  });
  
  errorRate.add(!postSuccess);
  
  // Test 3: Simulate user delay
  const delayResponse = http.get(`${data.baseUrl}/delay/1`);
  
  check(delayResponse, {
    'Delay status is 200': (r) => r.status === 200,
    'Delay response time < 2000ms': (r) => r.timings.duration < 2000,
  });
  
  // Random sleep between 1-3 seconds
  sleep(Math.random() * 2 + 1);
}

// Teardown function (runs once after all VUs finish)
export function teardown(data) {
  console.log('Load test completed');
}
