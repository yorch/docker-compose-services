# OctoBot

Open-source cryptocurrency trading bot with backtesting capabilities.

## Features

- Automated trading strategies
- Backtesting with historical data
- Multiple exchange support
- Technical analysis indicators
- Web dashboard
- Tentacles (plugins) system

## Quick Start

```bash
docker compose up -d
```

Access the web UI at `http://localhost:5001`

## Volumes

| Host Path            | Container Path         | Description        |
| -------------------- | ---------------------- | ------------------ |
| `./data/backtesting` | `/octobot/backtesting` | Backtesting data   |
| `./data/logs`        | `/octobot/logs`        | Log files          |
| `./data/tentacles`   | `/octobot/tentacles`   | Plugins/extensions |
| `./data/user`        | `/octobot/user`        | User configuration |

## Configuration

Configuration is stored in `./data/user/`:

- `user/config.json` - Main configuration
- `user/profiles/` - Trading profiles

### Exchange Setup

Edit `./data/user/config.json`:

```json
{
  "exchanges": {
    "binance": {
      "api-key": "your-key",
      "api-secret": "your-secret"
    }
  }
}
```

## Tentacles

Tentacles are OctoBot's plugin system for:

- Trading strategies
- Technical indicators
- Evaluators
- Backtesting tools

Install tentacles through the web UI or CLI.

## Backtesting

1. Download historical data through the UI
2. Select a trading profile
3. Run backtests to test strategies

## Links

- [OctoBot Website](https://www.octobot.online/)
- [Documentation](https://www.octobot.info/)
- [GitHub Repository](https://github.com/Drakkar-Software/OctoBot)
- [Tentacles Repository](https://github.com/Drakkar-Software/OctoBot-Tentacles)
