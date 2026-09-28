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
# Dev - web UI on http://localhost:8080 plus the torrenting port
docker compose -f docker-compose.yml -f docker-compose.ports.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS for the web UI.
# The ports overlay is still needed: Traefik proxies only the UI,
# so the torrenting port must stay published on the host.
docker compose -f docker-compose.yml -f docker-compose.ports.yml -f docker-compose.for-traefik.yml up -d

# Through a WireGuard VPN (Gluetun) - see below
./run-with-gluetun.sh
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

Sign in as `admin` with the temporary password from the logs, then set your own:

```bash
docker compose logs qbittorrent | grep "temporary password"
```

## Environment Variables

| Variable          | Description                                          | Default   |
| ----------------- | ---------------------------------------------------- | --------- |
| `HOST`            | Hostname Traefik routes to the web UI (Traefik only) | -         |
| `TZ`              | Timezone                                             | `Etc/UTC` |
| `PUID` / `PGID`   | User/group the downloads are written as              | `1000`    |
| `WEBUI_PORT`      | Web UI port (container and host)                     | `8080`    |
| `TORRENTING_PORT` | Torrenting port, TCP + UDP                           | `6881`    |

### Gluetun (VPN setup only)

| Variable                | Description                                 | Required |
| ----------------------- | ------------------------------------------- | -------- |
| `VPN_SERVICE_PROVIDER`  | Gluetun provider name, e.g. `mullvad`       | Yes      |
| `WIREGUARD_PRIVATE_KEY` | From your provider's WireGuard config       | Yes      |
| `WIREGUARD_ADDRESSES`   | IPv4 address from that config               | Yes      |
| `SERVER_CITIES`         | Preferred exit cities                       | No       |
| `UPDATER_PERIOD`        | How often Gluetun refreshes its server list | No       |

## Volumes

| Host Path        | Container Path | Description                            |
| ---------------- | -------------- | -------------------------------------- |
| `./config`       | `/config`      | qBittorrent configuration (gitignored) |
| `./downloads`    | `/downloads`   | Downloaded files (gitignored)          |
| `./data/gluetun` | `/gluetun`     | Gluetun state (VPN setup only)         |

## VPN Integration (Gluetun)

`docker-compose.gluetun.yml` runs qBittorrent inside Gluetun's network namespace
(`network_mode: service:gluetun`), so all its traffic, including the web UI, goes
through the VPN. Gluetun publishes the web UI and torrenting ports in that setup. Fill
in the Gluetun variables and run `./run-with-gluetun.sh`.

## Links

- [qBittorrent Website](https://www.qbittorrent.org/)
- [LinuxServer.io Image](https://docs.linuxserver.io/images/docker-qbittorrent/)
- [GitHub Repository](https://github.com/qbittorrent/qBittorrent)
