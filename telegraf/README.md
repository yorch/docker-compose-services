# Telegraf

Plugin-driven server agent for collecting and reporting metrics.

## Features

- 300+ input plugins
- Multiple output destinations
- Data transformation
- Prometheus integration
- Minimal memory footprint

## Quick Start

1. Create a `telegraf.conf` configuration file
2. Start the service:

```bash
docker compose up -d
```

## Configuration

Create `telegraf.conf`:

```toml
[agent]
  interval = "10s"
  round_interval = true
  flush_interval = "10s"

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "${INFLUX_TOKEN}"
  organization = "my-org"
  bucket = "my-bucket"

[[inputs.cpu]]
  percpu = true
  totalcpu = true

[[inputs.mem]]

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs"]

[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
```

## Environment Variables

| Variable       | Description        | Required |
| -------------- | ------------------ | -------- |
| `INFLUX_TOKEN` | InfluxDB API token | Yes      |

## Volumes

| Host Path              | Container Path                | Description    |
| ---------------------- | ----------------------------- | -------------- |
| `./telegraf.conf`      | `/etc/telegraf/telegraf.conf` | Configuration  |
| `/var/run/docker.sock` | `/var/run/docker.sock`        | Docker metrics |

## Common Input Plugins

| Plugin          | Description              |
| --------------- | ------------------------ |
| `cpu`           | CPU usage                |
| `mem`           | Memory usage             |
| `disk`          | Disk usage               |
| `docker`        | Docker metrics           |
| `net`           | Network stats            |
| `http_response` | HTTP endpoint monitoring |

## Common Output Plugins

| Plugin              | Description                 |
| ------------------- | --------------------------- |
| `influxdb_v2`       | InfluxDB 2.x                |
| `prometheus_client` | Prometheus metrics endpoint |
| `file`              | Write to file               |

## Links

- [Telegraf Website](https://www.influxdata.com/time-series-platform/telegraf/)
- [Documentation](https://docs.influxdata.com/telegraf/)
- [Plugin Directory](https://docs.influxdata.com/telegraf/latest/plugins/)
- [GitHub Repository](https://github.com/influxdata/telegraf)
