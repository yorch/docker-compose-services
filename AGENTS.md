# AGENTS.md

This file provides guidance to any AI agent (Claude Code, Codex, Cursor, Copilot, etc.) when working with code in this repository. `CLAUDE.md` is a symlink to this file for backward compatibility.

## Workflow — worktrees and PRs

Default to **worktrees and pull requests** for every change, unless the user explicitly says otherwise:

- Create a dedicated git worktree (or branch) per task: `git worktree add ../<repo>-<topic> -b <type>/<scope>-<short-desc>`
- Do all edits inside the worktree; never commit directly to `main`
- Push the branch and open a PR with a Conventional Commit title; wait for review/CI before merging
- Direct commits to `main` and in-place edits without a PR are only allowed when the user explicitly says "commit directly" or "no PR needed"
- After merge, remove the worktree: `git worktree remove ../<repo>-<topic>` and prune branches

## What this repo is

A catalog of ~58 independent self-hosted service stacks. Each top-level folder is one
service and is fully self-contained — there is no shared runtime, no build step, and no
cross-service imports. The only repo-wide code is `update-readme.ts` (README generator)
and `Taskfile.yml` / `dc-dev.sh` (thin wrappers over `docker compose`).

Treat each service folder as its own mini-project. Changes to one service should never
require touching another.

## Compose file layering

The central convention. A service's compose files are **merged** by passing multiple
`-f` flags; each file has a single responsibility:

| File                             | Responsibility                                                                                                                                               |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `docker-compose.yml`             | The service itself: image, `restart: unless-stopped`, `environment`, `volumes`, `healthcheck`, `depends_on`. Generally **no** `ports` and **no** `networks`. |
| `docker-compose.dev.yml`         | Local/dev exposure only — publishes `ports`.                                                                                                                 |
| `docker-compose.for-traefik.yml` | Production exposure only — Traefik `labels` + joining the external `traefik` network.                                                                        |

Some services deviate with extra overlays for optional components
(`qbittorrent/docker-compose.gluetun.yml`, `jaeger/docker-compose.hotrod.yml`,
`traefik/docker-compose.http-auth.yml`, `*.ports.yml`). When they do, a matching
`run-*.sh` script in the service folder documents the exact `-f` combination — treat
that script as the source of truth for which files a setup needs. `qbittorrent` is the
one case where the Traefik setup still needs `docker-compose.ports.yml`, because Traefik
proxies only the web UI and the torrenting port must stay published.

Keep new overlays additive: never duplicate keys already set in `docker-compose.yml`.

**The base file must be named `docker-compose.yml`.** `update-readme.ts` decides what
counts as a service by testing for that exact filename, so naming it anything else
(`docker-compose.base.yml`, say) silently removes the service from the generated table
with no error — and no amount of regeneration brings it back. Put deviations in
overlays, never in the base file's name.

### Traefik overlay shape

Every `docker-compose.for-traefik.yml` follows the same template (see `grafana/`):

```yaml
services:
  <service>:
    networks:
      - traefik
    labels:
      - 'traefik.enable=true'
      - 'traefik.docker.network=traefik'
      - 'traefik.http.services.<name>.loadbalancer.server.port=<container-port>'
      - 'traefik.http.routers.<name>.rule=Host(`${DOMAIN}`)'
      - 'traefik.http.routers.<name>.entrypoints=websecure'
      - 'traefik.http.routers.<name>.tls=true'
      - 'traefik.http.routers.<name>.tls.certResolver=webcert'
      - 'traefik.http.routers.<name>.service=<name>'

networks:
  traefik:
    external: true
```

The `webcert` cert resolver and `websecure` entrypoint are defined in `traefik/` and
`traefik3/`. The external `traefik` network must exist first — create it with
`traefik3/setup.sh` (`docker network create traefik`).

## Commands

All service commands run **from inside the service folder**.

```bash
# Dev: base + dev.yml (pull, then up -d)
task run-dev
task stop-dev

# Production/Traefik: base + for-traefik.yml (pull, then up -d)
task run-for-traefik
task stop-for-traefik
```

`Taskfile.yml` preconditions fail fast if `docker-compose.yml` or the requested overlay
is missing, or if a `.env.sample` exists without a corresponding `.env`.

