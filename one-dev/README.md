# OneDev

Self-hosted Git server with built-in CI/CD capabilities.

## Features

- Git repository hosting
- Built-in CI/CD pipelines
- Issue tracking
- Code review and pull requests
- Symbol search and navigation
- Container-based build agents

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

Access OneDev at `http://localhost:6610` (dev) and sign in with `INITIAL_USER` /
`INITIAL_PASSWORD`. The admin is created on first start, so the setup wizard is never
exposed.

Behind Traefik only HTTPS is proxied: clone over `https://${DOMAIN}`. Git over SSH
(port 6611) is published by the dev overlay only.

## Environment Variables

| Variable               | Description                                                 | Required |
| ---------------------- | ----------------------------------------------------------- | -------- |
| `DOMAIN`               | Hostname Traefik routes to OneDev (Traefik only)            | Traefik  |
| `INITIAL_USER`         | Admin username created on first start                       | Yes      |
| `INITIAL_PASSWORD`     | Admin password created on first start                       | Yes      |
| `INITIAL_EMAIL`        | Admin email                                                 | Yes      |
| `INITIAL_SERVER_URL`   | Public URL (`https://${DOMAIN}` or `http://localhost:6610`) | Yes      |
| `INITIAL_SSH_ROOT_URL` | SSH root URL; derived from the server URL if unset          | No       |
| `PORT_WEB`             | Dev host port for the web UI (default `6610`)               | No       |
| `PORT_SSH`             | Dev host port for Git over SSH (default `6611`)             | No       |

The `INITIAL_*` values only apply to the first start. The compose file passes them to
OneDev as lowercase `initial_*` keys, the only form OneDev reads.

## Volumes

| Host Path       | Container Path | Description     |
| --------------- | -------------- | --------------- |
| `./data/onedev` | `/opt/onedev`  | All OneDev data |

## CI/CD Pipelines

OneDev uses a `buildspec.yml` file in your repository:

```yaml
version: 1
jobs:
  - name: Build
    steps:
      - !CheckoutStep
        name: Checkout
      - !CommandStep
        name: Build
        runInContainer: true
        image: maven:3.8-openjdk-17
        commands:
          - mvn package
```

## Docker Socket Access

For CI/CD with Docker builds, mount the Docker socket:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

## Links

- [OneDev Website](https://onedev.io/)
- [Documentation](https://docs.onedev.io/)
- [GitHub Repository](https://github.com/theonedev/onedev)
