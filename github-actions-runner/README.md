# GitHub Actions Runner

Self-hosted runner for GitHub Actions workflows.

## Features

- Run GitHub Actions workflows on your own infrastructure
- Support for organization-level runners
- Custom environments and software
- Faster builds with local caching

## Quick Start

1. Create a personal access token with `repo` and `admin:org` scopes
2. Configure environment variables
3. Start the runner:

```bash
docker compose up -d
```

## Environment Variables

| Variable       | Description                  | Required |
| -------------- | ---------------------------- | -------- |
| `ACCESS_TOKEN` | GitHub personal access token | Yes      |
| `ORGANIZATION` | GitHub organization name     | Yes      |

## Building

This service uses a custom Dockerfile. Build with:

```bash
docker compose build
```

## Registering Runners

The runner will automatically register with your GitHub organization using the provided token.

### Token Scopes

The personal access token needs these scopes:

- `repo` - Full control of private repositories
- `admin:org` - Full control of orgs and teams (for org runners)

## Multiple Runners

To run multiple runners, scale the service:

```bash
docker compose up -d --scale runner=3
```

## Links

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [GitHub Repository](https://github.com/actions/runner)
