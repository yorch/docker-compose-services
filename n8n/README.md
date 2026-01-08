# n8n

Workflow automation platform - open-source alternative to Zapier/Make.

## Features

- 400+ integrations
- Visual workflow builder
- Custom JavaScript/Python nodes
- Self-hosted and privacy-focused
- AI capabilities with vector store support

## Quick Start

```bash
docker compose up -d
```

Access n8n at `http://localhost:5678`

## Architecture

This setup uses n8n's **queue mode** with external task runners for scalable workflow execution:

- **main**: Main n8n application (web UI, API, workflow coordinator)
- **worker**: Queue worker for background workflow execution
- **runners**: External task runners for executing workflow nodes (JavaScript/Python)

## Services

| Service        | Description                       |
| -------------- | --------------------------------- |
| `main`         | Main n8n application              |
| `worker`       | Queue worker for executions       |
| `runners`      | External task runners (JS/Python) |
| `db`           | PostgreSQL database               |
| `qdrant`       | Vector database for AI            |
| `redis`        | Cache and job queues              |
| `adminer`      | Database admin UI                 |
| `redisinsight` | Redis admin UI                    |
| `auto-update`  | Watchtower auto-updates           |

## Environment Variables

### Application Configuration

| Variable                                | Description              | Default |
| --------------------------------------- | ------------------------ | ------- |
| `N8N_HOST`                              | Public hostname          | -       |
| `N8N_PORT`                              | Application port         | `5678`  |
| `N8N_PROTOCOL`                          | Protocol (http/https)    | `https` |
| `WEBHOOK_URL`                           | Webhook callback URL     | -       |
| `N8N_ENCRYPTION_KEY`                    | Encryption key           | -       |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | Enforce file permissions | -       |
| `GENERIC_TIMEZONE`                      | Timezone                 | -       |
| `TZ`                                    | System timezone          | -       |
| `NODE_ENV`                              | Node environment         | -       |

### Queue & Workers Configuration

| Variable                               | Description                    | Default |
| -------------------------------------- | ------------------------------ | ------- |
| `EXECUTIONS_MODE`                      | Execution mode (queue)         | `queue` |
| `QUEUE_BULL_REDIS_HOST`                | Redis host for queues          | `redis` |
| `OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS` | Offload manual runs to workers | `true`  |
| `QUEUE_HEALTH_CHECK_ACTIVE`            | Enable worker health checks    | -       |

### Task Runners Configuration

| Variable                            | Description                  | Default    |
| ----------------------------------- | ---------------------------- | ---------- |
| `N8N_RUNNERS_ENABLED`               | Enable external runners      | `true`     |
| `N8N_RUNNERS_MODE`                  | Runners mode (external)      | `external` |
| `N8N_RUNNERS_AUTH_TOKEN`            | Runners authentication token | -          |
| `N8N_RUNNERS_BROKER_LISTEN_ADDRESS` | Broker listen address        | `0.0.0.0`  |

### Database Configuration

| Variable                 | Description         | Default      |
| ------------------------ | ------------------- | ------------ |
| `POSTGRES_DB`            | PostgreSQL database | -            |
| `POSTGRES_USER`          | PostgreSQL user     | -            |
| `POSTGRES_PASSWORD`      | PostgreSQL password | -            |
| `DB_TYPE`                | Database type       | `postgresdb` |
| `DB_POSTGRESDB_HOST`     | PostgreSQL host     | `db`         |
| `DB_POSTGRESDB_USER`     | PostgreSQL user     | -            |
| `DB_POSTGRESDB_PASSWORD` | PostgreSQL password | -            |
| `DB_POSTGRESDB_DATABASE` | PostgreSQL database | -            |

### Watchtower Configuration

| Variable           | Description           | Default |
| ------------------ | --------------------- | ------- |
| `WATCHTOWER_SCOPE` | Watchtower scope name | -       |

## Volumes

| Host Path            | Container Path             | Description      |
| -------------------- | -------------------------- | ---------------- |
| `./data/n8n`         | `/home/node/.n8n`          | n8n data         |
| `./data/files`       | `/files`                   | Shared files     |
| `./data/postgres`    | `/var/lib/postgresql/data` | Database data    |
| `./data/qdrant`      | `/qdrant/storage`          | Vector data      |
| `./data/redis`       | `/data`                    | Redis data       |
| `./data/redisinsight`| `/data`                    | RedisInsight data|

## AI Features

This setup includes Qdrant for vector storage, enabling AI workflows:

- Document Q&A
- Semantic search
- RAG pipelines
- AI agents

## Links

- [n8n Website](https://n8n.io/)
- [Documentation](https://docs.n8n.io/)
- [Workflow Templates](https://n8n.io/workflows/)
- [GitHub Repository](https://github.com/n8n-io/n8n)
