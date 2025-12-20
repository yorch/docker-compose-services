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
docker compose up -d
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

## Links

- [Docker Registry Documentation](https://docs.docker.com/registry/)
- [Registry UI (Joxit)](https://joxit.dev/docker-registry-ui/)
