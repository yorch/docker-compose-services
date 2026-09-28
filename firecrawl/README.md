# Firecrawl

Turn entire websites into LLM-ready markdown or structured data. Scrape, crawl and extract with a single API.

## Features

- Web scraping and crawling
- Markdown conversion
- Structured data extraction
- JavaScript rendering (Playwright)
- Rate limiting
- Queue-based processing

## Quick Start

```bash
cp .env.sample .env  # then set POSTGRES_PASSWORD and BULL_AUTH_KEY

# Dev - API on http://localhost:3002
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS, restricted to FIRECRAWL_ALLOWED_IPS
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

The self-hosted API has **no authentication** (`USE_DB_AUTHENTICATION=false`), so a
public route would be an open scraping proxy. The Traefik overlay therefore only admits
the source ranges in `FIRECRAWL_ALLOWED_IPS` (others get 403). It uses an IP allowlist
rather than basic auth because SDK clients send their own `Authorization: Bearer`
header, which basic auth would replace.

## Services

| Service              | Description                                                   |
| -------------------- | ------------------------------------------------------------- |
| `api`                | API and all workers, run by one "harness" process (port 3002) |
| `playwright-service` | Headless browser for JavaScript-rendered pages                |
| `nuq-postgres`       | Job queue (ephemeral, like upstream: no volume)               |
| `rabbitmq`           | Queue notifications                                           |
| `redis`              | Rate limiting and caching                                     |

This mirrors upstream's `docker-compose.yaml` with published, pinned images. Upstream's
experimental FoundationDB queue (`NUQ_BACKEND=fdb`) is not included.

## Environment Variables

| Variable                  | Description                                                 | Required |
| ------------------------- | ----------------------------------------------------------- | -------- |
| `DOMAIN`                  | Hostname Traefik routes to the API (Traefik only)           | Traefik  |
| `FIRECRAWL_ALLOWED_IPS`   | Comma-separated CIDRs allowed through Traefik               | Traefik  |
| `POSTGRES_PASSWORD`       | Queue database password (`openssl rand -hex 24`)            | Yes      |
| `BULL_AUTH_KEY`           | Secret path of the queue admin panel, `/admin/<key>/queues` | Yes      |
| `PORT`                    | Dev host port (default `3002`)                              | No       |
| `USE_DB_AUTHENTICATION`   | Supabase-backed API keys; needs the `SUPABASE_*` variables  | No       |
| `LOGGING_LEVEL`           | `debug`, `info`, `warn`, `error`                            | No       |
| `BLOCK_MEDIA`             | Skip images/video/audio while scraping                      | No       |
| `SELF_HOSTED_WEBHOOK_URL` | Webhook the instance posts job events to                    | No       |

Throughput knobs (`NUM_WORKERS_PER_QUEUE`, `CRAWL_CONCURRENT_REQUESTS`,
`MAX_CONCURRENT_JOBS`, `BROWSER_POOL_SIZE`) are listed in `.env.sample`.

### LLM Configuration (Optional)

Enables JSON-format scrapes and `/extract`.

| Variable               | Description                  |
| ---------------------- | ---------------------------- |
| `OPENAI_API_KEY`       | OpenAI API key               |
| `OPENAI_BASE_URL`      | Custom OpenAI-compatible URL |
| `MODEL_NAME`           | Model name for extraction    |
| `MODEL_EMBEDDING_NAME` | Embedding model              |
| `OLLAMA_BASE_URL`      | Ollama server URL            |

### Proxy Configuration (Optional)

| Variable         | Description      |
| ---------------- | ---------------- |
| `PROXY_SERVER`   | Proxy server URL |
| `PROXY_USERNAME` | Proxy username   |
| `PROXY_PASSWORD` | Proxy password   |

### Search (Optional)

`/search` uses Google directly unless you point it at a SearXNG instance with JSON
output enabled:

| Variable             | Description         |
| -------------------- | ------------------- |
| `SEARXNG_ENDPOINT`   | SearXNG endpoint    |
| `SEARXNG_ENGINES`    | Engines to query    |
| `SEARXNG_CATEGORIES` | Categories to query |

## API Usage

```bash
# Scrape a URL
curl -X POST http://localhost:3002/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com", "formats": ["markdown"]}'

# Crawl a website
curl -X POST http://localhost:3002/v1/crawl \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com", "limit": 10}'
```

SDKs work unchanged: point them at your URL and pass any API key string.

## Links

- [Firecrawl Website](https://www.firecrawl.dev/)
- [Self-Hosting Guide](https://github.com/firecrawl/firecrawl/blob/main/SELF_HOST.md)
- [GitHub Repository](https://github.com/firecrawl/firecrawl)
