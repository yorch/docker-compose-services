# OneDev

Self-hosted Git server with built-in CI/CD capabilities.

## Features

- Git repository hosting
- Built-in CI/CD pipelines
- Issue tracking
- Code review and pull requests
- Symbol search and navigation
- Container-based build agents

## Quick Start

```bash
docker compose up -d
```

Access OneDev at `http://localhost:6610`

## Environment Variables

| Variable             | Description            | Required |
| -------------------- | ---------------------- | -------- |
| `INITIAL_USER`       | Initial admin username | Yes      |
| `INITIAL_PASSWORD`   | Initial admin password | Yes      |
| `INITIAL_EMAIL`      | Initial admin email    | Yes      |
| `INITIAL_SERVER_URL` | Public server URL      | Yes      |

## Volumes

| Host Path       | Container Path | Description     |
| --------------- | -------------- | --------------- |
| `./data/onedev` | `/opt/onedev`  | All OneDev data |

## CI/CD Pipelines

OneDev uses a `buildspec.yml` file in your repository:

```yaml
version: 1
jobs:
  - name: Build
    steps:
      - !CheckoutStep
        name: Checkout
      - !CommandStep
        name: Build
        runInContainer: true
        image: maven:3.8-openjdk-17
        commands:
          - mvn package
```

## Docker Socket Access

For CI/CD with Docker builds, mount the Docker socket:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

## Links

- [OneDev Website](https://onedev.io/)
- [Documentation](https://docs.onedev.io/)
- [GitHub Repository](https://github.com/theonedev/onedev)
