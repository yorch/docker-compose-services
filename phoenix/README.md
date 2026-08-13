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
- SQLite storage out of the box, no external database required

## Quick Start

Copy `.env.sample` to `.env` first. Every value in it is optional for a local
run, so the defaults start a working instance with authentication disabled.

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

| Variable                                 | Description                                                      | Default |
| ---------------------------------------- | ---------------------------------------------------------------- | ------- |
| `DOMAIN`                                 | Public hostname, used by the Traefik router                      | -       |
| `PHOENIX_ENABLE_AUTH`                    | Require a login for the UI, the APIs and trace ingest            | `false` |
| `PHOENIX_SECRET`                         | Required when auth is enabled. Signs access and refresh tokens   | -       |
| `PHOENIX_DEFAULT_ADMIN_INITIAL_PASSWORD` | Password for `admin@localhost`, read on first start only         | `admin` |
| `PHOENIX_USE_SECURE_COOKIES`             | Store auth tokens in HTTPS-only cookies instead of local storage | `false` |
| `PHOENIX_CSRF_TRUSTED_ORIGINS`           | Comma-separated origins allowed to submit authenticated requests | -       |
| `PHOENIX_DEFAULT_RETENTION_POLICY_DAYS`  | Days to keep traces. `0` keeps them forever                      | `0`     |

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
mount. Changing it moves the database off the volume, where it is lost on the
next recreate.

## Ports

| Port        | Description                                    |
| ----------- | ---------------------------------------------- |
| `6006:6006` | Web UI, REST/GraphQL API, OTLP over HTTP (dev) |
| `4317:4317` | OTLP over gRPC collector (dev)                 |

## Volumes

| Host Path        | Container Path | Description                                    |
| ---------------- | -------------- | ---------------------------------------------- |
| `./data/phoenix` | `/data`        | SQLite database, inferences and trace datasets |

## Storage

Phoenix defaults to SQLite at `./data/phoenix/phoenix.db`, which is enough for a
single instance. For heavier ingest it can use PostgreSQL instead by setting
`PHOENIX_SQL_DATABASE_URL` - see the self-hosting docs below. Switching engines
does not migrate existing traces.

## Links

- [Phoenix Docs](https://arize.com/docs/phoenix)
- [Self-Hosting Guide](https://arize.com/docs/phoenix/self-hosting)
- [Configuration Reference](https://arize.com/docs/phoenix/self-hosting/configuration)
- [GitHub](https://github.com/Arize-ai/phoenix)
- [Docker Hub](https://hub.docker.com/r/arizephoenix/phoenix)
