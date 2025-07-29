# Frameworks and Tools

Esta sección contiene tutoriales sobre frameworks, protocolos, herramientas y tecnologías que trascienden lenguajes específicos de programación.

## 🛠️ Categorías de Herramientas

### 📡 Message Brokers & Event Streaming
- **152** - [gRPC vs Kafka: Which One Should You Choose](./152-grpc-vs-kafka-which-one-should-you-choose/)
- **186** - [Apache Kafka Architecture](./186-apache-kafka-architecture/)
- **218** - [Apache Kafka vs RabbitMQ Performance](./218-apache-kafka-vs-rabbitmq-performance-latency-throughput-saturation/)

### 🌐 API Technologies & Protocols
- **240** - [gRPC vs REST vs GraphQL Comparison](./240-grpc-vs-rest-vs-graphql-comparison-performance/)
- **246** - [TCP vs UDP Performance Analysis](./246-tcp-vs-udp-performance-latency-throughput/)
- **249** - [TCP vs UDP Performance (Huge Improvement)](./249-tcp-vs-udp-performance-huge-improvement/)
- **251** - [TCP vs UDP Performance (Round 3)](./251-tcp-vs-udp-performance-round-3/)

### ⚖️ Load Balancing & Infrastructure
- **191** - [Types of Load Balancing Algorithms](./191-types-of-load-balancing-algorithms/)
- **006** - [Instructions to Create VPC](./006-instructions-to-create-vpc/)

## 🎯 Casos de Uso por Herramienta

### Apache Kafka
- **Ideal para**: Event streaming, microservices communication
- **Escalabilidad**: Horizontal, multi-cluster
- **Casos reales**: Logs aggregation, real-time analytics

### gRPC vs REST vs GraphQL
- **gRPC**: Microservices internos, alta performance
- **REST**: APIs públicas, simplicidad
- **GraphQL**: Frontend flexibility, data aggregation

### TCP vs UDP
- **TCP**: Aplicaciones que requieren confiabilidad
- **UDP**: Gaming, streaming, IoT con baja latencia
- **Híbrido**: QUIC, WebRTC

## 📊 Comparaciones de Performance

### Message Brokers
```
Throughput (messages/sec):
Kafka: 2M+ messages/sec
RabbitMQ: 500K messages/sec
Redis Streams: 1M+ messages/sec
```

### API Protocols
```
Latency (P99):
gRPC: 1-3ms
REST: 5-15ms
GraphQL: 10-30ms (depends on resolvers)
```

### Network Protocols
```
Latency:
UDP: <1ms
TCP: 2-5ms
QUIC: 1-3ms (UDP + reliability)
```

## 🚀 Tendencias y Adopción

### En Crecimiento
- **gRPC**: Adoptado por microservices
- **QUIC**: HTTP/3 standard
- **Event Sourcing**: Con Kafka/EventStore

### Establecidos
- **REST**: Estándar para APIs públicas
- **TCP**: Base de la comunicación confiable
- **Load Balancers**: Nginx, HAProxy, Envoy

## 📚 Guías de Implementación

### Kafka Setup
```bash
# Docker Compose
kafka:
  image: confluentinc/cp-kafka:latest
  environment:
    KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
```

### gRPC Service
```protobuf
service UserService {
  rpc GetUser(UserRequest) returns (UserResponse);
  rpc CreateUser(CreateUserRequest) returns (UserResponse);
}
```

### Load Balancer Config
```nginx
upstream backend {
    least_conn;
    server backend1:8080;
    server backend2:8080;
    server backend3:8080;
}
```

## 🔗 Navegación

- [← Volver a Programming Languages](../)
- [Ver Comparaciones de Performance](../comparisons/)
- [Ver Tutoriales de Golang](../golang/)

---
*Frameworks y Herramientas: 9 tutoriales*
