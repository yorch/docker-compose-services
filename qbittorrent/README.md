# qBittorrent

Open-source BitTorrent client with web UI.

## Features

- Web-based interface
- RSS feed support
- IP filtering
- Sequential downloading
- Multiple search engines
- VPN integration support

## Quick Start

```bash
docker compose up -d
```

Access the web UI at `http://localhost:8080`

Default credentials: `admin` / Check logs for password

## Environment Variables

| Variable          | Description     | Default |
| ----------------- | --------------- | ------- |
| `PUID`            | User ID         | `1000`  |
| `PGID`            | Group ID        | `1000`  |
| `TZ`              | Timezone        | -       |
| `WEBUI_PORT`      | Web UI port     | `8080`  |
| `TORRENTING_PORT` | Torrenting port | `6881`  |

## Volumes

| Host Path     | Container Path | Description         |
| ------------- | -------------- | ------------------- |
| `./config`    | `/config`      | Configuration files |
| `./downloads` | `/downloads`   | Downloaded files    |

## VPN Integration (Gluetun)

For VPN support, use with Gluetun:

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun
    cap_add:
      - NET_ADMIN
    environment:
      - VPN_SERVICE_PROVIDER=...
    ports:
      - 8080:8080

  qbittorrent:
    network_mode: 'service:gluetun'
    depends_on:
      - gluetun
```

## Initial Password

Check container logs for the initial password:

```bash
docker compose logs qbittorrent | grep password
```

## Links

- [qBittorrent Website](https://www.qbittorrent.org/)
- [LinuxServer.io Image](https://docs.linuxserver.io/images/docker-qbittorrent/)
- [GitHub Repository](https://github.com/qbittorrent/qBittorrent)
