# Traefik 3

Modern HTTP reverse proxy and load balancer (v3.x).

## Features

- Dynamic configuration
- Automatic HTTPS with Let's Encrypt
- Docker label-based routing
- Middleware support
- Dashboard UI
- WASM plugin support (v3)
- Improved performance

## Quick Start

```bash
docker compose up -d
```

Access the dashboard at `http://localhost:8080`

## What's New in v3

- Breaking changes from v2 configuration
- WASM middleware support
- Improved metrics
- HTTP/3 support (QUIC)
- OpenTelemetry integration

## Ports

| Port   | Description            |
| ------ | ---------------------- |
| `80`   | HTTP traffic           |
| `443`  | HTTPS traffic          |
| `8080` | Dashboard (if enabled) |

## Environment Variables

| Variable           | Description          |
| ------------------ | -------------------- |
| `CF_DNS_API_TOKEN` | Cloudflare API token |

## Volumes

| Host Path              | Container Path             | Description         |
| ---------------------- | -------------------------- | ------------------- |
| `/var/run/docker.sock` | `/var/run/docker.sock`     | Docker API          |
| `./traefik.yml`        | `/etc/traefik/traefik.yml` | Static config       |
| `./acme.json`          | `/etc/traefik/acme.json`   | Certificate storage |

## Basic Configuration (v3)

Create `traefik.yml`:

```yaml
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ':80'
  websecure:
    address: ':443'

providers:
  docker:
    exposedByDefault: false

certificatesResolvers:
  letsencrypt:
    acme:
      email: your@email.com
      storage: /etc/traefik/acme.json
      httpChallenge:
        entryPoint: web
```

## Docker Labels (v3)

```yaml
labels:
  - 'traefik.enable=true'
  - 'traefik.http.routers.myapp.rule=Host(`myapp.example.com`)'
  - 'traefik.http.routers.myapp.entrypoints=websecure'
  - 'traefik.http.routers.myapp.tls.certresolver=letsencrypt'
  - 'traefik.http.services.myapp.loadbalancer.server.port=8080'
```

## Migration from v2

Key changes:

- `traefikService` renamed to `service`
- Plugin configuration changes
- Metrics configuration updates

See [migration guide](https://doc.traefik.io/traefik/migration/v2-to-v3/).

## Links

- [Traefik Website](https://traefik.io/)
- [Documentation](https://doc.traefik.io/traefik/)
- [Migration Guide](https://doc.traefik.io/traefik/migration/v2-to-v3/)
- [GitHub Repository](https://github.com/traefik/traefik)
