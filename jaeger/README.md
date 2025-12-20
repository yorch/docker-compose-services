# Jaeger

Distributed tracing system for microservices observability.

## Features

- Distributed context propagation
- Distributed transaction monitoring
- Root cause analysis
- Service dependency analysis
- Performance optimization

## Quick Start

```bash
docker compose up -d
```

Access the Jaeger UI at `http://localhost:16686`

## Ports

| Port    | Protocol | Description                 |
| ------- | -------- | --------------------------- |
| `6831`  | UDP      | Thrift-compact (most SDKs)  |
| `6832`  | UDP      | Thrift-binary (Node.js SDK) |
| `5778`  | HTTP     | Agent configs (sampling)    |
| `4317`  | gRPC     | OTLP collector              |
| `4318`  | HTTP     | OTLP collector              |
| `14250` | HTTP     | model.proto                 |
| `14268` | HTTP     | jaeger.thrift direct        |
| `16686` | HTTP     | Web UI                      |

## Environment Variables

| Variable                 | Description                   | Default |
| ------------------------ | ----------------------------- | ------- |
| `COLLECTOR_OTLP_ENABLED` | Enable OpenTelemetry Protocol | `true`  |

## Storage

> ⚠️ **Warning**: This setup uses in-memory storage. Data is lost on restart.

For production, configure external storage:

- Elasticsearch
- Cassandra
- Kafka

## OpenTelemetry Integration

Send traces using OTLP:

```python
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

exporter = OTLPSpanExporter(endpoint="http://jaeger:4317")
```

## Links

- [Jaeger Website](https://www.jaegertracing.io/)
- [Documentation](https://www.jaegertracing.io/docs/)
- [OpenTelemetry](https://opentelemetry.io/)
- [GitHub Repository](https://github.com/jaegertracing/jaeger)
