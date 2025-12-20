# CouchDB

Apache CouchDB - a NoSQL document database with HTTP API and built-in replication.

## Features

- RESTful HTTP API
- Document-oriented storage
- Multi-master replication
- Offline-first capabilities
- Built-in web interface (Fauxton)

## Quick Start

```bash
docker compose up -d
```

Access Fauxton web interface at `http://localhost:5984/_utils`

## Environment Variables

| Variable           | Description    | Required |
| ------------------ | -------------- | -------- |
| `COUCHDB_USER`     | Admin username | Yes      |
| `COUCHDB_PASSWORD` | Admin password | Yes      |

## Volumes

| Host Path          | Container Path             | Description         |
| ------------------ | -------------------------- | ------------------- |
| `./data/couchdb`   | `/opt/couchdb/data`        | Database files      |
| `./config/couchdb` | `/opt/couchdb/etc/local.d` | Configuration files |

## Custom Configuration

Place custom configuration files in `./config/couchdb/` with `.ini` extension.

Example `./config/couchdb/custom.ini`:

```ini
[couchdb]
max_document_size = 4294967296

[httpd]
bind_address = 0.0.0.0
```

## Links

- [Apache CouchDB Website](https://couchdb.apache.org/)
- [Documentation](https://docs.couchdb.org/)
- [Docker Hub](https://hub.docker.com/_/couchdb)
