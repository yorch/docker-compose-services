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

| Container    | Holds                                             |
| ------------ | ------------------------------------------------- |
| `postgres`   | Accounts, projects, prompts, dataset definitions  |
| `clickhouse` | Traces, observations and scores                   |
| `redis`      | The queue between `web` and `worker`              |
| `seaweedfs`  | Event payloads and uploaded media (S3-compatible) |

**Object storage has to be reachable by the browser, not just by the other
containers.** Langfuse signs media URLs and hands them to the browser, so `web`
is given a public S3 address (`S3_PUBLIC_URL`) while `worker` keeps the internal
`http://seaweedfs:8333`. Point `S3_PUBLIC_URL` at something the browser cannot
resolve and the app works except that uploaded images never load.

That is why the Traefik setup needs **two** hostnames.

## Quick Start

1. Generate the secrets:

```bash
./setup.sh --dev     # dev: also sets the two addresses to localhost
./setup.sh           # Traefik: secrets only, addresses are yours to set
```

This creates `.env` from `.env.sample`, fills every blank secret with a
generated value of the right shape, assembles `DATABASE_URL` to match the
Postgres password it just generated, and chmods the file to `600`. It never
prints a value, and it never overwrites one that is already set — so it is safe
to re-run, including against a live deployment.

To do it by hand instead:

```bash
cp .env.sample .env
openssl rand -base64 32   # SALT
openssl rand -hex 32      # ENCRYPTION_KEY — must be exactly 64 hex characters
openssl rand -base64 32   # NEXTAUTH_SECRET
openssl rand -hex 16      # one each for POSTGRES_PASSWORD, CLICKHOUSE_PASSWORD,
                          # REDIS_AUTH and S3_SECRET_KEY
```

Then make `DATABASE_URL` agree with `POSTGRES_USER` / `POSTGRES_PASSWORD` /
`POSTGRES_DB`; nothing assembles it for you. Use a hex password if you write it
by hand — base64 can contain `/` and `+`, which need percent-encoding inside a
connection string.

Either way, set the two addresses:

| Variable        | Dev                     | Behind Traefik         |
| --------------- | ----------------------- | ---------------------- |
| `NEXTAUTH_URL`  | `http://localhost:3000` | `https://${DOMAIN}`    |
| `S3_PUBLIC_URL` | `http://localhost:8333` | `https://${S3_DOMAIN}` |

The Traefik setup also needs `DOMAIN` and `S3_DOMAIN`. To check nothing was
missed without revealing anything, `grep -E '^[A-Z_]+=$' .env` should list only
optional variables.

2. Start the service:

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

In dev the UI is at `http://localhost:3000`. Behind Traefik it is at
`https://${DOMAIN}`, with the S3 API at `https://${S3_DOMAIN}`.

First start takes a while: ClickHouse migrations run before `web` is ready.

3. Sign up in the UI. To skip the sign-up screen entirely, fill in the
   `LANGFUSE_INIT_*` variables before the first start — they are only read
   against an empty database.

## Ports

| Port   | Container    | Description            | Exposure                                            |
| ------ | ------------ | ---------------------- | --------------------------------------------------- |
| `3000` | `web`        | UI and ingestion API   | Published in dev, proxied by Traefik at `${DOMAIN}` |
| `8333` | `seaweedfs`  | S3 API                 | Published in dev, proxied at `${S3_DOMAIN}`         |
| `9333` | `seaweedfs`  | Master UI              | Loopback only in dev. Never proxied                 |
| `3030` | `worker`     | Worker health endpoint | Loopback only in dev                                |
| `8123` | `clickhouse` | HTTP interface         | Loopback only in dev                                |
| `9000` | `clickhouse` | Native protocol        | Loopback only in dev                                |
| `5432` | `postgres`   | Postgres               | Loopback only in dev                                |
| `6379` | `redis`      | Redis                  | Loopback only in dev                                |

`DEV_BIND_IP` moves the loopback-only ports; the UI and the S3 API are
always published on all interfaces, because a browser has to reach them.

## Environment Variables

Required — every one is declared `:?`, so a blank value stops the stack with a
message naming the variable.

| Variable              | Description                                                 |
| --------------------- | ----------------------------------------------------------- | ---------------------- |
| `NEXTAUTH_URL`        | Public origin of the UI, no trailing slash                  |
| `S3_PUBLIC_URL`       | `http://localhost:8333`                                     | `https://${S3_DOMAIN}` |
| `DATABASE_URL`        | Postgres connection string, must match the three vars below |
| `SALT`                | Hashes API keys — `openssl rand -base64 32`                 |
| `ENCRYPTION_KEY`      | Exactly 64 hex characters — `openssl rand -hex 32`          |
| `NEXTAUTH_SECRET`     | Signs session cookies — `openssl rand -base64 32`           |
| `POSTGRES_PASSWORD`   | Password for the Postgres user                              |
| `CLICKHOUSE_PASSWORD` | Password for the ClickHouse user                            |
| `REDIS_AUTH`          | Password for Redis                                          |
| `S3_SECRET_KEY`       | Secret key for object storage                               |
| `DOMAIN`              | **Traefik only** — hostname serving the UI                  |
| `S3_DOMAIN`           | **Traefik only** — hostname serving the S3 API              |

