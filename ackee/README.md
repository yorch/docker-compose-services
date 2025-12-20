# Ackee

Self-hosted, Node.js based analytics tool for those who care about privacy.

## Features

- Privacy-focused analytics
- No cookies required
- Lightweight tracking script
- Beautiful dashboard
- Detailed referrer tracking
- MongoDB backend

## Quick Start

```bash
docker compose up -d
```

Access Ackee at `http://localhost:3000`

## Services

| Service | Description       |
| ------- | ----------------- |
| `app`   | Ackee application |
| `mongo` | MongoDB database  |

## Environment Variables

| Variable             | Description            | Required |
| -------------------- | ---------------------- | -------- |
| `ACKEE_USERNAME`     | Admin username         | Yes      |
| `ACKEE_PASSWORD`     | Admin password         | Yes      |
| `ACKEE_ALLOW_ORIGIN` | Allowed origins (CORS) | Yes      |
| `ACKEE_TTL`          | Token time-to-live     | -        |

## Volumes

| Host Path      | Container Path | Description  |
| -------------- | -------------- | ------------ |
| `./data/mongo` | `/data/db`     | MongoDB data |

## Website Integration

Add to your website:

```html
<script
  async
  src="https://your-ackee-instance/tracker.js"
  data-ackee-server="https://your-ackee-instance"
  data-ackee-domain-id="your-domain-id"
></script>
```

## Links

- [Ackee Website](https://ackee.electerious.com/)
- [Documentation](https://docs.ackee.electerious.com/)
- [GitHub Repository](https://github.com/electerious/Ackee)
