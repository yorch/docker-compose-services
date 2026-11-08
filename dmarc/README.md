# DMARC reports

Turns DMARC aggregate reports into a readable summary of who sends as your domain.

A domain with a DMARC record at `p=none` collects reports and enforces nothing — but the
reports arrive as gzipped XML, one per receiving provider per day, and nobody reads them by
hand. This service polls the reporting mailbox and prints one row per source with its message
count, disposition and DKIM/SPF alignment, keeping a JSON copy of each summary in `./data`.

## Features

- One row per source, so an unauthorised sender stands out instead of hiding in XML
- Flags rows where neither DKIM nor SPF aligned — either an unlisted legitimate sender or a spoof
- Handles raw XML, `.xml.gz` and zipped reports
- Read-only: nothing is sent, deleted or moved
- Keeps a timestamped JSON history under `./data`
- Refuses DTDs and entity declarations and caps decompressed size, because reports are
  untrusted input from third parties

## Quick Start

```bash
cp .env.sample .env    # then fill in IMAP_PASSWORD
mkdir -p data
docker compose up -d
docker compose logs -f
```

The first poll runs immediately, then every `DMARC_INTERVAL_SECONDS`.

To summarise a single report without the service:

```bash
docker compose run --rm -T --entrypoint python3 dmarc /app/dmarc-report.py --file /app/data/report.xml.gz
python3 dmarc-report.py --self-test        # parser check, no mailbox needed
```

## Environment Variables

| Variable                 | Description                                                      | Default |
| ------------------------ | ---------------------------------------------------------------- | ------- |
| `IMAP_HOST`              | IMAP server of the mailbox that receives the reports             | -       |
| `IMAP_PORT`              | IMAP port (implicit TLS)                                         | `993`   |
| `IMAP_USER`              | Mailbox address, matching the `rua=` in the DMARC record         | -       |
| `IMAP_PASSWORD`          | Mailbox password or app password                                 | -       |
| `IMAP_MAILBOX`           | Mailbox to read                                                  | `INBOX` |
| `DMARC_INTERVAL_SECONDS` | Poll interval in seconds; 86400 matches how often reports arrive | `86400` |

## Reading the output

```
DMARC aggregate summary — example.com
12 message(s) across 2 source(s)
publishers: google.com 1

source ip           count  disposition dkim  spf   header from
198.51.100.7            9  none        pass  pass  example.com
203.0.113.9             3  none        fail  fail  example.com  <- unaligned
```

`<- unaligned` is the line that matters. Under `p=none` a message with neither DKIM nor SPF
aligned is delivered anyway; under `p=quarantine` it goes to spam. Investigate every unaligned
source before tightening the policy.

## Tightening the policy

Start at `p=none`, read the summaries for a couple of weeks, then change one token in the DNS
record:

```
_dmarc.example.com TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"
```

`p=reject` comes later. If anything sends from subdomains, consider `sp=` first: subdomains
inherit the policy, and a subdomain that is a CNAME cannot carry its own SPF or DKIM records.

## Volumes

| Host Path | Container Path | Description                |
| --------- | -------------- | -------------------------- |
| `./data`  | `/app/data`    | Timestamped JSON summaries |

## Notes

- Reports are only sent when your DMARC record includes `rua=`. Without it there is nothing
  to read.
- Aggregate reports contain no message content: source addresses, counts and pass/fail results
  only.
- The parser uses `defusedxml` when the image provides it and a guarded `ElementTree` parse
  otherwise. Both refuse DTDs and entities.
