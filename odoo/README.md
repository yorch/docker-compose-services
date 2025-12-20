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
docker compose up -d
```

Access Odoo at `http://localhost:8069`

## Services

| Service      | Description         |
| ------------ | ------------------- |
| `app`        | Odoo application    |
| `db`         | PostgreSQL database |
| `adminer`    | Database admin UI   |
| `watchtower` | Auto-updates        |

## Environment Variables

### Odoo Configuration

| Variable   | Description       | Required |
| ---------- | ----------------- | -------- |
| `HOST`     | Database hostname | Yes      |
| `USER`     | Database user     | Yes      |
| `PASSWORD` | Database password | Yes      |

### PostgreSQL Configuration

| Variable            | Description       |
| ------------------- | ----------------- |
| `POSTGRES_DB`       | Database name     |
| `POSTGRES_USER`     | Database user     |
| `POSTGRES_PASSWORD` | Database password |

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
