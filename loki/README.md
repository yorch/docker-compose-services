# Loki

Log aggregation system that indexes labels rather than log content, queried with LogQL.

## Features

- Indexes only a small set of labels per stream, so storage stays close to the compressed size of the raw logs
- LogQL — a query language shaped like PromQL, including metric queries over log streams
- Single-binary deployment with filesystem storage: no object store, no database, no cache
- Built-in compactor with retention, so old logs are deleted on a schedule instead of growing forever
- Grafana's native log source, and the backend for Grafana Logs Drilldown
- Optional Grafana Alloy overlay that tails every Docker container on the host into Loki
- Multi-tenancy available, though this stack runs single-tenant

## Quick Start

Run the setup script first. It creates `.env`, prepares `./data/loki` so Loki can
write to it, and offers to generate a basic auth credential. It is idempotent, so
re-running it is always safe:

```bash
./setup.sh
```

Then start whichever setup you want:

```bash
# Dev - publishes the HTTP API on localhost:3100
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Dev, plus Alloy shipping this host's container logs into it
./run-with-alloy.sh

# Behind Traefik - HTTPS and basic auth through the reverse proxy
./run-for-traefik.sh   # fill in DOMAIN, USERNAME, HASHED_PASSWORD in .env first

# Behind Traefik, plus Alloy
./run-for-traefik-with-alloy.sh
```

On macOS the setup script is optional - the dev overlay runs from a bare
`docker compose up -d`. On Linux it is not; see below.

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

Loki takes roughly 30 seconds to report ready on first start — the ingester
deliberately waits 15s after joining the ring before accepting writes:

```bash
curl http://localhost:3100/ready
```

### Linux file ownership

The image runs as UID `10001`, and Docker creates a missing bind-mount directory
owned by `root`. On Linux that combination stops Loki dead on first start:

```
mkdir /loki/rules: permission denied
error initialising module: ruler-storage
```

With `restart: unless-stopped` the container then crash-loops, and the error
names the ruler - a subsystem this stack never uses - rather than the ownership
problem, because `ruler.storage.local.directory` is simply the first path Loki
tries to create.

`./setup.sh` handles this. It probes whether UID `10001` can actually write to
`./data/loki` and only corrects ownership when it cannot, using a root container
rather than `sudo` - a regular user cannot give a file away to another UID, but
the Docker daemon is already root. The equivalent by hand:

```bash
mkdir -p data/loki && sudo chown -R 10001:10001 data/loki
```

Docker Desktop on macOS remaps bind mount ownership through its virtiofs layer,
so writes from UID `10001` succeed regardless and the script reports nothing to
do. That also means this failure cannot be reproduced on macOS - it needs a real
Linux host, or a path Docker Desktop does not share.

## Sending logs to Loki

Loki does not collect logs — something has to push them to
`/loki/api/v1/push`. Three options, in rough order of how much they fit this repo:

| Option                                         | Notes                                                                                                                                           |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Grafana Alloy** (`docker-compose.alloy.yml`) | Shipped here. Discovers every container on the Docker socket and tails it. See below.                                                           |
| **Loki Docker driver plugin**                  | A host-level log driver installed with `docker plugin install grafana/loki-docker-driver:latest`, then set per container as a `logging:` block. |
| **OpenTelemetry Collector**                    | Loki 3.x accepts OTLP directly at `/otlp/v1/logs`, so a collector already in your pipeline can forward logs without an intermediate exporter.   |

Promtail is not an option any more — its LTS ended in February 2026 and it is
no longer maintained. Alloy is its replacement, and their configuration formats
are not compatible.

### The Alloy overlay

`docker-compose.alloy.yml` adds a `grafana/alloy` container configured by
`alloy-config.alloy`. It discovers containers over the Docker socket and attaches
these labels:

| Label             | Value                                              |
| ----------------- | -------------------------------------------------- |
| `job`             | Always `docker`                                    |
| `container`       | Container name, with Docker's leading `/` stripped |
| `compose_project` | From the `com.docker.compose.project` label        |
| `compose_service` | From the `com.docker.compose.service` label        |

Because every stack in this repo is its own compose project, that makes
`{compose_project="grafana"}` a useful query out of the box.

Two things to know before enabling it:

- **It mounts `/var/run/docker.sock`.** Read-only, which is enough to list
  containers and stream logs, but socket access still exposes every container's
  environment and output. That is why the overlay is opt-in.
- **Alloy replays existing log files when it first attaches**, and Loki rejects
  anything older than `reject_old_samples_max_age` (168h) with a 400. On a host
  with long-running containers the first minute of Alloy's logs is a wall of
  `has timestamp too old` errors. This is expected and self-correcting — fresh
  lines are accepted normally.

Alloy's debug UI — which shows every component's health and the live target list
— is bound to `127.0.0.1:12345` inside the container by the image's default
command, so it is unreachable from the host. Opening it takes both a published
port and a rebind, which is a throwaway override rather than a committed file:

```bash
cat > alloy-ui.yml <<'EOF'
services:
  alloy:
    ports:
      - 12345:12345
    command:
      - run
      - --server.http.listen-addr=0.0.0.0:12345
      - --storage.path=/var/lib/alloy/data
      - /etc/alloy/config.alloy
EOF

docker compose -f docker-compose.yml -f docker-compose.alloy.yml -f alloy-ui.yml up -d
# http://localhost:12345
```

## Connecting Grafana

