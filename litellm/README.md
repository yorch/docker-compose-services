# LiteLLM

Unified API proxy for 100+ LLM providers (OpenAI, Anthropic, Azure, and more).

## Features

- Single API for all LLM providers
- Load balancing and fallbacks
- Request/response logging
- Budget management
- Rate limiting
- Prometheus metrics

## Quick Start

```bash
docker compose up -d
```

Access LiteLLM at `http://localhost:4000`

## Services

| Service      | Description                     |
| ------------ | ------------------------------- |
| `app`        | LiteLLM proxy                   |
| `db`         | PostgreSQL database             |
| `prometheus` | Metrics collection (Enterprise) |

## Environment Variables

| Variable             | Description                  | Required |
| -------------------- | ---------------------------- | -------- |
| `DATABASE_URL`       | PostgreSQL connection string | Yes      |
| `LITELLM_MASTER_KEY` | Admin API key                | Yes      |
| `LITELLM_SALT_KEY`   | Encryption salt              | Yes      |
| `STORE_MODEL_IN_DB`  | Store model config in DB     | -        |

## Volumes

| Host Path                 | Container Path                   | Description       |
| ------------------------- | -------------------------------- | ----------------- |
| `./data/postgres`         | `/var/lib/postgresql/data`       | Database data     |
| `./data/prometheus`       | `/prometheus`                    | Metrics data      |
| `./config/prometheus.yml` | `/etc/prometheus/prometheus.yml` | Prometheus config |

## Configuration

Create a `config.yaml` for model configuration:

```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: openai/gpt-4
      api_key: sk-...
  - model_name: claude-3
    litellm_params:
      model: anthropic/claude-3-opus-20240229
      api_key: sk-ant-...
```

## Usage

### OpenAI-compatible API

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer your-master-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Links

- [LiteLLM Website](https://litellm.ai/)
- [Documentation](https://docs.litellm.ai/)
- [GitHub Repository](https://github.com/BerriAI/litellm)
