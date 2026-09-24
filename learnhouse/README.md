# LearnHouse

Open-source learning platform for creating and running courses, with a collaborative editor, assignments, and certificates.

## Features

- Course builder with chapters, rich activities, video, documents and quizzes
- Real-time collaborative editing and boards (WebSocket collab server)
- Assignments, grading, progress tracking and certificates
- Optional AI course assistant (Google, OpenAI, Anthropic, Ollama, ...)
- Initial admin and organization created automatically on first start
- Postgres 18 (with pgvector) and Redis backends

## Quick Start

Copy `.env.sample` to `.env` and fill in the blank values: the three secrets,
`POSTGRES_PASSWORD`, and the initial admin email and password (and `DOMAIN` for
Traefik).

```bash
# Dev - publishes http://localhost:8080
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

The first start creates the database schema, the admin account and the
organization; it takes a minute or two before the healthcheck passes. Then sign
in at `http://localhost:8080/login` (dev) or `https://${DOMAIN}/login` (Traefik)
with `LEARNHOUSE_INITIAL_ADMIN_EMAIL` / `LEARNHOUSE_INITIAL_ADMIN_PASSWORD`.

Once it is healthy, record the schema version for Alembic. The app creates its
tables directly rather than through migrations, so a fresh database has no
Alembic baseline, and a later `alembic upgrade head` would try to recreate every
table and fail. Run this once per install (use the same `-f` flags as `up`):

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml \
  exec app sh -c "cd /app/api && uv run alembic stamp heads"
```

## How the overlays differ

LearnHouse bakes its public URL into links, auth cookies and the collab
WebSocket address, so those values are set per overlay rather than in the base
file:

- **Dev** uses `http://localhost:${DEV_PORT}` and `ws://`. It also runs an
  `ssr-fwd` sidecar: server-side rendering fetches the API through the same
  public URL as the browser, and inside the app container nothing listens on
  `${DEV_PORT}`, so the sidecar forwards that port to the container's nginx.
  Without it pages render with no organization data.
- **Traefik** uses `https://${DOMAIN}` and `wss://`. Server-side rendering
  fetches `https://${DOMAIN}` from inside the container, so the host must be
  able to reach its own public hostname (DNS resolving from inside Docker, and
  no NAT hairpin blocking).

Switching an existing install between the two means recreating the container
with the other overlay; the data carries over.

## Services

| Service   | Description                                                        |
| --------- | ------------------------------------------------------------------ |
| `app`     | LearnHouse web, API and collab server behind internal nginx (`80`) |
| `db`      | Postgres 18 with pgvector                                          |
| `redis`   | Redis 7 (cache, sessions, collab)                                  |
| `ssr-fwd` | Dev overlay only - forwards `${DEV_PORT}` to `80` inside `app`     |

## Environment Variables

| Variable                            | Description                                                  | Default                |
| ----------------------------------- | ------------------------------------------------------------ | ---------------------- |
| `DOMAIN`                            | Public hostname, used by the Traefik overlay                 | -                      |
| `DEV_PORT`                          | Host port for the dev overlay                                | `8080`                 |
| `LEARNHOUSE_AUTH_JWT_SECRET_KEY`    | Required. JWT signing key (32+ characters)                   | -                      |
| `NEXTAUTH_SECRET`                   | Required. Web auth secret                                    | -                      |
| `COLLAB_INTERNAL_KEY`               | Required. Shared key between the API and the collab server   | -                      |
| `LEARNHOUSE_INITIAL_ADMIN_EMAIL`    | Required. Admin account created on first start               | -                      |
| `LEARNHOUSE_INITIAL_ADMIN_PASSWORD` | Required. Password for that account                          | -                      |
| `LEARNHOUSE_INITIAL_ORG_NAME`       | Organization created on first start                          | `Default Organization` |
| `LEARNHOUSE_INITIAL_ORG_SLUG`       | Slug of that organization                                    | `default`              |
| `POSTGRES_DB`                       | Database name                                                | -                      |
| `POSTGRES_USER`                     | Database user                                                | -                      |
| `POSTGRES_PASSWORD`                 | Required. Database password, limited to `[A-Za-z0-9.~_-]`    | -                      |
| `LEARNHOUSE_IS_AI_ENABLED`          | Enable AI features                                           | `False`                |
| `LEARNHOUSE_AI_PROVIDER`            | AI provider (`google`, `openai`, `anthropic`, `ollama`, ...) | `google`               |
| `LEARNHOUSE_AI_API_KEY`             | API key for the AI provider                                  | -                      |
| `LEARNHOUSE_GEMINI_API_KEY`         | Google key, also the embeddings fallback                     | -                      |
| `LEARNHOUSE_EMAIL_PROVIDER`         | `resend` or `smtp`                                           | `resend`               |
| `LEARNHOUSE_SYSTEM_EMAIL_ADDRESS`   | Sender address for system email                              | -                      |
| `LEARNHOUSE_RESEND_API_KEY`         | Resend API key                                               | -                      |
| `LEARNHOUSE_SMTP_HOST`              | SMTP host                                                    | -                      |
| `LEARNHOUSE_SMTP_PORT`              | SMTP port                                                    | `587`                  |
| `LEARNHOUSE_SMTP_USERNAME`          | SMTP username                                                | -                      |
| `LEARNHOUSE_SMTP_PASSWORD`          | SMTP password                                                | -                      |
| `LEARNHOUSE_SMTP_USE_TLS`           | Use TLS for SMTP                                             | `True`                 |
| `NEXT_PUBLIC_UNSPLASH_ACCESS_KEY`   | Unsplash key for the in-editor image picker                  | -                      |

The initial admin and organization values are read on the first start only.
See the
[environment variable reference](https://docs.learnhouse.app/self-hosting/configuration/environment-variables)
for everything else (S3 storage, Google sign-in, Stripe, Judge0, ...); add any
of them to the `app` service's `environment`.

## Volumes

| Host Path         | Container Path        | Description                       |
| ----------------- | --------------------- | --------------------------------- |
| `./data/content`  | `/app/api/content`    | Uploaded course content and media |
| `./data/postgres` | `/var/lib/postgresql` | Postgres 18 data                  |
| `./data/redis`    | `/data`               | Redis append-only file            |

## Upgrading

The app image is pinned (`1.3.6`). Read the
[release notes](https://github.com/learnhouse/learnhouse/releases) first, and
back up `./data` before upgrading.

1. If you skipped the `alembic stamp heads` step after installing, run it now,
   on the **old** image, before changing the tag.
2. Bump the `app` image tag, then pull and recreate with the usual `up -d`
   command.
3. Apply the schema migrations - the app does **not** run them on start:

   ```bash
   docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml \
     exec app sh -c "cd /app/api && uv run alembic upgrade head"
   ```

## Links

- [LearnHouse Website](https://www.learnhouse.app)
- [Self-hosting Documentation](https://docs.learnhouse.app/self-hosting)
- [GitHub Repository](https://github.com/learnhouse/learnhouse)
