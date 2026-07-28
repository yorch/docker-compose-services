# Agentlogs

Self-hosted viewer for AI coding agent session logs, with OAuth login and AI-generated summaries.

## Features

- Browse and search AI agent session logs
- GitHub and GitLab OAuth authentication
- Optional waitlist for new sign-ups
- AI-generated summaries via OpenRouter or any OpenAI-compatible endpoint
- Transactional email through Resend

## Quick Start

Copy `.env.sample` to `.env` and fill it in first.

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

Access at `http://localhost:3000`.

## Environment Variables

| Variable               | Description                                             | Default              |
| ---------------------- | ------------------------------------------------------- | -------------------- |
| `DOMAIN`               | Public hostname, used by the Traefik router             | -                    |
| `BETTER_AUTH_SECRET`   | Required. Signs auth state and sessions                 | -                    |
| `WEB_URL`              | Public base URL, used for OAuth callbacks and redirects | -                    |
| `WAITLIST_ENABLED`     | New users default to the waitlist role                  | `true`               |
| `GITHUB_CLIENT_ID`     | Required if GitHub login is enabled                     | -                    |
| `GITHUB_CLIENT_SECRET` | Required if GitHub login is enabled                     | -                    |
| `GITLAB_CLIENT_ID`     | Required if GitLab login is enabled                     | -                    |
| `GITLAB_CLIENT_SECRET` | Required if GitLab login is enabled                     | -                    |
| `GITLAB_ISSUER`        | Self-managed GitLab URL when not using gitlab.com       | `https://gitlab.com` |
| `RESEND_API_KEY`       | Enables transactional email delivery                    | -                    |
| `EMAIL_SENDER`         | Overrides the default transactional sender              | -                    |
| `OPENROUTER_API_KEY`   | Enables AI summaries when no custom endpoint is set     | -                    |
| `AI_BASE_URL`          | Base URL of an OpenAI-compatible API                    | -                    |
| `AI_MODEL`             | Required with `AI_BASE_URL`. Model identifier           | -                    |
| `AI_API_KEY`           | Optional key for the compatible endpoint                | -                    |

Generate the auth secret with:

```bash
openssl rand -base64 32
```

## Ports

| Port        | Description  |
| ----------- | ------------ |
| `3000:3000` | Web UI (dev) |

## Volumes

| Host Path    | Container Path | Description                      |
| ------------ | -------------- | -------------------------------- |
| `./data/app` | `/app/.data`   | SQLite database and file storage |

## Links

- [Agentlogs Website](https://agentlogs.ai/)
- [Self-hosting Docs](https://agentlogs.ai/docs/server/hosting)
