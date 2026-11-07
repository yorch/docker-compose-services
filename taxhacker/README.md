# TaxHacker

Self-hosted AI accounting app that reads receipts, invoices and bank statements with your own LLM and files them into a ledger.

## Features

- Upload photos, PDFs or spreadsheets and let an LLM extract vendor, date, amount, tax and line items
- Bring your own model: OpenAI, Google Gemini, Mistral, or any OpenAI-compatible endpoint (Ollama, LM Studio, vLLM, LocalAI)
- Custom fields, categories and projects, each with its own extraction prompt
- Historical currency conversion for 170+ currencies and major cryptocurrencies
- Mailbox sync picks up invoice emails on a schedule
- Filter, export to CSV with attachments, and download a full data archive
- Everything stays on your server: PostgreSQL for the ledger, a bind mount for the documents

## Quick Start

Create `.env` first - the compose file refuses to start without the database
password and the auth secret, and the Traefik overlay also needs basic-auth
credentials:

```bash
../setup-env.sh taxhacker   # from the repo root: ./setup-env.sh taxhacker
```

It generates `POSTGRES_PASSWORD` and `BETTER_AUTH_SECRET` and reports the
optional values it cannot fill (the LLM API keys). `cp .env.sample .env` works
too if you would rather fill everything in by hand.

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

Open `http://localhost:7331` (dev) or `https://${DOMAIN}` (Traefik). The first
page is a short setup form: pick an LLM provider and paste its API key, and the
app seeds its default categories and currencies. Keys can be set in
`.env` instead (see below) or changed later in **Settings → AI**.

The Traefik overlay requires basic-auth credentials because self-hosted mode has
no login of its own:

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'your-password' | cut -d: -f2
```

Put the username in `BASIC_AUTH_USER` and the hash, single-quoted, in
`BASIC_AUTH_PASSWORD_HASH`. The stack refuses to start without both.

## Services

| Service    | Description                                   |
| ---------- | --------------------------------------------- |
| `app`      | TaxHacker web app and API (port 7331)         |
| `cron`     | Mailbox sync heartbeat, same image as the app |
| `postgres` | PostgreSQL 18 database                        |

Migrations run automatically when `app` starts (`prisma migrate deploy`), and
`cron` waits for `app` to be healthy so the two never migrate concurrently.

## Environment Variables

| Variable                   | Description                                            | Default                 | Required |
| -------------------------- | ------------------------------------------------------ | ----------------------- | -------- |
| `POSTGRES_PASSWORD`        | PostgreSQL password (URL-safe, no `@:/#?`)             | -                       | Yes      |
| `BETTER_AUTH_SECRET`       | Session and credential encryption key (16+ characters) | -                       | Yes      |
| `BASE_URL`                 | Public URL of the instance, no trailing slash          | `http://localhost:7331` | No       |
| `SELF_HOSTED_MODE`         | `true` skips the app's own login (basic auth instead)  | `true`                  | No       |
| `DISABLE_SIGNUP`           | Close new user registration                            | `true`                  | No       |
| `POSTGRES_DB`              | Database name                                          | `taxhacker`             | No       |
| `POSTGRES_USER`            | Database user                                          | `postgres`              | No       |
| `TAXHACKER_VERSION`        | Image tag                                              | `0.8.5`                 | No       |
| `DOMAIN`                   | Domain for Traefik routing                             | -                       | Traefik  |
| `BASIC_AUTH_USER`          | Basic-auth username for the Traefik overlay            | -                       | Traefik  |
| `BASIC_AUTH_PASSWORD_HASH` | bcrypt hash from `htpasswd -nbB`                       | -                       | Traefik  |
| `DEV_BIND_IP`              | Bind IP for the dev Postgres port                      | `127.0.0.1`             | No       |

### LLM providers

All optional, and all overridable in the app's settings.

| Variable             | Description           | Default                 |
| -------------------- | --------------------- | ----------------------- |
| `OPENAI_API_KEY`     | OpenAI API key        | -                       |
| `OPENAI_MODEL_NAME`  | OpenAI model          | `gpt-4o-mini`           |
| `GOOGLE_API_KEY`     | Google Gemini API key | -                       |
| `GOOGLE_MODEL_NAME`  | Gemini model          | `gemini-2.5-flash`      |
| `MISTRAL_API_KEY`    | Mistral API key       | -                       |
| `MISTRAL_MODEL_NAME` | Mistral model         | `mistral-medium-latest` |

## Volumes

| Host Path         | Container Path        | Description                  |
| ----------------- | --------------------- | ---------------------------- |
| `./data/app`      | `/app/data`           | Uploaded documents, previews |
| `./data/postgres` | `/var/lib/postgresql` | PostgreSQL 18 cluster        |

Back up `./data/app` together with a `pg_dump` of `postgres` - the ledger rows
and the files they point at only make sense as a pair. Keep the
`BETTER_AUTH_SECRET` from `.env` as well: it encrypts the mailbox passwords
stored in the database, and a restore without it leaves them unreadable.

## Notes

- `SELF_HOSTED_MODE=true` disables TaxHacker's built-in authentication. Keep the
  basic-auth middleware from `docker-compose.for-traefik.yml` in place, or set
  the flag to `false` and create the user by hand (upstream's
  `docs/self-hosted-public-access.md`) if the instance faces the internet.
- The dev overlay publishes port 7331 on every host interface, because the app
  is the product rather than a sidecar. With self-hosted mode on there is no
  login, so only run it on a network you trust - or on a machine whose firewall
  keeps 7331 private.
- The `cron` container reads its schedule from `etc/crontab`. Editing that file
  needs a `docker compose restart cron`, not just a save.

## Links

- [TaxHacker Website](https://taxhacker.app)
- [GitHub Repository](https://github.com/vas3k/TaxHacker)
- [Self-hosted deployment notes](https://github.com/vas3k/TaxHacker#-deployment-and-self-hosting)
