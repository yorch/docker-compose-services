#!/usr/bin/env python3
"""Summarise DMARC aggregate reports from a mailbox.

DMARC sends one gzipped XML report per receiving provider per day. They are
unreadable by hand, so this turns them into a per-source summary: who sent as
the domain, how much, and whether DKIM and SPF aligned.

As a container it polls on an interval and keeps a JSON copy of each summary:

    docker compose up -d
    docker compose logs -f

Run it by hand when you want to look at a single report:

    # one report you already have
    python3 dmarc-report.py --file report.xml.gz

    # fetch everything unseen right now
    python3 dmarc-report.py --fetch --mark-seen

    # prove the parser still works, no mailbox needed
    python3 dmarc-report.py --self-test

Settings come from the environment (see .env.sample), never from arguments, so
a password cannot land in `ps` or shell history.

It only reads. Nothing is sent, deleted or moved; --mark-seen is opt-in, and
without it a later run summarises the same messages again.

Reports are untrusted input from third parties, so the parser refuses DTDs and
entity declarations and caps decompressed size: an aggregate report has no use
for either, and both are how XML and archive bombs arrive.
"""

from __future__ import annotations

import argparse
import gzip
import io
import json
import os
import signal
import sys
import time
import xml.etree.ElementTree as ET
import zipfile
from collections import defaultdict
from datetime import datetime, timezone

REQUIRED_ENV = ("IMAP_HOST", "IMAP_USER", "IMAP_PASSWORD")
MAX_COMPRESSED_BYTES = 5 * 1024 * 1024
MAX_DECOMPRESSED_BYTES = 10 * 1024 * 1024

# Optional but stronger: defusedxml refuses entity expansion outright. It is not
# a hard dependency because a bare host or image may not have it, in which case
# the guarded parse below still applies.
try:  # pragma: no cover - depends on the environment
    from defusedxml import ElementTree as _SafeET  # type: ignore[import-not-found]
except ImportError:  # pragma: no cover
    _SafeET = None


