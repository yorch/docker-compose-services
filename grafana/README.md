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

Access Grafana at `http://localhost:3000`

Default credentials: `admin` / `admin`

## Environment Variables

| Variable                     | Description             | Default |
| ---------------------------- | ----------------------- | ------- |
| `GF_SERVER_DOMAIN`           | Server domain           | -       |
| `GF_SERVER_ROOT_URL`         | Full public URL         | -       |
| `GF_SECURITY_ADMIN_USER`     | Admin username          | `admin` |
| `GF_SECURITY_ADMIN_PASSWORD` | Admin password          | `admin` |
| `GF_PLUGINS_PREINSTALL`      | Plugins to auto-install | -       |

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

Set the `GF_PLUGINS_PREINSTALL` environment variable:

```yaml
environment:
  - GF_PLUGINS_PREINSTALL=grafana-clock-panel,yesoreyeram-infinity-datasource
```

Grafana 12 removed AngularJS plugin support, so `grafana-simple-json-datasource` no
longer loads; Infinity is Grafana's recommended JSON replacement. Grafana 13 also
deprecated `GF_INSTALL_PLUGINS` — the sample uses `GF_PLUGINS_PREINSTALL`, which installs
in the background and does not stop the server when the plugin registry is unreachable.

Or install manually:

```bash
docker compose exec grafana grafana-cli plugins install grafana-clock-panel
```

## Links

- [Grafana Website](https://grafana.com/)
- [Documentation](https://grafana.com/docs/)
- [Dashboard Gallery](https://grafana.com/grafana/dashboards/)
- [GitHub Repository](https://github.com/grafana/grafana)
