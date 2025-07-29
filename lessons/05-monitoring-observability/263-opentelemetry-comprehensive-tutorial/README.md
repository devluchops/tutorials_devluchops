# OpenTelemetry Comprehensive Tutorial - The Complete Guide

Tutorial completo de OpenTelemetry: el estándar para observabilidad de aplicaciones modernas.

## ¿Qué es OpenTelemetry?

OpenTelemetry (OTel) es un framework de observabilidad open source que proporciona:

- **Unified Instrumentation** - Un estándar para todos los lenguajes
- **Vendor Agnostic** - Funciona con cualquier backend de observabilidad
- **Three Pillars** - Traces, Metrics y Logs
- **Auto-instrumentation** - Instrumentación automática sin cambios de código

## 🎯 The Three Pillars of Observability

### 1. **Traces** 🔍
```
Request Journey:
User → Frontend → API → Database → Response
 |        |        |        |
100ms   +50ms    +200ms   +150ms = 500ms total
```

### 2. **Metrics** 📊
```
Time Series Data:
http_requests_total{method="GET", status="200"} 1.5k
response_time_seconds{service="api"} 0.25
error_rate{service="auth"} 0.02
```

### 3. **Logs** 📝
```
Structured Logging:
{
  "timestamp": "2025-01-15T10:30:00Z",
  "level": "ERROR",
  "message": "Database connection failed",
  "trace_id": "abc123",
  "span_id": "def456"
}
```

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │───▶│  OTel Collector │───▶│   Observability │
│  (Instrumented) │    │   (Pipeline)    │    │    Backend      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
    Auto + Manual          Processing              Jaeger/Zipkin
    Instrumentation        Batching               Prometheus
    SDKs                   Filtering              Grafana
                          Routing                SigNoz/DataDog
```

## Language Support

### **Production Ready** ✅
- **JavaScript/Node.js** - Excellent support
- **Python** - Comprehensive instrumentation
- **Java** - Enterprise ready
- **Go** - High performance
- **C#/.NET** - Microsoft backed
- **PHP** - Community driven

### **Stable** 🚀
- **Ruby** - Good ecosystem support
- **Rust** - Growing rapidly
- **C++** - System level instrumentation

## Auto-Instrumentation Examples

### Node.js - Zero Code Changes
```bash
# Install auto-instrumentation
npm install --save @opentelemetry/auto-instrumentations-node

# Run with instrumentation
node --require @opentelemetry/auto-instrumentations-node/register app.js
```

### Python - One Line Setup
```python
# Install
pip install opentelemetry-distro opentelemetry-exporter-otlp

# Auto-instrument
opentelemetry-bootstrap -a install
opentelemetry-instrument python app.py
```

### Java - JVM Agent
```bash
# Download javaagent
wget https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

# Run with agent
java -javaagent:opentelemetry-javaagent.jar -jar myapp.jar
```

## Manual Instrumentation Examples

### Creating Custom Spans
```javascript
// JavaScript
const { trace } = require('@opentelemetry/api');

async function processOrder(orderId) {
  const span = trace.getActiveSpan();
  span.setAttributes({
    'order.id': orderId,
    'order.type': 'purchase'
  });
  
  try {
    const result = await database.getOrder(orderId);
    span.setStatus({ code: SpanStatusCode.OK });
    return result;
  } catch (error) {
    span.recordException(error);
    span.setStatus({ 
      code: SpanStatusCode.ERROR, 
      message: error.message 
    });
    throw error;
  }
}
```

### Custom Metrics
```python
# Python
from opentelemetry import metrics

meter = metrics.get_meter(__name__)
request_counter = meter.create_counter(
    "http_requests_total",
    description="Total HTTP requests"
)

# Increment counter
request_counter.add(1, {"method": "GET", "endpoint": "/api/users"})
```

## OTel Collector Configuration

### Basic Pipeline
```yaml
# otel-collector.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    limit_mib: 512

exporters:
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true
  prometheus:
    endpoint: "0.0.0.0:8889"

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [jaeger]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
```

## Advanced Features

### 🔗 **Context Propagation**
```javascript
// Automatic context propagation across services
const headers = {
  'traceparent': '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01'
};
```

### 🏷️ **Semantic Conventions**
```python
# Standard attributes for HTTP requests
span.set_attributes({
    "http.method": "GET",
    "http.url": "https://api.example.com/users",
    "http.status_code": 200,
    "http.user_agent": "curl/7.64.1"
})
```

### 📊 **Resource Detection**
```go
// Go - Automatic resource detection
resource := resource.NewWithAttributes(
    semconv.SchemaURL,
    semconv.ServiceNameKey.String("my-service"),
    semconv.ServiceVersionKey.String("1.0.0"),
    semconv.DeploymentEnvironmentKey.String("production"),
)
```

## Production Best Practices

### 1. **Sampling Strategies**
```yaml
# Head-based sampling (at source)
sampling_percentage: 10

# Tail-based sampling (at collector)
tail_sampling:
  decision_wait: 10s
  policies:
    - name: error-sampling
      type: status_code
      status_code: {status_codes: [ERROR]}
```

### 2. **Performance Optimization**
- Use batch processors
- Configure memory limits
- Implement proper sampling
- Monitor collector resource usage

### 3. **Security**
- TLS encryption for data in transit
- Authentication for collector endpoints
- Sensitive data filtering
- RBAC for observability backends

## Integration Examples

### Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: otel-collector
spec:
  template:
    spec:
      containers:
      - name: otel-collector
        image: otel/opentelemetry-collector-contrib:latest
        command: ["otelcol-contrib"]
        args: ["--config=/etc/otel/config.yaml"]
        env:
        - name: K8S_NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
```

## Common Use Cases

### 1. **Microservices Tracing**
- End-to-end request tracking
- Service dependency mapping
- Performance bottleneck identification

### 2. **Error Tracking**
- Exception correlation with traces
- Error rate monitoring
- Root cause analysis

### 3. **SLI/SLO Monitoring**
- Service level indicators
- Custom business metrics
- Alerting on SLO violations

## Troubleshooting Guide

### Common Issues
1. **Missing traces** → Check instrumentation setup
2. **High overhead** → Adjust sampling rates
3. **Missing context** → Verify context propagation
4. **Collector errors** → Check configuration and resources

## Resources & Links

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Instrumentation Libraries](https://opentelemetry.io/registry/)
- [Community Slack](https://slack.cncf.io/) - #otel channel
- [GitHub Repository](https://github.com/open-telemetry)
- [Tutorial en YouTube](https://youtu.be/EXAMPLE)
