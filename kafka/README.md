# Apache Kafka

Distributed event streaming platform with KRaft mode (no Zookeeper required).

## Features

- High-throughput event streaming
- Durable message storage
- Horizontal scalability
- KRaft consensus (no Zookeeper dependency)
- Stream processing support

## Quick Start

```bash
docker compose up -d
```

## Architecture

This setup includes a full cluster with:

- **3 Controllers** (nodes 1-3) - Handle cluster metadata
- **3 Brokers** (nodes 4-6) - Handle data storage and replication

## Ports

External listener ports (not exposed by default, add to docker-compose.yml):

| Port    | Description                |
| ------- | -------------------------- |
| `29092` | Broker 1 external listener |
| `39092` | Broker 2 external listener |
| `49092` | Broker 3 external listener |

To access from outside Docker network, add port mappings:

```yaml
broker-1:
  ports:
    - '29092:9092'

broker-2:
  ports:
    - '39092:9092'

broker-3:
  ports:
    - '49092:9092'
```

## Environment Variables

| Variable                         | Description                    |
| -------------------------------- | ------------------------------ |
| `KAFKA_NODE_ID`                  | Unique node identifier         |
| `KAFKA_PROCESS_ROLES`            | Node roles (controller/broker) |
| `KAFKA_LISTENERS`                | Listener configuration         |
| `KAFKA_CONTROLLER_QUORUM_VOTERS` | Controller quorum members      |

## Usage

### Create a Topic

```bash
docker compose exec kafka-1 kafka-topics.sh \
  --bootstrap-server kafka-4:9092 \
  --create --topic my-topic \
  --partitions 3 --replication-factor 2
```

### Produce Messages

```bash
docker compose exec kafka-4 kafka-console-producer.sh \
  --bootstrap-server kafka-4:9092 \
  --topic my-topic
```

### Consume Messages

```bash
docker compose exec kafka-4 kafka-console-consumer.sh \
  --bootstrap-server kafka-4:9092 \
  --topic my-topic --from-beginning
```

## Notes

> ⚠️ No persistent storage configured by default. Add volumes for production use.

## Links

- [Apache Kafka Website](https://kafka.apache.org/)
- [Documentation](https://kafka.apache.org/documentation/)
- [KRaft Mode](https://kafka.apache.org/documentation/#kraft)
