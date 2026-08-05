# Zot

OCI-native container registry with a built-in web UI, CVE scanning and on-demand Docker Hub mirroring.

## Features

- OCI Distribution Spec compliant registry, usable with `docker`, `podman`, `skopeo` and `oras`
- Built-in web UI for browsing repositories, tags and image contents
- CVE scanning of stored images, backed by the Trivy vulnerability database
- On-demand mirroring of Docker Hub — pull an upstream image once, serve it locally forever
- Basic authentication with per-repository authorization
- Content deduplication and scheduled garbage collection
- Prometheus metrics endpoint
- Single container: no database, no cache, no sidecar

## Quick Start

Copy `.env.sample` to `.env`, then create the admin account. **Zot will not
start without an htpasswd file**, because `config.json` declares one:

```bash
cp .env.sample .env
./create-user.sh admin
```

Then start it:

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

With the dev overlay the registry and the UI share `http://localhost:5000`; sign
in with the `admin` account you just created. The Traefik overlay publishes no
ports, so reach it at `https://${DOMAIN}` instead.

## Configuration

**Zot has no environment-variable support.** `zot serve` reads everything from a
single file, and there is no interpolation of `${VAR}` inside it — so unlike
every other service here, Zot's settings do not live in `.env`. `config.json` is
committed to the repo and mounted read-only at `/etc/zot/config.json`; edit it
directly and restart the container. `.env` carries only the two values compose
itself interpolates: `DOMAIN` and `ZOT_HOST_PORT`.

`config.json` deliberately omits `distSpecVersion`. The image's own built-in
config omits it too, and leaving it out means the file does not need editing
when Zot moves to a newer distribution spec.

### Users and permissions

Accounts live in `./data/auth/htpasswd`, managed with `./create-user.sh`. Zot
watches that file and reloads it without a restart.

**Zot accepts bcrypt hashes only.** `create-user.sh` passes `-B` for exactly
this reason. A file written with any other algorithm loads without an error and
then rejects every login, which reads like a wrong password rather than a wrong
hash format.

The shipped `accessControl` gives two usernames special meaning:

| Username  | Access                                                    |
| --------- | --------------------------------------------------------- |
| `admin`   | Push, pull and delete on every repository (`adminPolicy`) |
| `metrics` | May scrape `/metrics`                                     |
| any other | Pull only (`defaultPolicy` is `["read"]`)                 |

Anonymous access is denied outright. That is the effect of _omitting_
`anonymousPolicy` — Zot grants unauthenticated requests only the actions listed
there, so leaving the key out denies everything. Adding it opens the registry up:

```jsonc
"repositories": {
  "**": {
    "defaultPolicy": ["read"],
    "anonymousPolicy": ["read"]   // public pulls, authenticated pushes
  }
}
```

To let more than one account push, either add usernames to
`http.accessControl.adminPolicy.users`, or widen `defaultPolicy` to
`["read", "create", "update"]` so every account in `htpasswd` can push.

### Docker Hub mirroring

The `sync` extension is enabled with `onDemand: true` against
`https://index.docker.io`. Pull an image that is not stored locally and Zot
fetches it from Docker Hub, serves it, and keeps a copy:

```bash
docker pull ${DOMAIN}/library/alpine:latest
```

Mirrored images keep their upstream path, so `library/alpine` on Docker Hub is
`${DOMAIN}/library/alpine` here. To keep them out of the namespace your own
repositories use, add a `content` block with a destination:

```jsonc
"content": [{ "prefix": "**", "destination": "/docker-hub" }]
```

`preserveDigest: true` and `"compat": ["docker2s2"]` are both required for Hub
images. Without them Zot converts manifests to OCI format on the way through,
which changes their digests and breaks digest-pinned pulls
(`repo@sha256:…`) and signature verification.

**Do not add `pollInterval` to the Docker Hub entry.** Hub rate-limits pulls and
does not implement catalog listing, so scheduled mirroring against it cannot
work. On-demand is the only supported mode.

Anonymous Docker Hub pulls are rate-limited per IP. For a busy host, add a
`credentialsFile` pointing at a mounted JSON file of Hub credentials.

### CVE scanning

The `search` extension downloads the Trivy vulnerability database on first
start and refreshes it every 24 hours (`cve.updateInterval`). This costs a few
hundred MB of disk under `./data/registry` and a sizable download each refresh.

The web UI depends on `search`, but CVE scanning does not have to stay on. To
keep the UI and drop the database, remove the `cve` block:

```jsonc
"search": { "enable": true },
"ui": { "enable": true }
```

## Environment Variables

| Variable        | Description                                 | Required     | Default |
| --------------- | ------------------------------------------- | ------------ | ------- |
| `DOMAIN`        | Public hostname, used by the Traefik router | Traefik only | -       |
| `ZOT_HOST_PORT` | Host port published by the dev overlay      | No           | `5000`  |

Everything else is configured in `config.json` — see [Configuration](#configuration).

On **macOS**, port 5000 is taken by the AirPlay Receiver (System Settings →
General → AirDrop & Handoff). Set `ZOT_HOST_PORT` to something else rather than
changing the port in `config.json`, which the Traefik overlay also refers to.

```bash
cp .env.sample .env
docker compose --env-file .env -f docker-compose.yml -f docker-compose.dev.yml config -q
```

## Ports

| Port        | Description                                       |
| ----------- | ------------------------------------------------- |
| `5000:5000` | Registry API, web UI and `/metrics` (dev overlay) |

Zot serves the registry, the UI and metrics from the same port.

## Volumes

| Host Path         | Container Path         | Description                                 |
| ----------------- | ---------------------- | ------------------------------------------- |
| `./config.json`   | `/etc/zot/config.json` | Zot configuration, mounted read-only        |
| `./data/registry` | `/var/lib/registry`    | Image blobs, manifests and the CVE database |
| `./data/auth`     | `/etc/zot/auth`        | `htpasswd` file                             |

The auth mount is the directory, not the file. Zot watches `htpasswd` with
fsnotify, and `htpasswd` replaces the file rather than editing it in place — a
single-file bind mount would stay pinned to the old inode and never see new
users.

## Health Check

The container has no Docker healthcheck. The image is distroless — it ships no
shell, `curl`, `wget` or `nc` — so an in-container check cannot run and adding
one marks the container permanently unhealthy.

Zot registers `/livez`, `/readyz` and `/startupz` ahead of its auth middleware,
so they answer without credentials:

```bash
curl -i http://localhost:5000/livez    # 200 OK
```

`/v2/` works as a check too, but returns `401` once authentication is on — which
still proves the server is up.

## Usage

### Login

```bash
docker login ${DOMAIN}
```

### Push an image

Only `admin` (or a username you added to `adminPolicy`) may push:

```bash
docker tag myimage:latest ${DOMAIN}/myimage:latest
docker push ${DOMAIN}/myimage:latest
```

### Pull an image

```bash
docker pull ${DOMAIN}/myimage:latest
```

### Metrics

```bash
./create-user.sh metrics
curl -u metrics:<password> http://localhost:5000/metrics
```

## Links

- [Zot Website](https://zotregistry.dev/)
- [Documentation](https://zotregistry.dev/latest/)
- [Configuration Reference](https://zotregistry.dev/latest/admin-guide/admin-configuration/)
- [Example Configurations](https://github.com/project-zot/zot/tree/main/examples)
- [GitHub Repository](https://github.com/project-zot/zot)
