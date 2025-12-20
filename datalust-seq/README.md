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
docker compose up -d
```

Access the web UI at `http://localhost:5341`

## Environment Variables

| Variable                         | Description                 | Default |
| -------------------------------- | --------------------------- | ------- |
| `ACCEPT_EULA`                    | Accept the EULA             | `Y`     |
| `SEQ_FIRSTRUN_ADMINPASSWORDHASH` | Initial admin password hash | -       |

### Generating Admin Password Hash

```bash
echo 'your-password' | docker run --rm -i datalust/seq config hash
```

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
