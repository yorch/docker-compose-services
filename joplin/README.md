# Joplin Server

Self-hosted sync server for Joplin, an open-source note-taking application.

## Features

- Sync notes across devices
- End-to-end encryption support
- Share notes and notebooks
- Collaboration features
- Web clipper integration

## Quick Start

```bash
docker compose up -d
```

## Services

| Service     | Description                |
| ----------- | -------------------------- |
| `app`       | Joplin Server              |
| `db`        | PostgreSQL database        |
| `adminer`   | Database administration UI |
| `dbbackups` | Automated database backups |

## Environment Variables

| Variable       | Description      | Default  |
| -------------- | ---------------- | -------- |
| `APP_NAME`     | Application name | `Joplin` |
| `APP_BASE_URL` | Public URL       | -        |
| `APP_PORT`     | Application port | `22300`  |
| `DB_CLIENT`    | Database client  | `pg`     |

### Database Configuration

| Variable            | Description       |
| ------------------- | ----------------- |
| `POSTGRES_HOST`     | Database hostname |
| `POSTGRES_PORT`     | Database port     |
| `POSTGRES_USER`     | Database user     |
| `POSTGRES_PASSWORD` | Database password |
| `POSTGRES_DATABASE` | Database name     |

### Email Configuration (Optional)

| Variable               | Description        |
| ---------------------- | ------------------ |
| `MAILER_ENABLED`       | Enable email       |
| `MAILER_HOST`          | SMTP host          |
| `MAILER_PORT`          | SMTP port          |
| `MAILER_SECURITY`      | SMTP security      |
| `MAILER_AUTH_USER`     | SMTP username      |
| `MAILER_AUTH_PASSWORD` | SMTP password      |
| `MAILER_NOREPLY_EMAIL` | From email address |

## Volumes

| Host Path                 | Container Path             | Description      |
| ------------------------- | -------------------------- | ---------------- |
| `./data/postgres`         | `/var/lib/postgresql/data` | Database data    |
| `./data/postgres-backups` | `/backups`                 | Database backups |

## Client Configuration

In Joplin desktop/mobile:

1. Go to Options > Synchronization
2. Set target to "Joplin Server"
3. Enter your server URL
4. Enter your credentials

## Links

- [Joplin Website](https://joplinapp.org/)
- [Joplin Server Documentation](https://joplinapp.org/help/apps/joplin_server/)
- [GitHub Repository](https://github.com/laurent22/joplin)