def strip_namespace(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def text_of(node: ET.Element | None, path: str, default: str = "") -> str:
    if node is None:
        return default
    found = node.find(path)
    if found is not None:
        return (found.text or default).strip()
    # Namespaced documents: match on the local name instead of the path.
    local = path.rsplit("/", 1)[-1]
    for child in node.iter():
        if strip_namespace(child.tag) == local:
            return (child.text or default).strip()
    return default


def _limited_decompress(data: bytes) -> bytes:
    with gzip.GzipFile(fileobj=io.BytesIO(data)) as handle:
        out = handle.read(MAX_DECOMPRESSED_BYTES + 1)
    if len(out) > MAX_DECOMPRESSED_BYTES:
        raise ValueError("report decompresses beyond the size limit")
    return out


def _parse_xml(data: bytes) -> ET.Element:
    # A DTD or entity declaration has no place in an aggregate report and is how
    # entity-expansion attacks arrive; ElementTree would otherwise expand them.
    head = data[:4096].lower()
    if b"<!doctype" in head or b"<!entity" in head:
        raise ValueError("report contains a DTD or entity declaration")
    if _SafeET is not None:
        return _SafeET.fromstring(data)
    return ET.fromstring(data)


def read_report(data: bytes, name: str = "") -> ET.Element:
    """Accept raw XML, gzipped XML, or a zip containing XML."""
    if len(data) > MAX_COMPRESSED_BYTES:
        raise ValueError(f"{name}: report exceeds the size limit")
    if data[:2] == b"PK":
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            for entry in archive.namelist():
                if not entry.lower().endswith(".xml"):
                    continue
                if archive.getinfo(entry).file_size > MAX_DECOMPRESSED_BYTES:
                    raise ValueError(f"{name}: zip member exceeds the size limit")
                return _parse_xml(archive.read(entry))
        raise ValueError(f"{name}: zip contains no XML")
    if data[:2] == b"\x1f\x8b":
        data = _limited_decompress(data)
    return _parse_xml(data)


def summarise(reports: list[ET.Element]) -> dict:
    """Aggregate records across reports.

    The interesting question is not "did DMARC pass" — under p=none it always
    reports — but which sources sent as the domain and whether their DKIM and
    SPF aligned. Grouping by source and alignment answers that.
    """
    sources: dict[tuple[str, str, str, str, str], int] = defaultdict(int)
    publishers: dict[str, int] = defaultdict(int)
    domains: set[str] = set()

    for report in reports:
        domain = text_of(report.find("policy_published"), "domain", "unknown")
        domains.add(domain)
        publishers[text_of(report.find("report_metadata"), "org_name", "unknown")] += 1

        for record in report.findall("record"):
            row = record.find("row")
            evaluated = row.find("policy_evaluated") if row is not None else None
            key = (
                text_of(record.find("identifiers"), "header_from", domain),
                text_of(row, "source_ip", "unknown"),
                text_of(evaluated, "disposition", "none"),
                text_of(evaluated, "dkim", "unknown"),
                text_of(evaluated, "spf", "unknown"),
            )
            sources[key] += int(text_of(row, "count", "0") or 0)

    rows = [
        {
            "headerFrom": header_from,
            "sourceIp": source_ip,
            "disposition": disposition,
            "dkim": dkim,
            "spf": spf,
            "count": count,
            "aligned": dkim == "pass" or spf == "pass",
        }
        for (header_from, source_ip, disposition, dkim, spf), count in sources.items()
    ]
    rows.sort(key=lambda r: (-r["count"], r["sourceIp"]))
    return {
        "generatedAt": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "domains": sorted(domains),
        "publishers": dict(sorted(publishers.items())),
        "sources": rows,
        "totalMessages": sum(r["count"] for r in rows),
    }


def format_summary(summary: dict) -> str:
    lines = [
        f"DMARC aggregate summary — {', '.join(summary['domains']) or 'no domain'}",
        f"{summary['totalMessages']} message(s) across {len(summary['sources'])} source(s)",
        "publishers: "
        + (", ".join(f"{k} {v}" for k, v in summary["publishers"].items()) or "none"),
        "",
        f"{'source ip':<18}{'count':>7}  {'disposition':<12}{'dkim':<6}{'spf':<6}header from",
    ]
    for row in summary["sources"]:
        flag = "" if row["aligned"] else "  <- unaligned"
        lines.append(
            f"{row['sourceIp']:<18}{row['count']:>7}  "
            f"{row['disposition']:<12}{row['dkim']:<6}{row['spf']:<6}"
            f"{row['headerFrom']}{flag}"
        )
    if not summary["sources"]:
        lines.append("(no records)")
    return "\n".join(lines)


def config_from_environ() -> dict[str, str]:
    values = {key: os.environ.get(key, "").strip() for key in REQUIRED_ENV}
    values["IMAP_PORT"] = os.environ.get("IMAP_PORT", "").strip() or "993"
    values["IMAP_MAILBOX"] = os.environ.get("IMAP_MAILBOX", "").strip() or "INBOX"
    missing = [key for key in REQUIRED_ENV if not values.get(key)]
    if missing:
        raise SystemExit(f"environment is missing: {', '.join(missing)}")
    return values


def _attachment_bytes(part) -> bytes | None:
    payload = part.get_payload(decode=True)
    return payload if isinstance(payload, bytes) else None


def fetch_reports(
    config: dict[str, str], mark_seen: bool
) -> tuple[list[ET.Element], list[str]]:
    import email
    import imaplib

    reports: list[ET.Element] = []
    problems: list[str] = []

    with imaplib.IMAP4_SSL(
        config["IMAP_HOST"], int(config.get("IMAP_PORT") or 993)
    ) as client:
        client.login(config["IMAP_USER"], config["IMAP_PASSWORD"])
        client.select(config.get("IMAP_MAILBOX") or "INBOX")
        status, data = client.search(None, "UNSEEN")
        if status != "OK":
            raise SystemExit(f"search failed: {status}")
        for raw_id in (data[0] or b"").split():
            message_id = raw_id.decode()
            status, parts = client.fetch(message_id, "(RFC822)")
            if status != "OK" or not parts or not isinstance(parts[0], tuple):
                problems.append(f"message {message_id}: fetch failed")
                continue
            message = email.message_from_bytes(parts[0][1])
            found = 0
            for part in message.walk():
                name = part.get_filename() or ""
                if not name.lower().endswith((".xml", ".xml.gz", ".gz", ".zip")):
                    continue
                payload = _attachment_bytes(part)
                if payload is None:
                    continue
                try:
                    reports.append(read_report(payload, name))
                    found += 1
                except Exception as error:  # noqa: BLE001 - report and continue
                    problems.append(f"{name}: {type(error).__name__}: {error}")
            if mark_seen:
                client.store(message_id, "+FLAGS", "(\\Seen)")
            if not found:
                problems.append(f"message {message_id}: no report attachment")
    return reports, problems


def write_json(summary: dict, directory: str) -> str | None:
    if not directory:
        return None
    try:
        os.makedirs(directory, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        path = os.path.join(directory, f"dmarc-{stamp}.json")
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(summary, handle, indent=2)
            handle.write("\n")
        return path
    except OSError as error:
        print(f"warning: cannot write json: {error.strerror}", file=sys.stderr)
        return None


def run_once(mark_seen: bool, json_dir: str) -> None:
    reports, problems = fetch_reports(config_from_environ(), mark_seen)
    summary = summarise(reports)
    print(format_summary(summary), flush=True)
    for problem in problems:
        print(f"warning: {problem}", file=sys.stderr, flush=True)
    path = write_json(summary, json_dir)
    if path:
        print(f"json: {path}", flush=True)


def run_loop(interval: int, json_dir: str) -> int:
    stop = False

    def handle(_signum, _frame):
        nonlocal stop
        stop = True

    signal.signal(signal.SIGTERM, handle)
    signal.signal(signal.SIGINT, handle)

    print(f"dmarc reporter: polling every {interval}s", flush=True)
    while not stop:
        try:
            run_once(True, json_dir)
        except SystemExit as error:
            print(f"error: {error}", file=sys.stderr, flush=True)
        except Exception as error:  # noqa: BLE001 - keep the loop alive
            print(f"error: {type(error).__name__}: {error}", file=sys.stderr, flush=True)
        # Sleep in short steps so a stop request is honoured promptly.
        for _ in range(interval):
            if stop:
                break
            time.sleep(1)
    print("dmarc reporter: stopped", flush=True)
    return 0


SYNTHETIC_REPORT = b"""<?xml version="1.0"?>
<feedback>
  <report_metadata><org_name>example.net</org_name><report_id>r1</report_id></report_metadata>
  <policy_published><domain>example.com</domain><p>none</p></policy_published>
  <record>
    <row><source_ip>198.51.100.7</source_ip><count>4</count>
      <policy_evaluated><disposition>none</disposition><dkim>pass</dkim><spf>pass</spf></policy_evaluated></row>
    <identifiers><header_from>example.com</header_from></identifiers>
  </record>
  <record>
    <row><source_ip>203.0.113.9</source_ip><count>2</count>
      <policy_evaluated><disposition>none</disposition><dkim>fail</dkim><spf>fail</spf></policy_evaluated></row>
    <identifiers><header_from>example.com</header_from></identifiers>
  </record>
</feedback>"""


def self_test() -> int:
    summary = summarise([read_report(SYNTHETIC_REPORT, "synthetic")])
    assert summary["domains"] == ["example.com"], summary["domains"]
    assert summary["totalMessages"] == 6, summary["totalMessages"]
    assert summary["sources"][0]["sourceIp"] == "198.51.100.7"
    assert summary["sources"][0]["aligned"] is True
    assert summary["sources"][1]["aligned"] is False
    # gzip and zip wrappers must parse identically to the raw document
    assert summarise([read_report(gzip.compress(SYNTHETIC_REPORT), "g")]) == summary
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w") as archive:
        archive.writestr("report.xml", SYNTHETIC_REPORT)
    assert summarise([read_report(buffer.getvalue(), "z")]) == summary
    # A DTD must be refused rather than expanded
    hostile = b'<?xml version="1.0"?><!DOCTYPE x [<!ENTITY a "b">]><feedback/>'
    try:
        read_report(hostile, "hostile")
    except ValueError:
        pass
    else:
        raise AssertionError("DTD was accepted")
    print("self-test OK")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarise DMARC aggregate reports")
    parser.add_argument("--file", help="parse a local .xml, .xml.gz or .zip report")
    parser.add_argument("--fetch", action="store_true", help="fetch unseen mail once")
    parser.add_argument("--loop", action="store_true", help="poll forever")
    parser.add_argument("--mark-seen", action="store_true", help="flag processed mail as seen")
    parser.add_argument("--json", help="write the summary as JSON to this path")
    parser.add_argument("--self-test", action="store_true")
    options = parser.parse_args()

    json_dir = os.environ.get("DMARC_JSON_DIR", "").strip()

    if options.self_test:
        return self_test()

    if options.loop:
        interval = int(os.environ.get("DMARC_INTERVAL_SECONDS", "") or 86400)
        if interval < 60:
            raise SystemExit("DMARC_INTERVAL_SECONDS must be at least 60")
        return run_loop(interval, json_dir)

    if options.file:
        try:
            with open(options.file, "rb") as handle:
                reports = [read_report(handle.read(), options.file)]
        except OSError as error:
            raise SystemExit(f"cannot read {options.file}: {error.strerror}") from error
        summary = summarise(reports)
        print(format_summary(summary))
        if options.json:
            write_json(summary, os.path.dirname(options.json) or ".")
        return 0

    if options.fetch:
        reports, problems = fetch_reports(config_from_environ(), options.mark_seen)
        summary = summarise(reports)
        print(format_summary(summary))
        for problem in problems:
            print(f"warning: {problem}", file=sys.stderr)
        if options.json:
            write_json(summary, os.path.dirname(options.json) or ".")
        return 0

    parser.error("choose --file, --fetch, --loop or --self-test")
    return 2


if __name__ == "__main__":
    sys.exit(main())
