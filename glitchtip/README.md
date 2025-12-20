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
docker compose up -d
```

## Services

| Service     | Description                  |
| ----------- | ---------------------------- |
| `web`       | Web application              |
| `worker`    | Celery background worker     |
| `postgres`  | PostgreSQL database          |
| `redis`     | Cache and message broker     |
| `migrate`   | Database migrations          |
| `dbbackups` | Automated PostgreSQL backups |

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

| Variable                                    | Description                 | Default |
| ------------------------------------------- | --------------------------- | ------- |
| `GLITCHTIP_MAX_EVENT_LIFE_DAYS`             | Event retention days        | `90`    |
| `GLITCHTIP_MAX_TRANSACTION_EVENT_LIFE_DAYS` | Transaction event retention | `90`    |
| `GLITCHTIP_MAX_TRANSACTION_LIFE_DAYS`       | Transaction retention       | `180`   |

### Worker Configuration

| Variable                            | Description                 | Default   |
| ----------------------------------- | --------------------------- | --------- |
| `CELERY_WORKER_CONCURRENCY`         | Concurrent workers          | CPU cores |
| `CELERY_WORKER_MAX_TASKS_PER_CHILD` | Tasks before worker restart | `100`     |

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
- [GitHub Repository](https://gitlab.com/glitchtip/glitchtip)
