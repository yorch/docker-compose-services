# SuperTokens

Open-source authentication solution.

## Features

- Session management
- Email/password authentication
- Social login (OAuth)
- Passwordless authentication
- Multi-tenancy support
- Self-hosted

## Quick Start

```bash
docker compose up -d
```

## Services

| Service       | Description         |
| ------------- | ------------------- |
| `supertokens` | SuperTokens core    |
| `postgres`    | PostgreSQL database |

## Environment Variables

| Variable                    | Description                  | Required |
| --------------------------- | ---------------------------- | -------- |
| `POSTGRESQL_CONNECTION_URI` | PostgreSQL connection string | Yes      |
| `API_KEYS`                  | API keys for core access     | -        |

### Database Configuration

| Variable                   | Description       |
| -------------------------- | ----------------- |
| `POSTGRESQL_HOST`          | Database host     |
| `POSTGRESQL_PORT`          | Database port     |
| `POSTGRESQL_USER`          | Database user     |
| `POSTGRESQL_PASSWORD`      | Database password |
| `POSTGRESQL_DATABASE_NAME` | Database name     |

## Ports

| Port   | Description          |
| ------ | -------------------- |
| `3567` | SuperTokens Core API |

## Volumes

| Host Path         | Container Path             | Description   |
| ----------------- | -------------------------- | ------------- |
| `./data/postgres` | `/var/lib/postgresql/data` | Database data |

## Integration

Install the SuperTokens SDK in your application:

```bash
# Node.js
npm install supertokens-node

# Python
pip install supertokens-python
```

Configure your backend to connect to the core:

```javascript
SuperTokens.init({
  supertokens: {
    connectionURI: 'http://localhost:3567',
  },
  // ... other config
});
```

## Links

- [SuperTokens Website](https://supertokens.com/)
- [Documentation](https://supertokens.com/docs/)
- [GitHub Repository](https://github.com/supertokens/supertokens-core)
