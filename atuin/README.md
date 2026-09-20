# Atuin

Self-hosted sync server for Atuin, the end-to-end encrypted shell history tool.

## Features

- Sync shell history across machines through your own server
- History is encrypted on the client, so the server only stores ciphertext
- Works with bash, zsh, fish, nushell and more
- Registration closed by default, opened only while creating accounts
- Postgres 18 backend

## Quick Start

Copy `.env.sample` to `.env` and set `POSTGRES_PASSWORD` (and `DOMAIN` for
Traefik).

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

The server listens at `http://localhost:8888` (dev) or `https://${DOMAIN}`
(Traefik). `GET /healthz` returns `200` once it is up.

Without TLS, Atuin sends account passwords in plaintext. Put any instance other
machines can reach behind Traefik (HTTPS), and keep the dev overlay for local
testing.

## Registering accounts

Registration is closed by default. To create your account:

1. Set `ATUIN_OPEN_REGISTRATION=true` in `.env` and recreate the container
   (re-run the `up -d` command above).
2. On a client, point Atuin at your server in `~/.config/atuin/config.toml`:

   ```toml
   sync_address = "https://atuin.example.com"
   ```

   Or export `ATUIN_SYNC_ADDRESS` instead.

3. Register and sync:

   ```bash
   atuin register -u <username> -e <email>
   atuin sync
   ```

4. Set `ATUIN_OPEN_REGISTRATION=false` again and recreate the container.

On every other machine, set the same `sync_address` and run `atuin login`. It
asks for your encryption key, which `atuin key` prints on the first machine.
The server cannot recover this key: lose it and the synced history cannot be
decrypted.

If a client was previously logged into Atuin's hosted server, run
`atuin logout` before switching `sync_address`.

## Services

| Service    | Description                |
| ---------- | -------------------------- |
| `atuin`    | Atuin sync server (`8888`) |
| `postgres` | Postgres 18 database       |

## Environment Variables

| Variable                  | Description                                               | Default             |
| ------------------------- | --------------------------------------------------------- | ------------------- |
| `DOMAIN`                  | Public hostname, used by the Traefik router               | -                   |
| `ATUIN_OPEN_REGISTRATION` | Allow new accounts to register                            | `false`             |
| `RUST_LOG`                | Server log level, e.g. `info,atuin_server=debug`          | `atuin_server=info` |
| `POSTGRES_DB`             | Database name                                             | -                   |
| `POSTGRES_USER`           | Database user                                             | -                   |
| `POSTGRES_PASSWORD`       | Required. Database password, limited to `[A-Za-z0-9.~_-]` | -                   |
| `DEV_BIND_IP`             | Interface the dev overlay binds Postgres (`5432`) to      | `127.0.0.1`         |

Any other `server.toml` setting can be passed as an `ATUIN_*` variable in
`docker-compose.yml`, using `__` for nested keys (for example
`ATUIN_METRICS__ENABLE=true`).

## Volumes

| Host Path         | Container Path        | Description                  |
| ----------------- | --------------------- | ---------------------------- |
| `./data/postgres` | `/var/lib/postgresql` | Postgres 18 data (all state) |

The Atuin container has no volume: its state lives in Postgres and its
configuration comes from environment variables. `/config` is deliberately left
unmounted. The server writes an example `server.toml` there on first start, and
the image runs as a non-root user (UID 1000) that cannot write to the root-owned
directory Docker creates for a missing bind-mount path on Linux.

## Upgrading

The image is pinned to a minor release (`18.22`), so pulls pick up patch
releases only. Read the
[release notes](https://github.com/atuinsh/atuin/releases) before moving to a
newer minor: upstream warns that some upgrades need manual steps.

## Links

- [Atuin Website](https://atuin.sh)
- [Self-hosting Documentation](https://docs.atuin.sh/cli/self-hosting/server-setup/)
- [GitHub Repository](https://github.com/atuinsh/atuin)
