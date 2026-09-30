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

The core refuses requests without `SUPERTOKENS_API_KEY` (`api-key` header), so exposing it
through Traefik does not let anyone else create users or sessions. The core is only called
by your backend, so you can also skip the Traefik overlay and reach it over a private
network.

## Services

| Service | Description         |
| ------- | ------------------- |
| `app`   | SuperTokens core    |
| `db`    | PostgreSQL database |

## Environment Variables

| Variable              | Description                                                 | Required |
| --------------------- | ----------------------------------------------------------- | -------- |
| `SUPERTOKENS_API_KEY` | Key your backend sends to the core (`openssl rand -hex 32`) | Yes      |
| `POSTGRES_PASSWORD`   | Database password (`openssl rand -hex 24`)                  | Yes      |
| `POSTGRES_USER`       | Database user (default `supertokens`)                       | No       |
| `POSTGRES_DB`         | Database name (default `supertokens`)                       | No       |
| `DOMAIN`              | Hostname Traefik routes to the core (Traefik only)          | Traefik  |
| `DEV_BIND_IP`         | Host interface for the dev port (default `127.0.0.1`)       | No       |

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
    apiKey: process.env.SUPERTOKENS_API_KEY,
  },
  // ... other config
});
```

## Links

- [SuperTokens Website](https://supertokens.com/)
- [Documentation](https://supertokens.com/docs/)
- [GitHub Repository](https://github.com/supertokens/supertokens-core)
