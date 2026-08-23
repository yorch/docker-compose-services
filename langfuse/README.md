# Langfuse

Open-source LLM observability platform for tracing, evaluating and debugging LLM applications.

## Features

- Tracing for LLM calls, chains, agents and retrieval steps
- Cost, latency and token analytics per model, user and session
- Prompt management with versioning and deployment labels
- Evaluations, including LLM-as-a-judge and human annotation
- Datasets and experiments for regression testing prompts
- Full-text search across inputs, outputs and metadata
- Monitors and alerts on trace metrics
- OpenTelemetry-based ingestion, with SDKs for Python and JS/TS

## Architecture

Six containers. `web` serves the UI and the ingestion API, `worker` drains the
ingestion queue into ClickHouse, and four datastores sit behind them:

| Container    | Holds                                            |
| ------------ | ------------------------------------------------ |
| `postgres`   | Accounts, projects, prompts, dataset definitions |
| `clickhouse` | Traces, observations and scores                  |
| `redis`      | The queue between `web` and `worker`             |
| `minio`      | Event payloads and uploaded media                |

**MinIO has to be reachable by the browser, not just by the other containers.**
Langfuse signs media URLs and hands them to the browser, so `web` is given a
public MinIO address (`MINIO_PUBLIC_URL`) while `worker` keeps the internal
`http://minio:9000`. Point `MINIO_PUBLIC_URL` at something the browser cannot
resolve and the app works except that uploaded images never load.

That is why the Traefik setup needs **two** hostnames.

## Quick Start

1. Copy the environment configuration and fill in the required values:

```bash
cp .env.sample .env

openssl rand -base64 32   # SALT
openssl rand -hex 32      # ENCRYPTION_KEY — must be exactly 64 hex characters
openssl rand -base64 32   # NEXTAUTH_SECRET
openssl rand -hex 16      # one each for POSTGRES_PASSWORD, CLICKHOUSE_PASSWORD,
                          # REDIS_AUTH and MINIO_ROOT_PASSWORD
```

Then set the two addresses, and make `DATABASE_URL` agree with
`POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` — nothing assembles it
for you:

| Variable           | Dev                     | Behind Traefik            |
| ------------------ | ----------------------- | ------------------------- |
| `NEXTAUTH_URL`     | `http://localhost:3000` | `https://${DOMAIN}`       |
| `MINIO_PUBLIC_URL` | `http://localhost:9090` | `https://${MINIO_DOMAIN}` |

2. Start the service:

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

In dev the UI is at `http://localhost:3000`. Behind Traefik it is at
`https://${DOMAIN}`, with MinIO's S3 API at `https://${MINIO_DOMAIN}`.

First start takes a while: ClickHouse migrations run before `web` is ready.

3. Sign up in the UI. To skip the sign-up screen entirely, fill in the
   `LANGFUSE_INIT_*` variables before the first start — they are only read
   against an empty database.

## Ports

| Port   | Container    | Description            | Exposure                                                      |
| ------ | ------------ | ---------------------- | ------------------------------------------------------------- |
| `3000` | `web`        | UI and ingestion API   | Published in dev, proxied by Traefik at `${DOMAIN}`           |
| `9000` | `minio`      | S3 API                 | Published on host `9090` in dev, proxied at `${MINIO_DOMAIN}` |
| `9001` | `minio`      | MinIO console          | Host `9091`, loopback only. Never proxied                     |
| `3030` | `worker`     | Worker health endpoint | Loopback only in dev                                          |
| `8123` | `clickhouse` | HTTP interface         | Loopback only in dev                                          |
| `9000` | `clickhouse` | Native protocol        | Loopback only in dev                                          |
| `5432` | `postgres`   | Postgres               | Loopback only in dev                                          |
| `6379` | `redis`      | Redis                  | Loopback only in dev                                          |

`DEV_BIND_IP` moves the loopback-only ports; the UI and the MinIO S3 API are
always published on all interfaces, because a browser has to reach them.

## Environment Variables

Required — every one is declared `:?`, so a blank value stops the stack with a
message naming the variable.

| Variable              | Description                                                 |
| --------------------- | ----------------------------------------------------------- |
| `NEXTAUTH_URL`        | Public origin of the UI, no trailing slash                  |
| `MINIO_PUBLIC_URL`    | Browser-reachable MinIO S3 address                          |
| `DATABASE_URL`        | Postgres connection string, must match the three vars below |
| `SALT`                | Hashes API keys — `openssl rand -base64 32`                 |
| `ENCRYPTION_KEY`      | Exactly 64 hex characters — `openssl rand -hex 32`          |
| `NEXTAUTH_SECRET`     | Signs session cookies — `openssl rand -base64 32`           |
| `POSTGRES_PASSWORD`   | Password for the Postgres user                              |
| `CLICKHOUSE_PASSWORD` | Password for the ClickHouse user                            |
| `REDIS_AUTH`          | Password for Redis                                          |
| `MINIO_ROOT_PASSWORD` | Password for MinIO, at least 8 characters                   |
| `DOMAIN`              | **Traefik only** — hostname serving the UI                  |
| `MINIO_DOMAIN`        | **Traefik only** — hostname serving the S3 API              |

