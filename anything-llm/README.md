# AnythingLLM

An all-in-one AI application for local LLM chat with documents, embedding, and vector database management.

## Features

- Chat with documents using local or cloud LLMs
- Built-in vector database for document embeddings
- Support for multiple LLM providers
- Document ingestion and processing

## Quick Start

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

## Configuration

Configuration is managed through a mounted `.env` file at `./data/.env`.

### Environment Variables

| Variable      | Description                    | Default               |
| ------------- | ------------------------------ | --------------------- |
| `STORAGE_DIR` | Storage directory for app data | `/app/server/storage` |

## Volumes

| Host Path     | Container Path        | Description                    |
| ------------- | --------------------- | ------------------------------ |
| `./data/app`  | `/app/server/storage` | Application data and documents |
| `./data/.env` | `/app/server/.env`    | Configuration file             |

## Links

- [GitHub Repository](https://github.com/Mintplex-Labs/anything-llm)
- [Documentation](https://docs.useanything.com/)
