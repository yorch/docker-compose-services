# Phoenix

Open-source LLM tracing, evaluation and prompt experimentation, with a built-in OpenTelemetry collector.

## Features

- OpenTelemetry trace collector for LLM and agent applications, over gRPC and HTTP
- Span waterfall UI for prompts, completions, tool calls, latency and token cost
- Datasets and experiments for comparing prompts, models and app versions
- Built-in LLM-as-a-judge evaluations for hallucination, relevance and toxicity
- Prompt playground for replaying and editing a captured span
- REST, GraphQL and MCP APIs
- Optional authentication with a local admin account
- PostgreSQL storage, sized for sustained trace ingest

## Services

| Service    | Description                                            |
| ---------- | ------------------------------------------------------ |
| `phoenix`  | UI, REST/GraphQL/MCP APIs and OTLP collectors          |
| `postgres` | Traces, spans, datasets, experiments and user accounts |

## Quick Start

Copy `.env.sample` to `.env` and set `POSTGRES_PASSWORD` first — the stack
refuses to start without it. Everything else has a working default.

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

On **macOS with Docker Desktop**, Postgres 18 will not start against a bind
mount — see [Storage](#storage) for the overlay that fixes local development.
Linux hosts need no change.

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

Access at `http://localhost:6006`.

## Sending Traces

Point any OpenTelemetry exporter at the collector. With the dev overlay:

```bash
export PHOENIX_COLLECTOR_ENDPOINT=http://localhost:6006
```

| Protocol       | Endpoint                          |
| -------------- | --------------------------------- |
| OTLP over HTTP | `http://localhost:6006/v1/traces` |
| OTLP over gRPC | `http://localhost:4317`           |

With authentication enabled, exporters must also send an API key created in the
UI, as `Authorization: Bearer <key>`.

The Traefik overlay proxies port 6006 only, which covers the UI, the APIs and
OTLP over HTTP. gRPC ingest on 4317 is not published there - send traces over
HTTP, or add a dedicated Traefik entrypoint for it.

## Environment Variables

| Variable                                 | Description                                                      | Default   |
| ---------------------------------------- | ---------------------------------------------------------------- | --------- |
| `DOMAIN`                                 | Public hostname, used by the Traefik router                      | -         |
| `POSTGRES_DB`                            | Database name. Configures both containers                        | `phoenix` |
| `POSTGRES_USER`                          | Database user. Configures both containers                        | `phoenix` |
| `POSTGRES_PASSWORD`                      | **Required.** Database password                                  | -         |
| `PHOENIX_ENABLE_AUTH`                    | Require a login for the UI, the APIs and trace ingest            | `false`   |
| `PHOENIX_SECRET`                         | Required when auth is enabled. Signs access and refresh tokens   | -         |
| `PHOENIX_DEFAULT_ADMIN_INITIAL_PASSWORD` | Password for `admin@localhost`, read on first start only         | `admin`   |
| `PHOENIX_USE_SECURE_COOKIES`             | Store auth tokens in HTTPS-only cookies instead of local storage | `false`   |
| `PHOENIX_CSRF_TRUSTED_ORIGINS`           | Comma-separated origins allowed to submit authenticated requests | -         |
| `PHOENIX_DEFAULT_RETENTION_POLICY_DAYS`  | Days to keep traces. `0` keeps them forever                      | `0`       |

Generate the auth secret with:

```bash
openssl rand -hex 32
```

`PHOENIX_SECRET`, `PHOENIX_DEFAULT_ADMIN_INITIAL_PASSWORD` and
`PHOENIX_CSRF_TRUSTED_ORIGINS` ship commented out in `.env.sample` and must stay
that way until you give them a real value. Phoenix reads an empty string as an
invalid value rather than as "unset", so an `PHOENIX_SECRET=` line with nothing
after it stops the container from starting - even with authentication off.

`PHOENIX_WORKING_DIR` is fixed at `/data` in the compose file to match the bind
mount. Unsetting it sends the file artifacts to `~/.phoenix` inside the
container, where the next recreate discards them.

## Ports

| Port        | Description                                    |
| ----------- | ---------------------------------------------- |
| `6006:6006` | Web UI, REST/GraphQL API, OTLP over HTTP (dev) |
| `4317:4317` | OTLP over gRPC collector (dev)                 |

## Volumes

| Host Path         | Container Path        | Description                            |
| ----------------- | --------------------- | -------------------------------------- |
| `./data/phoenix`  | `/data`               | Inferences, trace datasets, wasm cache |
| `./data/postgres` | `/var/lib/postgresql` | Database cluster                       |

## Storage

Traces, spans, datasets, experiments and user accounts live in Postgres.
`./data/phoenix` holds only the file-based artifacts — inferences, trace
datasets and the wasm cache.

Phoenix is wired to Postgres through `PHOENIX_POSTGRES_HOST`, `_PORT`, `_USER`,
`_PASSWORD` and `_DB` rather than a hand-written `PHOENIX_SQL_DATABASE_URL`,
because Phoenix percent-encodes the credentials when it assembles the connection
string itself. A literal `@` in a hand-written URL truncates the authority.

**Incomplete wiring is silent.** `get_env_postgres_connection_str()` returns
`None` when the host or user is missing, and Phoenix falls back to SQLite in the
working directory — healthy container, working UI, empty Postgres, and the loss
only surfaces when you restore a database backup. Verify by querying Postgres,
not by reading logs:

```bash
docker compose exec postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\dt'
```

A correctly wired instance has ~65 tables (`spans`, `traces`, `projects`,
`datasets`, `alembic_version`, …). A fallback instance has none, and
`./data/phoenix/phoenix.db` exists — its absence is the quick check.

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
mount on `/var/lib/postgresql`. The two layouts are not interchangeable, so do
not switch an existing data directory between them.

## Links

- [Phoenix Docs](https://arize.com/docs/phoenix)
- [Self-Hosting Guide](https://arize.com/docs/phoenix/self-hosting)
- [Configuration Reference](https://arize.com/docs/phoenix/self-hosting/configuration)
- [GitHub](https://github.com/Arize-ai/phoenix)
- [Docker Hub](https://hub.docker.com/r/arizephoenix/phoenix)
