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
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Dev + n8n Assistant sandbox (opt-in profile) - see "n8n Assistant sandbox" below
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile sandbox up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d

# Behind Traefik + n8n Assistant sandbox
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml --profile sandbox up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

Access n8n at `http://localhost:5678`

## Architecture

This setup uses n8n's **queue mode** with external task runners for scalable workflow execution:

- **main**: Main n8n application (web UI, API, workflow coordinator)
- **worker**: Queue worker for background workflow execution
- **runners**: External task runners for executing workflow nodes (JavaScript/Python)

## n8n Assistant sandbox

n8n Assistant can write and run code to answer requests. That code runs in a sandbox
rather than inside n8n, which is what the optional `sandbox` profile provides:

| Service            | Purpose                                                              |
| ------------------ | -------------------------------------------------------------------- |
| `sandbox-certs`    | Generates the mTLS material the other two need, then exits           |
| `sandbox-api`      | Control plane n8n calls when Assistant needs to run code             |
| `sandbox-runner-1` | Runs the sandboxes; a privileged Docker-in-Docker container          |
| `searxng`          | Web-search backend for Assistant, reached internally by service name |

These services are behind a Compose **profile**, so a plain `up -d` never starts them —
enable them with `--profile sandbox` as shown above. None of them publishes a port:
n8n reaches `sandbox-api` by service name over the Compose network.

> **`sandbox-runner-1` runs `privileged: true`.** Docker-in-Docker needs it, and it
> is equivalent to root on the host. Never expose it, and do not run it on a host
> you would not hand root to. The same goes for the sandbox services generally:
> they exist to run untrusted, model-generated code.

Turning Assistant itself on is a separate step — set these in `.env` and restart
n8n:

```
N8N_ENABLED_MODULES=instance-ai
N8N_INSTANCE_AI_MODEL=anthropic/claude-opus-4-8
N8N_INSTANCE_AI_MODEL_API_KEY=sk-ant-xxx
```

Assistant stays inert until a model is configured. For a production instance n8n
recommends a hosted sandbox provider (Daytona) over this bundled one, which is
aimed at local development and testing.

### Sandbox secrets

Generate each of these with `openssl rand -hex 32`:

| Variable                                | Description                                                  |
| --------------------------------------- | ------------------------------------------------------------ |
| `SANDBOX_API_KEYS`                      | API keys `sandbox-api` accepts                               |
| `SANDBOX_API_RUNNER_REGISTRATION_TOKEN` | Shared secret the runner registers with                      |
| `SANDBOX_API_RUNNER_API_KEY`            | Key the runner uses against the API                          |
| `N8N_SANDBOX_SERVICE_API_KEY`           | How n8n authenticates; must match a `SANDBOX_API_KEYS` value |
| `SEARXNG_SECRET`                        | SearXNG session secret                                       |

The sandbox containers deliberately receive **only** the variables they need —
the n8n encryption key, the database password and the model API key never reach
them.

The mTLS certificates under the `sandbox-tls` volume are generated on first start
and **do not auto-renew**. To regenerate, remove the volume and bring the profile
back up:

```bash
docker compose --profile sandbox down
docker volume rm n8n_sandbox-tls
```

## Services

| Service            | Description                                    |
| ------------------ | ---------------------------------------------- |
| `main`             | Main n8n application                           |
| `worker`           | Queue worker for executions                    |
| `runners`          | External task runners (JS/Python)              |
| `db`               | PostgreSQL database                            |
| `qdrant`           | Vector database for AI                         |
| `redis`            | Cache and job queues                           |
| `adminer`          | Database admin UI                              |
| `redisinsight`     | Redis admin UI                                 |
| `auto-update`      | Watchtower auto-updates                        |
| `sandbox-certs`    | Sandbox mTLS bootstrap, profile `sandbox` only |
| `sandbox-api`      | Sandbox control plane, profile `sandbox` only  |
| `sandbox-runner-1` | Privileged sandbox runner, profile `sandbox`   |
| `searxng`          | Assistant web search, profile `sandbox` only   |

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

### n8n Assistant Configuration

| Variable                          | Description                               | Default                   |
| --------------------------------- | ----------------------------------------- | ------------------------- |
| `N8N_ENABLED_MODULES`             | Set to `instance-ai` to enable Assistant  | -                         |
| `N8N_INSTANCE_AI_MODEL`           | Model identifier for Assistant            | -                         |
| `N8N_INSTANCE_AI_MODEL_API_KEY`   | API key for that model's provider         | -                         |
| `N8N_INSTANCE_AI_SANDBOX_ENABLED` | Route Assistant code execution to sandbox | `false`                   |
| `N8N_INSTANCE_AI_SANDBOX_API_URL` | Sandbox API address                       | `http://sandbox-api:8080` |
| `N8N_SANDBOX_VERSION`             | Sandbox image version for all three       | `1.5.0`                   |
| `N8N_INSTANCE_AI_SEARXNG_URL`     | SearXNG address for Assistant web search  | `http://searxng:8080`     |

## Volumes

| Host Path             | Container Path             | Description                                          |
| --------------------- | -------------------------- | ---------------------------------------------------- |
| `./data/n8n`          | `/home/node/.n8n`          | n8n data                                             |
| `./data/files`        | `/files`                   | Shared files                                         |
| `./data/postgres`     | `/var/lib/postgresql/data` | Database data                                        |
| `./data/qdrant`       | `/qdrant/storage`          | Vector data                                          |
| `./data/redis`        | `/data`                    | Redis data                                           |
| `./data/redisinsight` | `/data`                    | RedisInsight data                                    |
| `sandbox-tls`         | `/tls`                     | Sandbox mTLS certs (named volume, profile `sandbox`) |

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