`DOMAIN` and `MINIO_DOMAIN` are only read by `docker-compose.for-traefik.yml`,
so the dev setup does not need them. They are not optional there.

Optional.

| Variable                                     | Description                                        | Default                        |
| -------------------------------------------- | -------------------------------------------------- | ------------------------------ |
| `LANGFUSE_VERSION`                           | Langfuse image tag                                 | `4`                            |
| `DEV_BIND_IP`                                | Host interface for the dev overlay's sidecar ports | `127.0.0.1`                    |
| `POSTGRES_DB` / `POSTGRES_USER`              | Postgres database and user name                    | `langfuse`                     |
| `CLICKHOUSE_DB` / `CLICKHOUSE_USER`          | ClickHouse database and user name                  | `default` / `clickhouse`       |
| `MINIO_ROOT_USER` / `MINIO_BUCKET_NAME`      | MinIO user and bucket                              | `minio` / `langfuse`           |
| `CLICKHOUSE_URL`                             | ClickHouse HTTP endpoint                           | `http://clickhouse:8123`       |
| `CLICKHOUSE_MIGRATION_URL`                   | ClickHouse native endpoint, used for migrations    | `clickhouse://clickhouse:9000` |
| `CLICKHOUSE_CLUSTER_ENABLED`                 | Run ClickHouse DDL as cluster statements           | `false`                        |
| `REDIS_HOST` / `REDIS_PORT`                  | Redis address                                      | `redis` / `6379`               |
| `TELEMETRY_ENABLED`                          | Report anonymous usage to the project              | `true`                         |
| `LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES`      | Enable unreleased features                         | `false`                        |
| `EMAIL_FROM_ADDRESS` / `SMTP_CONNECTION_URL` | Both needed to send user invitations               | —                              |
| `LANGFUSE_INIT_*`                            | Bootstrap org, project, keys and first user        | —                              |

## Volumes

| Host Path                | Container Path               | Description              |
| ------------------------ | ---------------------------- | ------------------------ |
| `./data/postgres`        | `/var/lib/postgresql/data`   | Accounts and projects    |
| `./data/clickhouse/data` | `/var/lib/clickhouse`        | Traces and observations  |
| `./data/clickhouse/logs` | `/var/log/clickhouse-server` | ClickHouse server logs   |
| `./data/redis`           | `/data`                      | Ingestion queue          |
| `./data/minio`           | `/data`                      | Event payloads and media |

Redis is persisted deliberately. It is the queue between `web` and `worker`,
not a cache, and it runs with `--maxmemory-policy noeviction` so queued
ingestion jobs are not dropped under memory pressure.

## Upgrading

**Moving from Langfuse 3 to 4 is not just a retag.** Version 4 requires
ClickHouse 25.12 or newer, and upstream is explicit that **ClickHouse must be
upgraded before the application**. Langfuse 3 runs fine on current ClickHouse,
so the safe sequence against an existing deployment is:

1. Bump only the `clickhouse` image to `25.12` and start the stack, still on
   Langfuse 3. Let it come up healthy.
2. Then move `LANGFUSE_VERSION` to `4`. ClickHouse schema migrations run
   automatically on startup.

Check what wrote your existing data before you start —
`grep -o "Starting ClickHouse [0-9.]*" data/clickhouse/logs/clickhouse-server.log | tail -1`.
ClickHouse does not support downgrades, so never pin to a version older than
the one already on disk.

Langfuse 4 also drops support for Python SDK v2 and older, JS/TS SDK v3 and
older, the legacy batch ingestion endpoints, and trace-level LLM-as-a-judge
evaluators. Check your instrumentation before upgrading.

Postgres majors are not on-disk compatible either. Moving beyond 17 needs
`pg_upgrade` or a dump and restore, plus a matching change to the mount path —
Postgres 18 moved its `VOLUME` to `/var/lib/postgresql` and its `PGDATA` to
`/var/lib/postgresql/18/docker`.

Change both together or neither. Bumping only the image leaves the mount
pointing at a path Postgres 18 does not write to: it runs `initdb`, Langfuse
comes up against an empty database, and the old cluster sits untouched on disk
with nothing in any log to say so. That is also why the major is written into
the compose file rather than taken from a variable — a version knob that cannot
move the mount path with it is a way to lose a database quietly.

## Notes

MinIO uses Chainguard's image, which is what Langfuse upstream moved to. It
cannot be pinned: the free Chainguard tier publishes only `latest`. The
alternative, `minio/minio`, stopped publishing community images after
`RELEASE.2025-09-07` and no longer receives security updates.

## Integration

```python
from langfuse import get_client

langfuse = get_client(
    public_key="pk-lf-...",
    secret_key="sk-lf-...",
    host="https://langfuse.example.com",
)
```

## Links

- [Website](https://langfuse.com/)
- [Documentation](https://langfuse.com/docs)
- [Self-hosting guide](https://langfuse.com/self-hosting)
- [v3 to v4 upgrade guide](https://langfuse.com/self-hosting/upgrade/upgrade-guides/upgrade-v3-to-v4)
- [GitHub](https://github.com/langfuse/langfuse)
