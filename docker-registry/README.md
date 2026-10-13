# Docker Registry

Private Docker registry with web UI and authentication.

## Features

- Private Docker image hosting
- Web UI for browsing images
- Basic authentication (htpasswd)
- S3 storage backend support
- Redis caching
- Image deletion support

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

## Volumes

| Host Path         | Container Path      | Description   |
| ----------------- | ------------------- | ------------- |
| `./data/registry` | `/var/lib/registry` | Image storage |
| `./data/auth`     | `/auth`             | htpasswd file |

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

| Script                                  | What it does                                                                                                                             |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `./registry-audit.sh [--verify-refs]`   | Read-only report: tags, revisions and layer links per repository, repositories with no tags, dangling tags, missing blobs                |
| `./prune-empty-repos.sh [--delete] ...` | Removes repositories with no tags, tags whose manifest is gone (`--dangling-tags`) or layer links to deleted blobs (`--dangling-layers`) |
| `./garbage-collect.sh [--delete] ...`   | Deletes unreferenced blobs, and with `--delete-untagged` manifests no tag points to                                                      |

Everything is a dry run unless you pass `--delete`, which asks you to type `DELETE` (or
pass `--yes` when there is no terminal). The bucket is not versioned, so deletions are
permanent. Consider enabling S3 versioning with a lifecycle rule.

```bash
./registry-audit.sh                                  # what needs cleaning?
./prune-empty-repos.sh my/old-image                  # dry run, then add --delete
./prune-empty-repos.sh --dangling-layers --all       # dry run for every repository
./garbage-collect.sh --dry-run --delete-untagged     # what garbage collection would remove
./garbage-collect.sh --delete --delete-untagged      # does it
```

Things worth knowing:

- **Prune empty repositories before garbage collection.** When every tag of a repository
  is gone, garbage collection neither marks nor deletes its manifests, yet it still deletes
  their blobs. The revision links are left pointing at nothing.
- **`--delete` runs the registry read-only.** Pulls keep working and pushes get a 405 until
  it finishes, which can take hours on a large bucket. Run it inside `tmux` or with
  `nohup`. `--stop-registry` stops the registry completely instead. Garbage collection
  retries when S3 resets a connection (`--retries`).
- **Read-only mode needs a config file.** `storage.maintenance.readonly.enabled` cannot be
  set through environment variables, and `REGISTRY_STORAGE=s3` in the environment silently
  discards it. While it runs, `garbage-collect.sh` replaces the registry's environment with
  a short list and refuses to continue if `docker-compose.yml` defines variables it does
  not know about.

## Links

- [Docker Registry Documentation](https://docs.docker.com/registry/)
- [Registry UI (Joxit)](https://joxit.dev/docker-registry-ui/)
