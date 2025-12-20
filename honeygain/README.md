# Honeygain

Passive income application that shares unused internet bandwidth.

## Features

- Earn passive income by sharing bandwidth
- Minimal resource usage
- Cross-platform support

## Quick Start

1. Create an account at [Honeygain](https://www.honeygain.com/)
2. Configure your credentials
3. Start the container:

```bash
docker compose up -d
```

## Environment Variables

| Variable           | Description                | Required |
| ------------------ | -------------------------- | -------- |
| `ACCOUNT_EMAIL`    | Honeygain account email    | Yes      |
| `ACCOUNT_PASSWORD` | Honeygain account password | Yes      |
| `DEVICE_NAME`      | Device identifier          | Yes      |

## Configuration

Create a `.env` file:

```env
ACCOUNT_EMAIL=your-email@example.com
ACCOUNT_PASSWORD=your-password
DEVICE_NAME=docker-server
```

## Notes

- The container automatically accepts the Terms of Use
- Earnings depend on your location and network quality
- One account per IP address is recommended

## Links

- [Honeygain Website](https://www.honeygain.com/)
- [Dashboard](https://dashboard.honeygain.com/)
