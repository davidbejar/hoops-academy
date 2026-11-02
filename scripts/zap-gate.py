#!/usr/bin/env python3
"""Fails (exit 1) when a ZAP baseline JSON report has a High or Medium alert that .zap/baseline.conf does not accept.

ZAP's own exit status only distinguishes FAIL/WARN rules, not risk; this gate reads the risk of each alert instead:
    scripts/zap-gate.py zap.json [.zap/baseline.conf]
An alert instance is accepted when an IGNORE line for its plugin id matches it. Every IGNORE line carries a
justification; the justification may start with scoping tags, each narrowing the acceptance:
    [alert=<exact alert name>]   only that alert of the rule (rule 10055 = all CSP checks)
    [url=<path prefix>]          only instances whose URL path starts with the prefix (e.g. [url=/auth/] = Keycloak)
Several IGNORE lines per rule are allowed (ZAP itself keeps the last one; the gate honours all). An alert blocks when
any of its instances is not accepted.
"""
import json, pathlib, re, sys
from urllib.parse import urlparse

report = json.loads(pathlib.Path(sys.argv[1]).read_text())
conf = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else ".zap/baseline.conf")
accepted = []  # (plugin id, alert name or None, url prefix or None)
for line in conf.read_text().splitlines():
    parts = line.split("\t")
    if len(parts) >= 2 and not line.startswith("#") and parts[1].strip() == "IGNORE":
        note = parts[3].strip() if len(parts) > 3 else ""
        tags = {}
        # leading tag run only: "[alert=X][url=Y] text" -> {alert: X, url: Y}
        m = re.match(r"^((?:\[(?:alert|url)=[^\]]+\])+)", note)
        if m:
            tags = dict(re.findall(r"\[(alert|url)=([^\]]+)\]", m.group(1)))
        accepted.append((parts[0].strip(), tags.get("alert"), tags.get("url")))

def is_accepted(pid, name, uri):
    path = urlparse(uri).path or "/"
    return any(p == pid and a in (None, name) and (u is None or path.startswith(u)) for p, a, u in accepted)

risk = {"3": "High", "2": "Medium", "1": "Low", "0": "Informational"}
counts, blocking = {}, []
for site in report.get("site", []):
    for alert in site.get("alerts", []):
        code = str(alert.get("riskcode"))
        level = risk.get(code, "?")
        counts[level] = counts.get(level, 0) + 1
        if code not in ("2", "3"):
            continue
        pid, name = str(alert.get("pluginid")), alert.get("name")
        rejected = [i.get("uri") for i in alert.get("instances", []) if not is_accepted(pid, name, i.get("uri") or "")]
        if not alert.get("instances") and not is_accepted(pid, name, ""):
            rejected = ["(no instance URL)"]
        if rejected:
            blocking.append(f"{level}: {pid} {name} ({len(rejected)} of {alert.get('count')} instances) e.g. {rejected[0]}")

print("ZAP alerts by risk:", ", ".join(f"{k}={v}" for k, v in sorted(counts.items())) or "none")
for b in blocking:
    print("BLOCKING", b)
sys.exit(1 if blocking else 0)
