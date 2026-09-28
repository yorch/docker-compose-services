# Dokku

Docker-powered PaaS that helps you build and manage the lifecycle of applications.

## Features

- Heroku-like deployment experience
- Git push deployment
- Multiple language support
- Plugin ecosystem
- SSL certificates
- Database plugins

## Quick Start

See [SETUP.md](SETUP.md) for detailed setup and configuration instructions.

```bash
# Dev - publishes git-SSH on 3022, HTTP on 8080, HTTPS on 8443
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Dedicated Dokku host - takes the host's 22, 80 and 443
./run.sh   # docker compose -f docker-compose.yml -f docker-compose.ports.yml up -d
```

Dokku runs its own nginx and needs the host's ports 80/443, so it **cannot share a host
with `traefik3/`**, and port 22 means the host's own sshd must listen elsewhere. There
is no Traefik overlay on purpose.

## Environment Variables

| Variable         | Description                                                        | Required |
| ---------------- | ------------------------------------------------------------------ | -------- |
| `DOKKU_HOSTNAME` | Base domain; apps are served at `<app>.${DOKKU_HOSTNAME}`          | Yes      |
| `DOKKU_DATA_DIR` | **Absolute** host path for Dokku's data (default `/var/lib/dokku`) | No       |

`DOKKU_DATA_DIR` must be absolute: Dokku hands paths under it to the host's Docker daemon
(`DOKKU_HOST_ROOT`, `DOKKU_LIB_HOST_ROOT`) when it starts app containers, so a relative
`./data` path would resolve to nothing on the host.

## Volumes

| Host Path              | Container Path         | Description                          |
| ---------------------- | ---------------------- | ------------------------------------ |
| `${DOKKU_DATA_DIR}`    | `/mnt/dokku`           | Apps, config, plugins, SSH keys      |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket (Dokku runs your apps) |

The container uses `network_mode: bridge` because Dokku starts app containers on the
daemon's default bridge and its nginx proxies to their IPs.

## Ports

| Dedicated | Dev    | Description    |
| --------- | ------ | -------------- |
| `22`      | `3022` | SSH (git push) |
| `80`      | `8080` | HTTP           |
| `443`     | `8443` | HTTPS          |

## Basic Usage

### Deploy an Application

```bash
# On your local machine
git remote add dokku dokku@your-server:app-name
git push dokku main
```

### Manage Applications

```bash
# List apps
dokku apps:list

# Create app
dokku apps:create myapp

# Destroy app
dokku apps:destroy myapp
```

### Database Plugins

```bash
# Install PostgreSQL plugin
dokku plugin:install https://github.com/dokku/dokku-postgres.git

# Create database
dokku postgres:create mydb

# Link to app
dokku postgres:link mydb myapp
```

## Documentation

For detailed setup instructions, configuration options, and plugin documentation, refer to [SETUP.md](SETUP.md).

## Links

- [Dokku Website](https://dokku.com/)
- [Documentation](https://dokku.com/docs/)
- [GitHub Repository](https://github.com/dokku/dokku)
