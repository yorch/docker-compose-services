# Sim Studio AI

AI simulation and workflow studio platform.

## Features

- Visual workflow builder
- AI agent simulations
- Multi-model support
- Workflow automation
- Real-time collaboration

## Quick Start

```bash
docker compose up -d
```

## Environment Variables

| Variable             | Description               | Required |
| -------------------- | ------------------------- | -------- |
| `DATABASE_URL`       | PostgreSQL connection URL | Yes      |
| `BETTER_AUTH_SECRET` | Authentication secret     | Yes      |
| `BETTER_AUTH_URL`    | Application URL           | Yes      |
| `ENCRYPTION_KEY`     | Data encryption key       | Yes      |

### LLM Provider API Keys

| Variable                       | Description                |
| ------------------------------ | -------------------------- |
| `OPENAI_API_KEY`               | OpenAI API key             |
| `ANTHROPIC_API_KEY`            | Anthropic (Claude) API key |
| `GOOGLE_GENERATIVE_AI_API_KEY` | Google AI API key          |

## Volumes

| Host Path         | Container Path             | Description   |
| ----------------- | -------------------------- | ------------- |
| `./data/postgres` | `/var/lib/postgresql/data` | Database data |

## Usage

1. Access the web interface
2. Create a new simulation
3. Add AI agents with different roles
4. Configure workflows
5. Run simulations

## Links

- [GitHub Repository](https://github.com/sim-studio-ai/sim-studio)
