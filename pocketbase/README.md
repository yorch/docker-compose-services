# PocketBase

Open-source backend in a single file.

Provides a real-time database, authentication, and file storage. It is designed to be lightweight and easy to use, making it a great choice for developers looking to quickly build and deploy applications.

## Features

- Realtime database
- Authentication (email, OAuth)
- File storage
- Admin dashboard
- REST API
- Realtime subscriptions

## Quick Start

```bash
docker compose up -d
```

Access the admin UI at `http://localhost:8080/_/`

## Environment Variables

| Variable | Description | Default |
| -------- | ----------- | ------- |
| `PORT`   | Server port | `8080`  |

## Volumes

| Host Path | Container Path | Description          |
| --------- | -------------- | -------------------- |
| `./data`  | `/app/data`    | All application data |

### Data Directory Structure

```
data/
├── pb_data/         # Database and internal files
└── pb_public/       # Public static files
```

## First-Time Setup

1. It will generate an installer link that should be automatically opened in the browser to set up your first superuser account. If not, access the admin UI at `/_/`.
2. Create your admin account (or use CLI: `./pocketbase superuser create EMAIL PASS`)
3. Define collections (tables)
4. Set up authentication providers

## Collections

Create collections in the admin UI or via API:

```bash
# Example: Create a collection via API
curl -X POST http://localhost:8080/api/collections \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "posts",
    "type": "base",
    "schema": [
      {"name": "title", "type": "text"},
      {"name": "content", "type": "text"}
    ]
  }'
```

## SDK Usage

```javascript
import PocketBase from 'pocketbase';

const pb = new PocketBase('http://localhost:8080');

// Authenticate
await pb.collection('users').authWithPassword('email@example.com', 'password');

// Query records
const records = await pb.collection('posts').getList(1, 20);

// Create record
await pb.collection('posts').create({ title: 'Hello', content: 'World' });
```

## Hooks and Extensions

Place JavaScript/TypeScript files in `pb_hooks/` for server-side hooks.

## Links

- [PocketBase Website](https://pocketbase.io/)
- [Documentation](https://pocketbase.io/docs/)
- [GitHub Repository](https://github.com/pocketbase/pocketbase)
