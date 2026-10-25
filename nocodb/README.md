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

| Host Path         | Container Path        | Description      |
| ----------------- | --------------------- | ---------------- |
| `./data/nocodb`   | `/usr/app/data`       | Application data |
| `./data/postgres` | `/var/lib/postgresql` | Database data    |

PostgreSQL 18 is not on-disk compatible with the 14 image this stack used before.
Dump and restore (`pg_dumpall`, then `psql`) before pointing an existing deployment at
the new image. The bind mount above already uses the PostgreSQL 18 path.

## API Access

NocoDB provides REST and GraphQL APIs:

```bash
# Get API token from UI: Settings > API Tokens

curl -X GET "http://localhost:8080/api/v1/db/data/v1/..." \
  -H "xc-token: your-api-token"
```

## Migrating from PostgreSQL 14

The image now runs PostgreSQL 18, which cannot start a 14 data directory. Dump and
restore before starting the new image.

1. With the **old** stack still running, dump every database:

   ```bash
   docker compose -f docker-compose.yml exec -T db \
     sh -c 'pg_dumpall -U "$POSTGRES_USER"' > /tmp/nocodb-pg14.sql
   ```

2. Stop the stack and keep the old data directory as a backup:

   ```bash
   docker compose -f docker-compose.yml down
   mv data/postgres data/postgres.pg14
   ```

3. Start the empty PostgreSQL 18 database and restore into it:

   ```bash
   docker compose -f docker-compose.yml up -d --wait db
   docker compose -f docker-compose.yml exec -T db \
     sh -c 'psql -U "$POSTGRES_USER" -d postgres' < /tmp/nocodb-pg14.sql
   ```

   The `role "..." already exists` and `database "..." already exists` messages are
   expected: the image creates the bootstrap role and database before the restore runs.

4. Start the rest of the stack:

   ```bash
   docker compose -f docker-compose.yml up -d
   ```

If you already pulled this change, the repo ships a helper that takes the dump from the
old data directory:

```bash
docker compose -f docker-compose.yml down
../pg-dump.sh .
```

It writes `data/pg14-dump-<timestamp>.sql`, prints the restore commands, and never moves
or deletes data. It refuses to run while the database container is up.

Use the same `-f` flags you normally run. The base file is enough here because the dump
and restore happen inside the `db` container.

## Links

- [NocoDB Website](https://nocodb.com/)
- [Documentation](https://docs.nocodb.com/)
- [GitHub Repository](https://github.com/nocodb/nocodb)
