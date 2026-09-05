# Twenty

Self-hosted Salesforce alternative CRM with a server, background worker, PostgreSQL, and Redis.

## Features

- Modern CRM with customizable objects and views
- Workflow automation and background jobs
- Self-hosted with full data ownership
- S3-compatible storage support
- Open source

## Quick Start

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

Access the CRM at `http://localhost:3000` (dev) or `https://${DOMAIN}` (Traefik).

## Services

| Service  | Description                   |
| -------- | ----------------------------- |
| `server` | Twenty web server (port 3000) |
| `worker` | Background job worker         |
| `db`     | PostgreSQL 16 database        |
| `redis`  | Redis cache and job queue     |

## Environment Variables

| Variable               | Description                                | Default              | Required |
| ---------------------- | ------------------------------------------ | -------------------- | -------- |
| `PG_DATABASE_PASSWORD` | PostgreSQL password (URL-safe, no `@:/#?`) | -                    | Yes      |
| `ENCRYPTION_KEY`       | Encryption key for secrets                 | -                    | Yes      |
| `SERVER_URL`           | Public URL of the server                   | -                    | Yes      |
| `PG_DATABASE_USER`     | PostgreSQL user                            | `postgres`           | No       |
| `PG_DATABASE_HOST`     | PostgreSQL host                            | `db`                 | No       |
| `PG_DATABASE_PORT`     | PostgreSQL port                            | `5432`               | No       |
| `PG_DATABASE_NAME`     | PostgreSQL database name                   | `default`            | No       |
| `REDIS_URL`            | Redis connection URL                       | `redis://redis:6379` | No       |
| `STORAGE_TYPE`         | Storage backend (`local` or `s3`)          | `local`              | No       |
| `DOMAIN`               | Domain for Traefik routing                 | -                    | Traefik  |
| `DEV_BIND_IP`          | Bind IP for dev sidecar ports              | `127.0.0.1`          | No       |

### Optional encryption

| Variable                  | Description                                        | Default |
| ------------------------- | -------------------------------------------------- | ------- |
| `FALLBACK_ENCRYPTION_KEY` | Previous key during a rotation                     | -       |
| `APP_SECRET`              | Legacy key for instances pre-dating ENCRYPTION_KEY | -       |

### Optional S3 storage

| Variable                       | Description     |
| ------------------------------ | --------------- |
| `STORAGE_S3_REGION`            | S3 region       |
| `STORAGE_S3_NAME`              | S3 bucket name  |
| `STORAGE_S3_ENDPOINT`          | S3 endpoint URL |
| `STORAGE_S3_ACCESS_KEY_ID`     | S3 access key   |
| `STORAGE_S3_SECRET_ACCESS_KEY` | S3 secret key   |

## Volumes

| Host Path         | Container Path                               | Description               |
| ----------------- | -------------------------------------------- | ------------------------- |
| `./data/postgres` | `/var/lib/postgresql/data`                   | PostgreSQL data           |
| `./data/redis`    | `/data`                                      | Redis data                |
| `./data/server`   | `/app/packages/twenty-server/.local-storage` | Server local file storage |

## Links

- [Twenty Website](https://twenty.com)
- [Documentation](https://docs.twenty.com)
- [GitHub Repository](https://github.com/twentyhq/twenty)
