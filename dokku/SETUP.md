# Setup

## Helper script

The following script can be created in `/usr/local/bin` with the name `dokku` to easily manage the Dokku
installation from outside of the container:

```sh
#!/bin/bash

# This is the directory where your Dokku docker-compose file is located
DIR=/opt/dokku

docker compose \
  --project-directory ${DIR} \
  exec app \
  dokku \
  ${@}
```

## Plugins

To install plugins, you can create a file `plugin-list` inside `./data/dokku`, for instance:

```text
postgres: https://github.com/dokku/dokku-postgres.git
mariadb: https://github.com/dokku/dokku-mariadb.git
redis: https://github.com/dokku/dokku-redis.git
mongo: https://github.com/dokku/dokku-mongo.git
letsencrypt: https://github.com/dokku/dokku-letsencrypt.git
maintenance: https://github.com/dokku/dokku-maintenance.git
```

## Setup SSH keys

If you have your public key in Github, you can easily import it as admin user to Dokku with:

```sh
curl https://github.com/{user}.keys | dokku ssh-keys:add admin
```

## Let's encrypt

```sh
dokku config:set --global DOKKU_LETSENCRYPT_EMAIL={youremail}
```
