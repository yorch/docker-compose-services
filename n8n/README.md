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

## Services

| Service        | Description            |
| -------------- | ---------------------- |
| `n8n`          | Main application       |
| `postgres`     | PostgreSQL database    |
| `qdrant`       | Vector database for AI |
| `redis`        | Cache and queues       |
| `adminer`      | Database admin UI      |
| `redisinsight` | Redis admin UI         |
| `watchtower`   | Auto-updates           |

## Environment Variables

| Variable           | Description           | Default |
| ------------------ | --------------------- | ------- |
| `N8N_HOST`         | Public hostname       | -       |
| `N8N_PORT`         | Application port      | `5678`  |
| `N8N_PROTOCOL`     | Protocol (http/https) | `https` |
| `WEBHOOK_URL`      | Webhook callback URL  | -       |
| `GENERIC_TIMEZONE` | Timezone              | -       |
| `TZ`               | System timezone       | -       |

### Database Configuration

| Variable                 | Description         |
| ------------------------ | ------------------- |
| `DB_TYPE`                | Database type       |
| `DB_POSTGRESDB_HOST`     | PostgreSQL host     |
| `DB_POSTGRESDB_USER`     | PostgreSQL user     |
| `DB_POSTGRESDB_PASSWORD` | PostgreSQL password |
| `DB_POSTGRESDB_DATABASE` | PostgreSQL database |

## Volumes

| Host Path         | Container Path             | Description   |
| ----------------- | -------------------------- | ------------- |
| `./data/n8n`      | `/home/node/.n8n`          | n8n data      |
| `./data/postgres` | `/var/lib/postgresql/data` | Database data |
| `./data/qdrant`   | `/qdrant/storage`          | Vector data   |
| `./data/redis`    | `/data`                    | Redis data    |

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
