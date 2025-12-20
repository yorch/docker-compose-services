# OpenUI

AI-powered UI generation tool by Weights & Biases.

## Features

- Generate UI components from text descriptions
- Multiple LLM provider support
- Real-time preview
- Code export
- GitHub OAuth login

## Quick Start

```bash
docker compose up -d
```

## Environment Variables

| Variable             | Description            | Required |
| -------------------- | ---------------------- | -------- |
| `OPENUI_SESSION_KEY` | Session encryption key | Yes      |

### Authentication

| Variable               | Description                |
| ---------------------- | -------------------------- |
| `GITHUB_CLIENT_ID`     | GitHub OAuth client ID     |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth client secret |

### LLM Providers

| Variable            | Description                |
| ------------------- | -------------------------- |
| `OPENAI_API_KEY`    | OpenAI API key             |
| `ANTHROPIC_API_KEY` | Anthropic (Claude) API key |
| `GEMINI_API_KEY`    | Google Gemini API key      |
| `GROQ_API_KEY`      | Groq API key               |
| `COHERE_API_KEY`    | Cohere API key             |
| `MISTRAL_API_KEY`   | Mistral API key            |
| `OLLAMA_HOST`       | Ollama server URL          |
| `WANDB_API_KEY`     | Weights & Biases API key   |

## Volumes

| Host Path       | Container Path  | Description      |
| --------------- | --------------- | ---------------- |
| `./data/openui` | `/root/.openui` | Application data |

## Usage

1. Describe the UI you want to create
2. Select an LLM provider
3. Review the generated component
4. Export the code

## Links

- [OpenUI Website](https://openui.fly.dev/)
- [GitHub Repository](https://github.com/wandb/openui)
- [Weights & Biases](https://wandb.ai/)
