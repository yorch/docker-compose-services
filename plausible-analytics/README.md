# Plausible Analytics

Privacy-friendly, lightweight website analytics.

## Features

- No cookies required
- GDPR/CCPA compliant
- Lightweight script (<1KB)
- Real-time dashboard
- Goal and event tracking
- Email reports

## Quick Start

1. Generate required keys:

```bash
# Generate SECRET_KEY_BASE
openssl rand -base64 48

# Generate TOTP_VAULT_KEY
openssl rand -base64 32
```

2. Configure environment variables
3. Start the services:

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

| Service      | Description             |
| ------------ | ----------------------- |
| `app`        | Plausible application   |
| `postgres`   | PostgreSQL for metadata |
| `clickhouse` | ClickHouse for events   |

## Environment Variables

| Variable                  | Description            | Required |
| ------------------------- | ---------------------- | -------- |
| `BASE_URL`                | Public URL             | Yes      |
| `SECRET_KEY_BASE`         | Secret key (64+ chars) | Yes      |
| `TOTP_VAULT_KEY`          | 2FA encryption key     | Yes      |
| `DATABASE_URL`            | PostgreSQL URL         | Yes      |
| `CLICKHOUSE_DATABASE_URL` | ClickHouse URL         | Yes      |

### Email Configuration

| Variable         | Description        |
| ---------------- | ------------------ |
| `MAILER_EMAIL`   | From email address |
| `MAILER_ADAPTER` | Email adapter      |
| `SMTP_HOST_ADDR` | SMTP server        |
| `SMTP_HOST_PORT` | SMTP port          |
| `SMTP_USER_NAME` | SMTP username      |
| `SMTP_USER_PWD`  | SMTP password      |

### GeoIP (Optional)

| Variable              | Description         |
| --------------------- | ------------------- |
| `MAXMIND_LICENSE_KEY` | MaxMind license key |

## Volumes

| Host Path         | Container Path        | Description      |
| ----------------- | --------------------- | ---------------- |
| `./data/app`      | `/var/lib/plausible`  | Application data |
| `./data/postgres` | `/var/lib/postgresql` | PostgreSQL data  |

PostgreSQL 18 is not on-disk compatible with the 14 image this stack used before.
Dump and restore (`pg_dumpall`, then `psql`) before pointing an existing deployment at
the new image. The bind mount above already uses the PostgreSQL 18 path.

| `./data/clickhouse` | `/var/lib/clickhouse` | ClickHouse data |

## Website Integration

Add to your website:

```html
<script
  defer
  data-domain="yourdomain.com"
  src="https://plausible.yourdomain.com/js/script.js"
></script>
```

## Migrating from PostgreSQL 14

The image now runs PostgreSQL 18, which cannot start a 14 data directory. Dump and
restore before starting the new image.

1. With the **old** stack still running, dump every database:

   ```bash
   docker compose -f docker-compose.yml exec -T db \
     sh -c 'pg_dumpall -U "$POSTGRES_USER"' > /tmp/plausible-pg14.sql
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
     sh -c 'psql -U "$POSTGRES_USER" -d postgres' < /tmp/plausible-pg14.sql
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

- [Plausible Website](https://plausible.io/)
- [Documentation](https://plausible.io/docs)
- [GitHub Repository](https://github.com/plausible/analytics)
