# Linkwarden

Self-hosted bookmark manager with full-text search capabilities.

## Features

- Bookmark organization with collections
- Full-text search with Meilisearch
- Automatic screenshots and archives
- Browser extensions
- Collaboration features
- Import/export support

## Quick Start

```bash
cp .env.sample .env  # then set POSTGRES_PASSWORD, NEXTAUTH_SECRET and MEILI_MASTER_KEY

# Dev - app on http://localhost:3000
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Dev + Adminer (opt-in profile) on 127.0.0.1:8080
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile adminer up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

Behind Traefik set `NEXTAUTH_URL=https://${DOMAIN}/api/v1/auth`.

## Services

| Service       | Description                                                             |
| ------------- | ----------------------------------------------------------------------- |
| `app`         | Linkwarden application                                                  |
| `db`          | PostgreSQL database                                                     |
| `meilisearch` | Full-text search (production mode, key required)                        |
| `adminer`     | Database admin UI, **dev overlay only**, opt-in via `--profile adminer` |

## Environment Variables

| Variable                        | Description                                                      | Required |
| ------------------------------- | ---------------------------------------------------------------- | -------- |
| `POSTGRES_PASSWORD`             | Database password                                                | Yes      |
| `NEXTAUTH_SECRET`               | Session secret (`openssl rand -hex 32`)                          | Yes      |
| `MEILI_MASTER_KEY`              | Meilisearch key, shared by the app and Meilisearch               | Yes      |
| `NEXTAUTH_URL`                  | `<public URL>/api/v1/auth`                                       | Yes      |
| `MEILI_HOST`                    | Search endpoint (default: the bundled `http://meilisearch:7700`) | No       |
| `POSTGRES_USER` / `POSTGRES_DB` | Database user / name (default `linkwarden`)                      | No       |
| `DOMAIN`                        | Hostname Traefik routes to the app                               | Traefik  |
| `DEV_BIND_IP`                   | Host interface for dev Postgres / Meilisearch / Adminer          | No       |

All other options in `.env.sample` (OAuth providers, AI tagging, email, storage) are
passed to the app as-is through `env_file`.

## Volumes

| Host Path            | Container Path             | Description      |
| -------------------- | -------------------------- | ---------------- |
| `./data/app`         | `/data/data`               | Application data |
| `./data/postgres`    | `/var/lib/postgresql/data` | Database data    |
| `./data/meilisearch` | `/meili_data`              | Search index     |

## Browser Extensions

- [Chrome Extension](https://chrome.google.com/webstore/)
- [Firefox Add-on](https://addons.mozilla.org/firefox/)

## Links

- [Linkwarden Website](https://linkwarden.app/)
- [Documentation](https://docs.linkwarden.app/)
- [GitHub Repository](https://github.com/linkwarden/linkwarden)
