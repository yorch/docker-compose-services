# Wyze Bridge

RTSP bridge for Wyze cameras - view your cameras in any RTSP-compatible viewer.

## Features

- RTSP stream conversion
- Support for Wyze Cam v1/v2/v3/Pan
- HLS streaming
- Motion detection webhooks
- Multi-camera support
- Low latency streaming

## Quick Start

```bash
docker compose up -d
```

## Environment Variables

| Variable        | Description           | Required |
| --------------- | --------------------- | -------- |
| `WYZE_EMAIL`    | Wyze account email    | Yes      |
| `WYZE_PASSWORD` | Wyze account password | Yes      |

### Optional Settings

| Variable       | Description               | Default |
| -------------- | ------------------------- | ------- |
| `TOTP_KEY`     | 2FA TOTP key              | -       |
| `WB_AUTH`      | Basic auth (user:pass)    | -       |
| `QUALITY`      | Stream quality (SD/HD)    | `HD`    |
| `ENABLE_AUDIO` | Enable audio streaming    | `true`  |
| `SNAPSHOT`     | Snapshot refresh interval | -       |
| `RECORD_ALL`   | Record all streams        | `false` |

### Network Modes

| Variable   | Description                |
| ---------- | -------------------------- |
| `NET_MODE` | Network mode (LAN/P2P/ANY) |
| `LLHLS`    | Enable Low-Latency HLS     |

## Ports

| Port   | Description |
| ------ | ----------- |
| `1935` | RTMP        |
| `8554` | RTSP        |
| `8888` | HLS         |
| `8889` | WebRTC      |
| `5000` | Web UI      |

## Volumes

| Host Path      | Container Path | Description |
| -------------- | -------------- | ----------- |
| `./data`       | `/tokens`      | Auth tokens |
| `./recordings` | `/record`      | Recordings  |

## Stream URLs

Access your cameras at:

- **RTSP**: `rtsp://localhost:8554/camera-name`
- **HLS**: `http://localhost:8888/camera-name/stream.m3u8`
- **WebRTC**: `http://localhost:5000/camera-name`

## Home Assistant Integration

Add to your `configuration.yaml`:

```yaml
camera:
  - platform: generic
    name: Wyze Cam
    stream_source: rtsp://wyze-bridge:8554/camera-name
    still_image_url: http://wyze-bridge:5000/api/camera-name/photo.jpg
```

## Links

- [GitHub Repository](https://github.com/mrlt8/docker-wyze-bridge)
- [Wyze Website](https://www.wyze.com/)
