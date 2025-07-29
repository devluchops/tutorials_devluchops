# Loki + Grafana Log Aggregation Tutorial

Tutorial completo para implementar log aggregation con Loki y Grafana en Kubernetes.

## ¿Qué es Loki?

Loki es un sistema de agregación de logs horizontalmente escalable, altamente disponible y multi-tenant, inspirado en Prometheus. A diferencia de otros sistemas de logging, Loki está diseñado para ser muy rentable y fácil de operar.

## Arquitectura del Stack de Logging

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Promtail      │───▶│      Loki       │◄───│    Grafana      │
│   (Agent)       │    │   (Storage)     │    │   (Dashboard)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       │
    ┌─────────────────┐    ┌─────────────────┐          │
    │   Application   │    │   Object Store  │          │
    │     Logs        │    │   (S3/GCS)      │          │
    └─────────────────┘    └─────────────────┘          │
                                                         │
                                   ┌─────────────────────┘
                                   ▼
                            ┌─────────────────┐
                            │     Alerts      │
                            │  (AlertManager) │
                            └─────────────────┘
```

## Componentes

### 1. **Loki** - Log Aggregation System
- Recibe, almacena y consulta logs
- Compatible con Prometheus para métricas
- Almacenamiento eficiente con índices mínimos

### 2. **Promtail** - Log Collection Agent
- Recolecta logs de archivos y containers
- Envía logs a Loki
- Parsing y labeling automático

### 3. **Grafana** - Visualization
- Dashboard para consultar logs
- Integración nativa con Loki
- Alertas basadas en logs

## Casos de Uso

- **Debugging**: Correlacionar logs con métricas
- **Monitoring**: Detectar errores en aplicaciones
- **Compliance**: Auditoría y retención de logs
- **Performance**: Analizar patrones de comportamiento

## Tutorial Step-by-Step

### Paso 1: Instalación de Loki Stack
### Paso 2: Configuración de Promtail
### Paso 3: Setup de Dashboards en Grafana
### Paso 4: LogQL Queries avanzadas
### Paso 5: Alertas basadas en logs
### Paso 6: Escalamiento y performance tuning

## LogQL Examples

```logql
# Errores en los últimos 5 minutos
{app="api"} |= "ERROR" [5m]

# Rate de errores por minuto
rate({app="api"} |= "ERROR" [1m])

# Top 10 errores
topk(10, count by (error_message) ({app="api"} |= "ERROR"))
```

## Enlaces útiles

- [Loki Documentation](https://grafana.com/docs/loki/)
- [LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
- [Tutorial en YouTube](https://youtu.be/EXAMPLE)
