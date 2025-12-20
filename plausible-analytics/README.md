# Plausible Analytics

Privacy-friendly, lightweight website analytics.

## Features

- No cookies required
- GDPR/CCPA compliant
- Lightweight script (<1KB)
- Real-time dashboard
- Goal and event tracking
- Email reports

## Quick Start

1. Generate required keys:

```bash
# Generate SECRET_KEY_BASE
openssl rand -base64 48

# Generate TOTP_VAULT_KEY
openssl rand -base64 32
```

2. Configure environment variables
3. Start the services:

```bash
docker compose up -d
```

## Services

| Service      | Description             |
| ------------ | ----------------------- |
| `app`        | Plausible application   |
| `postgres`   | PostgreSQL for metadata |
| `clickhouse` | ClickHouse for events   |

## Environment Variables

| Variable                  | Description            | Required |
| ------------------------- | ---------------------- | -------- |
| `BASE_URL`                | Public URL             | Yes      |
| `SECRET_KEY_BASE`         | Secret key (64+ chars) | Yes      |
| `TOTP_VAULT_KEY`          | 2FA encryption key     | Yes      |
| `DATABASE_URL`            | PostgreSQL URL         | Yes      |
| `CLICKHOUSE_DATABASE_URL` | ClickHouse URL         | Yes      |

### Email Configuration

| Variable         | Description        |
| ---------------- | ------------------ |
| `MAILER_EMAIL`   | From email address |
| `MAILER_ADAPTER` | Email adapter      |
| `SMTP_HOST_ADDR` | SMTP server        |
| `SMTP_HOST_PORT` | SMTP port          |
| `SMTP_USER_NAME` | SMTP username      |
| `SMTP_USER_PWD`  | SMTP password      |

### GeoIP (Optional)

| Variable              | Description         |
| --------------------- | ------------------- |
| `MAXMIND_LICENSE_KEY` | MaxMind license key |

## Volumes

| Host Path           | Container Path             | Description      |
| ------------------- | -------------------------- | ---------------- |
| `./data/app`        | `/var/lib/plausible`       | Application data |
| `./data/postgres`   | `/var/lib/postgresql/data` | PostgreSQL data  |
| `./data/clickhouse` | `/var/lib/clickhouse`      | ClickHouse data  |

## Website Integration

Add to your website:

```html
<script
  defer
  data-domain="yourdomain.com"
  src="https://plausible.yourdomain.com/js/script.js"
></script>
```

## Links

- [Plausible Website](https://plausible.io/)
- [Documentation](https://plausible.io/docs)
- [GitHub Repository](https://github.com/plausible/analytics)
