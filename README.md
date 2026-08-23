# Collection of services running with `docker-compose`

## Run a service

Each service is a self-contained folder. Its compose files are **layered** — you pick
the exposure you want by combining the base file with one overlay:

| File                             | Purpose                                                            |
| -------------------------------- | ------------------------------------------------------------------ |
| `docker-compose.yml`             | The service itself. Usually publishes **no ports** on its own.     |
| `docker-compose.dev.yml`         | Publishes ports on `localhost`.                                    |
| `docker-compose.for-traefik.yml` | Routes through Traefik with HTTPS. Requires the `traefik` network. |

```bash
cd grafana
cp .env.sample .env   # then fill it in

# Dev - reachable at localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS on your domain
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

Running a bare `docker compose up -d` uses only the base file, so for most services
nothing is published and the UI is unreachable. Each service's README lists the exact
combinations it supports; a few ship a `run-*.sh` script for non-standard setups.

The Traefik overlay needs the shared external network to exist first:

```bash
./traefik3/setup.sh   # docker network create traefik
```

### Shortcuts

`Taskfile.yml` wraps the same combinations — run these from inside a service folder.
It requires [Task](https://taskfile.dev/installation/):

```bash
task run-dev            # pull + up -d, base + dev overlay
task stop-dev
task run-for-traefik    # pull + up -d, base + Traefik overlay
task stop-for-traefik
```

Or from the repo root, `./dc-dev.sh <service> <args...>` applies the dev overlay and
forwards anything else to `docker compose`:

```bash
./dc-dev.sh grafana logs -f
```

## Maintenance

```bash
yarn format          # prettier across the repo
yarn update-readme   # regenerate the services table below
```

## Services

<!-- START SERVICES -->

| Service                                          | Description                                                                                                                          |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| [Ackee](./ackee)                                 | Self-hosted, Node.js based analytics tool for those who care about privacy.                                                          |
| [Agentlogs](./agentlogs)                         | Self-hosted viewer for AI coding agent session logs, with OAuth login and AI-generated summaries.                                    |
| [Anything Llm](./anything-llm)                   | An all-in-one AI application for local LLM chat with documents, embedding, and vector database management.                           |
| [Auto Update](./auto-update)                     | Automated Docker container updater that monitors and updates running containers.                                                     |
| [Couchdb](./couchdb)                             | Apache CouchDB - a NoSQL document database with HTTP API and built-in replication.                                                   |
| [Countly](./countly)                             | Product analytics platform for mobile, web, and desktop applications.                                                                |
| [Datalust Seq](./datalust-seq)                   | Centralized structured log server with powerful search and analysis capabilities.                                                    |
| [Docker Registry](./docker-registry)             | Private Docker registry with web UI and authentication.                                                                              |
| [Dokku](./dokku)                                 | Docker-powered PaaS that helps you build and manage the lifecycle of applications.                                                   |
| [Errbit](./errbit)                               | Open-source error catcher compatible with the Airbrake API for exception tracking.                                                   |
| [Firecrawl](./firecrawl)                         | Turn entire websites into LLM-ready markdown or structured data. Scrape, crawl and extract with a single API.                        |
| [Flowise](./flowise)                             | Low-code/no-code LLM app builder with drag-and-drop UI for AI workflows.                                                             |
| [Ghost](./ghost)                                 | Professional publishing platform and headless CMS for blogs and publications.                                                        |
| [Gitea](./gitea)                                 | Self-hosted Git service similar to GitHub/GitLab with a lightweight footprint.                                                       |
| [Github Actions Runner](./github-actions-runner) | Self-hosted runner for GitHub Actions workflows.                                                                                     |
| [Glitchtip](./glitchtip)                         | Open-source error tracking compatible with Sentry SDKs. Lightweight alternative to Sentry.                                           |
| [Grafana](./grafana)                             | Open-source analytics and monitoring dashboard platform.                                                                             |
| [Hasura](./hasura)                               | Instant GraphQL APIs over PostgreSQL and other databases.                                                                            |
| [Heimdall](./heimdall)                           | Application dashboard and launcher for organizing your web applications.                                                             |
| [Hoarder](./hoarder)                             | Bookmark manager with AI-powered tagging and full-text search.                                                                       |
| [Honeygain](./honeygain)                         | Passive income application that shares unused internet bandwidth.                                                                    |
| [Influxdb2](./influxdb2)                         | Time-series database for metrics, events, and analytics.                                                                             |
| [Jaeger](./jaeger)                               | Distributed tracing system for microservices observability.                                                                          |
| [Joplin](./joplin)                               | Self-hosted sync server for Joplin, an open-source note-taking application.                                                          |
| [Kafka](./kafka)                                 | Distributed event streaming platform with KRaft mode (no Zookeeper required).                                                        |
| [Langfuse](./langfuse)                           | Open-source LLM observability platform for tracing, evaluating and debugging LLM applications.                                       |
| [Linkwarden](./linkwarden)                       | Self-hosted bookmark manager with full-text search capabilities.                                                                     |
| [Litellm](./litellm)                             | Unified API proxy for 100+ LLM providers (OpenAI, Anthropic, Azure, and more).                                                       |
| [Logflare](./logflare)                           | Log ingestion and analytics service (Supabase's logging backend).                                                                    |
| [Loki](./loki)                                   | Log aggregation system that indexes labels rather than log content, queried with LogQL.                                              |
| [Lychee](./lychee)                               | Self-hosted photo management and sharing platform.                                                                                   |
| [Minecraft Server](./minecraft-server)           | Minecraft Java Edition game server using itzg/minecraft-server image.                                                                |
| [Mosquitto](./mosquitto)                         | Lightweight MQTT message broker.                                                                                                     |
| [N8n](./n8n)                                     | Workflow automation platform - open-source alternative to Zapier/Make.                                                               |
| [Nocodb](./nocodb)                               | Open-source Airtable alternative - turns any database into a smart spreadsheet.                                                      |
| [Octobot](./octobot)                             | Open-source cryptocurrency trading bot with backtesting capabilities.                                                                |
| [Odoo](./odoo)                                   | Open-source ERP and business applications suite.                                                                                     |
| [One Dev](./one-dev)                             | Self-hosted Git server with built-in CI/CD capabilities.                                                                             |
| [Open Webui](./open-webui)                       | Web interface for interacting with LLMs - ChatGPT-like UI for Ollama and OpenAI.                                                     |
| [Openobserve](./openobserve)                     | Full-stack observability platform for logs, metrics and traces, with built-in dashboards and alerting.                               |
| [Openui](./openui)                               | AI-powered UI generation tool by Weights & Biases.                                                                                   |
| [Phoenix](./phoenix)                             | Open-source LLM tracing, evaluation and prompt experimentation, with a built-in OpenTelemetry collector.                             |
| [Plausible Analytics](./plausible-analytics)     | Privacy-friendly, lightweight website analytics.                                                                                     |
| [Pocketbase](./pocketbase)                       | Open-source backend in a single file.                                                                                                |
| [Portainer](./portainer)                         | Docker and Kubernetes management GUI.                                                                                                |
| [Qbittorrent](./qbittorrent)                     | Open-source BitTorrent client with web UI.                                                                                           |
| [Redpanda](./redpanda)                           | Kafka-compatible streaming data platform - no ZooKeeper required.                                                                    |
| [Rybbit](./rybbit)                               | Open-source, privacy-friendly web and product analytics — a cookieless Google Analytics replacement with no consent banner required. |
| [Shlink](./shlink)                               | Self-hosted URL shortener.                                                                                                           |
| [Siglens](./siglens)                             | High-performance log aggregation and observability platform with 100x lower storage costs than Elasticsearch.                        |
| [Sim Studio Ai](./sim-studio-ai)                 | AI simulation and workflow studio platform.                                                                                          |
| [Supertokens](./supertokens)                     | Open-source authentication solution.                                                                                                 |
| [Telegraf](./telegraf)                           | Plugin-driven server agent for collecting and reporting metrics.                                                                     |
| [Timescale](./timescale)                         | PostgreSQL for time-series data.                                                                                                     |
| [Traefik](./traefik)                             | Modern HTTP reverse proxy and load balancer (v2.x).                                                                                  |
| [Traefik3](./traefik3)                           | Modern HTTP reverse proxy and load balancer (v3.x).                                                                                  |
| [Vaultwarden](./vaultwarden)                     | Lightweight Bitwarden-compatible password manager server.                                                                            |
| [Waha](./waha)                                   | WhatsApp HTTP API - Open-source WhatsApp API that connects to WhatsApp via web interface.                                            |
| [Watchtower](./watchtower)                       | Automated Docker container updates.                                                                                                  |
| [Wg Dashboard](./wg-dashboard)                   | Web-based dashboard for WireGuard VPN management.                                                                                    |
| [Wg Easy](./wg-easy)                             | Easy-to-use WireGuard VPN with web UI.                                                                                               |
| [Wg Portal](./wg-portal)                         | Enterprise-grade WireGuard VPN management portal.                                                                                    |
| [Woodpecker](./woodpecker)                       | Lightweight container-native CI/CD engine driven by a `.woodpecker.yaml` in each repository.                                         |
| [Woodpecker Agent](./woodpecker-agent)           | Standalone Woodpecker CI agent that adds build capacity to an existing Woodpecker server.                                            |
| [Wordpress](./wordpress)                         | Popular content management system (CMS) for websites and blogs.                                                                      |
| [Wyze Bridge](./wyze-bridge)                     | RTSP bridge for Wyze cameras - view your cameras in any RTSP-compatible viewer.                                                      |
| [Zot](./zot)                                     | OCI-native container registry with a built-in web UI, CVE scanning and on-demand Docker Hub mirroring.                               |

<!-- END SERVICES -->
