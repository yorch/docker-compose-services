# Collection of services running with `docker-compose`

## Run a service

```bash
docker compose up -d
```

If a service needs to run for Traefik, use:

```bash
task run-for-traefik
```

This requires `Task` to be installed: <https://taskfile.dev/installation/>

## Services

<!-- START SERVICES -->
| Service | Description |
| --- | --- |
| [Ackee](./ackee) | Self-hosted, Node.js based analytics tool for those who care about privacy. |
| [Anything Llm](./anything-llm) | An all-in-one AI application for local LLM chat with documents, embedding, and vector database management. |
| [Auto Update](./auto-update) | Automated Docker container updater that monitors and updates running containers. |
| [Couchdb](./couchdb) | Apache CouchDB - a NoSQL document database with HTTP API and built-in replication. |
| [Countly](./countly) | Product analytics platform for mobile, web, and desktop applications. |
| [Datalust Seq](./datalust-seq) | Centralized structured log server with powerful search and analysis capabilities. |
| [Docker Registry](./docker-registry) | Private Docker registry with web UI and authentication. |
| [Dokku](./dokku) | Docker-powered PaaS that helps you build and manage the lifecycle of applications. |
| [Errbit](./errbit) | Open-source error catcher compatible with the Airbrake API for exception tracking. |
| [Firecrawl](./firecrawl) | Turn entire websites into LLM-ready markdown or structured data. Scrape, crawl and extract with a single API. |
| [Flowise](./flowise) | Low-code/no-code LLM app builder with drag-and-drop UI for AI workflows. |
| [Ghost](./ghost) | Professional publishing platform and headless CMS for blogs and publications. |
| [Gitea](./gitea) | Self-hosted Git service similar to GitHub/GitLab with a lightweight footprint. |
| [Github Actions Runner](./github-actions-runner) | Self-hosted runner for GitHub Actions workflows. |
| [Glitchtip](./glitchtip) | Open-source error tracking compatible with Sentry SDKs. Lightweight alternative to Sentry. |
| [Grafana](./grafana) | Open-source analytics and monitoring dashboard platform. |
| [Hasura](./hasura) | Instant GraphQL APIs over PostgreSQL and other databases. |
| [Heimdall](./heimdall) | Application dashboard and launcher for organizing your web applications. |
| [Hoarder](./hoarder) | Bookmark manager with AI-powered tagging and full-text search. |
| [Honeygain](./honeygain) | Passive income application that shares unused internet bandwidth. |
| [Influxdb2](./influxdb2) | Time-series database for metrics, events, and analytics. |
| [Jaeger](./jaeger) | Distributed tracing system for microservices observability. |
| [Joplin](./joplin) | Self-hosted sync server for Joplin, an open-source note-taking application. |
| [Kafka](./kafka) | Distributed event streaming platform with KRaft mode (no Zookeeper required). |
| [Linkwarden](./linkwarden) | Self-hosted bookmark manager with full-text search capabilities. |
| [Litellm](./litellm) | Unified API proxy for 100+ LLM providers (OpenAI, Anthropic, Azure, and more). |
| [Logflare](./logflare) | Log ingestion and analytics service (Supabase's logging backend). |
| [Lychee](./lychee) | Self-hosted photo management and sharing platform. |
| [Minecraft Server](./minecraft-server) | Minecraft Java Edition game server using itzg/minecraft-server image. |
| [Mosquitto](./mosquitto) | Lightweight MQTT message broker. |
| [N8n](./n8n) | Workflow automation platform - open-source alternative to Zapier/Make. |
| [Nocodb](./nocodb) | Open-source Airtable alternative - turns any database into a smart spreadsheet. |
| [Octobot](./octobot) | Open-source cryptocurrency trading bot with backtesting capabilities. |
| [Odoo](./odoo) | Open-source ERP and business applications suite. |
| [One Dev](./one-dev) | Self-hosted Git server with built-in CI/CD capabilities. |
| [Open Webui](./open-webui) | Web interface for interacting with LLMs - ChatGPT-like UI for Ollama and OpenAI. |
| [Openui](./openui) | AI-powered UI generation tool by Weights & Biases. |
| [Plausible Analytics](./plausible-analytics) | Privacy-friendly, lightweight website analytics. |
| [Pocketbase](./pocketbase) | Open-source backend in a single file. |
| [Portainer](./portainer) | Docker and Kubernetes management GUI. |
| [Redpanda](./redpanda) | Kafka-compatible streaming data platform - no ZooKeeper required. |
| [Shlink](./shlink) | Self-hosted URL shortener. |
| [Siglens](./siglens) | High-performance log aggregation and observability platform with 100x lower storage costs than Elasticsearch. |
| [Sim Studio Ai](./sim-studio-ai) | AI simulation and workflow studio platform. |
| [Supertokens](./supertokens) | Open-source authentication solution. |
| [Telegraf](./telegraf) | Plugin-driven server agent for collecting and reporting metrics. |
| [Timescale](./timescale) | PostgreSQL for time-series data. |
| [Traefik](./traefik) | Modern HTTP reverse proxy and load balancer (v2.x). |
| [Traefik3](./traefik3) | Modern HTTP reverse proxy and load balancer (v3.x). |
| [Vaultwarden](./vaultwarden) | Lightweight Bitwarden-compatible password manager server. |
| [Waha](./waha) | WhatsApp HTTP API - Open-source WhatsApp API that connects to WhatsApp via web interface. |
| [Watchtower](./watchtower) | Automated Docker container updates. |
| [Wg Dashboard](./wg-dashboard) | Web-based dashboard for WireGuard VPN management. |
| [Wg Easy](./wg-easy) | Easy-to-use WireGuard VPN with web UI. |
| [Wg Portal](./wg-portal) | Enterprise-grade WireGuard VPN management portal. |
| [Wordpress](./wordpress) | Popular content management system (CMS) for websites and blogs. |
| [Wyze Bridge](./wyze-bridge) | RTSP bridge for Wyze cameras - view your cameras in any RTSP-compatible viewer. |
<!-- END SERVICES -->
