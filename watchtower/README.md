# Watchtower

Automated Docker container updates.

## Features

- Automatic container updates
- Configurable schedules
- Notification support
- Private registry support
- Container lifecycle hooks
- Rolling restarts

## Quick Start

```bash
docker compose up -d
```

## Environment Variables

| Variable                        | Description                  | Default |
| ------------------------------- | ---------------------------- | ------- |
| `WATCHTOWER_POLL_INTERVAL`      | Check interval (seconds)     | `86400` |
| `WATCHTOWER_CLEANUP`            | Remove old images            | `false` |
| `WATCHTOWER_INCLUDE_STOPPED`    | Update stopped containers    | `false` |
| `WATCHTOWER_INCLUDE_RESTARTING` | Update restarting containers | `false` |
| `WATCHTOWER_REVIVE_STOPPED`     | Restart stopped containers   | `false` |
| `WATCHTOWER_ROLLING_RESTART`    | Rolling restart enabled      | `false` |

### Schedule (Cron)

| Variable              | Description              |
| --------------------- | ------------------------ |
| `WATCHTOWER_SCHEDULE` | Cron schedule expression |

Example: `0 0 4 * * *` (4:00 AM daily)

### Notifications

| Variable                      | Description                                                 |
| ----------------------------- | ----------------------------------------------------------- |
| `WATCHTOWER_NOTIFICATIONS`    | Notification type (email, slack, msteams, gotify, shoutrrr) |
| `WATCHTOWER_NOTIFICATION_URL` | Shoutrrr notification URL                                   |

## Volumes

| Host Path              | Container Path         | Description   |
| ---------------------- | ---------------------- | ------------- |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket |

## Selective Updates

### Monitor Specific Containers

```bash
docker compose up -d watchtower
docker run -d --label=com.centurylinklabs.watchtower.enable=true myapp
```

### Exclude Containers

```yaml
labels:
  - 'com.centurylinklabs.watchtower.enable=false'
```

## Run Once

Update all containers once and exit:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once
```

## Lifecycle Hooks

Run commands before/after updates:

```yaml
labels:
  - 'com.centurylinklabs.watchtower.lifecycle.pre-update=/scripts/pre-update.sh'
  - 'com.centurylinklabs.watchtower.lifecycle.post-update=/scripts/post-update.sh'
```

## Links

- [Watchtower Website](https://containrrr.dev/watchtower/)
- [Documentation](https://containrrr.dev/watchtower/)
- [GitHub Repository](https://github.com/containrrr/watchtower)
