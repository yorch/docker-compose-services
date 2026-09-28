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
cp .env.sample .env  # then set POSTGRES_PASSWORD and LOGFLARE_API_KEY

# Dev - publishes ports on localhost (UI and API on http://localhost:4000)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

Runs in single-tenant mode with the Postgres backend: the browser is signed in as the
seeded user automatically. Create a source in the UI, then ingest with the API key and
the source's UUID (shown on the source page):

```bash
curl -H "x-api-key: $LOGFLARE_API_KEY" -H "Content-Type: application/json" \
  -d '{"event_message": "hello"}' \
  "http://localhost:4000/api/logs?source=<source-uuid>"
```

## Services

| Service | Description                                                    |
| ------- | -------------------------------------------------------------- |
| `app`   | Logflare (UI + API)                                            |
| `db`    | PostgreSQL 16: Logflare's metadata and the log storage backend |

## Environment Variables

| Variable            | Description                                                             | Required |
| ------------------- | ----------------------------------------------------------------------- | -------- |
| `POSTGRES_PASSWORD` | Database password (`openssl rand -hex 24`)                              | Yes      |
| `LOGFLARE_API_KEY`  | Ingest/query token for the seeded user (`openssl rand -hex 32`)         | Yes      |
| `POSTGRES_USER`     | Database user (default `postgres`)                                      | No       |
| `POSTGRES_DB`       | Database name, also the log schema (default `logflare`)                 | No       |
| `LOGFLARE_PORT`     | Port Logflare listens on and the dev overlay publishes (default `4000`) | No       |
| `DB_PORT`           | Dev host port for Postgres (default `5432`)                             | No       |
| `DEV_BIND_IP`       | Host interface for the dev Postgres port (default `127.0.0.1`)          | No       |

`LOGFLARE_API_KEY` is a deprecated alias of `LOGFLARE_PUBLIC_ACCESS_TOKEN` in current
Logflare releases; it still works on the pinned 1.12.5.

### BigQuery Backend (Optional)

Uncomment the `GOOGLE_*` variables in `docker-compose.yml` and `.env`, and the
`gcloud.json` mount:

| Variable                   | Description                    |
| -------------------------- | ------------------------------ |
| `GOOGLE_PROJECT_ID`        | GCP project ID                 |
| `GOOGLE_PROJECT_NUMBER`    | GCP project number             |
| `GOOGLE_DATASET_ID_APPEND` | Suffix appended to dataset IDs |

## Volumes

| Host Path            | Container Path                          | Description                        |
| -------------------- | --------------------------------------- | ---------------------------------- |
| `./data/postgres`    | `/var/lib/postgresql/data`              | Database data                      |
| `./setup.sql`        | `/docker-entrypoint-initdb.d/setup.sql` | Enables logical WAL + replication  |
| `./data/gcloud.json` | `/opt/app/rel/logflare/bin/gcloud.json` | GCP key (BigQuery only, commented) |

## GCP Setup

For the BigQuery backend:

1. Create a GCP project
2. Enable the BigQuery API
3. Create a service account with BigQuery permissions
4. Download the JSON key file to `./data/gcloud.json`, then uncomment its mount

## Links

- [Logflare Website](https://logflare.app/)
- [GitHub Repository](https://github.com/Logflare/logflare)
- [Supabase Logging](https://supabase.com/docs/guides/platform/logs)
