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
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d

# Other setups:
./run-manual-db-backup.sh
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

## Services

| Service     | Description                                                |
| ----------- | ---------------------------------------------------------- |
| `app`       | Joplin Server                                              |
| `db`        | PostgreSQL database                                        |
| `dbbackups` | Automated database backups                                 |
| `adminer`   | Database admin UI, **dev overlay only** (`127.0.0.1:8080`) |

Adminer is never routed through Traefik. To inspect a production database, open an SSH
tunnel to the host and run the dev overlay's `adminer` there, or connect with `psql`.

## Environment Variables

| Variable       | Description                                                 | Default     |
| -------------- | ----------------------------------------------------------- | ----------- |
| `DOMAIN`       | Hostname Traefik routes to Joplin (Traefik only)            | -           |
| `APP_NAME`     | Application name                                            | `Joplin`    |
| `APP_BASE_URL` | Public URL; must match the URL you browse to (origin check) | -           |
| `APP_PORT`     | Port Joplin listens on, published as-is by the dev overlay  | `22300`     |
| `DEV_BIND_IP`  | Host interface for the dev overlay's Postgres and Adminer   | `127.0.0.1` |

### Database Configuration

| Variable            | Description                                              |
| ------------------- | -------------------------------------------------------- |
| `POSTGRES_USER`     | Database user                                            |
| `POSTGRES_PASSWORD` | Database password (**required**, `openssl rand -hex 32`) |
| `POSTGRES_DATABASE` | Database name                                            |
| `POSTGRES_PORT`     | Database port                                            |

### Backups

| Variable                       | Description                                                     |
| ------------------------------ | --------------------------------------------------------------- |
| `DBBACKUPS_SCHEDULE`           | Cron schedule (default `@daily`)                                |
| `DBBACKUPS_BACKUP_KEEP_DAYS`   | Daily backups to keep                                           |
| `DBBACKUPS_BACKUP_KEEP_WEEKS`  | Weekly backups to keep                                          |
| `DBBACKUPS_BACKUP_KEEP_MONTHS` | Monthly backups to keep                                         |
| `DBBACKUPS_HEALTHCHECK_PORT`   | Health endpoint, routed at `dbbackups.${DOMAIN}` behind Traefik |

### Email Configuration (Optional)

| Variable               | Description        |
| ---------------------- | ------------------ |
| `MAILER_ENABLED`       | Enable email       |
| `MAILER_HOST`          | SMTP host          |
| `MAILER_PORT`          | SMTP port          |
| `MAILER_SECURITY`      | SMTP security      |
| `MAILER_AUTH_USER`     | SMTP username      |
| `MAILER_AUTH_PASSWORD` | SMTP password      |
| `MAILER_NOREPLY_NAME`  | From name          |
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
