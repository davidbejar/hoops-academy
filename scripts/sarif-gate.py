#!/usr/bin/env python3
"""SAST gate over SARIF reports (CodeQL, Semgrep), ADR-0045: exit 1 on a blocking result not accepted in a baseline.

    scripts/sarif-gate.py --fail-on high  --baseline .github/codeql/accepted.json codeql/java.sarif
    scripts/sarif-gate.py --fail-on error --baseline .semgrep/accepted.json semgrep.sarif [--suggest]

Blocking: `--fail-on high` = a rule's security-severity >= 7.0 (CodeQL High and Critical); `--fail-on error` = SARIF
level error (Semgrep ERROR). A result the tool marks as suppressed never blocks.

The baseline is {"accepted": [entry, ...]}; an entry covers one finding:
    {"rule": <rule id>, "path": <repo path>, "fingerprint": <16 hex>, "reason": <why>, "expires": "YYYY-MM-DD",
     "line": <informational>}
`fingerprint` is the SHA-256 (first 16 hex) of the finding's first source line with whitespace collapsed, so an
acceptance survives lines moving around it but not a change of the flagged line itself. `reason` and `expires` are
mandatory (exit 2 otherwise); after `expires` the finding blocks again. Entries matching nothing are reported STALE.
`--suggest` prints entries for the blocking results (reason and expiry to fill in by a reviewer).
"""
import argparse
import datetime
import hashlib
import json
import pathlib
import sys

REQUIRED = ("rule", "path", "fingerprint", "reason", "expires")


def fingerprint(text):
    return hashlib.sha256(" ".join(text.split()).encode()).hexdigest()[:16]


def load_baseline(path):
    entries, errors = json.loads(pathlib.Path(path).read_text()).get("accepted", []), []
    for i, e in enumerate(entries):
        missing = [k for k in REQUIRED if not str(e.get(k, "")).strip()]
        if missing:
            errors.append(f"entry {i} ({e.get('rule')} {e.get('path')}): missing {', '.join(missing)}")
            continue
        try:
            e["_expires"] = datetime.date.fromisoformat(e["expires"])
        except ValueError:
            errors.append(f"entry {i} ({e['rule']} {e['path']}): malformed expires {e['expires']!r}")
    if errors:
        print("\n".join(f"CONFIG {path}: {x}" for x in errors))
        sys.exit(2)
    return entries


def findings(report, root):
    """(rule id, path, line, fingerprint, label, blocking-relevant attributes) of every unsuppressed result."""
    lines_cache = {}
    for run in report.get("runs", []):
        tool = run.get("tool", {})
        components = [tool.get("driver", {})] + tool.get("extensions", [])  # CodeQL lists rules per query pack
        rules = {r.get("id"): r for c in components for r in c.get("rules", [])}
        for res in run.get("results", []):
            if any(s.get("status", "accepted") == "accepted" for s in res.get("suppressions", [])):
                continue
            rule = rules.get(res.get("ruleId"), {})
            level = res.get("level") or rule.get("defaultConfiguration", {}).get("level", "warning")
            try:
                severity = float(rule.get("properties", {}).get("security-severity", 0))
            except ValueError:
                severity = 0.0
            loc = (res.get("locations") or [{}])[0].get("physicalLocation", {})
            path = loc.get("artifactLocation", {}).get("uri", "")
            region = loc.get("region", {})
            line = region.get("startLine", 0)
            if path not in lines_cache:
                source = pathlib.Path(root, path)
                lines_cache[path] = source.read_text(errors="replace").splitlines() if source.is_file() else []
            text = lines_cache[path][line - 1] if 0 < line <= len(lines_cache[path]) else \
                region.get("snippet", {}).get("text", "")
            yield {"rule": res.get("ruleId"), "path": path, "line": line, "fingerprint": fingerprint(text),
                   "level": level, "severity": severity}


def label(f):
    s = f["severity"]
    if s >= 9.0:
        return "critical"
    if s >= 7.0:
        return "high"
    if s >= 4.0:
        return "medium"
    return "low" if s > 0 else f["level"]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("reports", nargs="+")
    parser.add_argument("--baseline", required=True)
    parser.add_argument("--fail-on", choices=("high", "error"), required=True)
    parser.add_argument("--root", default=".", help="checkout the SARIF paths are relative to")
    parser.add_argument("--today", type=datetime.date.fromisoformat, default=datetime.date.today())
    parser.add_argument("--suggest", action="store_true")
    args = parser.parse_args()

    baseline = load_baseline(args.baseline)
    used, counts, blocking, expired = set(), {}, [], []
    for report in args.reports:
        for f in findings(json.loads(pathlib.Path(report).read_text()), args.root):
            counts[label(f)] = counts.get(label(f), 0) + 1
            relevant = f["severity"] >= 7.0 if args.fail_on == "high" else f["level"] == "error"
            if not relevant:
                continue
            hits = [i for i, e in enumerate(baseline)
                    if (e["rule"], e["path"], e["fingerprint"]) == (f["rule"], f["path"], f["fingerprint"])]
            used.update(hits)
            live = [i for i in hits if args.today <= baseline[i]["_expires"]]
            if live:
                continue
            if hits:
                expired.append(f"{f['rule']} {f['path']}:{f['line']} (held until {baseline[hits[0]]['expires']})")
            blocking.append(f)

    print("findings by severity:", ", ".join(f"{k}={v}" for k, v in sorted(counts.items())) or "none",
          f"| accepted in baseline: {len(used)} of {len(baseline)}")
    for i, e in enumerate(baseline):
        if i not in used:
            print(f"STALE baseline entry (matches nothing, remove it): {e['rule']} {e['path']} {e['fingerprint']}")
    for x in expired:
        print(f"EXPIRED acceptance: {x}: fix the finding or renew it with a reason")
    for f in blocking:
        print(f"BLOCKING {label(f)} {f['rule']} {f['path']}:{f['line']}")
    if args.suggest and blocking:
        suggestion = [{"rule": f["rule"], "path": f["path"], "line": f["line"], "fingerprint": f["fingerprint"],
                       "reason": "", "expires": ""} for f in blocking]
        print(json.dumps(suggestion, indent=2))
    sys.exit(1 if blocking else 0)


if __name__ == "__main__":
    main()
