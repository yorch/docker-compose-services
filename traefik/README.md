# Traefik

Modern HTTP reverse proxy and load balancer (v2.x).

## Features

- Dynamic configuration
- Automatic HTTPS with Let's Encrypt
- Docker label-based routing
- Middleware support
- Dashboard UI
- Multiple providers

## Quick Start

```bash
docker compose up -d
```

Access the dashboard at `http://localhost:8080`

## Ports

| Port   | Description            |
| ------ | ---------------------- |
| `80`   | HTTP traffic           |
| `443`  | HTTPS traffic          |
| `8080` | Dashboard (if enabled) |

## Environment Variables

| Variable       | Description                          |
| -------------- | ------------------------------------ |
| `CF_API_EMAIL` | Cloudflare email (for DNS challenge) |
| `CF_API_KEY`   | Cloudflare API key                   |

## Volumes

| Host Path              | Container Path             | Description         |
| ---------------------- | -------------------------- | ------------------- |
| `/var/run/docker.sock` | `/var/run/docker.sock`     | Docker API          |
| `./traefik.yml`        | `/etc/traefik/traefik.yml` | Static config       |
| `./acme.json`          | `/etc/traefik/acme.json`   | Certificate storage |

## Basic Configuration

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

## Docker Labels

Route a service through Traefik:

```yaml
labels:
  - 'traefik.enable=true'
  - 'traefik.http.routers.myapp.rule=Host(`myapp.example.com`)'
  - 'traefik.http.routers.myapp.entrypoints=websecure'
  - 'traefik.http.routers.myapp.tls.certresolver=letsencrypt'
```

## Common Middlewares

```yaml
labels:
  # Basic auth
  - 'traefik.http.middlewares.auth.basicauth.users=user:$$password'

  # Redirect HTTP to HTTPS
  - 'traefik.http.middlewares.redirect.redirectscheme.scheme=https'

  # Rate limiting
  - 'traefik.http.middlewares.ratelimit.ratelimit.average=100'
```

## Links

- [Traefik Website](https://traefik.io/)
- [Documentation](https://doc.traefik.io/traefik/)
- [GitHub Repository](https://github.com/traefik/traefik)
