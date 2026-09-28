# Traefik 3

Reverse proxy (v3.x) that fronts every other service here, with automatic HTTPS via Let's Encrypt.

## Features

- Routes to containers via Docker labels (`exposedbydefault=false`, so only labelled containers are published)
- Automatic TLS certificates through the `webcert` resolver (TLS-ALPN challenge; DNS challenge optional)
- HTTP → HTTPS redirect on every request
- Dashboard at `https://${TRAEFIK_HOST}`, always behind basic auth
- Docker socket mounted read-only

## Quick Start

Other services join the external `traefik` network, so create it once before the first start:

```bash
./setup.sh  # docker network create traefik

cp .env.sample .env  # then set TRAEFIK_HOST, ACME_EMAIL and the dashboard credentials
docker compose up -d
```

Generate the dashboard password hash with:

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'your-password' | cut -d: -f2
```

Put it in `.env` **single-quoted** — bcrypt hashes contain `$`, which compose would otherwise interpolate.

Services opt in through their `docker-compose.for-traefik.yml`, using the `websecure` entrypoint and the
`webcert` cert resolver defined here.

## Upgrading from v2

This folder previously ran `traefik:v2.9`, whose Docker provider cannot talk to Docker Engine 29+ (it fails
with an empty `Error response from daemon`, so no routes load). Moving to v3 needs no label changes for the
services in this repo, and the existing `data/acme.json` certificates are reused as-is.

The dashboard now requires `DASHBOARD_USERNAME` and `DASHBOARD_HASHED_PASSWORD`; compose refuses to start
until both are set. See the [v2 → v3 migration guide](https://doc.traefik.io/traefik/migration/v2-to-v3/)
for anything beyond this stack's configuration.

## Ports

| Port  | Description                    |
| ----- | ------------------------------ |
| `80`  | HTTP (redirects to HTTPS)      |
| `443` | HTTPS for every routed service |

## Environment Variables

| Variable                    | Required | Description                                                         |
| --------------------------- | -------- | ------------------------------------------------------------------- |
| `TRAEFIK_HOST`              | Yes      | Hostname for the dashboard, e.g. `traefik.example.com`              |
| `ACME_EMAIL`                | Yes      | Email registered with Let's Encrypt                                 |
| `DASHBOARD_USERNAME`        | Yes      | Dashboard basic-auth user                                           |
| `DASHBOARD_HASHED_PASSWORD` | Yes      | bcrypt hash for that user (single-quoted, see above)                |
| `TRAEFIK_LOG_LEVEL`         | No       | `DEBUG`, `INFO`, `WARN` or `ERROR` (default `INFO`)                 |
| `DO_AUTH_TOKEN`             | No       | DigitalOcean token, only if you enable the commented DNS challenge  |
| `INFLUXDB2_*`               | No       | InfluxDB v2 metrics, only if you enable the commented metrics flags |

## Volumes

| Host Path              | Container Path         | Description                                |
| ---------------------- | ---------------------- | ------------------------------------------ |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker API, read-only, for label discovery |
| `./data`               | `/opt/traefik`         | `acme.json` certificate storage            |
| `./logs`               | `/opt/logs`            | Log files, if `--log.filePath` is enabled  |

## Links

- [Traefik Website](https://traefik.io/)
- [Documentation](https://doc.traefik.io/traefik/)
- [Migration Guide v2 → v3](https://doc.traefik.io/traefik/migration/v2-to-v3/)
- [GitHub Repository](https://github.com/traefik/traefik)
