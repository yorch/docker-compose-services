# Docker Registry

Private Docker registry with web UI and authentication.

## Features

- Private Docker image hosting
- Web UI for browsing images
- Basic authentication (htpasswd)
- S3 storage backend support
- Redis caching
- Image deletion support
- Optional scheduled cleanup of the S3 storage (see [Maintenance](#maintenance))

## Quick Start

1. Create authentication:

```bash
./create-user.sh <username>
```

2. Start the registry:

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d

# Behind Traefik, plus scheduled cleanup of the S3 storage (see Maintenance)
./run-with-maintenance.sh
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

## Services

| Service    | Description        |
| ---------- | ------------------ |
| `registry` | Docker Registry v3 |
| `ui`       | Web UI (Joxit)     |
| `redis`    | Cache              |

Opt-in, with `docker-compose.maintenance.yml` (see [Maintenance](#maintenance)):

| Service       | Description                                   |
| ------------- | --------------------------------------------- |
| `maintenance` | Scheduled audit and cleanup of the S3 storage |

## Environment Variables

| Variable         | Description    | Required |
| ---------------- | -------------- | -------- |
| `REGISTRY_PORT`  | Registry port  | Yes      |
| `REDIS_PASSWORD` | Redis password | Yes      |

### S3 Storage (Optional)

| Variable                        | Description    |
| ------------------------------- | -------------- |
| `REGISTRY_STORAGE_S3_ACCESSKEY` | S3 access key  |
| `REGISTRY_STORAGE_S3_SECRETKEY` | S3 secret key  |
| `REGISTRY_STORAGE_S3_BUCKET`    | S3 bucket name |
| `REGISTRY_STORAGE_S3_REGION`    | S3 region      |

### Scheduled Maintenance (Optional)

Only used with `docker-compose.maintenance.yml`. All of them have defaults.

| Variable                         | Default           | Description                                                                    |
| -------------------------------- | ----------------- | ------------------------------------------------------------------------------ |
| `MAINTENANCE_DRY_RUN`            | `true`            | Nothing is deleted until this is `false`; jobs only log what they would delete |
| `MAINTENANCE_WEEKLY_AT`          | `Mon 06:00`       | Weekly job: `<Mon..Sun> HH:MM` in the server's time zone                       |
| `MAINTENANCE_GC_AT`              | `first-Sun 03:00` | Monthly garbage collection: `first-<day> HH:MM`, or `off`                      |
| `MAINTENANCE_MIN_AGE_HOURS`      | `24`              | Repositories without tags are left alone while they had activity this recently |
| `MAINTENANCE_KEEP_TAGS`          | `0`               | Tag retention: keep the newest N tags per repository (`0` = off)               |
| `MAINTENANCE_PROTECTED_TAGS`     | `latest,main,v*`  | Tag patterns retention never removes                                           |
| `MAINTENANCE_LOG_RETENTION_DAYS` | `90`              | Job logs older than this are deleted                                           |
| `MAINTENANCE_TZ`                 | server's          | Time zone for the schedule when it should differ, e.g. `America/New_York`      |

## Volumes

| Host Path         | Container Path      | Description   |
| ----------------- | ------------------- | ------------- |
| `./data/registry` | `/var/lib/registry` | Image storage |
| `./data/auth`     | `/auth`             | htpasswd file |

With `docker-compose.maintenance.yml`, the `maintenance` service also uses:

| Host Path              | Container Path         | Description                                   |
| ---------------------- | ---------------------- | --------------------------------------------- |
| `./data/maintenance`   | `/maintenance`         | Job logs, state, scratch dir                  |
| this folder            | the same path          | Scripts and compose files                     |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Recreates the registry for garbage collection |

## Creating Users

```bash
./create-user.sh <username>
```

It will ask for the password, and then creates or updates `./data/auth/htpasswd`.

## Usage

### Login

```bash
docker login your-registry.com
```

### Push Image

```bash
docker tag myimage:latest your-registry.com/myimage:latest
docker push your-registry.com/myimage:latest
```

### Pull Image

```bash
docker pull your-registry.com/myimage:latest
```

## Maintenance

Deleting tags (in the UI or with the API) does not free space. It only removes the tag
links: the repository stays in the catalog, its manifests stay, and the layer blobs stay in
storage until garbage collection runs. These scripts clean that up for the S3 backend.

They read the S3 settings from the running registry, so the stack must be up, and they run
the AWS CLI in a throwaway `amazon/aws-cli` container, so the host only needs Docker.

| Script                                    | What it does                                                                                                                                                                   |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `./registry-audit.sh [--verify-refs]`     | Read-only report: tags, revisions and layer links per repository, repositories with no tags, dangling tags, missing blobs                                                      |
| `./prune-empty-repos.sh [--delete] ...`   | Removes repositories with no tags (named, or `--empty` for all of them), tags whose manifest is gone (`--dangling-tags`) or layer links to deleted blobs (`--dangling-layers`) |
| `./prune-old-tags.sh [--delete] --keep N` | Tag retention: keeps the newest N tags of each repository, apart from protected ones (`latest`, `main` by default)                                                             |
| `./garbage-collect.sh [--delete] ...`     | Deletes unreferenced blobs, and with `--delete-untagged` manifests no tag points to                                                                                            |

Everything is a dry run unless you pass `--delete`, which asks you to type `DELETE` (or
pass `--yes` when there is no terminal). The bucket is not versioned, so deletions are
permanent. Consider enabling S3 versioning with a lifecycle rule.

```bash
./registry-audit.sh                                  # what needs cleaning?
./prune-empty-repos.sh my/old-image                  # dry run, then add --delete
./prune-empty-repos.sh --empty --min-age 24          # every repository without tags, unless touched in the last day
./prune-empty-repos.sh --dangling-tags --all         # tags that show "manifest unknown"
./prune-empty-repos.sh --dangling-layers --all       # layer links to blobs that are gone
./prune-old-tags.sh --keep 10 --protect latest,main,v* --all   # dry run of a retention rule
./garbage-collect.sh --dry-run --delete-untagged     # what garbage collection would remove
./garbage-collect.sh --delete --delete-untagged      # does it
```

`registry-audit.sh` exits with `0` when nothing is wrong, `10` for dangling tags only (which
`prune-empty-repos.sh --dangling-tags` removes), `20` when a live image references blobs
that no longer exist (nothing can repair that), and `1` when it could not finish.

Things worth knowing:

- **Prune empty repositories before garbage collection.** When every tag of a repository
  is gone, garbage collection neither marks nor deletes its manifests, yet it still deletes
  their blobs. The revision links are left pointing at nothing.
- **`--delete` runs the registry read-only.** Pulls keep working and pushes get a 405 until
  it finishes, which can take hours on a large bucket. Run it inside `tmux` or with
  `nohup`. `--stop-registry` stops the registry completely instead. Garbage collection
  retries when S3 resets a connection (`--retries`). If a run is killed half way (container
  killed, host rebooted) the registry stays read-only: `./garbage-collect.sh --revert`
  puts it back.
- **Read-only mode needs a config file.** `storage.maintenance.readonly.enabled` cannot be
  set through environment variables, and `REGISTRY_STORAGE=s3` in the environment silently
  discards it. While it runs, `garbage-collect.sh` replaces the registry's environment with
  a short list and refuses to continue if `docker-compose.yml` defines variables it does
  not know about.
- **Retention removes tags, not manifests.** The images of removed tags stay in storage as
  untagged manifests until `garbage-collect.sh --delete --delete-untagged` runs.
- **S3-compatible storage works too.** `REGISTRY_STORAGE_S3_REGIONENDPOINT` (and
  `_FORCEPATHSTYLE`, `_SECURE`, `REGISTRY_STORAGE_REDIRECT_DISABLE`) are passed on to the
  scripts when the registry uses them.

### Scheduled maintenance

The `maintenance` service runs these scripts on a schedule. It is opt-in, so start the
stack with this script, which adds `docker-compose.maintenance.yml`:

```bash
./run-with-maintenance.sh
```

| Job     | When (server time) | What                                                                                                                           |
| ------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| weekly  | `Mon 06:00`        | audit, tag retention (if enabled), dangling tags, empty repositories, dangling layer links, then an audit again                |
| monthly | `first-Sun 03:00`  | the weekly steps, then garbage collection with `--delete-untagged`. The registry is read-only for the length of the collection |

- **Dry run by default.** Until you set `MAINTENANCE_DRY_RUN=false` in `.env` every step only
  logs what it would delete. Read a first run before turning deletions on:
  `docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml -f docker-compose.maintenance.yml exec maintenance bash ./maintenance.sh run weekly`
- **It stops before deleting anything** if the audit finds a live image with missing blobs
  or cannot finish. The failure is in the log and the job's exit status.
- **Repositories without tags** are only removed once nothing has touched them for
  `MAINTENANCE_MIN_AGE_HOURS` (24), so a first push that is still in progress is safe.
- **Tag retention is off** (`MAINTENANCE_KEEP_TAGS=0`). Set it to keep the newest N tags of
  each repository. `MAINTENANCE_PROTECTED_TAGS` (`latest,main,v*`) are never removed and do
  not count towards N.
- **Logs** are in `./data/maintenance/logs/`, one file per job plus `history.log`, and are
  deleted after `MAINTENANCE_LOG_RETENTION_DAYS` (90). `./maintenance.sh status` prints the
  settings and the latest runs.
- **The service mounts the Docker socket**, which is root-equivalent on the host: the
  monthly job recreates the registry in read-only mode, and every job starts throw-away
  `amazon/aws-cli` containers. It also mounts this folder at the same absolute path
  inside the container, because compose and the scripts resolve paths on the host.
- **Stopping it is safe.** `docker stop` waits (up to three minutes) for a running collection
  to put the registry back in read-write mode. If the container is killed outright, it
  repairs the registry the next time it starts.

TODO: alerting. A failed job is only visible in its log and in `logs/history.log`; it
should notify somewhere (ntfy, healthchecks.io, email).

## Links

- [Docker Registry Documentation](https://docs.docker.com/registry/)
- [Registry UI (Joxit)](https://joxit.dev/docker-registry-ui/)
