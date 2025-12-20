# Hoarder (Karakeep)

Bookmark manager with AI-powered tagging and full-text search.

## Features

- AI-powered automatic tagging
- Full-text search with Meilisearch
- Webpage screenshots via headless Chrome
- Browser extensions available
- Self-hosted and privacy-focused

## Quick Start

```bash
docker compose up -d
```

## Services

| Service          | Description                     |
| ---------------- | ------------------------------- |
| `web`            | Main web application            |
| `chrome`         | Headless Chrome for screenshots |
| `meilisearch`    | Full-text search engine         |
| `meilisearch-ui` | Search engine admin UI          |

## Environment Variables

| Variable           | Description                    | Required |
| ------------------ | ------------------------------ | -------- |
| `NEXTAUTH_SECRET`  | Authentication secret          | Yes      |
| `NEXTAUTH_URL`     | Public URL                     | Yes      |
| `MEILI_MASTER_KEY` | Meilisearch authentication key | Yes      |
| `BROWSER_WEB_URL`  | Chrome connection URL          | Yes      |

### AI Features (Optional)

| Variable          | Description                   |
| ----------------- | ----------------------------- |
| `OPENAI_API_KEY`  | OpenAI API key for AI tagging |
| `DISABLE_SIGNUPS` | Disable new user registration |

## Volumes

| Host Path            | Container Path | Description      |
| -------------------- | -------------- | ---------------- |
| `./data/web`         | `/data`        | Application data |
| `./data/meilisearch` | `/meili_data`  | Search index     |

## Browser Extensions

Install the browser extension for easy bookmarking:

- [Chrome Extension](https://chrome.google.com/webstore/)
- [Firefox Add-on](https://addons.mozilla.org/firefox/)

## Links

- [GitHub Repository](https://github.com/karakeep-app/karakeep)
- [Documentation](https://docs.karakeep.app/)

> Note: This project was previously known as "Hoarder" and has been renamed to "Karakeep".