The `grafana/` stack in this repo is a separate compose project with its own
network, so it cannot resolve `http://loki:3100` by default.

- **Dev:** point the Grafana data source at `http://host.docker.internal:3100`.
- **Behind Traefik:** use `https://${DOMAIN}` with basic auth enabled on the data
  source, or attach both stacks to the external `traefik` network and use
  `http://loki:3100` directly, which skips TLS and auth for internal traffic.

Loki needs no API key — with `auth_enabled: false` it serves a single implicit
tenant named `fake`, and the `X-Scope-OrgID` header is ignored.

## Configuration

Loki is configured by `loki-config.yaml`, not by environment variables. The file
is committed and mounted read-only; edit it directly for anything not exposed
below.

The container runs with `-config.expand-env=true`, so `${VAR}` placeholders
inside that file are expanded by Loki from the environment. Only the variables
listed in the table below use it, and each carries its own default in the config,
so an empty `.env` still starts a working instance.

## Environment Variables

| Variable                | Default    | Description                                                                   |
| ----------------------- | ---------- | ----------------------------------------------------------------------------- |
| `DOMAIN`                | _required_ | Public hostname for the Traefik overlay                                       |
| `USERNAME`              | _required_ | Basic auth user for the Traefik overlay                                       |
| `HASHED_PASSWORD`       | _required_ | Basic auth hash with every `$` doubled. `./setup.sh` generates it correctly.  |
| `LOKI_RETENTION_PERIOD` | `744h`     | How long logs are kept before the compactor deletes them. Go duration string. |
| `LOKI_LOG_LEVEL`        | `info`     | `debug`, `info`, `warn` or `error`                                            |

The three required values are only read by `docker-compose.for-traefik.yml`. The
dev overlay needs no `.env` at all.

## Security

Loki has **no authentication of its own**. `auth_enabled: false` selects
single-tenant mode; it does not mean unauthenticated requests are rejected.
Anything that can reach port 3100 can read every log line, push forged ones, and
submit delete requests. The Traefik overlay therefore applies a basic auth
middleware by default, and the dev overlay should stay bound to a trusted network.

## Volumes

| Host Path              | Container Path            | Description                                                  |
| ---------------------- | ------------------------- | ------------------------------------------------------------ |
| `./loki-config.yaml`   | `/etc/loki/config.yaml`   | Loki configuration, mounted read-only                        |
| `./data/loki`          | `/loki`                   | Chunks, TSDB index and cache, WAL, compactor and ruler state |
| `./alloy-config.alloy` | `/etc/alloy/config.alloy` | Alloy pipeline, mounted read-only (Alloy overlay)            |
| `./data/alloy`         | `/var/lib/alloy/data`     | Alloy read positions (Alloy overlay)                         |

## Retention

Deletion is driven by the compactor, which runs inside the same process. It is
enabled in `loki-config.yaml` — Loki's stock configuration ships with retention
**off**, meaning nothing is ever deleted.

Logs are removed `retention_delete_delay` (2h) after they age past
`LOKI_RETENTION_PERIOD`, and the compactor evaluates this every
`compaction_interval` (10m). Shortening the retention period does not free space
immediately; the next compaction cycle picks it up.

## Health Check

The compose file declares no `healthcheck`. The image is distroless and contains
exactly one file under its binary paths, `/usr/bin/loki` — there is no shell,
`curl`, `wget` or `nc` to probe with, and the binary itself has no HTTP client
mode. Any healthcheck would mark the container permanently unhealthy. Probe it
from outside instead:

```bash
curl http://localhost:3100/ready     # ingester ready to accept writes
curl http://localhost:3100/metrics   # Prometheus metrics
```

## Troubleshooting

**Every push returns 500 `Ingester is shutting down`, but the container is up
and `/ready` says `ready`.** The disk holding `./data/loki/wal` is more than 90%
full. Loki's WAL guard (`ingester.wal.disk_full_threshold`) turns the ingester
read-only at that point, and nothing in the error mentions disk space. Free space,
or raise the threshold in `loki-config.yaml`. Confirm with:

```bash
docker compose logs loki | grep "disk usage exceeded threshold"
df -h .
```

**Alloy logs a wall of `has timestamp too old` 400s on startup.** Expected on
first attach — see the Alloy overlay section above.

**`failed parsing config` mentioning a `${...}` string.** The container was
started without `-config.expand-env=true`. That flag is part of `command:` in
`docker-compose.yml`; overriding `command` anywhere drops it.

**Basic auth rejects the correct password.** The bcrypt hash in `.env` lost part
of itself to compose's interpolation. Every `$` in `HASHED_PASSWORD` must be
written as `$$`; otherwise `$2y$05$Nx7...` is read as a reference to a variable
named `Nx7...`, which expands to nothing. Check what actually reached Traefik:

```bash
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml config | grep basicauth
```

The output escapes literal dollars back to `$$`, so a correct hash shows three
`$$` and a full digest. A truncated value ending right after `$$05` is the bug.

**Queries return nothing but pushes succeed.** Check the time range. Loki
defaults query ranges to the last hour, and log lines are stamped with the
timestamp the sender supplied, not the time they arrived.

## Links

- [Loki Website](https://grafana.com/oss/loki/)
- [Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Reference](https://grafana.com/docs/loki/latest/query/)
- [Configuration Reference](https://grafana.com/docs/loki/latest/configure/)
- [Grafana Alloy Documentation](https://grafana.com/docs/alloy/latest/)
- [GitHub Repository](https://github.com/grafana/loki)
