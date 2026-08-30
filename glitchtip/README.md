# GlitchTip

Open-source error tracking compatible with Sentry SDKs. Lightweight alternative to Sentry.

## Features

- Sentry SDK compatible
- Error tracking and grouping
- Performance monitoring
- Team collaboration
- Email notifications
- Built-in database backups

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

## Services

| Service     | Description                     |
| ----------- | ------------------------------- |
| `web`       | Web application (granian ASGI)  |
| `worker`    | django-vtasks background worker |
| `postgres`  | PostgreSQL database             |
| `valkey`    | Cache and task queue (Valkey 9) |
| `migrate`   | Database migrations             |
| `dbbackups` | Automated PostgreSQL backups    |

## Environment Variables

| Variable            | Description       | Required |
| ------------------- | ----------------- | -------- |
| `SECRET_KEY`        | Django secret key | Yes      |
| `GLITCHTIP_DOMAIN`  | Public URL        | Yes      |
| `POSTGRES_DB`       | Database name     | Yes      |
| `POSTGRES_USER`     | Database user     | Yes      |
| `POSTGRES_PASSWORD` | Database password | Yes      |

### Email Configuration

| Variable              | Description          |
| --------------------- | -------------------- |
| `DEFAULT_FROM_EMAIL`  | Sender email address |
| `EMAIL_HOST`          | SMTP server          |
| `EMAIL_PORT`          | SMTP port            |
| `EMAIL_HOST_USER`     | SMTP username        |
| `EMAIL_HOST_PASSWORD` | SMTP password        |
| `EMAIL_USE_TLS`       | Enable TLS           |

### User Registration

| Variable                       | Description             | Default |
| ------------------------------ | ----------------------- | ------- |
| `ENABLE_USER_REGISTRATION`     | Allow new registrations | `true`  |
| `ENABLE_ORGANIZATION_CREATION` | Allow org creation      | `false` |

### Data Retention

| Variable                               | Description                        | Default |
| -------------------------------------- | ---------------------------------- | ------- |
| `GLITCHTIP_RETENTION_DAYS`             | Master default for all retention   | `90`    |
| `GLITCHTIP_EVENT_RETENTION_DAYS`       | Error event retention (hot + cold) | `90`    |
| `GLITCHTIP_EVENT_HOT_DAYS`             | Days in PostgreSQL before archival | `30`    |
| `GLITCHTIP_TRANSACTION_RETENTION_DAYS` | Transaction retention (hot + cold) | `90`    |
| `GLITCHTIP_LOG_RETENTION_DAYS`         | Log retention (hot + cold)         | `90`    |
| `GLITCHTIP_LOG_HOT_DAYS`               | Days logs stay in PostgreSQL       | `7`     |
| `GLITCHTIP_UPTIME_RETENTION_DAYS`      | Uptime check retention             | `90`    |
| `GLITCHTIP_FILE_RETENTION_DAYS`        | File (sourcemap, debug symbol)     | `90`    |
| `GLITCHTIP_RELEASE_RETENTION_DAYS`     | Release retention                  | `365`   |

### Server / Scaling (v6: granian + django-vtasks)

| Variable                 | Description                         | Default   |
| ------------------------ | ----------------------------------- | --------- |
| `TRUSTED_PROXIES`        | Trusted proxy IPs/CIDRs for granian | `*`       |
| `GRANIAN_WORKERS`        | Granian web workers                 | `1`       |
| `VTASKS_CONCURRENCY`     | Concurrent asyncio background tasks | `20`      |
| `DATABASE_POOL_MAX_SIZE` | psycopg connection pool size        | `20`      |
| `LOG_LEVEL`              | Python log level                    | `WARNING` |

### Security / Proxy

| Variable               | Description                                     | Default |
| ---------------------- | ----------------------------------------------- | ------- |
| `ALLOWED_HOSTS`        | Comma-separated allowed hostnames               | `*`     |
| `CSRF_TRUSTED_ORIGINS` | Trusted origins for CSRF (needed behind proxy)  |         |
| `SECURE_HSTS_SECONDS`  | HSTS max-age (0 disables)                       | `0`     |
| `BASE_PATH`            | Subpath to run under (e.g. `/glitchtip`)        |         |
| `PROXY_ENV`            | Trust `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` | `false` |

## Volumes

| Host Path                 | Container Path             | Description      |
| ------------------------- | -------------------------- | ---------------- |
| `./data/postgres`         | `/var/lib/postgresql/data` | Database data    |
| `./data/uploads`          | `/code/uploads`            | Uploaded files   |
| `./data/postgres-backups` | `/backups`                 | Database backups |

## Client Integration

Use any Sentry SDK with your GlitchTip DSN:

```javascript
import * as Sentry from '@sentry/browser';

Sentry.init({
  dsn: 'https://your-key@your-glitchtip-domain/1',
});
```

## Links

- [GlitchTip Website](https://glitchtip.com/)
- [Documentation](https://glitchtip.com/documentation)
- [GitLab Repository](https://gitlab.com/glitchtip/glitchtip)
