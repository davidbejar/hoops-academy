#!/usr/bin/env python3
"""Write config/docs/requirements.txt with a SHA-256 for every file of every pinned version (AG-12, pip --require-hashes).
Stdlib only. The pins (name==version) are read from the file; each version's files come from PyPI's JSON API.

    python3 -I scripts/docs_requirements.py            # rewrite the hashes of the current pins
    python3 -I scripts/docs_requirements.py --check    # exit 1 when a line has no hash (CI runs scripts/tests instead)

New versions: install zensical unpinned in a fresh virtualenv, `pip freeze`, replace the name==version lines, run this
script, then `just docs-build` (docs/runbooks/docs-site.md). Dependabot (pip, /config/docs) keeps the hashes of its own PRs.
"""
import json
import pathlib
import re
import sys
import urllib.request

REQ = pathlib.Path(__file__).resolve().parent.parent / "config/docs/requirements.txt"
LINE = re.compile(r"^(?P<name>[A-Za-z][\w.\-]*)==(?P<version>[\w.]+)")


def file_hashes(name, version):
    url = f"https://pypi.org/pypi/{name}/{version}/json"
    with urllib.request.urlopen(url, timeout=60) as resp:  # nosemgrep: fixed https URL of the package index
        files = json.load(resp)["urls"]
    return sorted({f["digests"]["sha256"] for f in files})


def render(text):
    header, pins = [], []
    for line in text.replace("\\\n", " ").splitlines():
        m = LINE.match(line)
        (pins if m else header).append(m.groupdict() if m else line)
    out = list(header)
    for p in pins:
        hashes = file_hashes(p["name"], p["version"])
        out.append(f"{p['name']}=={p['version']} \\")
        out.extend(f"    --hash=sha256:{h}" + (" \\" if i < len(hashes) - 1 else "") for i, h in enumerate(hashes))
    return "\n".join(out) + "\n"


def main():
    text = REQ.read_text()
    if "--check" in sys.argv:
        loose = [l for l in text.replace("\\\n", " ").splitlines() if LINE.match(l) and "--hash=sha256:" not in l]
        print("\n".join(f"no hash: {l}" for l in loose))
        return 1 if loose else 0
    REQ.write_text(render(text))
    return 0


if __name__ == "__main__":
    sys.exit(main())
