# Woodpecker CI

Lightweight container-native CI/CD engine driven by a `.woodpecker.yaml` in each repository.

## Features

- Every pipeline step runs in its own container
- Pipelines defined in-repo as `.woodpecker.yaml`
- Matrix builds and multi-workflow pipelines
- Horizontally scalable by adding agents
- Authenticates against GitHub, Gitea, Forgejo, GitLab and Bitbucket

## Quick Start

Copy `.env.sample` to `.env` and fill it in first - see below for the GitHub
OAuth app and the agent secret.

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

`WOODPECKER_HOST` must match how you actually reach the server, because it is
also the OAuth callback host — a mismatch fails login after the GitHub redirect.
`.env.sample` ships the Traefik value, so **for the dev overlay change it to
`http://localhost:8000`** and register that as the callback URL on the OAuth app.

The UI is then at `http://localhost:8000`; sign in with GitHub.

On macOS with Docker Desktop, Postgres 18 will not start against a bind mount —
see [Storage](#storage) for the one-line `PGDATA` override that fixes local
development. Linux hosts need no change.

## Services

| Service    | Description                                       |
| ---------- | ------------------------------------------------- |
| `server`   | Web UI, API, and gRPC endpoint agents connect to  |
| `agent`    | Executes pipeline steps as containers on the host |
| `postgres` | Pipeline history, users, and secrets              |

Both images are pinned to the `v3` tag, which currently resolves to the same
digest as `v3.16.0`. The agent logs its version as `next-<sha>` rather than a
release number — that is upstream build metadata, not a wrongly pinned image.

## Setup

### 1. Create the GitHub OAuth app

Go to **Settings > Developer settings > OAuth Apps > New OAuth App** and set the
authorization callback URL to `${WOODPECKER_HOST}/authorize` — for example
`https://woodpecker.example.com/authorize`. Copy the client ID and secret into
`.env`.

The callback host must match `WOODPECKER_HOST` exactly, or login fails after the
GitHub redirect.

### 2. Generate the agent secret

```bash
openssl rand -hex 32
```

Put the result in `WOODPECKER_AGENT_SECRET`. The server and agent both read it;
if they disagree the agent connects and is rejected, and no pipelines run.

### 3. Grant yourself admin

Set `WOODPECKER_ADMIN` to your GitHub login. Leave `WOODPECKER_OPEN=false` so
registration stays closed — with it enabled, any GitHub account can sign in.

## Environment Variables

| Variable                   | Description                                         | Default      |
| -------------------------- | --------------------------------------------------- | ------------ |
| `DOMAIN`                   | Public hostname, used by the Traefik router         | -            |
| `WOODPECKER_HOST`          | Full public URL, must match the OAuth callback host | -            |
| `WOODPECKER_AGENT_SECRET`  | Shared server/agent secret                          | -            |
| `WOODPECKER_ADMIN`         | Comma-separated GitHub logins granted admin         | -            |
| `WOODPECKER_OPEN`          | Allow any GitHub user to register                   | `false`      |
| `WOODPECKER_GITHUB_CLIENT` | GitHub OAuth app client ID                          | -            |
| `WOODPECKER_GITHUB_SECRET` | GitHub OAuth app client secret                      | -            |
| `POSTGRES_DB`              | Database name                                       | `woodpecker` |
| `POSTGRES_USER`            | Database user                                       | `woodpecker` |
| `POSTGRES_PASSWORD`        | Database password                                   | `woodpecker` |

## Ports

| Port        | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| `8000:8000` | Web UI and API (dev overlay)                                 |
| `9000`      | gRPC for agents. Internal only — deliberately not published. |

## Volumes

| Host Path         | Container Path        | Description                                                              |
| ----------------- | --------------------- | ------------------------------------------------------------------------ |
| `./data/server`   | `/var/lib/woodpecker` | Unused with the Postgres driver; holds the SQLite database if you switch |
| `./data/agent`    | `/etc/woodpecker`     | Agent registration details                                               |
| `./data/postgres` | `/var/lib/postgresql` | Database data (see Storage below)                                        |

## Storage

This service runs `postgres:18-alpine`. **Postgres 18 changed where the image
keeps its data**: the image's `VOLUME` moved from `/var/lib/postgresql/data` to
`/var/lib/postgresql`, and `PGDATA` is now `/var/lib/postgresql/18/docker`.

Mounting the pre-18 path against this image does not fail — Docker just creates
an anonymous volume at `/var/lib/postgresql`, writes the real database there, and
leaves your bind mount empty. The loss only surfaces at
`docker compose down -v` or `docker volume prune`. Verify with:

```bash
docker inspect postgres:18-alpine | jq '.[0].Config.Volumes'
```

On **macOS with Docker Desktop**, Postgres 18 will not start against this mount —
it exits with `data directory "/var/lib/postgresql/18/docker" has wrong
ownership`, because it must create and own a subdirectory inside the bind mount.
Linux hosts are unaffected.

For local development on macOS, put the database back on the pre-18 layout with
an extra overlay file:

```yaml
# docker-compose.macos.yml
services:
  postgres:
    environment:
      - PGDATA=/var/lib/postgresql/data
    volumes: !override
      - ./data/postgres:/var/lib/postgresql/data
```

```bash
mkdir -p data/postgres
docker compose -f docker-compose.yml -f docker-compose.dev.yml \
  -f docker-compose.macos.yml up -d
```

Three details, each of which breaks it if omitted:

- **`!override` is required.** A plain `volumes:` key merges with the base file
  instead of replacing it, leaving the mount on `/var/lib/postgresql` and the
  override silently ineffective. Needs Compose v2.24 or newer.
- **`PGDATA` and the mount must change together.** The mount without `PGDATA`
  sends the database to an anonymous volume with no error.
- **Pre-create `data/postgres`.** If Docker Desktop creates it, ownership is
  wrong and Postgres exits.

Postgres 18 data is not backward compatible with 17 or earlier. Moving between
major versions needs `pg_dumpall` and a restore, not just a remount.

## Security

The agent mounts `/var/run/docker.sock` so it can start pipeline steps as
containers on the host daemon. **The agent therefore has root-equivalent access
to the host.** This is inherent to Woodpecker's Docker backend, not a quirk of
this setup.

Three upstream defaults limit what that means for whoever writes a pipeline. All
three are worth leaving as they are:

- **Host volume mounts require a _trusted_ repository.** Escalated capabilities
  such as mounting volumes are unavailable unless a repository is explicitly
  marked trusted, and only a server admin can set that.
- **Pull requests from forks require approval.** The default is
  `Approvals for forked repositories`, so a fork's PR does not run until someone
  approves it.
- **`WOODPECKER_OPEN=false`** keeps registration closed. Note this governs who
  can _sign in_, not what a pipeline may do — the two settings above are what
  bound pipeline privilege.

Relaxing any of the three widens the blast radius to the host, so treat marking
a repository trusted as the significant decision it is.

## Using Traefik

The `server` container joins both the `default` and `traefik` networks. Both are
required: Traefik reaches the web UI on port 8000 over `traefik`, while
`postgres` and the `agent` are reachable only on `default`.

Drop `default` and the server does not start at all — it cannot resolve
`postgres`, and crash-loops during store setup with
`dial tcp: lookup postgres ... no such host`.

## Adding a Repository

1. Sign in at `WOODPECKER_HOST` with GitHub
2. Open **Repositories > Add repository** and enable the one you want
3. Commit a `.woodpecker.yaml` to that repository:

   ```yaml
   steps:
     - name: test
       image: alpine
       commands:
         - echo "hello from Woodpecker"
   ```

## Links

- [Woodpecker CI Website](https://woodpecker-ci.org/)
- [Documentation](https://woodpecker-ci.org/docs/intro)
- [Server Configuration](https://woodpecker-ci.org/docs/administration/configuration/server)
- [GitHub Repository](https://github.com/woodpecker-ci/woodpecker)
