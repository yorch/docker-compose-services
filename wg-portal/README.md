# WireGuard Portal

Web portal for managing WireGuard interfaces, peers and users (wg-portal v2), with a companion WireGuard container.

## Features

- Multi-user management with LDAP/OAuth support
- Multiple WireGuard interfaces and peer templates
- Email notifications
- REST API

## Quick Start

```bash
cp .env.sample .env  # then set the admin password and the two web secrets

# Local - UI on http://localhost:8888 (loopback only), WireGuard on UDP 51820
docker compose up -d

# Behind Traefik - HTTPS for the UI
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

Sign in with `WG_PORTAL_ADMIN_USER` / `WG_PORTAL_ADMIN_PASSWORD`. Without them wg-portal
creates `admin@wgportal.local` / `wgportal-default`, so the password is required (and
must be at least 16 characters). The admin is only created if it doesn't exist yet: on an
existing install, change a default password from the UI.

The UI port is published on loopback by default (`UI_BIND_IP`); reach it remotely
through the Traefik overlay or an SSH tunnel. wg-portal runs in the `wireguard`
container's network namespace, so that container publishes the ports and carries the
Traefik labels.

## Environment Variables

| Variable                   | Description                                      | Default                 |
| -------------------------- | ------------------------------------------------ | ----------------------- |
| `WG_PORTAL_ADMIN_PASSWORD` | Admin password, 16+ characters (**required**)    | -                       |
| `WG_PORTAL_ADMIN_USER`     | Admin user (an email address)                    | `admin@wgportal.local`  |
| `WG_PORTAL_SESSION_SECRET` | Web session secret (**required**)                | -                       |
| `WG_PORTAL_CSRF_SECRET`    | CSRF secret (**required**)                       | -                       |
| `WG_PORTAL_URL`            | Public URL of the UI (links, OAuth redirects)    | `http://localhost:8888` |
| `DOMAIN`                   | Hostname Traefik routes to the UI (Traefik only) | -                       |
| `UI_BIND_IP`               | Host interface the UI port 8888 is published on  | `127.0.0.1`             |

Anything else (LDAP, OAuth, mail, database backend) goes in `./wg/config/config.yml`,
or the matching `WG_PORTAL_*` variables; see the
[configuration reference](https://wgportal.org/latest/documentation/configuration/overview/).

## Ports

| Port    | Protocol | Description                  |
| ------- | -------- | ---------------------------- |
| `51820` | UDP      | WireGuard VPN                |
| `8888`  | TCP      | Web UI (loopback by default) |

## Volumes

| Host Path     | Container Path                                   | Description                          |
| ------------- | ------------------------------------------------ | ------------------------------------ |
| `./wg/etc`    | `/etc/wireguard` (wg-portal), `/config/wg_confs` | WireGuard configs incl. private keys |
| `./wg/data`   | `/app/data`                                      | wg-portal database                   |
| `./wg/config` | `/app/config`                                    | Optional `config.yml`                |

`./wg/` is gitignored: it holds WireGuard private keys.

## Links

- [WireGuard Portal documentation](https://wgportal.org/)
- [GitHub Repository](https://github.com/h44z/wg-portal)
