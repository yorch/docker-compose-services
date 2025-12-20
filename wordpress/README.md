# WordPress

Popular content management system (CMS) for websites and blogs.

## Features

- User-friendly content editor
- Extensive plugin ecosystem
- Theme customization
- Multi-site support
- REST API

## Quick Start

```bash
docker compose up -d
```

Access WordPress at `http://localhost:8080`

## Services

| Service     | Description            |
| ----------- | ---------------------- |
| `wordpress` | WordPress application  |
| `db`        | MySQL/MariaDB database |

## Environment Variables

### WordPress

| Variable                 | Description       | Required |
| ------------------------ | ----------------- | -------- |
| `WORDPRESS_DB_HOST`      | Database host     | Yes      |
| `WORDPRESS_DB_USER`      | Database user     | Yes      |
| `WORDPRESS_DB_PASSWORD`  | Database password | Yes      |
| `WORDPRESS_DB_NAME`      | Database name     | Yes      |
| `WORDPRESS_TABLE_PREFIX` | Table prefix      | -        |

### Database

| Variable              | Description         |
| --------------------- | ------------------- |
| `MYSQL_ROOT_PASSWORD` | MySQL root password |
| `MYSQL_DATABASE`      | Database name       |
| `MYSQL_USER`          | MySQL user          |
| `MYSQL_PASSWORD`      | MySQL password      |

## Volumes

| Host Path          | Container Path   | Description     |
| ------------------ | ---------------- | --------------- |
| `./data/wordpress` | `/var/www/html`  | WordPress files |
| `./data/mysql`     | `/var/lib/mysql` | Database data   |

## First-Time Setup

1. Access the web interface
2. Select your language
3. Fill in site information:
   - Site Title
   - Admin username and password
   - Email address
4. Complete installation

## wp-config.php Settings

Additional configuration via environment:

| Variable                 | Description       |
| ------------------------ | ----------------- |
| `WORDPRESS_DEBUG`        | Enable debug mode |
| `WORDPRESS_CONFIG_EXTRA` | Extra PHP config  |

## Backup

```bash
# Backup database
docker compose exec db mysqldump -u root -p$MYSQL_ROOT_PASSWORD wordpress > backup.sql

# Backup files
tar -czf wordpress-files.tar.gz ./data/wordpress
```

## Links

- [WordPress Website](https://wordpress.org/)
- [Documentation](https://wordpress.org/support/)
- [Docker Hub](https://hub.docker.com/_/wordpress)
