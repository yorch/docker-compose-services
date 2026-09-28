# WordPress

Popular content management system (CMS) for websites and blogs.

## Features

- Official `wordpress` (Apache) and `mariadb` LTS images
- Installs itself on first start with the admin account from `.env` — the web installer
  is never left open for the first visitor
- HTTPS-aware behind Traefik (honours `X-Forwarded-Proto`, no redirect loops)
- Plugin and theme ecosystem, REST API

## Quick Start

```bash
cp .env.sample .env  # then set DB_PASSWORD, DB_ROOT_PASSWORD and WP_PASSWORD

# Dev - publishes ports on localhost
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Behind Traefik - HTTPS through the reverse proxy (set WP_URL=https://${DOMAIN} first)
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

Access WordPress at `http://localhost:8080` (dev) and log in at `/wp-admin` with
`WP_USERNAME` / `WP_PASSWORD`.

## Services

| Service   | Description                                                   |
| --------- | ------------------------------------------------------------- |
| `app`     | WordPress on Apache (port 80)                                 |
| `wp-init` | One-shot `wp-cli` run that installs WordPress if it isn't yet |
| `mariadb` | MariaDB 12.3 LTS                                              |

## Environment Variables

| Variable           | Description                                                             | Required |
| ------------------ | ----------------------------------------------------------------------- | -------- |
| `DOMAIN`           | Hostname Traefik routes to WordPress (Traefik only)                     | Traefik  |
| `WP_URL`           | URL used for the first-start install (default `http://localhost:8080`)  | Traefik  |
| `WP_TITLE`         | Site title for the first-start install (default `WordPress`)            | No       |
| `WP_USERNAME`      | Admin username created on first start                                   | Yes      |
| `WP_PASSWORD`      | Admin password created on first start                                   | Yes      |
| `WP_EMAIL`         | Admin email                                                             | Yes      |
| `DB_USERNAME`      | Database user (default `wordpress`)                                     | No       |
| `DB_PASSWORD`      | Database password                                                       | Yes      |
| `DB_NAME`          | Database name (default `wordpress`)                                     | No       |
| `DB_ROOT_PASSWORD` | MariaDB root password                                                   | Yes      |
| `DEV_BIND_IP`      | Host interface for the dev overlay's MariaDB port (default `127.0.0.1`) | No       |

`WP_URL`, `WP_TITLE` and the `WP_*` admin values only apply to the first install; after
that they live in the database and are changed from the admin UI.

## Volumes

| Host Path      | Container Path   | Description                                   |
| -------------- | ---------------- | --------------------------------------------- |
| `./data/html`  | `/var/www/html`  | WordPress core, `wp-config.php`, `wp-content` |
| `./data/mysql` | `/var/lib/mysql` | Database data                                 |

## Migrating from the Bitnami-based stack

Earlier versions of this folder ran `bitnami/wordpress` and `bitnami/mariadb`, which
Bitnami stopped publishing in 2025. Their data (`./data/wordpress`, `./data/mariadb`)
has a different layout, so the new stack uses new paths and leaves the old ones alone.
Move your site over with a dump and a copy:

```bash
# 1. With the OLD stack still running, dump the database
docker compose exec mariadb sh -c \
  'mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"' > wordpress.sql
docker compose down

# 2. Pull this version, add DB_ROOT_PASSWORD/WP_PASSWORD etc. to .env (keep your
#    DB_USERNAME/DB_PASSWORD/DB_NAME), and start the new stack once so it initialises
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d

# 3. Import the dump over the fresh install
docker compose exec -T mariadb sh -c \
  'mariadb -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"' < wordpress.sql

# 4. Bring over uploads, plugins and themes
cp -a ./data/wordpress/wp-content/. ./data/html/wp-content/
sudo chown -R 33:33 ./data/html/wp-content   # www-data in the official image (Linux hosts)
```

Your old users and passwords come back with the import. Both images default to the `wp_`
table prefix; if you changed it, add `WORDPRESS_TABLE_PREFIX` to the `app` environment.
Once the site checks out, delete `./data/wordpress` and `./data/mariadb`.

## Backup

```bash
# Database
docker compose exec mariadb sh -c \
  'mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"' > backup.sql

# Files
tar -czf wordpress-files.tar.gz ./data/html/wp-content
```

## Links

- [WordPress Website](https://wordpress.org/)
- [Documentation](https://wordpress.org/support/)
- [Docker Hub: wordpress](https://hub.docker.com/_/wordpress)
- [Docker Hub: mariadb](https://hub.docker.com/_/mariadb)
