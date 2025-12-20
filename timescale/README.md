# TimescaleDB

PostgreSQL for time-series data.

## Features

- Full PostgreSQL compatibility
- Hypertables for time-series
- Continuous aggregates
- Compression
- Data retention policies
- Real-time analytics

## Quick Start

```bash
docker compose up -d
```

## Environment Variables

| Variable            | Description         | Required |
| ------------------- | ------------------- | -------- |
| `POSTGRES_PASSWORD` | PostgreSQL password | Yes      |
| `POSTGRES_USER`     | PostgreSQL user     | -        |
| `POSTGRES_DB`       | Default database    | -        |

## Ports

| Port   | Description |
| ------ | ----------- |
| `5432` | PostgreSQL  |

## Volumes

| Host Path | Container Path             | Description   |
| --------- | -------------------------- | ------------- |
| `./data`  | `/var/lib/postgresql/data` | Database data |

## Creating Hypertables

```sql
-- Create a regular table
CREATE TABLE conditions (
  time        TIMESTAMPTZ NOT NULL,
  location    TEXT NOT NULL,
  temperature DOUBLE PRECISION NULL
);

-- Convert to hypertable
SELECT create_hypertable('conditions', 'time');
```

## Continuous Aggregates

```sql
CREATE MATERIALIZED VIEW conditions_hourly
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', time) AS bucket,
       location,
       AVG(temperature) as avg_temp
FROM conditions
GROUP BY bucket, location;
```

## Data Retention

```sql
-- Add retention policy (keep 30 days)
SELECT add_retention_policy('conditions', INTERVAL '30 days');
```

## Compression

```sql
-- Enable compression
ALTER TABLE conditions SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'location'
);

-- Add compression policy
SELECT add_compression_policy('conditions', INTERVAL '7 days');
```

## Links

- [TimescaleDB Website](https://www.timescale.com/)
- [Documentation](https://docs.timescale.com/)
- [GitHub Repository](https://github.com/timescale/timescaledb)
