# Jaeger Distributed Tracing en Kubernetes Tutorial

Este tutorial te enseña cómo implementar distributed tracing con Jaeger en Kubernetes para monitorear microservicios.

## ¿Qué aprenderás?

- Configurar Jaeger en Kubernetes
- Instrumentar aplicaciones con OpenTelemetry
- Analizar traces distribuidos
- Integrar con Prometheus y Grafana
- Best practices para observabilidad

## Prerrequisitos

- Kubernetes cluster funcionando
- kubectl configurado
- Helm 3.x instalado
- Conocimientos básicos de microservicios

## Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │───▶│   API Gateway   │───▶│   Backend       │
│   (React)       │    │   (Go)          │    │   (Python)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────┐
                    │     Jaeger      │
                    │   Collector     │
                    └─────────────────┘
```

## Contenido del Tutorial

### 1. Instalación de Jaeger
### 2. Configuración de OpenTelemetry
### 3. Instrumentación de aplicaciones
### 4. Dashboard y análisis de traces
### 5. Alertas basadas en tracing

## Enlaces útiles

- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [OpenTelemetry](https://opentelemetry.io/)
- [Tutorial en YouTube](https://youtu.be/EXAMPLE)

## Archivos incluidos

- `kubernetes/` - Manifiestos de Kubernetes
- `apps/` - Aplicaciones de ejemplo instrumentadas
- `helm/` - Charts de Helm para despliegue
- `docs/` - Documentación adicional
