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
cp .env.sample .env  # then set WGD_PASSWORD

# Dev - web UI on http://localhost:10086 (loopback only)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

Sign in with `WGD_USERNAME` / `WGD_PASSWORD`. Without them the image accepts
`admin`/`admin`, so the password is required.

## Environment Variables

| Variable       | Description                              | Default     |
| -------------- | ---------------------------------------- | ----------- |
| `WGD_PASSWORD` | Web account password (**required**)      | -           |
| `WGD_USERNAME` | Web account username                     | `admin`     |
| `DOMAIN`       | Hostname Traefik routes to the dashboard | -           |
| `PUBLIC_IP`    | Public IP written into client configs    | auto-detect |
| `GLOBAL_DNS`   | Default DNS for WireGuard clients        | `1.1.1.1`   |
| `PORT_WEB`     | Web port (container, and dev host port)  | `10086`     |
| `TZ`           | Container timezone                       | `Etc/UTC`   |
| `DEV_BIND_IP`  | Host interface for the dev web UI        | `127.0.0.1` |

## Volumes

| Host Path       | Container Path           | Description       |
| --------------- | ------------------------ | ----------------- |
| `./data/config` | `/etc/amnezia/amneziawg` | AmneziaWG configs |
| `./data/etc`    | `/etc/wireguard`         | WireGuard configs |
| `./data/data`   | `/data`                  | Dashboard data    |

## Ports

| Port    | Description         |
| ------- | ------------------- |
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
- [GitHub Repository](https://github.com/WGDashboard/WGDashboard)
