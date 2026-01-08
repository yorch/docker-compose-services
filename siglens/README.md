# SigLens

High-performance log aggregation and observability platform with 100x lower storage costs than Elasticsearch.

## Features

- Full-text log search and analytics
- Built-in SQL query support
- Elasticsearch/OpenSearch API compatibility
- Splunk SPL query language support
- Column-oriented storage with compression
- Real-time data ingestion
- Low memory footprint
- Prometheus metrics support
- Grafana integration

## Quick Start

1. Copy environment configuration:

```bash
cp .env.sample .env
```

2. Start the service:

```bash
docker compose up -d
```

Access SigLens UI at `http://localhost:5122`

## Ports

| Port   | Description         |
| ------ | ------------------- |
| `8081` | Ingestion API       |
| `5122` | Query server and UI |

## Environment Variables

| Variable      | Description               | Default |
| ------------- | ------------------------- | ------- |
| `INGEST_PORT` | Port for data ingestion   | `8081`  |
| `UI_PORT`     | Port for UI and query API | `5122`  |

## Volumes

| Host Path  | Container Path    | Description         |
| ---------- | ----------------- | ------------------- |
| `./data`   | `/siglens/data`   | Indexed log data    |
| `./logs`   | `/siglens/logs`   | SigLens server logs |
| `./config` | `/siglens/config` | Configuration files |

## Configuration

The main configuration is in `config/server.yaml`:

### Key Settings

```yaml
# Data retention
retentionHours: 360 # 15 days default

# Memory management
memoryLimits:
  lowMemoryMode: true
  maxUsagePercent: 80

# Query timeout
queryTimeoutSecs: 300

# TLS configuration
tls:
  enabled: false
  certificatePath: ''
  privateKeyPath: ''
```

## Data Ingestion

### Via Splunk HEC

```bash
curl -X POST http://localhost:8081/services/collector/event \
  -H "Authorization: Splunk your-token" \
  -H "Content-Type: application/json" \
  -d '{
    "event": {
      "message": "Application started",
      "severity": "info",
      "service": "web-app"
    }
  }'
```

### Via Elasticsearch Bulk API

```bash
curl -X POST http://localhost:8081/_bulk \
  -H "Content-Type: application/x-ndjson" \
  -d '
{"index":{"_index":"logs"}}
{"timestamp":"2024-01-01T12:00:00Z","message":"Error occurred","level":"error"}
'
```

### Via Fluent Bit

```ini
[OUTPUT]
    Name http
    Match *
    Host localhost
    Port 8081
    URI /elastic/_bulk
    Format json
    Json_date_key timestamp
    Json_date_format iso8601
```

### Via Logstash

```ruby
output {
  elasticsearch {
    hosts => ["http://localhost:8081"]
    index => "logs-%{+YYYY.MM.dd}"
  }
}
```

## Querying Data

### SQL Queries

```sql
SELECT timestamp, message, level
FROM logs
WHERE level = 'error'
AND timestamp > NOW() - INTERVAL '1 hour'
ORDER BY timestamp DESC
LIMIT 100
```

### SPL (Splunk) Queries

```spl
index=logs level=error
| stats count by service
| sort -count
```

### Elasticsearch Query DSL

```bash
curl -X POST http://localhost:5122/_search \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [
          {"match": {"level": "error"}},
          {"range": {"timestamp": {"gte": "now-1h"}}}
        ]
      }
    }
  }'
```

## Grafana Integration

1. Add SigLens as Elasticsearch datasource:
   - URL: `http://siglens:5122`
   - Version: `7.9.3`
   - Index pattern: `logs-*`

2. Create dashboard with log panels using Lucene query syntax

## Prometheus Metrics

SigLens exposes metrics at `http://localhost:5122/metrics`:

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'siglens'
    static_configs:
      - targets: ['localhost:5122']
```

## Performance Tips

- **Column Storage**: SigLens uses columnar storage for 10-100x compression
- **Memory Mode**: Enable `lowMemoryMode` for environments with <8GB RAM
- **Retention**: Adjust `retentionHours` based on disk space
- **Batch Ingestion**: Use bulk APIs for better throughput
- **Index Patterns**: Use time-based indices for better query performance

## Storage Estimates

| Log Rate   | Storage (30 days) | Memory Usage |
| ---------- | ----------------- | ------------ |
| 100 MB/day | ~3 GB             | 1-2 GB       |
| 1 GB/day   | ~30 GB            | 2-4 GB       |
| 10 GB/day  | ~300 GB           | 4-8 GB       |
| 100 GB/day | ~3 TB             | 8-16 GB      |

_Actual compression varies by log format and content_

## Troubleshooting

### Check service logs

```bash
docker compose logs -f siglens
```

### Verify ingestion

```bash
curl http://localhost:8081/health
```

### Check query server

```bash
curl http://localhost:5122/health
```

### Reset data

```bash
docker compose down
rm -rf data/ logs/
docker compose up -d
```

## Links

- [SigLens Website](https://siglens.com/)
- [Documentation](https://siglens.com/docs/)
- [GitHub Repository](https://github.com/siglens/siglens)
- [Docker Hub](https://hub.docker.com/r/siglens/siglens)
- [Query Language Guide](https://siglens.com/docs/query-language/)
