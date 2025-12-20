# Grafana

Open-source analytics and monitoring dashboard platform.

## Features

- Beautiful dashboards and visualizations
- Support for 50+ data sources
- Alerting and notifications
- Plugin ecosystem
- Team collaboration

## Quick Start

```bash
docker compose up -d
```

Access Grafana at `http://localhost:3000`

Default credentials: `admin` / `admin`

## Environment Variables

| Variable                     | Description             | Default |
| ---------------------------- | ----------------------- | ------- |
| `GF_SERVER_DOMAIN`           | Server domain           | -       |
| `GF_SERVER_ROOT_URL`         | Full public URL         | -       |
| `GF_SECURITY_ADMIN_USER`     | Admin username          | `admin` |
| `GF_SECURITY_ADMIN_PASSWORD` | Admin password          | `admin` |
| `GF_INSTALL_PLUGINS`         | Plugins to auto-install | -       |

### Google OAuth (Optional)

| Variable                         | Description                |
| -------------------------------- | -------------------------- |
| `GF_AUTH_GOOGLE_ENABLED`         | Enable Google OAuth        |
| `GF_AUTH_GOOGLE_CLIENT_ID`       | Google OAuth client ID     |
| `GF_AUTH_GOOGLE_CLIENT_SECRET`   | Google OAuth client secret |
| `GF_AUTH_GOOGLE_ALLOWED_DOMAINS` | Allowed email domains      |

## Volumes

| Host Path | Container Path     | Description                   |
| --------- | ------------------ | ----------------------------- |
| `./data`  | `/var/lib/grafana` | Dashboards, configs, and data |

## Installing Plugins

Set the `GF_INSTALL_PLUGINS` environment variable:

```yaml
environment:
  - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-piechart-panel
```

Or install manually:

```bash
docker compose exec grafana grafana-cli plugins install grafana-clock-panel
```

## Links

- [Grafana Website](https://grafana.com/)
- [Documentation](https://grafana.com/docs/)
- [Dashboard Gallery](https://grafana.com/grafana/dashboards/)
- [GitHub Repository](https://github.com/grafana/grafana)
