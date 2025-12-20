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
docker compose up -d
```

## Environment Variables

| Variable         | Description      | Required |
| ---------------- | ---------------- | -------- |
| `DOKKU_HOSTNAME` | Your domain name | Yes      |

## Volumes

| Host Path              | Container Path         | Description      |
| ---------------------- | ---------------------- | ---------------- |
| `./data/dokku`         | `/mnt/dokku`           | Application data |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket    |

## Ports

| Port  | Description    |
| ----- | -------------- |
| `22`  | SSH (git push) |
| `80`  | HTTP           |
| `443` | HTTPS          |

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
