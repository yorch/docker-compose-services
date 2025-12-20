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
docker compose up -d
```

## Services

| Service         | Description                            |
| --------------- | -------------------------------------- |
| `app`           | Main Errbit application (port 3000)    |
| `init-db`       | Database initialization and migrations |
| `mongo`         | MongoDB database                       |
| `mongo-express` | MongoDB web interface                  |

## Environment Variables

| Variable                | Description               | Required |
| ----------------------- | ------------------------- | -------- |
| `MONGO_URL`             | MongoDB connection string | Yes      |
| `SECRET_KEY_BASE`       | Rails secret key          | Yes      |
| `ERRBIT_ADMIN_EMAIL`    | Admin email address       | Yes      |
| `ERRBIT_ADMIN_PASSWORD` | Admin password            | Yes      |
| `ERRBIT_ADMIN_USER`     | Admin username            | Yes      |

### Email Configuration (Optional)

| Variable        | Description          |
| --------------- | -------------------- |
| `SMTP_HOST`     | SMTP server hostname |
| `SMTP_PORT`     | SMTP server port     |
| `SMTP_USER`     | SMTP username        |
| `SMTP_PASSWORD` | SMTP password        |

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
