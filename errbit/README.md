# Errbit

Open-source error catcher compatible with the Airbrake API for exception tracking.

## Features

- Airbrake API compatible
- Error aggregation and grouping
- Email notifications
- GitHub/GitLab integration
- Multi-app support

## Quick Start

```bash
cp .env.sample .env  # then set the passwords and SECRET_KEY_BASE

# Dev - publishes ports on localhost (app on http://localhost:3000)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Dev + mongo-express (opt-in profile) on 127.0.0.1:8081
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile mongo-express up -d

# Behind Traefik - HTTPS through the reverse proxy
docker compose -f docker-compose.yml -f docker-compose.for-traefik.yml up -d
```

The Traefik overlay joins an external network that must already exist. Create it
once per host:

```bash
../traefik3/setup.sh   # docker network create traefik
```

On first start `errbit-init` creates the admin from `ERRBIT_ADMIN_*`; sign in with
`ERRBIT_ADMIN_EMAIL` / `ERRBIT_ADMIN_PASSWORD`. It only seeds while no users exist
(Errbit's seed would otherwise reset the admin password on every start).

With `RAILS_ENV=production` (the default) Errbit redirects plain HTTP to HTTPS, so in
dev open `http://localhost:3000/users/sign_in` directly or set `RAILS_ENV=development`.

> **MongoDB 8 and Linux kernels 6.19–7.0.13.** MongoDB 8.x refuses to start (or
> crashes) on these kernels because of a TCMalloc/rseq bug
> ([SERVER-121912](https://jira.mongodb.org/browse/SERVER-121912)). This includes
> Docker Desktop VMs shipping kernel 7.0.12. Kernels up to 6.18 are unaffected; 7.0.14
> fixes the kernel side, together with a MongoDB 8 release that includes
> [SERVER-125742](https://jira.mongodb.org/browse/SERVER-125742). Data written by 8.x
> cannot be opened by 7.0, so fix the host kernel rather than downgrading.

## Services

| Service         | Description                                                                |
| --------------- | -------------------------------------------------------------------------- |
| `app`           | Errbit (Rails + Thruster, container port 80)                               |
| `errbit-init`   | One-shot: seeds the admin on first start, creates Mongo indexes            |
| `mongo`         | MongoDB 8                                                                  |
| `mongo-express` | MongoDB web UI, **dev overlay only**, opt-in via `--profile mongo-express` |

mongo-express is never routed through Traefik (see AGENTS.md).

## Environment Variables

| Variable                 | Description                                                | Required |
| ------------------------ | ---------------------------------------------------------- | -------- |
| `DOMAIN`                 | Public hostname (Traefik host and `ERRBIT_HOST`)           | Yes      |
| `MONGODB_PASSWORD`       | MongoDB root password (`openssl rand -hex 24`)             | Yes      |
| `MONGODB_USERNAME`       | MongoDB root user (default `errbit`)                       | No       |
| `SECRET_KEY_BASE`        | Rails secret (`openssl rand -hex 64`)                      | Yes      |
| `RAILS_ENV`              | `production` (default, forces HTTPS) or `development`      | No       |
| `ERRBIT_ADMIN_EMAIL`     | Admin email, created on first start                        | Yes      |
| `ERRBIT_ADMIN_PASSWORD`  | Admin password, created on first start                     | Yes      |
| `ERRBIT_ADMIN_USER`      | Admin username                                             | Yes      |
| `MONGO_EXPRESS_PASSWORD` | mongo-express basic-auth password (dev overlay)            | Dev      |
| `MONGO_EXPRESS_USERNAME` | mongo-express basic-auth user (default `admin`)            | No       |
| `DEV_BIND_IP`            | Host interface for dev Mongo / mongo-express (`127.0.0.1`) | No       |

Other `ERRBIT_*` options are described in the
[configuration docs](https://github.com/errbit/errbit/blob/main/docs/configuration.md).

### Email Configuration (Optional)

| Variable                    | Description                    |
| --------------------------- | ------------------------------ |
| `EMAIL_DELIVERY_METHOD`     | `smtp`, `sendmail` or `test`   |
| `SMTP_SERVER`               | SMTP server hostname           |
| `SMTP_PORT`                 | SMTP server port               |
| `SMTP_AUTHENTICATION`       | `plain`, `login` or `cram_md5` |
| `SMTP_USERNAME`             | SMTP username                  |
| `SMTP_PASSWORD`             | SMTP password                  |
| `SMTP_DOMAIN`               | HELO domain                    |
| `SMTP_ENABLE_STARTTLS_AUTO` | Use STARTTLS when available    |

## Volumes

| Host Path      | Container Path | Description  |
| -------------- | -------------- | ------------ |
| `./data/mongo` | `/data/db`     | MongoDB data |

## Integration

Configure your application's Airbrake/Errbit notifier to point to your Errbit instance.

### Ruby Example

```ruby
Airbrake.configure do |config|
  config.host = 'https://your-errbit-domain.com'
  config.project_id = 1
  config.project_key = 'your-api-key'
end
```

## Links

- [Errbit Website](https://errbit.com/)
- [GitHub Repository](https://github.com/errbit/errbit)
- [Airbrake Documentation](https://airbrake.io/docs/)
