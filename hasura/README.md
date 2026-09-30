# Hasura

Instant GraphQL APIs over PostgreSQL and other databases.

## Features

- Auto-generated GraphQL APIs from database schema
- Real-time subscriptions
- Role-based access control
- Remote schemas and actions
- Event triggers and scheduled events
- Multi-database support

## Quick Start

```bash
# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

Access the Hasura Console at `http://localhost:8080` and enter `HASURA_GRAPHQL_ADMIN_SECRET`
when asked. API clients send it as the `x-hasura-admin-secret` header (or use JWT/webhook
auth for end users).

## Services

| Service                | Description              |
| ---------------------- | ------------------------ |
| `graphql-engine`       | Hasura GraphQL Engine    |
| `data-connector-agent` | Multi-database connector |
| `db`                   | PostgreSQL database      |

## Environment Variables

| Variable                        | Description                                           | Default     |
| ------------------------------- | ----------------------------------------------------- | ----------- |
| `HASURA_GRAPHQL_ADMIN_SECRET`   | Admin secret for the console and API (**required**)   | -           |
| `POSTGRES_PASSWORD`             | Database password (**required**)                      | -           |
| `POSTGRES_USER` / `POSTGRES_DB` | Database user / name                                  | `hasura`    |
| `HASURA_GRAPHQL_DEV_MODE`       | Verbose errors; enable only locally                   | `false`     |
| `HASURA_GRAPHQL_ENABLE_CONSOLE` | Serve the web console                                 | `true`      |
| `DEV_BIND_IP`                   | Host interface for the dev Postgres / connector ports | `127.0.0.1` |

The metadata database and the default data source both point at the bundled `db`.

### Logging

| Variable                           | Description         |
| ---------------------------------- | ------------------- |
| `HASURA_GRAPHQL_ENABLED_LOG_TYPES` | Log types to enable |

## Data Connectors

The included data connector agent supports:

- Amazon Athena
- MariaDB
- MySQL
- Oracle
- Snowflake

## Volumes

| Host Path         | Container Path             | Description   |
| ----------------- | -------------------------- | ------------- |
| `./data/postgres` | `/var/lib/postgresql/data` | Database data |

## Links

- [Hasura Website](https://hasura.io/)
- [Documentation](https://hasura.io/docs/)
- [Tutorials](https://hasura.io/learn/)
- [GitHub Repository](https://github.com/hasura/graphql-engine)
