# Heimdall

Application dashboard and launcher for organizing your web applications.

## Features

- Clean and organized application dashboard
- Support for enhanced applications with API integration
- Customizable backgrounds and themes
- Search functionality
- Tag-based organization

## Quick Start

```bash
docker compose up -d
```

Access Heimdall at `http://localhost:80`

## Environment Variables

| Variable | Description                   | Default |
| -------- | ----------------------------- | ------- |
| `PUID`   | User ID for file permissions  | `1000`  |
| `PGID`   | Group ID for file permissions | `1000`  |
| `TZ`     | Timezone                      | -       |

## Volumes

| Host Path  | Container Path | Description                |
| ---------- | -------------- | -------------------------- |
| `./config` | `/config`      | Configuration and settings |

## Adding Applications

1. Click the "Add" button
2. Enter application name and URL
3. Optionally configure enhanced app settings for supported services
4. Choose an icon and color

## Enhanced Applications

Some applications support enhanced integration with API keys:

- Sonarr / Radarr
- Pihole
- Tautulli
- And many more

## Links

- [Heimdall Website](https://heimdall.site/)
- [GitHub Repository](https://github.com/linuxserver/Heimdall)
- [Supported Applications](https://apps.heimdall.site/)
