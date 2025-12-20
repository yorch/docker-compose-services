# Countly

Product analytics platform for mobile, web, and desktop applications.

## Features

- Real-time analytics dashboard
- User segmentation and cohorts
- Push notifications
- Crash reporting
- A/B testing
- Extensive plugin system

## Quick Start

```bash
docker compose up -d
```

## Services

| Service            | Description      |
| ------------------ | ---------------- |
| `nginx`            | Reverse proxy    |
| `countly-api`      | API server       |
| `countly-frontend` | Web dashboard    |
| `mongo`            | MongoDB database |

## Environment Variables

| Variable                       | Description                             |
| ------------------------------ | --------------------------------------- |
| `COUNTLY_PLUGINS`              | Comma-separated list of enabled plugins |
| `COUNTLY_CONFIG__MONGODB_HOST` | MongoDB hostname                        |
| `COUNTLY_CONFIG_HOSTNAME`      | Public hostname                         |
| `NODE_OPTIONS`                 | Node.js options (memory allocation)     |

## Configuration

### API Workers

Adjust the number of API workers based on your CPU cores:

```yaml
environment:
  - COUNTLY_CONFIG_API_WORKERS=2
```

### Nginx Configuration

Custom nginx configuration is mounted from `./conf/nginx.server.conf`.

## Volumes

| Host Path                  | Container Path                                       | Description  |
| -------------------------- | ---------------------------------------------------- | ------------ |
| `./data/mongo`             | `/data/db`                                           | MongoDB data |
| `./conf/nginx.server.conf` | `/opt/bitnami/nginx/conf/server_blocks/countly.conf` | Nginx config |

## Links

- [Countly Website](https://count.ly/)
- [Documentation](https://support.count.ly/)
- [GitHub Repository](https://github.com/Countly/countly-server)
