# Shlink

Self-hosted URL shortener.

## Features

- Short URL generation
- Custom slugs
- QR code generation
- Visit tracking and analytics
- API-driven
- Multiple domains support

## Quick Start

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

Dev: API on `http://localhost:8080`, web client on `http://localhost:8081`. Behind Traefik:
API on `https://${SHLINK_DOMAIN}`, web client on `https://web.${SHLINK_DOMAIN}`.

## Services

| Service | Description                               |
| ------- | ----------------------------------------- |
| `app`   | Shlink API server and short-URL redirects |
| `web`   | Shlink web client (static, no secrets)    |
| `db`    | PostgreSQL database                       |

## Environment Variables

| Variable                | Description                                                        | Required |
| ----------------------- | ------------------------------------------------------------------ | -------- |
| `SHLINK_DOMAIN`         | Short-URL domain; also the Traefik host (`web.` prefix for the UI) | Yes      |
| `INITIAL_API_KEY`       | Admin API key created on first start (`openssl rand -hex 32`)      | Yes      |
| `POSTGRES_PASSWORD`     | Database password (`openssl rand -hex 24`)                         | Yes      |
| `POSTGRES_DB`           | Database name (default `shlink`)                                   | No       |
| `POSTGRES_USER`         | Database user (default `shlink`)                                   | No       |
| `GEOLITE_LICENSE_KEY`   | MaxMind key for visit geolocation; empty disables it               | No       |
| `IS_HTTPS_ENABLED`      | Generate `https://` short URLs (default `true`)                    | No       |
| `ANONYMIZE_REMOTE_ADDR` | Anonymize visitor IPs (default `true`)                             | No       |

## Volumes

| Host Path         | Container Path             | Description   |
| ----------------- | -------------------------- | ------------- |
| `./data/postgres` | `/var/lib/postgresql/data` | Database data |

## API Usage

```bash
# Create short URL
curl -X POST https://your-domain/rest/v3/short-urls \
  -H "X-Api-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"longUrl": "https://example.com/very-long-url"}'
```

## Web Client

The web client is a static app that runs in your browser. It is **not** preconfigured with
a server: doing so would publish `SHLINK_SERVER_API_KEY` to every visitor in
`servers.json`. Open the web client, choose _Add a server_, and enter the API URL and
`INITIAL_API_KEY` once. The key is stored in that browser only.

## Links

- [Shlink Website](https://shlink.io/)
- [Documentation](https://shlink.io/documentation/)
- [GitHub Repository](https://github.com/shlinkio/shlink)
