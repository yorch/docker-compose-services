# Woodpecker Agent

Standalone Woodpecker CI agent that adds build capacity to an existing Woodpecker server.

## Features

- Runs pipeline workflows on this host, reporting to a remote server
- TLS-secured gRPC connection by default
- Configurable concurrency via `WOODPECKER_MAX_WORKFLOWS`
- No web UI and no published ports — it dials out to the server

## Prerequisite

**The server must expose its gRPC endpoint to this host.** The agent does not
use the web UI or its HTTPS port; it speaks gRPC, which the server serves on
port 9000 internally.

The [`woodpecker`](../woodpecker) service in this repository does **not** expose
gRPC by default — it publishes nothing and its Traefik overlay routes only HTTP.
Add `docker-compose.grpc.yml` on the server side to publish it:

```bash
cd ../woodpecker
./run-for-traefik-with-grpc.sh
```

That routes gRPC through Traefik on a second hostname, which is what
`WOODPECKER_SERVER` should point at.

## Quick Start

Copy `.env.sample` to `.env` and fill it in — the agent will not start without
`WOODPECKER_SERVER` and `WOODPECKER_AGENT_SECRET`.

```bash
docker compose up -d
```

Confirm it registered by checking the server's admin page under **Agents**, or:

```bash
docker compose logs -f agent
```

A healthy agent logs a successful connection. `agent could not auth: please
provide a token` means the secret does not match the server's.

## Environment Variables

| Variable                   | Description                                    | Required | Default |
| -------------------------- | ---------------------------------------------- | -------- | ------- |
| `WOODPECKER_SERVER`        | Server gRPC endpoint as `host:port`, no scheme | Yes      | -       |
| `WOODPECKER_AGENT_SECRET`  | Must match the server's value exactly          | Yes      | -       |
| `WOODPECKER_GRPC_SECURE`   | Use TLS for the gRPC connection                | No       | `true`  |
| `WOODPECKER_GRPC_VERIFY`   | Verify the server certificate                  | No       | `true`  |
| `WOODPECKER_MAX_WORKFLOWS` | Workflows run concurrently by this agent       | No       | `1`     |

Upstream defaults `WOODPECKER_GRPC_SECURE` to `false`; this service defaults it
to `true`, because an agent reaching a server over the internet with TLS off
sends the shared secret in the clear.

Two further settings are not wired into the compose file but can be added to the
`environment` block if you need them:

- `WOODPECKER_HOSTNAME` — the name the agent registers under. Left unset it uses
  the container hostname.
- `WOODPECKER_AGENT_LABELS` — label filters so only matching pipelines are
  scheduled here, e.g. an ARM or GPU host.

## Volumes

| Host Path      | Container Path         | Description                                      |
| -------------- | ---------------------- | ------------------------------------------------ |
| `./data/agent` | `/etc/woodpecker`      | Agent registration ID, persisted across restarts |
| Docker socket  | `/var/run/docker.sock` | Lets the agent start pipeline containers         |

## Security

This agent mounts `/var/run/docker.sock`, so **it has root-equivalent access to
this host**. Anyone who can run a pipeline on the connected server can run
containers here.

That matters more for a standalone agent than for one sitting beside its server:
you are lending compute to a server that may be administered by someone else.
Only point this at a Woodpecker instance you trust, and prefer a host with
nothing else valuable on it.

Woodpecker's own defaults limit the blast radius — host volume mounts require a
repository an admin has marked trusted, and pull requests from forks need
approval — but those are enforced on the **server**, not here. This agent obeys
whatever that server tells it to run.

## Scaling

Raise `WOODPECKER_MAX_WORKFLOWS` to run more workflows on one host, or deploy
this service on several hosts pointing at the same server. Each agent registers
separately and the server distributes work between them.

## Links

- [Woodpecker CI Website](https://woodpecker-ci.org/)
- [Agent Configuration](https://woodpecker-ci.org/docs/administration/configuration/agent)
- [GitHub Repository](https://github.com/woodpecker-ci/woodpecker)
