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

```bash
# 1. Create the password file with a first user (prompts for the password)
./setup.sh <username>

# 2. Start the broker on port 1883
docker compose up -d
```

The broker requires authentication (`allow_anonymous false`), and
`./config/mosquitto/mosquitto.conf` is tracked in this folder. Run `setup.sh` before the
first `up`. If the password file is missing, Docker creates a directory in its place
and the broker crash-loops.

## Ports

| Port   | Description                   |
| ------ | ----------------------------- |
| `1883` | MQTT                          |
| `8883` | MQTT over TLS (if configured) |
| `9001` | WebSocket (if configured)     |

## Volumes

| Host Path                           | Container Path                     | Description            |
| ----------------------------------- | ---------------------------------- | ---------------------- |
| `./config/mosquitto/mosquitto.conf` | `/mosquitto/config/mosquitto.conf` | Configuration          |
| `./config/mosquitto/passwd`         | `/mosquitto/config/passwd`         | Password file          |
| `./data`                            | `/mosquitto/data`                  | Persistent data        |
| `./log`                             | `/mosquitto/log`                   | Log files (gitignored) |

## Creating Users

Add or update a user at any time (the broker picks it up after a restart):

```bash
./setup.sh <username>
docker compose restart mqtt
```

`config/mosquitto/passwd` holds password hashes and is gitignored.

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
