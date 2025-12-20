# WireGuard Dashboard

Web-based dashboard for WireGuard VPN management.

## Features

- Web UI for WireGuard management
- Peer management
- QR code generation for mobile
- Traffic statistics
- Multi-configuration support

## Quick Start

```bash
docker compose up -d
```

## Environment Variables

| Variable             | Description                | Default          |
| -------------------- | -------------------------- | ---------------- |
| `WG_CONF_DIR`        | WireGuard config directory | `/etc/wireguard` |
| `WG_DEFAULT_DNS`     | Default DNS server         | `1.1.1.1`        |
| `WG_DEFAULT_ADDRESS` | Default address range      | -                |

## Volumes

| Host Path  | Container Path   | Description       |
| ---------- | ---------------- | ----------------- |
| `./config` | `/etc/wireguard` | WireGuard configs |
| `./data`   | `/data`          | Dashboard data    |

## Ports

| Port    | Description         |
| ------- | ------------------- |
| `10086` | Web UI              |
| `51820` | WireGuard VPN (UDP) |

## Capabilities

This container requires the `NET_ADMIN` capability:

```yaml
cap_add:
  - NET_ADMIN
```

## First-Time Setup

1. Access the web interface
2. Create your first WireGuard interface
3. Add peers (clients)
4. Download or scan QR codes for client configuration

## Links

- [WireGuard Website](https://www.wireguard.com/)
- [GitHub Repository](https://github.com/donaldzou/WGDashboard)
