# OpenSEO

Open-source pay-as-you-go SEO tool and alternative to Semrush and Ahrefs, powered by the DataForSEO API.

> **Warning:** Auth is disabled (`AUTH_MODE=local_noauth`) in Docker mode. Only
> expose OpenSEO behind an auth-protected reverse proxy, tunnel, or private
> network. The dev overlay binds to localhost by default.

## Features

- Keyword research and rank tracking via DataForSEO
- SAM, an in-app AI SEO agent (optional, via OpenRouter)
- Google Search Console integration (optional)
- Single-container self-hosting with embedded D1 SQLite state (no separate database container)
- Telemetry disabled by default for privacy

## Quick Start

Copy `.env.sample` to `.env` and fill in your DataForSEO API key first.

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

Access at `http://localhost:3001` (dev) or `https://${DOMAIN}` (Traefik).

The container builds the app on first start and may take 1-2 minutes before the
web UI is reachable.

## Services

| Service    | Description     |
| ---------- | --------------- |
| `open-seo` | OpenSEO web app |

## Environment Variables

| Variable                     | Description                                                                 | Default     |
| ---------------------------- | --------------------------------------------------------------------------- | ----------- |
| `DATAFORSEO_API_KEY`         | Required. Base64-encoded DataForSEO API credential                          | -           |
| `DOMAIN`                     | Public hostname, used by the Traefik router                                 | -           |
| `PORT`                       | Port the container listens on                                               | `3001`      |
| `ALLOWED_HOST`               | Hostname when behind a reverse proxy (Traefik sets this to `${DOMAIN}`)     | -           |
| `OPENSEO_TELEMETRY_DISABLED` | Disables telemetry when set                                                 | `1`         |
| `DO_NOT_TRACK`               | Standard do-not-track signal                                                | `1`         |
| `OPENROUTER_API_KEY`         | Enables AI features (SAM) via OpenRouter                                    | -           |
| `OPENROUTER_MODEL`           | Model identifier for OpenRouter                                             | -           |
| `GOOGLE_CLIENT_ID`           | Google Search Console OAuth client ID                                       | -           |
| `GOOGLE_CLIENT_SECRET`       | Google Search Console OAuth client secret                                   | -           |
| `BETTER_AUTH_SECRET`         | Signs auth sessions. Required for GSC. Generate with `openssl rand -hex 32` | -           |
| `DEV_BIND_IP`                | Bind IP for dev port (localhost only recommended)                           | `127.0.0.1` |

## Volumes

| Host Path         | Container Path   | Description                                             |
| ----------------- | ---------------- | ------------------------------------------------------- |
| `./data/open-seo` | `/app/.wrangler` | Wrangler/Cloudflare Workers local state (D1 SQLite, KV) |

## Links

- [OpenSEO Website](https://openseo.so)
- [GitHub Repository](https://github.com/every-app/open-seo)
- [DataForSEO](https://dataforseo.com/)
