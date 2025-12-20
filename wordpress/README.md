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

| Service   | Description           |
| --------- | --------------------- |
| `app`     | WordPress application |
| `mariadb` | MariaDB database      |

## Environment Variables

### WordPress

| Variable                      | Description       | Required |
| ----------------------------- | ----------------- | -------- |
| `WORDPRESS_DATABASE_HOST`     | Database host     | Yes      |
| `WORDPRESS_DATABASE_USER`     | Database user     | Yes      |
| `WORDPRESS_DATABASE_NAME`     | Database name     | Yes      |
| `WORDPRESS_DATABASE_PASSWORD` | Database password | Yes      |
| `WORDPRESS_USERNAME`          | Admin username    | Yes      |
| `WORDPRESS_PASSWORD`          | Admin password    | Yes      |
| `WORDPRESS_EMAIL`             | Admin email       | Yes      |

### Database

| Variable                | Description           |
| ----------------------- | --------------------- |
| `MARIADB_ROOT_PASSWORD` | MariaDB root password |
| `MARIADB_DATABASE`      | Database name         |
| `MARIADB_USER`          | MariaDB user          |
| `MARIADB_PASSWORD`      | MariaDB password      |

## Volumes

| Host Path          | Container Path       | Description     |
| ------------------ | -------------------- | --------------- |
| `./data/wordpress` | `/bitnami/wordpress` | WordPress files |
| `./data/mariadb`   | `/bitnami/mariadb`   | Database data   |

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
