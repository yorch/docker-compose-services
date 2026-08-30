# Lychee

Self-hosted photo management and sharing platform.

## Features

- Photo and album management
- EXIF data display
- Sharing and public albums
- Tagging and search
- Import from various sources
- Multi-user support

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

## Upgrading from the legacy image

The `lycheeorg/lychee` image is now FrankenPHP-based (Laravel Octane) instead of
the old nginx + PHP-FPM stack. The new image refuses to start if a `.env` file is
mounted at `/conf/.env`, and the mount paths have changed:

| Old container path | New container path    |
| ------------------ | --------------------- |
| `/conf`            | _(removed — use env)_ |
| `/uploads`         | `/app/public/uploads` |
| `/sym`             | _(removed)_           |
| `/logs`            | `/app/storage/logs`   |
| _(none)_           | `/app/storage/tmp`    |

The host-side `./data/lychee/uploads` and `./data/lychee/logs` directories keep
their data; only the container paths change. The old `./data/lychee/conf` and
`./data/lychee/sym` directories are no longer used and can be removed after
confirming the upgrade works. `APP_KEY` is now mandatory — generate one with
`echo "APP_KEY=base64:$(openssl rand -base64 32)"` and add it to `.env`.

## Services

| Service | Description         |
| ------- | ------------------- |
| `app`   | Lychee application  |
| `db`    | PostgreSQL database |

## Environment Variables

| Variable            | Description                            | Required |
| ------------------- | -------------------------------------- | -------- |
| `APP_URL`           | Public URL (scheme + host)             | Yes      |
| `APP_KEY`           | Laravel app key (base64 32 bytes)      | Yes      |
| `POSTGRES_DB`       | Database name                          | Yes      |
| `POSTGRES_USER`     | Database user                          | Yes      |
| `POSTGRES_PASSWORD` | Database password                      | Yes      |
| `LYCHEE_DOMAIN`     | Domain for Traefik Host() rule         | Traefik  |
| `TIMEZONE`          | Server timezone                        | -        |
| `PUID`              | Container user ID (default 1000)       | -        |
| `PGID`              | Container group ID (default 1000)      | -        |
| `APP_NAME`          | Application name (default Lychee)      | -        |
| `APP_ENV`           | Laravel env (default production)       | -        |
| `APP_DEBUG`         | Debug mode (default false)             | -        |
| `SESSION_DRIVER`    | Session driver (default file)          | -        |
| `SESSION_LIFETIME`  | Session lifetime minutes (default 120) | -        |
| `CACHE_STORE`       | Cache store (default file)             | -        |
| `QUEUE_CONNECTION`  | Queue driver (default database)        | -        |

## Volumes

| Host Path               | Container Path             | Description      |
| ----------------------- | -------------------------- | ---------------- |
| `./data/lychee/uploads` | `/app/public/uploads`      | Photo uploads    |
| `./data/lychee/logs`    | `/app/storage/logs`        | Application logs |
| `./data/lychee/tmp`     | `/app/storage/tmp`         | Temporary files  |
| `./data/postgres`       | `/var/lib/postgresql/data` | Database         |

## First-Time Setup

1. Access the web interface
2. Create an admin account
3. Configure settings
4. Upload photos or import from a folder

## Links

- [Lychee Website](https://lycheeorg.github.io/)
- [Documentation](https://lycheeorg.github.io/docs/)
- [GitHub Repository](https://github.com/LycheeOrg/Lychee)
