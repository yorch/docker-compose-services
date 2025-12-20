# Flowise

Low-code/no-code LLM app builder with drag-and-drop UI for AI workflows.

## Features

- Visual workflow builder
- 100+ integrations (LLMs, tools, memory)
- API endpoints for each flow
- Custom tool creation
- Chat widgets for embedding

## Quick Start

```bash
docker compose up -d
```

## Services

| Service | Description         |
| ------- | ------------------- |
| `app`   | Flowise application |
| `db`    | PostgreSQL database |

## Environment Variables

| Variable                    | Description          | Default    |
| --------------------------- | -------------------- | ---------- |
| `FLOWISE_USERNAME`          | Dashboard username   | -          |
| `FLOWISE_PASSWORD`          | Dashboard password   | -          |
| `DATABASE_TYPE`             | Database type        | `postgres` |
| `DATABASE_HOST`             | Database hostname    | `db`       |
| `POSTGRES_DB`               | Database name        | -          |
| `POSTGRES_USER`             | Database user        | -          |
| `POSTGRES_PASSWORD`         | Database password    | -          |
| `FLOWISE_FILE_SIZE_LIMIT`   | Max file upload size | -          |
| `DISABLE_FLOWISE_TELEMETRY` | Disable telemetry    | `true`     |

### Proxy Configuration (Optional)

| Variable                   | Description     |
| -------------------------- | --------------- |
| `GLOBAL_AGENT_HTTP_PROXY`  | HTTP proxy URL  |
| `GLOBAL_AGENT_HTTPS_PROXY` | HTTPS proxy URL |

## Volumes

| Host Path         | Container Path             | Description              |
| ----------------- | -------------------------- | ------------------------ |
| `./data/flowise`  | `/root/.flowise`           | Flowise data and uploads |
| `./data/postgres` | `/var/lib/postgresql/data` | Database data            |

## Links

- [Flowise Website](https://flowiseai.com/)
- [Documentation](https://docs.flowiseai.com/)
- [GitHub Repository](https://github.com/FlowiseAI/Flowise)
