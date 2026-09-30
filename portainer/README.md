# Portainer

Docker and Kubernetes management GUI.

## Features

- Visual container management
- Stack deployment (Docker Compose)
- Image management
- Network and volume management
- User and team management
- Multi-environment support

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

Access Portainer at `http://localhost:9000` (dev, loopback only).

Portainer has root-equivalent access to the Docker host, and until the first admin is
created anyone who reaches it can claim it. Behind Traefik it therefore also requires
basic auth. Generate the hash with:

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'your-password' | cut -d: -f2
```

## Environment Variables

| Variable                   | Description                                   | Required |
| -------------------------- | --------------------------------------------- | -------- |
| `HOST`                     | Hostname Traefik routes to Portainer          | Traefik  |
| `BASIC_AUTH_USER`          | Basic-auth user                               | Traefik  |
| `BASIC_AUTH_PASSWORD_HASH` | bcrypt hash for that user, single-quoted      | Traefik  |
| `DEV_BIND_IP`              | Host interface for the dev port (`127.0.0.1`) | No       |

## First-Time Setup

1. Access the web interface
2. Create an admin account (must be done within first few minutes)
3. Connect to your Docker environment

## Volumes

| Host Path              | Container Path         | Description      |
| ---------------------- | ---------------------- | ---------------- |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket    |
| `./data`               | `/data`                | Portainer data   |
| `./certs`              | `/certs`               | SSL certificates |

## Docker Socket Security

Mounting the Docker socket gives Portainer full control over Docker. For production:

- Use TLS for Docker API access
- Configure role-based access control
- Use Portainer Agent for remote hosts

## Connecting Remote Hosts

Install Portainer Agent on remote hosts:

```bash
docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  portainer/agent
```

## Links

- [Portainer Website](https://www.portainer.io/)
- [Documentation](https://docs.portainer.io/)
- [GitHub Repository](https://github.com/portainer/portainer)
