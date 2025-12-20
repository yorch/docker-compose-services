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
docker compose up -d
```

## Services

| Service | Description         |
| ------- | ------------------- |
| `app`   | Lychee application  |
| `db`    | PostgreSQL database |

## Environment Variables

| Variable            | Description        | Required |
| ------------------- | ------------------ | -------- |
| `POSTGRES_DB`       | Database name      | Yes      |
| `POSTGRES_USER`     | Database user      | Yes      |
| `POSTGRES_PASSWORD` | Database password  | Yes      |
| `LYCHEE_DOMAIN`     | Application domain | Yes      |
| `TIMEZONE`          | Server timezone    | -        |

### Database Connection

| Variable        | Description                 |
| --------------- | --------------------------- |
| `DB_CONNECTION` | Database type (pgsql/mysql) |
| `DB_HOST`       | Database host               |
| `DB_PORT`       | Database port               |
| `DB_DATABASE`   | Database name               |
| `DB_USERNAME`   | Database user               |
| `DB_PASSWORD`   | Database password           |

### Application Settings

| Variable          | Description            | Default |
| ----------------- | ---------------------- | ------- |
| `APP_FORCE_HTTPS` | Force HTTPS            | `false` |
| `STARTUP_DELAY`   | Startup delay seconds  | `0`     |
| `ADMIN_USER`      | Initial admin username | -       |
| `ADMIN_PASSWORD`  | Initial admin password | -       |

## Volumes

| Host Path               | Container Path             | Description      |
| ----------------------- | -------------------------- | ---------------- |
| `./data/lychee/conf`    | `/conf`                    | Configuration    |
| `./data/lychee/uploads` | `/uploads`                 | Photo uploads    |
| `./data/lychee/sym`     | `/sym`                     | Symbolic links   |
| `./data/lychee/logs`    | `/logs`                    | Application logs |
| `./data/postgres`       | `/var/lib/postgresql/data` | Database         |

## First-Time Setup

1. Access the web interface
2. Create an admin account
3. Configure settings
4. Upload photos or import from a folder

## Import Photos

Photos can be imported from:

- Web upload
- Server folder
- URL import
- Dropbox

## Links

- [Lychee Website](https://lycheeorg.github.io/)
- [Documentation](https://lycheeorg.github.io/docs/)
- [GitHub Repository](https://github.com/LycheeOrg/Lychee)
