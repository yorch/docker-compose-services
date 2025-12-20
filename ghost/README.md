# Ghost

Professional publishing platform and headless CMS for blogs and publications.

## Features

- Modern publishing editor
- Member subscriptions and payments
- Newsletter support
- SEO optimized
- Custom themes
- API for headless CMS usage

## Quick Start

```bash
docker compose up -d
```

## Services

| Service | Description       |
| ------- | ----------------- |
| `app`   | Ghost application |
| `db`    | MySQL database    |

## Environment Variables

| Variable                         | Description       | Default      |
| -------------------------------- | ----------------- | ------------ |
| `database__client`               | Database client   | `mysql`      |
| `database__connection__host`     | Database host     | `db`         |
| `database__connection__user`     | Database user     | -            |
| `database__connection__password` | Database password | -            |
| `database__connection__database` | Database name     | -            |
| `NODE_ENV`                       | Node environment  | `production` |

### Mail Configuration (Optional)

| Variable                    | Description                   |
| --------------------------- | ----------------------------- |
| `mail__transport`           | Mail transport (e.g., `SMTP`) |
| `mail__options__host`       | SMTP host                     |
| `mail__options__port`       | SMTP port                     |
| `mail__options__auth__user` | SMTP username                 |
| `mail__options__auth__pass` | SMTP password                 |

## Volumes

| Host Path      | Container Path           | Description             |
| -------------- | ------------------------ | ----------------------- |
| `./data/ghost` | `/var/lib/ghost/content` | Content, themes, images |
| `./data/mysql` | `/var/lib/mysql`         | Database data           |

## First-Time Setup

After starting, visit your Ghost URL to complete the setup wizard and create your admin account.

## Links

- [Ghost Website](https://ghost.org/)
- [Documentation](https://ghost.org/docs/)
- [Ghost Themes](https://ghost.org/themes/)
- [GitHub Repository](https://github.com/TryGhost/Ghost)
