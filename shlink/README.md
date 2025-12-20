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
docker compose up -d
```

## Services

| Service      | Description          |
| ------------ | -------------------- |
| `app`        | Shlink API server    |
| `web-client` | Shlink web interface |
| `postgres`   | PostgreSQL database  |

## Environment Variables

### Shlink Server

| Variable              | Description              | Required |
| --------------------- | ------------------------ | -------- |
| `DEFAULT_DOMAIN`      | Default short URL domain | Yes      |
| `IS_HTTPS_ENABLED`    | Enable HTTPS             | Yes      |
| `GEOLITE_LICENSE_KEY` | MaxMind GeoLite2 key     | -        |
| `INITIAL_API_KEY`     | Initial API key          | -        |

### Database

| Variable      | Description                      |
| ------------- | -------------------------------- |
| `DB_DRIVER`   | Database driver (postgres/mysql) |
| `DB_NAME`     | Database name                    |
| `DB_USER`     | Database user                    |
| `DB_PASSWORD` | Database password                |
| `DB_HOST`     | Database host                    |
| `DB_PORT`     | Database port                    |

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

Access the web interface to manage URLs visually. Configure it to point to your Shlink server.

## Links

- [Shlink Website](https://shlink.io/)
- [Documentation](https://shlink.io/documentation/)
- [GitHub Repository](https://github.com/shlinkio/shlink)
