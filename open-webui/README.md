# Open WebUI

Web interface for interacting with LLMs - ChatGPT-like UI for Ollama and OpenAI.

## Features

- Beautiful ChatGPT-style interface
- Support for Ollama and OpenAI APIs
- Conversation history
- Multiple model support
- File uploads and RAG
- User management

## Quick Start

```bash
docker compose up -d
```

Access Open WebUI at `http://localhost:3000`

## Environment Variables

| Variable                      | Description            | Required |
| ----------------------------- | ---------------------- | -------- |
| `WEBUI_SECRET_KEY`            | Session encryption key | Yes      |
| `WEBUI_SESSION_COOKIE_SECURE` | Use secure cookies     | -        |

### LLM Provider Configuration

| Variable          | Description    |
| ----------------- | -------------- |
| `OPENAI_API_KEY`  | OpenAI API key |
| `OLLAMA_BASE_URL` | Ollama API URL |

## Volumes

| Host Path      | Container Path      | Description      |
| -------------- | ------------------- | ---------------- |
| `./data/webui` | `/app/backend/data` | Application data |

## Connecting to Ollama

If running Ollama on the host machine:

```yaml
environment:
  - OLLAMA_BASE_URL=http://host.docker.internal:11434
```

If running Ollama in Docker on the same network:

```yaml
environment:
  - OLLAMA_BASE_URL=http://ollama:11434
```

## First-Time Setup

1. Access the web interface
2. Create an admin account (first user)
3. Configure your preferred LLM providers
4. Start chatting!

## Links

- [Open WebUI Website](https://openwebui.com/)
- [Documentation](https://docs.openwebui.com/)
- [GitHub Repository](https://github.com/open-webui/open-webui)
