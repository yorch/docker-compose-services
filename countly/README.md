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
# Dev - publishes nginx on http://localhost:8080 (set COUNTLY_CONFIG_HOSTNAME=localhost:8080)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

The first start takes several minutes: the frontend loads city coordinates into MongoDB
before it becomes healthy (nginx returns 502 until then). Then open the site and create
the admin account. Countly's first-run setup page is open to whoever reaches it first,
so finish it before sharing the URL.

## Services

| Service            | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| `nginx`            | Official nginx; routes `/i`, `/o` to the API, rest to the frontend |
| `countly-api`      | API server                                                         |
| `countly-frontend` | Web dashboard                                                      |
| `mongo`            | MongoDB 5                                                          |

## Environment Variables

| Variable                  | Description                                                | Required |
| ------------------------- | ---------------------------------------------------------- | -------- |
| `DOMAIN`                  | Hostname Traefik routes to Countly (Traefik only)          | Traefik  |
| `COUNTLY_CONFIG_HOSTNAME` | Public hostname Countly builds links with                  | Yes      |
| `COUNTLY_API_WORKERS`     | API worker processes, about one per CPU core (default `2`) | No       |

The enabled plugin list lives in `docker-compose.yml` (`x-countly-plugins`) and is shared
by the API and the frontend, which must match.

## Volumes

| Host Path                  | Container Path                   | Description  |
| -------------------------- | -------------------------------- | ------------ |
| `./data/mongo`             | `/data/db`                       | MongoDB data |
| `./conf/nginx.server.conf` | `/etc/nginx/conf.d/default.conf` | Nginx config |

## Links

- [Countly Website](https://count.ly/)
- [Documentation](https://support.count.ly/)
- [GitHub Repository](https://github.com/Countly/countly-server)
