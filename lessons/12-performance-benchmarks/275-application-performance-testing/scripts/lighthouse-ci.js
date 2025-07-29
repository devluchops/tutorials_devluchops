// scripts/lighthouse-ci.js
const lighthouse = require('lighthouse');
const chromeLauncher = require('chrome-launcher');
const fs = require('fs');

async function runLighthouseAudit(url, options = {}) {
  console.log(`Starting Lighthouse audit for: ${url}`);
  
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
  
  try {
    const runnerResult = await lighthouse(url, opts);
    
    // Generate report
    const reportHtml = runnerResult.report;
    const score = runnerResult.lhr.categories.performance.score * 100;
    
    console.log(`Performance score: ${score}`);
    
    // Save report
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const reportPath = `reports/lighthouse-report-${timestamp}.html`;
    
    // Create reports directory if it doesn't exist
    if (!fs.existsSync('reports')) {
      fs.mkdirSync('reports');
    }
    
    fs.writeFileSync(reportPath, reportHtml);
    
    await chrome.kill();
    
    return {
      score,
      metrics: runnerResult.lhr.audits,
      reportPath,
      categories: runnerResult.lhr.categories
    };
    
  } catch (error) {
    await chrome.kill();
    throw error;
  }
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
    'https://www.google.com',
    'https://github.com',
    'https://stackoverflow.com'
  ];
  
  const results = [];
  
  for (const url of urls) {
    console.log(`\n${'='.repeat(50)}`);
    console.log(`Testing ${url}...`);
    console.log('='.repeat(50));
    
    try {
      const result = await runLighthouseAudit(url);
      const budgetResults = checkPerformanceBudget(result.metrics);
      
      results.push({
        url,
        score: result.score,
        budgetResults,
        reportPath: result.reportPath,
        categories: result.categories
      });
      
    } catch (error) {
      console.error(`Failed to test ${url}:`, error.message);
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
  
  fs.writeFileSync('reports/performance-summary.json', JSON.stringify(summary, null, 2));
  console.log('\nPerformance testing completed. Summary saved to reports/performance-summary.json');
  
  // Generate HTML summary
  const htmlSummary = generateHtmlSummary(summary);
  fs.writeFileSync('reports/performance-summary.html', htmlSummary);
  
  return summary;
}

function generateHtmlSummary(summary) {
  const resultsHtml = summary.results.map(result => {
    if (result.error) {
      return `
        <tr style="background-color: #ffebee;">
          <td>${result.url}</td>
          <td colspan="4">Error: ${result.error}</td>
        </tr>
      `;
    }
    
    const scoreColor = result.score >= 90 ? '#4caf50' : result.score >= 50 ? '#ff9800' : '#f44336';
    
    return `
      <tr>
        <td>${result.url}</td>
        <td style="color: ${scoreColor}; font-weight: bold;">${result.score.toFixed(1)}</td>
        <td>${result.categories.accessibility.score * 100}</td>
        <td>${result.categories['best-practices'].score * 100}</td>
        <td><a href="${result.reportPath}" target="_blank">View Report</a></td>
      </tr>
    `;
  }).join('');
  
  return `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Performance Test Summary</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            table { border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
            th { background-color: #f2f2f2; }
            .summary { background: #e3f2fd; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        </style>
    </head>
    <body>
        <h1>Performance Test Summary</h1>
        
        <div class="summary">
            <h2>Overview</h2>
            <p><strong>Test Date:</strong> ${summary.timestamp}</p>
            <p><strong>Total URLs Tested:</strong> ${summary.totalTests}</p>
            <p><strong>Tests Passed (≥90):</strong> ${summary.passed}</p>
            <p><strong>Average Score:</strong> ${summary.averageScore.toFixed(1)}</p>
        </div>
        
        <h2>Detailed Results</h2>
        <table>
            <thead>
                <tr>
                    <th>URL</th>
                    <th>Performance Score</th>
                    <th>Accessibility</th>
                    <th>Best Practices</th>
                    <th>Report</th>
                </tr>
            </thead>
            <tbody>
                ${resultsHtml}
            </tbody>
        </table>
    </body>
    </html>
  `;
}

// Run if executed directly
if (require.main === module) {
  runPerformanceTests().catch(console.error);
}

module.exports = {
  runLighthouseAudit,
  checkPerformanceBudget,
  runPerformanceTests
};
