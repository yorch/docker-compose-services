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

Access the web vault at `http://localhost:8080` (dev; set
`VAULTWARDEN_URL=http://localhost:8080`) or `https://${VAULTWARDEN_DOMAIN}` behind Traefik.

**Signups are closed by default.** Set `ADMIN_TOKEN`, open `/admin`, and invite users by
email. Without SMTP, an invited address can register directly. To allow open
registration temporarily, set `SIGNUPS_ALLOWED=true`.

## Environment Variables

| Variable              | Description                                                   | Default                         |
| --------------------- | ------------------------------------------------------------- | ------------------------------- |
| `VAULTWARDEN_DOMAIN`  | Public hostname (Traefik host)                                | required                        |
| `VAULTWARDEN_URL`     | Full public URL passed as `DOMAIN`                            | `https://${VAULTWARDEN_DOMAIN}` |
| `ADMIN_TOKEN`         | argon2 hash of the `/admin` password; empty disables `/admin` | empty                           |
| `SIGNUPS_ALLOWED`     | Open registration                                             | `false`                         |
| `INVITATIONS_ALLOWED` | Allow inviting users from `/admin` and organizations          | `true`                          |

### Email (Optional)

`SMTP_*` settings are read directly from `.env` (via `env_file`), because Vaultwarden
refuses to start when an SMTP variable is present but empty. Set `SMTP_HOST` and
`SMTP_FROM` together, plus `SMTP_PORT`, `SMTP_SECURITY` (`starttls`, `force_tls`, `off`),
`SMTP_USERNAME` and `SMTP_PASSWORD` as needed.

## Volumes

| Host Path | Container Path | Description    |
| --------- | -------------- | -------------- |
| `./data`  | `/data`        | All vault data |

## Admin Panel

Generate the `ADMIN_TOKEN` hash (prompts for the password):

```bash
docker run --rm -it vaultwarden/server:1.37.3 /vaultwarden hash
```

Put the resulting `$argon2id$…` string in `.env` **single-quoted**. It contains `$`,
which compose would otherwise interpolate. The admin panel is at `/admin`.

## Backups

Backup the entire `./data` directory:

```bash
# Stop the container
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml down

# Backup
tar -czf vaultwarden-backup.tar.gz ./data

# Restart
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
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
