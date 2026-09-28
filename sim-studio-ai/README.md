# Sim Studio AI

Open-source visual builder for AI agent workflows (Sim), with realtime collaboration, scheduled runs and a Postgres + pgvector backend.

## Features

- Visual, drag-and-drop workflow builder for AI agents
- Multi-model support (OpenAI, Anthropic, Google, Ollama, …)
- Realtime multi-user editing over Socket.IO
- Scheduled workflows and polling triggers via the `cron` service
- Knowledge bases on pgvector

## Quick Start

```bash
cp .env.sample .env  # then fill in POSTGRES_PASSWORD and the three secrets

# Dev - publishes ports on localhost (set NEXT_PUBLIC_APP_URL=http://localhost:3000)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

First start takes a few minutes: `migrations` must finish before `realtime` starts, and
each service waits for the previous one's (90s-interval) healthcheck.

Behind Traefik, one hostname serves both the app and the realtime socket: requests to
`/socket.io` go to `realtime:3002`, everything else to the app. The browser uses the
page's own origin, so no extra socket URL is needed.

## Services

| Service      | Description                                                       |
| ------------ | ----------------------------------------------------------------- |
| `simstudio`  | Next.js app (port 3000)                                           |
| `realtime`   | Socket.IO collaboration server (port 3002)                        |
| `migrations` | One-shot schema migration, runs before the app and realtime       |
| `cron`       | Background job scheduler; exits cleanly if `CRON_SECRET` is unset |
| `redis`      | Pub/sub for live status streaming and shared caches               |
| `db`         | PostgreSQL 17 with pgvector                                       |

## Environment Variables

| Variable                                    | Description                                                               | Required |
| ------------------------------------------- | ------------------------------------------------------------------------- | -------- |
| `DOMAIN`                                    | Hostname Traefik routes to the app (Traefik only)                         | Traefik  |
| `NEXT_PUBLIC_APP_URL`                       | Public URL of the app; also used as the auth URL                          | Yes      |
| `POSTGRES_PASSWORD`                         | Database password (`openssl rand -hex 24`)                                | Yes      |
| `BETTER_AUTH_SECRET`                        | Auth secret, shared by app and realtime (`openssl rand -hex 32`)          | Yes      |
| `ENCRYPTION_KEY`                            | Encrypts stored credentials; **cannot be changed later**                  | Yes      |
| `INTERNAL_API_SECRET`                       | Shared secret between app and realtime (`openssl rand -hex 32`)           | Yes      |
| `CRON_SECRET`                               | Enables scheduled workflows; without it `cron` exits                      | No       |
| `SIM_VERSION`                               | Image tag for simstudio, realtime, migrations and cron (default `v0.9.3`) | No       |
| `POSTGRES_USER`                             | Database user (default `postgres`)                                        | No       |
| `POSTGRES_DB`                               | Database name (default `simstudio`)                                       | No       |
| `RESEND_API_KEY`                            | Resend key for email; emails are logged to the console without it         | No       |
| `FREESTYLE_API_KEY`                         | Freestyle key for sandboxed code execution                                | No       |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth login                                                        | No       |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` | GitHub OAuth login                                                        | No       |
| `OLLAMA_URL`                                | Ollama endpoint for local models                                          | No       |
| `TZ`                                        | Timezone for the `cron` schedules (default `UTC`)                         | No       |
| `DEV_BIND_IP`                               | Host interface for the dev overlay's Postgres port (default `127.0.0.1`)  | No       |

## Upgrading

The app, realtime, migrations and cron images must run the same version. Bump
`SIM_VERSION` (or the default in `docker-compose.yml`) and restart the stack;
`migrations` updates the schema before the app and realtime come back up.

## Volumes

| Host Path         | Container Path             | Description   |
| ----------------- | -------------------------- | ------------- |
| `./data/postgres` | `/var/lib/postgresql/data` | Database data |

## Links

- [Sim Website](https://sim.ai/)
- [Documentation](https://docs.sim.ai/)
- [GitHub Repository](https://github.com/simstudioai/sim)
