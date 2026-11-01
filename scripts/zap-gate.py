#!/usr/bin/env python3
"""Fails (exit 1) when a ZAP baseline JSON report has a High or Medium alert that .zap/baseline.conf does not accept.

ZAP's own exit status only distinguishes FAIL/WARN rules, not risk; this gate reads the risk of each alert instead:
    scripts/zap-gate.py zap.json [.zap/baseline.conf]
An alert is accepted when its plugin id is set to IGNORE in the conf (every IGNORE line carries its justification).
A justification starting with "[alert=<name>]" accepts only the alert of that exact name (rule 10055 = all CSP checks).
"""
import json, pathlib, sys

report = json.loads(pathlib.Path(sys.argv[1]).read_text())
conf = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else ".zap/baseline.conf")
accepted = {}  # plugin id -> alert name or None (= every alert of the rule)
for line in conf.read_text().splitlines():
    parts = line.split("\t")
    if len(parts) >= 2 and not line.startswith("#") and parts[1].strip() == "IGNORE":
        note = parts[3].strip() if len(parts) > 3 else ""
        only = note[len("[alert="):note.index("]")] if note.startswith("[alert=") and "]" in note else None
        accepted[parts[0].strip()] = only

risk = {"3": "High", "2": "Medium", "1": "Low", "0": "Informational"}
counts, blocking = {}, []
for site in report.get("site", []):
    for alert in site.get("alerts", []):
        level = risk.get(str(alert.get("riskcode")), "?")
        counts[level] = counts.get(level, 0) + 1
        pid = str(alert.get("pluginid"))
        ok = pid in accepted and accepted[pid] in (None, alert.get("name"))
        if str(alert.get("riskcode")) in ("2", "3") and not ok:
            blocking.append(f"{level}: {alert.get('pluginid')} {alert.get('name')} ({alert.get('count')} instances)")

print("ZAP alerts by risk:", ", ".join(f"{k}={v}" for k, v in sorted(counts.items())) or "none")
for b in blocking:
    print("BLOCKING", b)
sys.exit(1 if blocking else 0)
