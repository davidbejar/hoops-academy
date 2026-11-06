#!/usr/bin/env python3
"""Fails (exit 1) when a ZAP JSON report has a High or Medium alert that the rules file does not accept.

ZAP's own exit status only distinguishes FAIL/WARN rules, not risk; this gate reads the risk of each alert instead:
    scripts/zap-gate.py zap.json [.zap/baseline.conf] [--today YYYY-MM-DD]
Used by the baseline scan (.zap/baseline.conf) and the API scans (.zap/api-<service>.conf), ADR-0045.

An alert instance is accepted when an IGNORE line for its plugin id matches it. Every IGNORE line carries a
justification (a line without one is a configuration error, exit 2); the justification may start with tags:
    [alert=<exact alert name>]   only that alert of the rule (rule 10055 = all CSP checks)
    [url=<path prefix>]          only instances whose URL path starts with the prefix (e.g. [url=/auth/] = Keycloak)
    [expires=YYYY-MM-DD]         the acceptance holds up to and including that day, then the alert blocks again
Several IGNORE lines per rule are allowed (ZAP itself keeps the last one; the gate honours all). An alert blocks when
any of its instances is not accepted.
"""
import argparse
import datetime
import json
import pathlib
import re
import sys
from urllib.parse import urlparse

TAG_RUN = re.compile(r"^((?:\[(?:alert|url|expires)=[^\]]+\])+)")
TAG = re.compile(r"\[(alert|url|expires)=([^\]]+)\]")
RISK = {"3": "High", "2": "Medium", "1": "Low", "0": "Informational"}


def read_acceptances(conf):
    """IGNORE lines as dicts {pid, alert, url, expires}; exits 2 on a line without justification or a bad date."""
    accepted, errors = [], []
    for number, line in enumerate(conf.read_text().splitlines(), 1):
        parts = line.split("\t")
        if line.startswith("#") or len(parts) < 2 or parts[1].strip() != "IGNORE":
            continue
        pid = parts[0].strip()
        note = parts[3].strip() if len(parts) > 3 else ""
        m = TAG_RUN.match(note)
        tags = dict(TAG.findall(m.group(1))) if m else {}
        justification = note[m.end():] if m else note
        if not justification.strip():
            errors.append(f"{conf}:{number}: IGNORE {pid} has no justification")
            continue
        expires = None
        if "expires" in tags:
            try:
                expires = datetime.date.fromisoformat(tags["expires"])
            except ValueError:
                errors.append(f"{conf}:{number}: IGNORE {pid} has a malformed expiry {tags['expires']!r}")
                continue
        accepted.append({"pid": pid, "alert": tags.get("alert"), "url": tags.get("url"), "expires": expires})
    if errors:
        print("\n".join(f"CONFIG {e}" for e in errors))
        sys.exit(2)
    return accepted


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("report")
    parser.add_argument("conf", nargs="?", default=".zap/baseline.conf")
    parser.add_argument("--today", type=datetime.date.fromisoformat, default=datetime.date.today())
    args = parser.parse_args()

    report = json.loads(pathlib.Path(args.report).read_text())
    acceptances = read_acceptances(pathlib.Path(args.conf))
    expired = set()

    def is_accepted(pid, name, uri):
        path = urlparse(uri).path or "/"
        hits = [a for a in acceptances if a["pid"] == pid and a["alert"] in (None, name)
                and (a["url"] is None or path.startswith(a["url"]))]
        live = [a for a in hits if a["expires"] is None or args.today <= a["expires"]]
        if hits and not live:
            expired.update((a["pid"], a["expires"].isoformat()) for a in hits)
        return bool(live)

    counts, blocking = {}, []
    for site in report.get("site", []):
        for alert in site.get("alerts", []):
            code = str(alert.get("riskcode"))
            level = RISK.get(code, "?")
            counts[level] = counts.get(level, 0) + 1
            if code not in ("2", "3"):
                continue
            pid, name = str(alert.get("pluginid")), alert.get("name")
            rejected = [i.get("uri") for i in alert.get("instances", [])
                        if not is_accepted(pid, name, i.get("uri") or "")]
            if not alert.get("instances") and not is_accepted(pid, name, ""):
                rejected = ["(no instance URL)"]
            if rejected:
                blocking.append(f"{level}: {pid} {name} ({len(rejected)} of {alert.get('count')} instances) "
                                f"e.g. {rejected[0]}")

    print("ZAP alerts by risk:", ", ".join(f"{k}={v}" for k, v in sorted(counts.items())) or "none")
    for pid, day in sorted(expired):
        print(f"EXPIRED acceptance of rule {pid} (held until {day}): fix the finding or renew it with a reason")
    for b in blocking:
        print("BLOCKING", b)
    sys.exit(1 if blocking else 0)


if __name__ == "__main__":
    main()
