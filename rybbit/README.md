# Rybbit

Open-source, privacy-friendly web and product analytics — a cookieless Google Analytics replacement with no consent banner required.

## Features

- Cookieless tracking, no consent banner needed, GDPR/CCPA compliant
- Real-time dashboard with sessions, pageviews, referrers and UTM breakdowns
- Funnels, user journeys, retention cohorts and goal tracking
- Custom events with properties, plus feature flags and error tracking
- Session replay
- Per-site organisations and multi-user teams
- Web vitals and performance reporting
- Three-level location tracking (country → region → city), with an optional 3D globe

## Architecture

Five containers. ClickHouse stores the event stream, Postgres holds accounts
and site configuration, Redis backs session tracking and bot-anomaly counters,
`backend` is the ingestion and query API on port 3001, and `client` is the
Next.js dashboard on port 3002. The dev overlay adds a sixth, Caddy, for the
reason below.

**The dashboard and the API have to answer on one hostname.** Rybbit publishes
its dashboard image with an empty `NEXT_PUBLIC_BACKEND_URL`, so the browser
bundle ships `baseURL: ""` and calls `/api` relative to whatever origin served
the page. Splitting the two containers across two ports does not work — the
dashboard would send every API call to itself.

Both setups here supply that single origin and route `/api` plus the OAuth
discovery documents to the backend, everything else to the dashboard.
`docker-compose.for-traefik.yml` does it with two Traefik routers on one `Host`
rule; `docker-compose.dev.yml` does it with a small Caddy container, the same
way upstream does.

## Quick Start

1. Copy the environment configuration and fill in the five required values:

```bash
cp .env.sample .env
openssl rand -hex 32   # BETTER_AUTH_SECRET
openssl rand -hex 16   # one each for the ClickHouse, Postgres and Redis passwords
```

`BASE_URL` is the fifth. Set it to `http://localhost:3002` for dev, or to
`https://<your-domain>` for the Traefik setup — in both cases the address you
open in a browser, not the backend's own port. The stack refuses to start with
any of these blank rather than coming up on a default password.

2. Start the service:

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

In dev everything is at `http://localhost:3002`. Behind Traefik everything is
at `https://${DOMAIN}`. Either way only that one port is published — the five
application containers stay on the compose network.

3. Open the dashboard and sign up. **The first account created on a fresh
   install becomes the owner.** Once it exists, set `DISABLE_SIGNUP=true` in
   `.env` and restart, or anyone who finds the URL can register.

## Ports

| Port   | Container    | Description       | Exposure                                        |
| ------ | ------------ | ----------------- | ----------------------------------------------- |
| `80`   | `caddy`      | Dev front door    | Published on host port `3002`, dev overlay only |
| `3001` | `backend`    | API and ingestion | Never published — reached at `/api`             |
| `3002` | `client`     | Next.js dashboard | Never published — reached at the root           |
| `8123` | `clickhouse` | ClickHouse HTTP   | Never published                                 |
| `5432` | `postgres`   | Postgres          | Never published                                 |
| `6379` | `redis`      | Redis             | Never published                                 |

## Environment Variables

Required — all five are declared `:?`, so a blank value stops the stack with a
message naming the variable.

| Variable              | Description                                         |
| --------------------- | --------------------------------------------------- |
| `BASE_URL`            | Public origin of the dashboard, no trailing slash   |
| `BETTER_AUTH_SECRET`  | Session cookie signing key — `openssl rand -hex 32` |
| `CLICKHOUSE_PASSWORD` | Password for the ClickHouse user                    |
| `POSTGRES_PASSWORD`   | Password for the Postgres user                      |
| `REDIS_PASSWORD`      | Password for Redis                                  |

Optional.

