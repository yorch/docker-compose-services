# WAHA

WhatsApp HTTP API - Open-source WhatsApp API that connects to WhatsApp via web interface.

## Features

- Send and receive messages
- Media support (images, videos, documents)
- Group management
- Contact management
- Message webhooks
- Multiple WhatsApp sessions
- Swagger API documentation
- Web dashboard

## Quick Start

```bash
docker compose up -d
```

Access the dashboard at `http://localhost:3000`

## Services

| Service | Description          |
| ------- | -------------------- |
| `app`   | WAHA API application |

## Environment Variables

| Variable                    | Description              | Required |
| --------------------------- | ------------------------ | -------- |
| `WAHA_API_KEY`              | API authentication key   | Yes      |
| `WAHA_DASHBOARD_USERNAME`   | Dashboard login username | Yes      |
| `WAHA_DASHBOARD_PASSWORD`   | Dashboard login password | Yes      |
| `WHATSAPP_SWAGGER_USERNAME` | Swagger UI username      | No       |
| `WHATSAPP_SWAGGER_PASSWORD` | Swagger UI password      | No       |

## Volumes

| Host Path | Container Path | Description              |
| --------- | -------------- | ------------------------ |
| `./data`  | `/app/data`    | Session and storage data |

## API Usage

### Send Text Message

```bash
curl -X POST http://localhost:3000/api/sendText \
  -H "X-Api-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "session": "default",
    "chatId": "1234567890@c.us",
    "text": "Hello from WAHA!"
  }'
```

### Send Image

```bash
curl -X POST http://localhost:3000/api/sendImage \
  -H "X-Api-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "session": "default",
    "chatId": "1234567890@c.us",
    "file": {
      "url": "https://example.com/image.jpg",
      "caption": "Image caption"
    }
  }'
```

### Start Session

```bash
curl -X POST http://localhost:3000/api/sessions/start \
  -H "X-Api-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "default",
    "config": {
      "webhooks": [
        {
          "url": "https://your-webhook.com/waha",
          "events": ["message"]
        }
      ]
    }
  }'
```

## Webhooks

Configure webhooks to receive real-time events:

```json
{
  "event": "message",
  "session": "default",
  "payload": {
    "id": "message-id",
    "from": "1234567890@c.us",
    "body": "Message text",
    "timestamp": 1234567890
  }
}
```

## Integration Examples

### Python

```python
import requests

API_URL = "http://localhost:3000/api"
API_KEY = "your-api-key"

headers = {
    "X-Api-Key": API_KEY,
    "Content-Type": "application/json"
}

# Send message
response = requests.post(
    f"{API_URL}/sendText",
    headers=headers,
    json={
        "session": "default",
        "chatId": "1234567890@c.us",
        "text": "Hello!"
    }
)
```

### Node.js

```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: 'http://localhost:3000/api',
  headers: {
    'X-Api-Key': 'your-api-key',
    'Content-Type': 'application/json',
  },
});

// Send message
await api.post('/sendText', {
  session: 'default',
  chatId: '1234567890@c.us',
  text: 'Hello!',
});
```

## Links

- [WAHA Website](https://waha.devlike.pro/)
- [Documentation](https://waha.devlike.pro/docs/)
- [GitHub Repository](https://github.com/devlikeapro/waha)
- [Docker Hub](https://hub.docker.com/r/devlikeapro/waha)