From the repo root, `./dc-dev.sh <service> <args...>` does the same dev merge, creates
`./data`, and forwards remaining args to `docker compose` (e.g. `./dc-dev.sh grafana logs -f`).

Services with non-standard overlays ship their own scripts — run those directly
(`./run.sh`, `./run-with-gluetun.sh`, …).

Repo-level:

```bash
yarn format          # prettier --write . (also formats compose YAML)
yarn update-readme   # regenerate the service table in README.md
```

Yarn 4 (`packageManager: yarn@4.12.0`). There are no tests, no build, and no linter.
"Quality gate" here means: `yarn format`, `yarn update-readme`, and `docker compose config`
parsing cleanly for any compose file you touched.

## Commits and pull requests

Use [Conventional Commits](https://www.conventionalcommits.org/) for **every commit
message and PR title**:

```text
<type>(<scope>): <description>
```

**Type** — `feat` (new service or capability), `fix`, `docs`, `chore` (image bumps,
tooling, editor config), `refactor`, `build`, `ci`.

**Scope** — the service folder name. Omit the scope for repo-wide changes.

```text
feat(agentlogs): add service with Traefik and dev overlays
chore(grafana): bump grafana-oss to 11.4.0
fix(glitchtip): drop default for GLITCHTIP_ENABLE_DUCKDB
docs(siglens): document INGEST_PORT
chore: upgrade yarn to v4.12.0
```

Rules:

- Description in imperative mood, lowercase, no trailing period.
- **One service per commit** where practical. The stacks are independent, so a commit
  spanning several services is almost always separable and makes history harder to read.
- Breaking or operator-action-required changes (renamed volume path, changed env var
  name, major image upgrade) get a `!` before the colon — `feat(traefik)!: migrate to v3`
  — and an explanatory commit body.
- Regenerating the root README belongs in the same commit as the service it describes,
  not a follow-up.

PR titles follow the identical format. Note that history predating this convention is
mixed sentence-case; match the convention above, not the older commits.

## Conventions

**Dev port bindings.** In `docker-compose.dev.yml`, publish a container that exists only
to serve a sibling in the same stack as `${DEV_BIND_IP:-127.0.0.1}:<host>:<container>`
rather than `<host>:<container>`. A bare mapping binds `0.0.0.0`, which puts the
container on every interface the host has — so a Postgres sidecar started for local work
is reachable by anything on the same coffee-shop wifi, and Docker's own iptables rules
sit in front of most host firewalls.

Use `:-`, not `-`. `.env.sample` files ship values blank, and `${DEV_BIND_IP-127.0.0.1}`
treats a blank as a real value, producing `:5432:5432`. `:-` falls back on empty as well
as unset. `DEV_BIND_IP` keeps the same name in every service so there is one thing to
learn, and belongs in each `.env.sample` like any other variable.

This applies to **sidecars, not products**: the databases behind an app (`db`, `mongo`,
`mariadb`), caches and search (`redis`, `qdrant`, `meilisearch`), and DB admin UIs
(`adminer`, `mongo-express`, `redisinsight`). It does **not** apply to a service that is
itself the thing being run, or to anything meant to be reached from another machine —
`minecraft-server`, `mosquitto`, the VPN stacks, `wyze-bridge`, `docker-registry`, `zot`,
`traefik`. Those keep the bare mapping; binding them to localhost would break the point
of running them.

**Env vars.** Every configurable value goes through `${VAR}` in the compose file and is
documented in `.env.sample`. `.env` is gitignored — never create or commit one. Use
`${VAR:-default}` for optional values, and one of the two fail-fast forms for values
with no safe default:

| Form              | Fails when                | Use for                                             |
| ----------------- | ------------------------- | --------------------------------------------------- |
| `${VAR?message}`  | `VAR` is **unset**        | Values a user would omit entirely (see `traefik3/`) |
| `${VAR:?message}` | unset **or empty string** | Anything `.env.sample` ships blank                  |

**Prefer `:?`.** `.env.sample` files list secrets as `SECRET=` with no value, and
copying that to `.env` leaves the variable _set but empty_ — which `${VAR?…}` does not
catch. `woodpecker/` uses `:?` throughout; see it for the pattern.

Never let the message contain a colon followed by a space. Inside an unquoted YAML
sequence item that turns the entry into a mapping, and compose fails with
`unexpected type map[string]interface {}` — an error that says nothing about your
variable. Write `generate one with openssl rand -hex 32`, not `generate with: …`.

Note that a service using `:?` cannot be validated with
`docker compose --env-file .env.sample config` — that is the point, but it means the
quality-gate check needs a filled `.env`.

**Persistence.** Bind mounts under `./data` (e.g. `./data/postgres:/var/lib/postgresql/data`),
never named volumes — no service in the repo declares a top-level `volumes:` block.
`data/` is gitignored.

**Postgres mount paths differ by major version — getting this wrong loses data
silently.** Postgres 18 moved the image's `VOLUME` and `PGDATA`:

| Image                     | Mount the bind mount at    |
| ------------------------- | -------------------------- |
| `postgres:17` and earlier | `/var/lib/postgresql/data` |
| `postgres:18` and later   | `/var/lib/postgresql`      |

Mounting the wrong path produces **no error**. Docker creates an anonymous volume at
the image's declared `VOLUME`, the database writes there, and the bind mount stays
empty — discovered only at `docker compose down -v` or `docker volume prune`. When
bumping a Postgres major version anywhere in this repo, change the mount path in the
same commit, and confirm with
`docker inspect postgres:<tag> | jq '.[0].Config.Volumes'`.

Major versions are not on-disk compatible: moving 17 → 18 needs `pg_dumpall` and a
restore, never just a remount. Services currently on `postgres:16-alpine` — `gitea`,
`glitchtip` and others — each carry this migration when they are upgraded.

**Shared config in multi-container stacks.** Use YAML anchors at the top of the file
(`x-environment: &default-environment`, `x-depends_on: &default-depends_on`) rather than
repeating env blocks per container — see `glitchtip/docker-compose.yml`.

**Service README.md.** Required for every service, and its shape is load-bearing:
`update-readme.ts` takes the **first non-empty, non-heading line after the `# Title`**
as the description in the root README table. A README that opens with a badge, an image,
or a `##` section yields a blank description cell rather than an error. Follow the
existing layout: title, one-line description, Features, Quick Start, Environment
Variables table, Volumes table, Links.

**Quick Start blocks use raw `docker compose -f` commands**, not `task` / `just` /
`yarn` shortcuts, so they stay correct regardless of which runner the repo uses. Show
every applicable setup — dev and Traefik are separate invocations:

````markdown
```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```
````

Never document a bare `docker compose up -d` for a service whose ports live in an
overlay: it starts a container with nothing published, so any `localhost:PORT` the
README promises is unreachable. Only services with no overlays get the bare form.

**Root README.** The region between `<!-- START SERVICES -->` and `<!-- END SERVICES -->`
is generated. Never hand-edit it; run `yarn update-readme`.

**Spelling.** New service/tool names often need adding to `cSpell.words` in
`.vscode/settings.json` (kept alphabetical).

## Adding a new service

1. Create `<service>/` with `docker-compose.yml` (image, restart policy, env vars, `./data` mounts).
2. Add `docker-compose.dev.yml` publishing ports, and `docker-compose.for-traefik.yml` with the Traefik template above.
3. Add `.env.sample` documenting **every** `${VAR}` the compose files reference. A var
   used without a `:-default` and missing from the sample means anyone copying it gets an
   empty value — which is how `gitea` shipped a database that could not start.
4. Add `run-for-traefik.sh` (copy from any existing service) if the stack needs a non-default `-f` combination.
5. Write `README.md` — the line right after the `# Title` becomes the root README
   description, and the Quick Start block must show every applicable `-f` combination.
6. Run `yarn update-readme` and `yarn format`.
7. Add any new proper nouns to `cSpell.words`.

Before committing docs changes, these two checks catch the mistakes that have actually
happened here — a service invisible to the table, and a `${VAR}` no `.env.sample`
defines:

```bash
# Every service folder the generator can see
ls */docker-compose.yml | wc -l

# Active vars missing from a service's .env.sample
cat <service>/docker-compose*.yml | sed 's/#.*//' | grep -oE '\$\{[A-Z0-9_]+' | sed 's/\${//' | sort -u
```
