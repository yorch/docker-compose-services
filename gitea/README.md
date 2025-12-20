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
docker compose up -d
```

## Services

| Service     | Description                |
| ----------- | -------------------------- |
| `app`       | Gitea application          |
| `db`        | PostgreSQL database        |
| `dbbackups` | Automated database backups |

## Environment Variables

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

```
Host gitea
    HostName your-server
    Port 222
    User git
```

## Links

- [Gitea Website](https://gitea.io/)
- [Documentation](https://docs.gitea.io/)
- [GitHub Repository](https://github.com/go-gitea/gitea)
