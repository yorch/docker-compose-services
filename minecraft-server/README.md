# Minecraft Server

Minecraft Java Edition game server using itzg/minecraft-server image.

## Features

- Easy server deployment
- Automatic updates
- Mod/plugin support (Paper, Fabric, Forge)
- Configurable memory and settings
- RCON support

## Quick Start

```bash
docker compose up -d
```

Connect to `localhost:25565` in Minecraft.

## Environment Variables

| Variable                     | Description              | Default |
| ---------------------------- | ------------------------ | ------- |
| `EULA`                       | Accept Minecraft EULA    | `TRUE`  |
| `MEMORY`                     | Server memory allocation | `4G`    |
| `ONLINE_MODE`                | Mojang authentication    | `FALSE` |
| `OVERRIDE_SERVER_PROPERTIES` | Allow env var overrides  | `TRUE`  |

### Server Configuration

| Variable           | Description                                 |
| ------------------ | ------------------------------------------- |
| `TYPE`             | Server type (VANILLA, PAPER, FABRIC, FORGE) |
| `VERSION`          | Minecraft version                           |
| `DIFFICULTY`       | Game difficulty                             |
| `MAX_PLAYERS`      | Maximum player count                        |
| `MOTD`             | Message of the day                          |
| `PVP`              | Enable PvP                                  |
| `SPAWN_PROTECTION` | Spawn protection radius                     |

## Ports

| Port    | Description      |
| ------- | ---------------- |
| `25565` | Minecraft server |

## Volumes

| Host Path | Container Path | Description                   |
| --------- | -------------- | ----------------------------- |
| `./data`  | `/data`        | Server files, worlds, configs |

## Modded Servers

### Fabric

```yaml
environment:
  TYPE: FABRIC
  VERSION: '1.20.4'
```

### Paper (with plugins)

```yaml
environment:
  TYPE: PAPER
  VERSION: '1.20.4'
```

Place plugins in `./data/plugins/`.

## Console Access

```bash
docker compose exec mc rcon-cli
```

## Notes

- The server runs in **offline mode** by default (no Mojang authentication)
- Image is pulled daily via `pull_policy: always`
- TTY enabled for console access

## Links

- [Docker Minecraft Server](https://docker-minecraft-server.readthedocs.io/)
- [GitHub Repository](https://github.com/itzg/docker-minecraft-server)
- [Minecraft Server Properties](https://minecraft.wiki/w/Server.properties)
