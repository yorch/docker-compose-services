# WG-Easy

Easy-to-use WireGuard VPN with web UI.

## Features

- Simple web interface
- QR code for mobile clients
- Easy client management
- Automatic key generation
- Docker-friendly deployment

## Quick Start

```bash
docker compose up -d
```

Access the web UI at `http://localhost:51821`

## Environment Variables

| Variable   | Description        | Required |
| ---------- | ------------------ | -------- |
| `WG_HOST`  | Public hostname/IP | Yes      |
| `PASSWORD` | Admin password     | Yes      |

### Optional Settings

| Variable                  | Description         | Default           |
| ------------------------- | ------------------- | ----------------- |
| `WG_PORT`                 | WireGuard port      | `51820`           |
| `WG_DEFAULT_DNS`          | Client DNS          | `1.1.1.1`         |
| `WG_DEFAULT_ADDRESS`      | Client IP range     | `10.8.0.x`        |
| `WG_MTU`                  | MTU value           | `null`            |
| `WG_PERSISTENT_KEEPALIVE` | Keep-alive interval | `0`               |
| `WG_ALLOWED_IPS`          | Client allowed IPs  | `0.0.0.0/0, ::/0` |
| `UI_TRAFFIC_STATS`        | Show traffic stats  | `true`            |
| `UI_CHART_TYPE`           | Chart type (0-3)    | `0`               |

## Ports

| Port    | Protocol | Description   |
| ------- | -------- | ------------- |
| `51820` | UDP      | WireGuard VPN |
| `51821` | TCP      | Web UI        |

## Volumes

| Host Path | Container Path   | Description       |
| --------- | ---------------- | ----------------- |
| `./data`  | `/etc/wireguard` | WireGuard configs |

## Capabilities

Required capabilities:

```yaml
cap_add:
  - NET_ADMIN
  - SYS_MODULE
sysctls:
  - net.ipv4.ip_forward=1
  - net.ipv4.conf.all.src_valid_mark=1
```

## Usage

1. Access the web interface
2. Log in with your password
3. Create new clients
4. Scan QR code or download config file
5. Import config into WireGuard client

## Links

- [WireGuard Website](https://www.wireguard.com/)
- [GitHub Repository](https://github.com/wg-easy/wg-easy)
