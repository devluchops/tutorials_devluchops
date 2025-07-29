# SigNoz APM - Open Source Alternative to DataDog

Tutorial completo de SigNoz: Application Performance Monitoring open source con observabilidad completa.

## ¿Qué es SigNoz?

SigNoz es una alternativa open source a DataDog, New Relic y otros APM comerciales. Proporciona:

- **APM & Distributed Tracing** 
- **Metrics Monitoring**
- **Log Management**
- **Infrastructure Monitoring**
- **Alerts & Notifications**

## 🚀 Ventajas de SigNoz

### ✅ **vs DataDog**
- 🆓 **Open Source** - Sin costos de licencia
- 🔒 **Data Privacy** - Tus datos permanecen en tu infraestructura
- 🛠️ **Customizable** - Código abierto modificable
- 📊 **Unified Platform** - Logs, métricas y traces en un lugar

### ✅ **vs Prometheus + Grafana**
- 🎯 **APM Native** - Diseñado específicamente para observabilidad de apps
- 🔍 **Distributed Tracing** - Out of the box
- 🚀 **Easier Setup** - Todo integrado
- 📱 **Modern UI** - Interface más intuitiva

## Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │───▶│   OpenTelemetry │───▶│     SigNoz      │
│   (Instrumented)│    │   Collector     │    │   (Backend)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │   ClickHouse    │
                                                │   (Database)    │
                                                └─────────────────┘
```

## Features Principales

### 🔍 **Application Performance Monitoring**
```bash
# Métricas clave automáticas
- Response Time (P50, P95, P99)
- Throughput (RPS)
- Error Rate
- Apdex Score
```

### 📊 **Distributed Tracing**
```bash
# Trace de request completo
User Request → API Gateway → Auth Service → Database
     ↓              ↓             ↓           ↓
   100ms         50ms          200ms       150ms
```

### 📈 **Custom Metrics**
```go
// Go example
func instrumentHandler(next http.Handler) http.Handler {
    return otelhttp.NewHandler(next, "api-handler")
}
```

### 🚨 **Smart Alerts**
- Error rate spikes
- Response time degradation
- Service dependency failures
- Custom metric thresholds

## Tutorial Contents

### 1. **Installation & Setup**
- Docker Compose deployment
- Kubernetes deployment
- Cloud deployment options

### 2. **Application Instrumentation**
- Auto-instrumentation
- Manual instrumentation
- Custom metrics creation

### 3. **Dashboards & Monitoring**
- Service overview
- Database monitoring
- Infrastructure metrics
- Custom dashboards

### 4. **Advanced Features**
- Log correlation with traces
- Error tracking
- Performance optimization
- Team collaboration

## Demo Applications

### Node.js Express App
```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const sdk = new NodeSDK({
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```

### Python Flask App
```python
from opentelemetry import trace
from opentelemetry.auto_instrumentation import sitecustomize

# Auto-instrumentation enabled
app = Flask(__name__)

@app.route('/api/users')
def get_users():
    span = trace.get_current_span()
    span.set_attribute("user.count", len(users))
    return jsonify(users)
```

## Comparación de Costos

| Feature | SigNoz | DataDog | New Relic |
|---------|--------|---------|-----------|
| APM | ✅ Free | $💰💰💰 | $💰💰 |
| Logs | ✅ Free | $💰💰 | $💰💰 |
| Infrastructure | ✅ Free | $💰 | $💰 |
| Custom Metrics | ✅ Free | $💰💰 | $💰 |
| Data Retention | ∞ (Your storage) | 💰 per month | 💰 per month |

## Production Ready Features

- **High Availability**: Multi-node deployment
- **Scalability**: Horizontal scaling con ClickHouse
- **Security**: SSO, RBAC, API keys
- **Backup & Recovery**: Automated backups
- **Performance**: Sub-second query performance

## Enlaces útiles

- [SigNoz Documentation](https://signoz.io/docs/)
- [GitHub Repository](https://github.com/SigNoz/signoz)
- [Community Slack](https://signoz.io/slack)
- [Tutorial en YouTube](https://youtu.be/EXAMPLE)
