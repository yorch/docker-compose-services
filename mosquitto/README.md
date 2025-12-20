# Mosquitto

Lightweight MQTT message broker.

## Features

- MQTT 3.1.1 and 5.0 support
- TLS/SSL encryption
- WebSocket support
- Username/password authentication
- Access control lists
- Bridge mode

## Quick Start

1. Create configuration file at `./config/mosquitto/mosquitto.conf`:

```conf
listener 1883
allow_anonymous false
password_file /mosquitto/config/passwd
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
```

2. Start the service:

```bash
docker compose up -d
```

## Ports

| Port   | Description                   |
| ------ | ----------------------------- |
| `1883` | MQTT                          |
| `8883` | MQTT over TLS (if configured) |
| `9001` | WebSocket (if configured)     |

## Volumes

| Host Path                           | Container Path                     | Description     |
| ----------------------------------- | ---------------------------------- | --------------- |
| `./config/mosquitto/mosquitto.conf` | `/mosquitto/config/mosquitto.conf` | Configuration   |
| `./config/mosquitto/passwd`         | `/mosquitto/config/passwd`         | Password file   |
| `./data`                            | `/mosquitto/data`                  | Persistent data |
| `./log`                             | `/mosquitto/log`                   | Log files       |

## Creating Users

Generate password file:

```bash
docker compose exec mqtt mosquitto_passwd -c /mosquitto/config/passwd username
```

Add additional users:

```bash
docker compose exec mqtt mosquitto_passwd -b /mosquitto/config/passwd username password
```

## Configuration Examples

### Allow Anonymous Access

```conf
allow_anonymous true
```

### WebSocket Support

```conf
listener 9001
protocol websockets
```

### TLS/SSL

```conf
listener 8883
cafile /mosquitto/config/ca.crt
certfile /mosquitto/config/server.crt
keyfile /mosquitto/config/server.key
```

## Testing

```bash
# Subscribe to a topic
mosquitto_sub -h localhost -p 1883 -u username -P password -t test/topic

# Publish a message
mosquitto_pub -h localhost -p 1883 -u username -P password -t test/topic -m "Hello MQTT"
```

## Web Clients (Optional)

Uncomment the `mqttx` or `explorer` service in docker-compose.yml for a web-based MQTT client.

## Links

- [Mosquitto Website](https://mosquitto.org/)
- [Documentation](https://mosquitto.org/documentation/)
- [Docker Hub](https://hub.docker.com/_/eclipse-mosquitto)