`DOMAIN` and `S3_DOMAIN` are only read by `docker-compose.for-traefik.yml`,
so the dev setup does not need them. They are not optional there.

Optional.

| Variable                                     | Description                                        | Default                        |
| -------------------------------------------- | -------------------------------------------------- | ------------------------------ |
| `LANGFUSE_VERSION`                           | Langfuse image tag                                 | `4`                            |
| `DEV_BIND_IP`                                | Host interface for the dev overlay's sidecar ports | `127.0.0.1`                    |
| `POSTGRES_DB` / `POSTGRES_USER`              | Postgres database and user name                    | `langfuse`                     |
| `CLICKHOUSE_DB` / `CLICKHOUSE_USER`          | ClickHouse database and user name                  | `default` / `clickhouse`       |
| `S3_ACCESS_KEY` / `S3_BUCKET_NAME`           | Object storage identity and bucket                 | `langfuse` / `langfuse`        |
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
| `./data/seaweedfs`       | `/data`                      | Event payloads and media |

Redis is persisted deliberately. It is the queue between `web` and `worker`,
not a cache, and it runs with `--maxmemory-policy noeviction` so queued
ingestion jobs are not dropped under memory pressure.

## Upgrading

**Moving from Langfuse 3 to 4 is not just a retag.** Upstream splits it into
three phases, each of which leaves the deployment in a stable state, so they can
be days apart.

**1. Infrastructure.** Version 4 requires ClickHouse 25.12 or newer (Postgres
15+, Redis 7.0+). Langfuse 3 runs fine on current ClickHouse, so bump only the
`clickhouse` image and start the stack still on Langfuse 3. Let it come up
healthy before going further — upstream is explicit that ClickHouse is upgraded
**before** the application.

**2. Server.** Move `LANGFUSE_VERSION` to `4`. ClickHouse schema migrations run
automatically on startup. What happens to writes depends on
`LANGFUSE_MIGRATION_V4_WRITE_MODE`:

| Mode          | Writes                                 | Use when                                             |
| ------------- | -------------------------------------- | ---------------------------------------------------- |
| `legacy`      | v3 tables only                         | De-risking the server upgrade — nothing else changes |
| `dual`        | both old and new tables                | Transitioning, while older SDKs catch up             |
| `events_only` | new `events` tables only (**default**) | Every producer already sends a compatible SDK        |

If all your instrumentation is on Python SDK ≥ 4.7.0 / JS-TS SDK ≥ 5.4.0, the
default is fine and the migration is done. If not, set `legacy` first, because
`events_only` **rejects older SDKs at ingestion**.

**3. Data model.** Only needed if you started at `legacy`. Upgrade the SDKs and
any API consumers, switch to `dual` so new data lands in both places, confirm it
is healthy, and only then deal with history — either
`LANGFUSE_BACKGROUND_MIGRATION_V4_ENABLE_HISTORIC_BACKFILL=true` (rewrites
everything, wants roughly 3x disk headroom) or simply dual-writing for one full
retention window and letting the old data age out. Finally drop the write-mode
override to land on `events_only`.

Order matters in phase 3: the backfill runs **once**, so enabling it before the
dual write is active and healthy leaves anything ingested in between permanently
missing from the new tables.

These `LANGFUSE_MIGRATION_V4_*` variables are transitional and upstream intends
to remove them in a later major, so they are not in `.env.sample`. Add them to
`.env` for the duration of a migration — every variable in `.env` reaches both
containers.

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

**Object storage is SeaweedFS, not MinIO.** MinIO stopped publishing community
container images in late 2025 and archived its repository in February 2026, so
the project is no longer maintained. Langfuse's own Helm chart replaced MinIO
with SeaweedFS in chart 2.0.0, and their values file documents path-style
addressing as "Required for SeaweedFS / MinIO" — the `LANGFUSE_S3_*` contract is
identical, so only the container changed.

Two details follow from SeaweedFS rather than MinIO:

- The bucket is created by a one-shot `seaweedfs-bucket` service. SeaweedFS
  does not create buckets on first write and Langfuse never calls
  `CreateBucket`, so it has to exist before either app container starts — the
  Helm chart uses a post-install hook for the same reason. `web` and `worker`
  wait on it with `service_completed_successfully`, and creating an existing
  bucket is harmless, so it is safe to re-run on every `up`.
- Credentials live in an inline Compose `config` rather than a file under
  `config/`, because Compose interpolates `${...}` in config content but not in
  a bind-mounted file. That keeps the secret in `.env` instead of in git.

The image is pinned to `4.44` rather than the `3.95` named in Langfuse's chart.
That pin dates from July 2025, and replacing an unmaintained object store with a
year-old image would give up most of the point; the S3 surface Langfuse uses —
path-style addressing and presigned URLs — is stable across 3.x and 4.x.

## Integration

`get_client()` is a singleton keyed on the public key and reads its
configuration from the environment, so credentials go in the environment rather
than in the call:

```bash
export LANGFUSE_PUBLIC_KEY="pk-lf-..."
export LANGFUSE_SECRET_KEY="sk-lf-..."
export LANGFUSE_HOST="https://langfuse.example.com"
```

```python
from langfuse import get_client

langfuse = get_client()
```

To configure it in code instead, use the constructor:

```python
from langfuse import Langfuse

langfuse = Langfuse(
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
