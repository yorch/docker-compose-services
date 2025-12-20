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
docker compose up -d
```

Access Portainer at `http://localhost:9000`

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
