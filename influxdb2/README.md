# InfluxDB 2

Time-series database for metrics, events, and analytics.

## Features

- High-performance time-series storage
- Flux query language
- Built-in dashboards and visualization
- Alerting and notifications
- Data retention policies
- API and client libraries

## Quick Start

```bash
docker compose up -d
```

Access the InfluxDB UI at `http://localhost:8086`

## Environment Variables

| Variable                           | Description               | Default        |
| ---------------------------------- | ------------------------- | -------------- |
| `DOCKER_INFLUXDB_INIT_MODE`        | Initialization mode       | `setup`        |
| `DOCKER_INFLUXDB_INIT_USERNAME`    | Initial admin username    | -              |
| `DOCKER_INFLUXDB_INIT_PASSWORD`    | Initial admin password    | -              |
| `DOCKER_INFLUXDB_INIT_ORG`         | Initial organization name | -              |
| `DOCKER_INFLUXDB_INIT_BUCKET`      | Initial bucket name       | -              |
| `DOCKER_INFLUXDB_INIT_RETENTION`   | Data retention period     | -              |
| `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` | API admin token           | Auto-generated |

## Volumes

| Host Path | Container Path       | Description      |
| --------- | -------------------- | ---------------- |
| `./data`  | `/var/lib/influxdb2` | Database storage |

## Configuration Example

```env
DOCKER_INFLUXDB_INIT_MODE=setup
DOCKER_INFLUXDB_INIT_USERNAME=admin
DOCKER_INFLUXDB_INIT_PASSWORD=secure-password
DOCKER_INFLUXDB_INIT_ORG=myorg
DOCKER_INFLUXDB_INIT_BUCKET=mybucket
DOCKER_INFLUXDB_INIT_RETENTION=30d
```

## Writing Data

### Line Protocol

```bash
curl -X POST "http://localhost:8086/api/v2/write?org=myorg&bucket=mybucket" \
  -H "Authorization: Token your-token" \
  -d "measurement,tag=value field=1.0"
```

### Telegraf

Use [Telegraf](../telegraf/) for collecting metrics from various sources.

## Links

- [InfluxDB Website](https://www.influxdata.com/)
- [Documentation](https://docs.influxdata.com/influxdb/v2/)
- [Flux Language](https://docs.influxdata.com/flux/)
- [GitHub Repository](https://github.com/influxdata/influxdb)
