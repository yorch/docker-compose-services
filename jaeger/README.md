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
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.ports.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d

# Other setups - with the HotROD demo app for generating traces:
./run.sh                          # local: UI on :16686, HotROD on :8080
./run-for-traefik-with-hotrod.sh  # behind Traefik
```

Behind Traefik the UI is served at `https://jaeger.${DOMAIN}` (and HotROD at
`https://jaeger-hotrod.${DOMAIN}`), both behind **required basic auth**: Jaeger has no
login of its own and the UI exposes every trace. Set `BASIC_AUTH_USER` and
`BASIC_AUTH_PASSWORD_HASH` (single-quoted) in `.env`; generate the hash with:

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'your-password' | cut -d: -f2
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
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
| `14250` | gRPC     | model.proto                 |
| `14268` | HTTP     | jaeger.thrift direct        |
| `16686` | HTTP     | Web UI                      |

## Environment Variables

| Variable                   | Description                                             | Required |
| -------------------------- | ------------------------------------------------------- | -------- |
| `DOMAIN`                   | Base domain; UI at `jaeger.${DOMAIN}` (Traefik only)    | Traefik  |
| `BASIC_AUTH_USER`          | Basic-auth user for the UI and HotROD (Traefik only)    | Traefik  |
| `BASIC_AUTH_PASSWORD_HASH` | bcrypt hash for that user, single-quoted (Traefik only) | Traefik  |

The collector ports (4317/4318 and the legacy agent ports) are published by the base
file in every setup, so applications on other hosts can send traces.

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
