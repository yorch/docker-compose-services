# NocoDB

Open-source Airtable alternative - turns any database into a smart spreadsheet.

## Features

- Spreadsheet UI for databases
- REST and GraphQL APIs
- Collaboration features
- Rich field types
- Automations and webhooks
- Multiple database support

## Quick Start

```bash
docker compose up -d
```

Access NocoDB at `http://localhost:8080`

## Services

| Service | Description         |
| ------- | ------------------- |
| `app`   | NocoDB application  |
| `db`    | PostgreSQL database |

## Environment Variables

| Variable | Description                | Required |
| -------- | -------------------------- | -------- |
| `NC_DB`  | Database connection string | Yes      |

### PostgreSQL Configuration

| Variable            | Description       |
| ------------------- | ----------------- |
| `POSTGRES_HOST`     | Database hostname |
| `POSTGRES_USER`     | Database user     |
| `POSTGRES_PASSWORD` | Database password |
| `POSTGRES_DB`       | Database name     |

### Optional Configuration

| Variable              | Description               |
| --------------------- | ------------------------- |
| `NC_SMTP_HOST`        | SMTP server               |
| `NC_SMTP_PORT`        | SMTP port                 |
| `NC_SMTP_USERNAME`    | SMTP username             |
| `NC_SMTP_PASSWORD`    | SMTP password             |
| `NC_S3_BUCKET`        | S3 bucket for attachments |
| `NC_S3_REGION`        | S3 region                 |
| `NC_S3_ACCESS_KEY`    | S3 access key             |
| `NC_S3_ACCESS_SECRET` | S3 secret key             |

## Volumes

| Host Path         | Container Path             | Description      |
| ----------------- | -------------------------- | ---------------- |
| `./data/nocodb`   | `/usr/app/data`            | Application data |
| `./data/postgres` | `/var/lib/postgresql/data` | Database data    |

## API Access

NocoDB provides REST and GraphQL APIs:

```bash
# Get API token from UI: Settings > API Tokens

curl -X GET "http://localhost:8080/api/v1/db/data/v1/..." \
  -H "xc-token: your-api-token"
```

## Links

- [NocoDB Website](https://nocodb.com/)
- [Documentation](https://docs.nocodb.com/)
- [GitHub Repository](https://github.com/nocodb/nocodb)
