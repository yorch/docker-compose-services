# Vaultwarden

Lightweight Bitwarden-compatible password manager server.

## Features

- Full Bitwarden API compatibility
- Organizations and sharing
- Web vault interface
- 2FA support (TOTP, WebAuthn)
- Emergency access
- Admin panel

## Quick Start

```bash
docker compose up -d
```

Access the web vault at `http://localhost:8080`

## Environment Variables

| Variable      | Description                   | Required |
| ------------- | ----------------------------- | -------- |
| `ADMIN_TOKEN` | Admin panel password (hashed) | Yes      |
| `DOMAIN`      | Public domain URL             | Yes      |

### Security Settings

| Variable              | Description             | Default |
| --------------------- | ----------------------- | ------- |
| `SIGNUPS_ALLOWED`     | Allow new registrations | `true`  |
| `INVITATIONS_ALLOWED` | Allow invitations       | `true`  |
| `SHOW_PASSWORD_HINT`  | Show password hints     | `false` |

### Email (Optional)

| Variable        | Description              |
| --------------- | ------------------------ |
| `SMTP_HOST`     | SMTP server              |
| `SMTP_PORT`     | SMTP port                |
| `SMTP_FROM`     | From address             |
| `SMTP_USERNAME` | SMTP username            |
| `SMTP_PASSWORD` | SMTP password            |
| `SMTP_SECURITY` | starttls, force_tls, off |

## Volumes

| Host Path | Container Path | Description    |
| --------- | -------------- | -------------- |
| `./data`  | `/data`        | All vault data |

## Admin Panel

Generate an admin token:

```bash
# Using argon2 (recommended)
echo -n "YourAdminPassword" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4

# Or use a plain token (less secure)
openssl rand -base64 48
```

Access admin panel at `/admin`.

## Backups

Backup the entire `./data` directory:

```bash
# Stop the container
docker compose down

# Backup
tar -czf vaultwarden-backup.tar.gz ./data

# Restart
docker compose up -d
```

## Bitwarden Clients

Works with all official Bitwarden clients:

- Browser extensions
- Desktop apps
- Mobile apps
- CLI tool

Configure clients to use your self-hosted URL.

## Links

- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [GitHub Repository](https://github.com/dani-garcia/vaultwarden)
- [Bitwarden Clients](https://bitwarden.com/download/)
