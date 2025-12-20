# Linkwarden

Self-hosted bookmark manager with full-text search capabilities.

## Features

- Bookmark organization with collections
- Full-text search with Meilisearch
- Automatic screenshots and archives
- Browser extensions
- Collaboration features
- Import/export support

## Quick Start

```bash
docker compose up -d
```

## Services

| Service       | Description              |
| ------------- | ------------------------ |
| `app`         | Linkwarden application   |
| `db`          | PostgreSQL database      |
| `meilisearch` | Full-text search engine  |
| `adminer`     | Database admin interface |

## Environment Variables

| Variable           | Description                    | Required |
| ------------------ | ------------------------------ | -------- |
| `DATABASE_URL`     | PostgreSQL connection string   | Yes      |
| `MEILI_MASTER_KEY` | Meilisearch authentication key | Yes      |

### PostgreSQL Configuration

| Variable            | Description       |
| ------------------- | ----------------- |
| `POSTGRES_HOST`     | Database hostname |
| `POSTGRES_USER`     | Database user     |
| `POSTGRES_PASSWORD` | Database password |
| `POSTGRES_DB`       | Database name     |

## Volumes

| Host Path            | Container Path             | Description      |
| -------------------- | -------------------------- | ---------------- |
| `./data/app`         | `/data`                    | Application data |
| `./data/postgres`    | `/var/lib/postgresql/data` | Database data    |
| `./data/meilisearch` | `/meili_data`              | Search index     |

## Browser Extensions

- [Chrome Extension](https://chrome.google.com/webstore/)
- [Firefox Add-on](https://addons.mozilla.org/firefox/)

## Links

- [Linkwarden Website](https://linkwarden.app/)
- [Documentation](https://docs.linkwarden.app/)
- [GitHub Repository](https://github.com/linkwarden/linkwarden)
