# Gitea

Self-hosted Git service similar to GitHub/GitLab with a lightweight footprint.

## Features

- Git repository hosting
- Issue tracking and pull requests
- Wiki and project management
- GitHub Actions-compatible CI/CD (Gitea Actions)
- Full-text repository indexing
- OAuth2 and LDAP authentication

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

| Service     | Description                |
| ----------- | -------------------------- |
| `app`       | Gitea application          |
| `db`        | PostgreSQL database        |
| `dbbackups` | Automated database backups |

## Environment Variables

Set these in `.env` (copy from `.env.sample`). All are required — the database
containers fail to start if `POSTGRES_PASSWORD` is empty.

| Variable                       | Description                                 | Default  |
| ------------------------------ | ------------------------------------------- | -------- |
| `GITEA_DOMAIN`                 | Public hostname, used by the Traefik router | -        |
| `POSTGRES_DATABASE`            | Database name                               | `gitea`  |
| `POSTGRES_USER`                | Database user                               | `gitea`  |
| `POSTGRES_PASSWORD`            | Database password                           | `gitea`  |
| `DBBACKUPS_SCHEDULE`           | Backup cron schedule                        | `@daily` |
| `DBBACKUPS_BACKUP_KEEP_DAYS`   | Daily backups to retain                     | `7`      |
| `DBBACKUPS_BACKUP_KEEP_WEEKS`  | Weekly backups to retain                    | `4`      |
| `DBBACKUPS_BACKUP_KEEP_MONTHS` | Monthly backups to retain                   | `6`      |
| `DBBACKUPS_HEALTHCHECK_PORT`   | Backup container healthcheck port           | `8080`   |

Set directly in `docker-compose.yml` rather than `.env`:

| Variable                               | Description                   | Default    |
| -------------------------------------- | ----------------------------- | ---------- |
| `USER_UID`                             | User ID for file permissions  | `1000`     |
| `USER_GID`                             | Group ID for file permissions | `1000`     |
| `GITEA__database__DB_TYPE`             | Database type                 | `postgres` |
| `GITEA__server__HTTP_PORT`             | HTTP port                     | `3000`     |
| `GITEA__indexer__REPO_INDEXER_ENABLED` | Enable repository indexing    | `true`     |
| `GITEA__actions__ENABLED`              | Enable Gitea Actions          | `true`     |

## Ports

| Port     | Description            |
| -------- | ---------------------- |
| `222:22` | SSH for Git operations |

## Volumes

| Host Path                 | Container Path             | Description                 |
| ------------------------- | -------------------------- | --------------------------- |
| `./data/gitea`            | `/data`                    | Gitea data and repositories |
| `./data/postgres`         | `/var/lib/postgresql/data` | Database data               |
| `./data/postgres-backups` | `/backups`                 | Database backups            |

## SSH Configuration

To use SSH for Git operations on a non-standard port:

```bash
git clone ssh://git@your-server:222/user/repo.git
```

Or add to `~/.ssh/config`:

```text
Host gitea
    HostName your-server
    Port 222
    User git
```

## Links

- [Gitea Website](https://gitea.io/)
- [Documentation](https://docs.gitea.io/)
- [GitHub Repository](https://github.com/go-gitea/gitea)
