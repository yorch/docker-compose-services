# Redpanda

Kafka-compatible streaming data platform - no ZooKeeper required.

## Features

- Kafka API compatible
- No JVM, written in C++
- No ZooKeeper dependency
- Single binary deployment
- Built-in Schema Registry
- Built-in HTTP Proxy (Pandaproxy)

## Quick Start

```bash
docker compose up -d
```

## Ports

| Port   | Description       |
| ------ | ----------------- |
| `9092` | Kafka API         |
| `8081` | Schema Registry   |
| `8082` | Pandaproxy (HTTP) |
| `9644` | Admin API         |

## Volumes

| Host Path | Container Path           | Description  |
| --------- | ------------------------ | ------------ |
| `./data`  | `/var/lib/redpanda/data` | Data storage |

## Kafka CLI Compatibility

Use standard Kafka tools:

```bash
# List topics
rpk topic list

# Create topic
rpk topic create my-topic -p 3 -r 1

# Produce messages
echo "hello" | rpk topic produce my-topic

# Consume messages
rpk topic consume my-topic
```

## Redpanda Console

For web UI, add Redpanda Console:

```yaml
console:
  image: redpandadata/console:latest
  ports:
    - '8080:8080'
  environment:
    - KAFKA_BROKERS=redpanda:9092
```

## Configuration

Common configurations via environment:

```yaml
environment:
  - REDPANDA_AUTO_CREATE_TOPICS_ENABLED=true
  - REDPANDA_LOG_LEVEL=info
```

## Links

- [Redpanda Website](https://redpanda.com/)
- [Documentation](https://docs.redpanda.com/)
- [GitHub Repository](https://github.com/redpanda-data/redpanda)
