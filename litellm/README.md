# LiteLLM

Unified API proxy for 100+ LLM providers (OpenAI, Anthropic, Azure, and more).

## Features

- Single API for all LLM providers
- Load balancing and fallbacks
- Request/response logging
- Budget management
- Rate limiting
- Admin UI for model and key management

## Quick Start

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

Access the Admin UI and log in with your `LITELLM_MASTER_KEY` value:

- **Dev:** `http://localhost:4000/ui`
- **Traefik:** `https://${DOMAIN}/ui`

## Services

| Service   | Description         |
| --------- | ------------------- |
| `litellm` | LiteLLM proxy       |
| `db`      | PostgreSQL database |

## Environment Variables

| Variable             | Description                                            | Required |
| -------------------- | ------------------------------------------------------ | -------- |
| `POSTGRES_DB`        | PostgreSQL database name                               | Yes      |
| `POSTGRES_USER`      | PostgreSQL user                                        | Yes      |
| `POSTGRES_PASSWORD`  | PostgreSQL password                                    | Yes      |
| `LITELLM_MASTER_KEY` | Admin API key (must start with `sk-`)                  | Yes      |
| `LITELLM_SALT_KEY`   | Encryption salt for stored credentials (immutable)     | Yes      |
| `STORE_MODEL_IN_DB`  | Store model config in DB / add via UI (default `True`) | No       |
| `DOMAIN`             | Traefik hostname                                       | Traefik  |
| `DEV_BIND_IP`        | Interface for dev port bindings (default `127.0.0.1`)  | No       |

> **Note on Redis:** This stack runs a single proxy instance, so Redis is not
> required. The `LITELLM_DISABLE_NO_REDIS_WARNING` env var is set to suppress
> the UI banner about missing Redis. Add Redis only if you scale to multiple
> proxy replicas (see [What Needs Redis](https://docs.litellm.ai/docs/proxy/redis_requirements)).

## Volumes

| Host Path         | Container Path             | Description   |
| ----------------- | -------------------------- | ------------- |
| `./data/postgres` | `/var/lib/postgresql/data` | Database data |
| `./config.yaml`   | `/app/config.yaml`         | Proxy config  |

## Configuration

The proxy ships with a `config.yaml` containing production-recommended settings
(request timeout, JSON logging, batched spend writes). Models can be added either
in that file or through the Admin UI when `STORE_MODEL_IN_DB=True`.

To add models via `config.yaml`, extend the `model_list` section:

```yaml
model_list:
  - model_name: gpt-4o
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY
  - model_name: claude-sonnet
    litellm_params:
      model: anthropic/claude-sonnet-4-20250514
      api_key: os.environ/ANTHROPIC_API_KEY
```

Provider API keys are not automatically passed into the container. To use
`os.environ/<VAR_NAME>` references in `config.yaml`, add the variable to `.env`
**and** add a matching entry to the `litellm` service's `environment` block in
`docker-compose.yml`:

```yaml
environment:
  - OPENAI_API_KEY=${OPENAI_API_KEY:-}
  - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-}
```

## Usage

### OpenAI-compatible API

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer your-master-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Links

- [LiteLLM Website](https://litellm.ai/)
- [Documentation](https://docs.litellm.ai/)
- [GitHub Repository](https://github.com/BerriAI/litellm)
