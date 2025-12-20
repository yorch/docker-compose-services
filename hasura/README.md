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
docker compose up -d
```

Access the Hasura Console at `http://localhost:8080`

## Services

| Service                | Description              |
| ---------------------- | ------------------------ |
| `graphql-engine`       | Hasura GraphQL Engine    |
| `data-connector-agent` | Multi-database connector |
| `db`                   | PostgreSQL database      |

## Environment Variables

| Variable                               | Description             | Default |
| -------------------------------------- | ----------------------- | ------- |
| `HASURA_GRAPHQL_METADATA_DATABASE_URL` | Metadata storage URL    | -       |
| `PG_DATABASE_URL`                      | Primary data source URL | -       |
| `HASURA_GRAPHQL_DEV_MODE`              | Enable development mode | `true`  |
| `HASURA_GRAPHQL_ENABLE_CONSOLE`        | Enable web console      | `true`  |
| `HASURA_GRAPHQL_ADMIN_SECRET`          | Admin secret key        | -       |

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
