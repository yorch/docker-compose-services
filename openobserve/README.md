# OpenObserve

Full-stack observability platform for logs, metrics and traces, with built-in dashboards and alerting.

## Features

- Logs, metrics and traces in a single stack
- Ingests OpenTelemetry, Fluent Bit, Vector, Filebeat and Elasticsearch-compatible data
- SQL and PromQL queries over ingested streams
- Dashboards, alerts and scheduled reports
- Stores data as Parquet on local disk or any S3-compatible object store
- Postgres-backed metadata for durability

## Quick Start

Copy `.env.sample` to `.env` and fill in the blank values first — the admin
login and the database password have no defaults.

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

With the dev overlay the UI is at `http://localhost:5080`; sign in with
`ZO_ROOT_USER_EMAIL` and `ZO_ROOT_USER_PASSWORD`. The Traefik overlay publishes
no ports, so reach it at `https://${DOMAIN}` instead.

On **macOS with Docker Desktop**, Postgres 18 will not start against a bind
mount — see [Storage](#storage) for the overlay that fixes local development.
Linux hosts need no change.

## Services

| Service    | Description                                             |
| ---------- | ------------------------------------------------------- |
| `app`      | Ingestion API, query engine and web UI on port 5080     |
| `postgres` | Metadata — users, dashboards, alerts and stream schemas |

The image is the AGPL-3.0 open source build. An enterprise build exists at
`o2cr.ai/openobserve/openobserve-enterprise`, published under a commercial
license agreement; the OSS `latest` tag tends to trail it by a few patch
releases.

## Metadata Store

`ZO_META_STORE=postgres` is what selects Postgres, and it is set in
`docker-compose.yml` rather than exposed in `.env`. **Supplying only
`ZO_META_POSTGRES_DSN` is not enough** — OpenObserve defaults to SQLite in local
mode, silently ignores the DSN, writes metadata to `./data/app/db/metadata.sqlite`
and leaves the Postgres container empty. There is no error, and the container
reports healthy either way, so the mistake only surfaces when you go looking for
your dashboards after a restore.

Don't check this by looking for `./data/app/db/metadata.sqlite` — that file is
created either way, and only its size differs (a few KB when unused, hundreds of
KB when it is the real store). Query Postgres instead; a correctly wired
instance has roughly 80 tables and your admin account:

```bash
docker compose exec postgres \
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c 'select email from users;'
```

## Storage

`ZO_LOCAL_MODE_STORAGE` decides where ingested data lands, and defaults to
`disk` — everything stays under `./data/app`, which is the right choice for a
single-node deployment.

To use an object store instead, set `ZO_LOCAL_MODE_STORAGE=s3` and fill in the
`ZO_S3_*` values. **They are read only in that mode**; while it stays `disk`,
all six are ignored no matter what you put in `.env`.

### Postgres 18 on macOS

This service runs `postgres:18-alpine`. **Postgres 18 changed where the image
keeps its data**: the image's `VOLUME` moved from `/var/lib/postgresql/data` to
`/var/lib/postgresql`, and `PGDATA` is now `/var/lib/postgresql/18/docker`.
Mounting the pre-18 path against this image does not fail — Docker creates an
anonymous volume, writes the real database there, and leaves the bind mount
empty.

On macOS with Docker Desktop the documented mount does not start at all; it
exits with `data directory "/var/lib/postgresql/18/docker" has wrong ownership`,
because Postgres must create and own a subdirectory inside the bind mount.
`docker-compose.macos.yml` puts the database back on the pre-18 layout for local
development:

```bash
mkdir -p data/postgres
docker compose -f docker-compose.yml -f docker-compose.dev.yml \
  -f docker-compose.macos.yml up -d
```

Pre-creating `data/postgres` matters — if Docker Desktop creates it, ownership is
wrong and Postgres exits. The overlay uses `!override` (Compose v2.24 or newer)
because a plain `volumes:` key merges with the base file and would leave the
mount on `/var/lib/postgresql`.

Use this overlay on macOS only, and only for a fresh database. The two layouts
are not interchangeable, so switching an existing `data/postgres` between them
does not work.

## Environment Variables

Everything marked required is declared required in `docker-compose.yml`. If one
is missing or empty, `docker compose` stops before starting anything and names
the variable. Nothing in the table has a compose-level default; the `Default`
column is what the image falls back to. `.env.sample` pre-fills `POSTGRES_DB`
and `POSTGRES_USER` with `openobserve`, so in practice only the two passwords
and the admin email need filling in.

**`POSTGRES_PASSWORD` must be URL-safe.** It is interpolated into
`ZO_META_POSTGRES_DSN` as a connection URL, so a `/` or `@` truncates the
authority and the container dies at startup with
`postgres connect options create failed: Configuration(InvalidPort)` — an error
that names the port rather than the password. `openssl rand -base64` routinely
emits `/`; use `openssl rand -hex 32` instead.

| Variable                | Description                                        | Required     | Default |
| ----------------------- | -------------------------------------------------- | ------------ | ------- |
| `DOMAIN`                | Public hostname, used by the Traefik router        | Traefik only | -       |
| `ZO_ROOT_USER_EMAIL`    | Initial admin login, created on first start        | Yes          | -       |
| `ZO_ROOT_USER_PASSWORD` | Initial admin password                             | Yes          | -       |
| `POSTGRES_DB`           | Database name                                      | Yes          | -       |
| `POSTGRES_USER`         | Database user                                      | Yes          | -       |
| `POSTGRES_PASSWORD`     | Database password, must be URL-safe                | Yes          | -       |
| `ZO_LOCAL_MODE_STORAGE` | Ingested data location — `disk` or `s3`            | No           | `disk`  |
| `ZO_S3_PROVIDER`        | `s3`, `aws`, `gcs`, `gcp`, `oss`, `minio`, `swift` | S3 only      | `s3`    |
| `ZO_S3_SERVER_URL`      | Endpoint URL — leave empty for AWS S3              | S3 only      | -       |
| `ZO_S3_REGION_NAME`     | Bucket region                                      | S3 only      | -       |
| `ZO_S3_BUCKET_NAME`     | Bucket name                                        | S3 only      | -       |
| `ZO_S3_ACCESS_KEY`      | Access key                                         | S3 only      | -       |
| `ZO_S3_SECRET_KEY`      | Secret key                                         | S3 only      | -       |

Because `.env.sample` ships secrets blank, validating against it directly fails
by design:

```bash
cp .env.sample .env   # then fill it in
docker compose --env-file .env -f docker-compose.yml config -q
```

## Ports

| Port        | Description                                  |
| ----------- | -------------------------------------------- |
| `5080:5080` | HTTP API, ingestion and web UI (dev overlay) |

## Volumes

| Host Path         | Container Path        | Description                                           |
| ----------------- | --------------------- | ----------------------------------------------------- |
| `./data/app`      | `/data`               | WAL, caches, and ingested data when storage is `disk` |
| `./data/postgres` | `/var/lib/postgresql` | Metadata database (see Storage above)                 |

## Health Check

The container has no Docker healthcheck. The image is distroless — it ships no
shell, `curl`, `wget` or `nc` — so an in-container check cannot run and adding
one marks the container permanently unhealthy. Check it from the host instead:

```bash
curl http://localhost:5080/healthz   # {"status":"ok"}
```

## Ingestion

Ingest with HTTP basic auth using the root credentials:

```bash
curl -u "${ZO_ROOT_USER_EMAIL}:${ZO_ROOT_USER_PASSWORD}" \
  -X POST "http://localhost:5080/api/default/default/_json" \
  -H 'Content-Type: application/json' \
  -d '[{"level":"info","message":"hello"}]'
```

For long-lived collectors, create a dedicated user and token in the UI rather
than reusing the root credentials.

## Links

- [OpenObserve Website](https://openobserve.ai/)
- [Documentation](https://openobserve.ai/docs/)
- [Environment Variables Reference](https://openobserve.ai/docs/environment-variables/)
- [GitHub Repository](https://github.com/openobserve/openobserve)
