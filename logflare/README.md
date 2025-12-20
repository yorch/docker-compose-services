# Logflare

Log ingestion and analytics service (Supabase's logging backend).

## Features

- Real-time log ingestion
- Structured log search
- BigQuery integration
- PostgreSQL backend option
- Dashboard and visualization

## Quick Start

```bash
docker compose up -d
```

## Services

| Service | Description          |
| ------- | -------------------- |
| `app`   | Logflare application |
| `db`    | PostgreSQL database  |

## Environment Variables

| Variable                 | Description               | Required |
| ------------------------ | ------------------------- | -------- |
| `DB_HOST`                | Database hostname         | Yes      |
| `DB_USERNAME`            | Database user             | Yes      |
| `DB_PASSWORD`            | Database password         | Yes      |
| `DB_NAME`                | Database name             | Yes      |
| `LOGFLARE_API_KEY`       | API key                   | Yes      |
| `LOGFLARE_SINGLE_TENANT` | Run in single-tenant mode | Yes      |
| `LOGFLARE_PORT`          | Application port          | Yes      |

### BigQuery Backend (Optional)

| Variable                         | Description         |
| -------------------------------- | ------------------- |
| `GOOGLE_PROJECT_ID`              | GCP project ID      |
| `GOOGLE_CLOUD_PROJECT`           | GCP project         |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to credentials |

## Volumes

| Host Path            | Container Path             | Description     |
| -------------------- | -------------------------- | --------------- |
| `./data/postgres`    | `/var/lib/postgresql/data` | Database data   |
| `./data/gcloud.json` | `/etc/gcloud.json`         | GCP credentials |

## GCP Setup

For BigQuery backend:

1. Create a GCP project
2. Enable BigQuery API
3. Create a service account with BigQuery permissions
4. Download the JSON key file to `./data/gcloud.json`

## Links

- [Logflare Website](https://logflare.app/)
- [GitHub Repository](https://github.com/Logflare/logflare)
- [Supabase Logging](https://supabase.com/docs/guides/platform/logs)
