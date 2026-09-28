# Datalust Seq

Centralized structured log server with powerful search and analysis capabilities.

## Features

- Structured log ingestion
- Full-text search with filtering
- Real-time log streaming
- Dashboards and alerts
- SQL-style queries
- Retention policies

## Quick Start

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

Access the web UI at `http://localhost:8080` (dev) and sign in as `admin` with
`SEQ_FIRSTRUN_ADMINPASSWORD`; Seq asks for a new password at the first login. Port
`5341` is ingestion-only and does not serve the UI or API.

## Environment Variables

| Variable                     | Description                                                | Required |
| ---------------------------- | ---------------------------------------------------------- | -------- |
| `DOMAIN`                     | Hostname Traefik routes to Seq (Traefik only)              | Traefik  |
| `SEQ_FIRSTRUN_ADMINPASSWORD` | Initial `admin` password, used only when `./data` is empty | Yes      |

Seq 2025.2 and later refuse to initialise a new instance without an admin password (or
an explicit opt-out of authentication), so compose fails fast if it is unset.

## Volumes

| Host Path | Container Path | Description                   |
| --------- | -------------- | ----------------------------- |
| `./data`  | `/data`        | Log storage and configuration |

## Ingestion

### Serilog (.NET)

```csharp
Log.Logger = new LoggerConfiguration()
    .WriteTo.Seq("http://seq:5341")
    .CreateLogger();
```

### HTTP API

```bash
curl -X POST http://localhost:5341/api/events/raw \
  -H "Content-Type: application/json" \
  -d '{"@t":"2024-01-01T00:00:00Z","@mt":"Hello, {Name}!","Name":"World"}'
```

## Links

- [Seq Website](https://datalust.co/seq)
- [Documentation](https://docs.datalust.co/docs)
- [Docker Hub](https://hub.docker.com/r/datalust/seq)
