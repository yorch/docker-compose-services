# Odoo

Open-source ERP and business applications suite.

## Features

- Complete ERP functionality
- Modular apps (CRM, Sales, Inventory, etc.)
- Customizable with add-ons
- Built-in reporting
- E-commerce integration

## Quick Start

```bash
# Dev - publishes ports on localhost
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

Access Odoo at `http://localhost:8069`.

The database manager (`/web/database/manager`: create, back up, restore, drop) is
protected by `ODOO_MASTER_PASSWORD`. Without it, Odoo shows a freshly generated master
password to whoever opens that page first. The stack writes it into Odoo's config via an
inline compose `configs:` entry (Docker Compose 2.23+), together with `proxy_mode` for
Traefik.

## Services

| Service       | Description                                                             |
| ------------- | ----------------------------------------------------------------------- |
| `app`         | Odoo application                                                        |
| `db`          | PostgreSQL database                                                     |
| `auto-update` | Watchtower, updating containers labelled with `WATCHTOWER_SCOPE`        |
| `adminer`     | Database admin UI, **dev overlay only**, opt-in via `--profile adminer` |

## Environment Variables

| Variable               | Description                                      | Required |
| ---------------------- | ------------------------------------------------ | -------- |
| `ODOO_MASTER_PASSWORD` | Database manager master password                 | Yes      |
| `POSTGRES_PASSWORD`    | Database password                                | Yes      |
| `POSTGRES_USER`        | Database user (default `odoo`)                   | No       |
| `DOMAIN`               | Hostname Traefik routes to Odoo                  | Traefik  |
| `WATCHTOWER_SCOPE`     | Watchtower scope for this stack (default `odoo`) | No       |
| `DEV_BIND_IP`          | Host interface for dev Postgres / Adminer        | No       |

## Volumes

| Host Path         | Container Path             | Description    |
| ----------------- | -------------------------- | -------------- |
| `./data/odoo`     | `/var/lib/odoo`            | Odoo data      |
| `./addons`        | `/mnt/extra-addons`        | Custom modules |
| `./data/postgres` | `/var/lib/postgresql/data` | Database data  |

## Custom Modules

Place custom Odoo modules in `./addons/`. They will be available in the Apps menu.

## First-Time Setup

1. Access the web interface
2. Create a new database
3. Set admin email and password
4. Select demo data (optional)
5. Install required apps

## Links

- [Odoo Website](https://www.odoo.com/)
- [Documentation](https://www.odoo.com/documentation/)
- [Odoo Apps Store](https://apps.odoo.com/)
- [GitHub Repository](https://github.com/odoo/odoo)
