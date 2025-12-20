# WireGuard Portal

Enterprise-grade WireGuard VPN management portal.

## Features

- Multi-user management
- LDAP/OAuth authentication
- Multiple WireGuard interfaces
- Peer templates
- Email notifications
- REST API

## Quick Start

```bash
docker compose up -d
```

## Environment Variables

| Variable         | Description           | Required |
| ---------------- | --------------------- | -------- |
| `WG_CONFIG_PATH` | WireGuard config path | Yes      |
| `ADMIN_USER`     | Admin username        | Yes      |
| `ADMIN_PASSWORD` | Admin password        | Yes      |

### Database

| Variable            | Description                           | Default  |
| ------------------- | ------------------------------------- | -------- |
| `DATABASE_TYPE`     | Database type (sqlite/mysql/postgres) | `sqlite` |
| `DATABASE_HOST`     | Database host                         | -        |
| `DATABASE_PORT`     | Database port                         | -        |
| `DATABASE_NAME`     | Database name                         | -        |
| `DATABASE_USER`     | Database user                         | -        |
| `DATABASE_PASSWORD` | Database password                     | -        |

### Authentication

| Variable              | Description         |
| --------------------- | ------------------- |
| `OAUTH_PROVIDER`      | OAuth provider      |
| `OAUTH_CLIENT_ID`     | OAuth client ID     |
| `OAUTH_CLIENT_SECRET` | OAuth client secret |
| `LDAP_URL`            | LDAP server URL     |
| `LDAP_BASE_DN`        | LDAP base DN        |

## Ports

| Port    | Protocol | Description   |
| ------- | -------- | ------------- |
| `8888`  | TCP      | Web UI        |
| `51820` | UDP      | WireGuard VPN |

## Volumes

| Host Path       | Container Path   | Description       |
| --------------- | ---------------- | ----------------- |
| `./data/config` | `/etc/wireguard` | WireGuard configs |
| `./data/db`     | `/data`          | Database storage  |

## Capabilities

```yaml
cap_add:
  - NET_ADMIN
  - SYS_MODULE
```

## Features

### User Management

- Local, LDAP, and OAuth users
- User groups
- Role-based access

### Peer Templates

- Predefined peer configurations
- Consistent client settings
- Easy provisioning

## Links

- [WireGuard Website](https://www.wireguard.com/)
- [GitHub Repository](https://github.com/h44z/wg-portal)
