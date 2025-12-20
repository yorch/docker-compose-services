# Auto Update (Watchtower)

Automated Docker container updater that monitors and updates running containers.

## Features

- Automatically updates Docker containers to the latest images
- Cleans up old images after updates
- Label-based filtering for selective updates
- Configurable update intervals

## Quick Start

```bash
docker compose up -d
```

## Configuration

### Command Options

The container runs with the following options:

- `--interval 300` - Check for updates every 5 minutes (300 seconds)
- `--label-enable` - Only update containers with the enable label
- `--cleanup` - Remove old images after updating

### Enabling Updates for Containers

Add this label to containers you want auto-updated:

```yaml
labels:
  - 'com.centurylinklabs.watchtower.enable=true'
```

## Volumes

| Host Path                   | Container Path         | Description                            |
| --------------------------- | ---------------------- | -------------------------------------- |
| `/var/run/docker.sock`      | `/var/run/docker.sock` | Docker socket for container management |
| `/root/.docker/config.json` | `/config.json`         | Registry authentication (optional)     |

## Links

- [Watchtower Documentation](https://containrrr.dev/watchtower/)
- [GitHub Repository](https://github.com/containrrr/watchtower)
