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
docker compose up -d
```

## Services

| Service              | Description              |
| -------------------- | ------------------------ |
| `api`                | Firecrawl API server     |
| `worker`             | Background job processor |
| `playwright-service` | Browser automation       |
| `redis`              | Queue and caching        |

## Environment Variables

| Variable                | Description                | Required |
| ----------------------- | -------------------------- | -------- |
| `TEST_API_KEY`          | API key for authentication | -        |
| `USE_DB_AUTHENTICATION` | Enable database auth       | -        |

### LLM Configuration (Optional)

| Variable          | Description                  |
| ----------------- | ---------------------------- |
| `OPENAI_API_KEY`  | OpenAI API key               |
| `OPENAI_BASE_URL` | Custom OpenAI-compatible URL |
| `MODEL_NAME`      | Model name for extraction    |
| `OLLAMA_BASE_URL` | Ollama server URL            |

### Proxy Configuration (Optional)

| Variable         | Description      |
| ---------------- | ---------------- |
| `PROXY_SERVER`   | Proxy server URL |
| `PROXY_USERNAME` | Proxy username   |
| `PROXY_PASSWORD` | Proxy password   |

### Search Engines (Optional)

| Variable            | Description      |
| ------------------- | ---------------- |
| `SERPER_API_KEY`    | Serper API key   |
| `SEARCHAPI_API_KEY` | SearchAPI key    |
| `SEARXNG_ENDPOINT`  | SearXNG endpoint |

## API Usage

```bash
# Scrape a URL
curl -X POST http://localhost:3002/v0/scrape \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# Crawl a website
curl -X POST http://localhost:3002/v0/crawl \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com", "limit": 10}'
```

## Links

- [Firecrawl Website](https://www.firecrawl.dev/)
- [Self-Hosting Guide](https://github.com/mendableai/firecrawl/blob/main/SELF_HOST.md)
- [GitHub Repository](https://github.com/mendableai/firecrawl)