| Variable             | Description                                            | Default     |
| -------------------- | ------------------------------------------------------ | ----------- |
| `DOMAIN`             | Hostname Traefik serves Rybbit on (Traefik setup only) | —           |
| `IMAGE_TAG`          | Rybbit image tag to run                                | `latest`    |
| `CLICKHOUSE_DB`      | ClickHouse database name                               | `analytics` |
| `CLICKHOUSE_USER`    | ClickHouse user name                                   | `default`   |
| `POSTGRES_DB`        | Postgres database name                                 | `analytics` |
| `POSTGRES_USER`      | Postgres user name                                     | `rybbit`    |
| `DISABLE_SIGNUP`     | Close registration to new accounts                     | `false`     |
| `DISABLE_TELEMETRY`  | Stop reporting anonymous usage to the project          | `false`     |
| `CLUSTER_WORKERS`    | Backend worker processes, roughly one per core         | `4`         |
| `LITE_DASHBOARD`     | Reduce the dashboard to a single overview page         | `false`     |
| `MAPBOX_TOKEN`       | Mapbox token, needed only for the 3D globe view        | —           |
| `OPENROUTER_API_KEY` | Enables AI-generated report summaries                  | —           |
| `OPENROUTER_MODEL`   | Model used for those summaries                         | —           |

`BASE_URL` is the value most likely to be wrong. It is where the backend thinks
it lives — invite links, the OAuth discovery documents, and the list of origins
it will accept requests from. Set it to anything other than the address you
actually open in a browser and the dashboard loads, then has every call it makes
rejected as an untrusted cross-origin request.

## Volumes

| Host Path             | Container Path             | Description                   |
| --------------------- | -------------------------- | ----------------------------- |
| `./data/clickhouse`   | `/var/lib/clickhouse`      | Event data                    |
| `./data/postgres`     | `/var/lib/postgresql`      | Accounts and site config      |
| `./data/redis`        | `/data`                    | Session and counter state     |
| `./config/clickhouse` | `/etc/clickhouse-server/…` | ClickHouse tuning (read-only) |

## Configuration

`config/clickhouse/` holds four XML fragments, mounted read-only:

| File                  | Mounted into | Purpose                                                                  |
| --------------------- | ------------ | ------------------------------------------------------------------------ |
| `network.xml`         | `config.d`   | Listen on all interfaces so the backend can connect                      |
| `logging.xml`         | `config.d`   | Warning-level logs, and drop ClickHouse's own `system.*_log` tables      |
| `resource-limits.xml` | `config.d`   | Cap server, merge and thread usage so ClickHouse cannot exhaust the host |
| `user-settings.xml`   | `users.d`    | Query limits and async inserts                                           |

Profile settings only take effect from `users.d`; the same file under
`config.d` is read and ignored.

`Caddyfile.dev` is the dev overlay's routing config. It is not used by the
Traefik setup — the equivalent rules live as labels in
`docker-compose.for-traefik.yml`.

`user-settings.xml` caps a single query at 32 GB, which suits a large host.
Lower `max_memory_usage` if you are running on a small VPS.

## Notes

**Postgres runs 18, and its bind mount is at `/var/lib/postgresql` — not
`/var/lib/postgresql/data`.** Postgres 18 moved the image's `VOLUME` there and
put `PGDATA` at `/var/lib/postgresql/18/docker`. Mounting the pre-18 path
produces no error: Docker creates an anonymous volume, the database writes into
it, and `./data/postgres` stays empty until a `docker compose down -v` takes the
data with it.

Upstream pins `postgres:17.4`; this runs `postgres:18-alpine` instead, matching
the Alpine convention the rest of the repo uses. Nothing in Rybbit's schema
depends on the difference — the migrations declare no `CREATE EXTENSION` and the
only function they reach for is `gen_random_uuid()`, core since Postgres 13 —
and none of Postgres 18's documented incompatibilities (partition `VACUUM`
scope, `COPY FROM` CSV, `AFTER` trigger roles, rule privileges, full-text
collation providers) touch it. Data checksums are on by default in 18.

Two things follow from this that are worth knowing before you have data:

- **Majors are not on-disk compatible.** Moving to 19 later needs `pg_dumpall`
  and a restore, plus a matching change to the mount path if the image layout
  shifts again. Never just retag and restart.
- **Alpine collates text through musl, not glibc.** An existing
  `./data/postgres` cannot simply be pointed at a Debian-based image of the same
  major; that swap needs a `REINDEX` of text indexes, or a dump and restore.

Behind Traefik, visitor geolocation works with no extra configuration — the
backend runs Fastify with `trustProxy` and reads `X-Forwarded-For`, which
Traefik sets to the real client address.

## Links

- [Website](https://rybbit.com)
- [Documentation](https://rybbit.com/docs)
- [GitHub](https://github.com/rybbit-io/rybbit)
- [Docker images](https://github.com/orgs/rybbit-io/packages)
