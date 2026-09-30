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
cp .env.sample .env  # then set WG_HOST and WG_EASY_PASSWORD

# Dev - web UI on http://localhost:51821 (loopback, INSECURE=true for plain HTTP)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS for the web UI
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

wg-easy v15 normally opens a setup wizard on the first visit, and whoever completes it
owns the VPN. This stack uses v15's **unattended setup** instead: on the first start it
creates the admin from `WG_EASY_USERNAME` / `WG_EASY_PASSWORD` and sets the public host,
so the wizard is never reachable. Sign in with those credentials. Later changes (DNS,
CIDRs, allowed IPs) are made in the web UI.

## Environment Variables

| Variable           | Description                                             | Required |
| ------------------ | ------------------------------------------------------- | -------- |
| `WG_HOST`          | Public hostname/IP clients connect to (UDP 51820)       | Yes      |
| `WG_EASY_PASSWORD` | Admin password created on first start (use a long one)  | Yes      |
| `WG_EASY_USERNAME` | Admin username (default `admin`)                        | No       |
| `DOMAIN`           | Hostname Traefik serves the web UI on                   | Traefik  |
| `DEV_BIND_IP`      | Host interface for the dev web UI (default `127.0.0.1`) | No       |

`WG_HOST`, `WG_EASY_USERNAME` and `WG_EASY_PASSWORD` are only read on the first start
(they map to wg-easy's `INIT_*` variables). Once setup is done, upstream recommends
removing the password from `.env`; compose would then need a placeholder, so rotating it
from the web UI is the practical option.

## Ports

| Port    | Protocol | Description   |
| ------- | -------- | ------------- |
| `51820` | UDP      | WireGuard VPN |
| `51821` | TCP      | Web UI        |

## Volumes

| Host Path      | Container Path    | Description       |
| -------------- | ----------------- | ----------------- |
| `./data/etc`   | `/etc/wireguard`  | WireGuard configs |
| `/lib/modules` | `/lib/modules:ro` | Kernel modules    |

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
