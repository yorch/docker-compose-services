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
cp .env.sample .env  # then set POSTGRES_PASSWORD (and PGADMIN_DEFAULT_PASSWORD)

# Dev - publishes PostgreSQL on port 5432
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Dev + pgAdmin (opt-in profile) on 127.0.0.1:8080
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile pgadmin up -d
```

pgAdmin is never routed through Traefik (see AGENTS.md). To inspect a remote instance,
SSH-tunnel to it.

## Environment Variables

| Variable                   | Description                                       | Required |
| -------------------------- | ------------------------------------------------- | -------- |
| `POSTGRES_PASSWORD`        | Password for the `postgres` user                  | Yes      |
| `PGADMIN_DEFAULT_PASSWORD` | pgAdmin login password (dev overlay)              | Dev      |
| `PGADMIN_DEFAULT_EMAIL`    | pgAdmin login email (default `admin@example.com`) | No       |
| `DEV_BIND_IP`              | Host interface for pgAdmin (default `127.0.0.1`)  | No       |

## Ports

| Port   | Description                     |
| ------ | ------------------------------- |
| `5432` | PostgreSQL                      |
| `8080` | pgAdmin (dev profile, loopback) |

## Volumes

| Host Path          | Container Path               | Description   |
| ------------------ | ---------------------------- | ------------- |
| `./data/timescale` | `/home/postgres/pgdata/data` | Database data |

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
