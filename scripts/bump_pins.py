#!/usr/bin/env python3
"""Pin inventory and bumper (WP89). Stdlib only. Use through scripts/bump-pins.sh.

Every pin is one entry of PINS: file(s), a regex whose named groups are the values to rewrite, and how to resolve the
latest. Same-major only unless --major. Image tags and digests move together. Nothing is written without --apply.
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

SKOPEO_IMAGE = "quay.io/skopeo/stable:v1.20.0@sha256:47853bb9fb24202af9110531ebd6e43c5f97701254ca290596640290d17942f4"
# The digest must be the multi-arch index (arm64 laptop and amd64 runner); a platform manifest fails with "Exec format
# error" (run 42629848979). scripts/tests/test_pins_multiarch.py checks every executed pin.
DIGEST = r"sha256:[0-9a-f]{64}"


class Pin:
    def __init__(self, name, files, pattern, kind, **opts):
        self.name, self.files, self.kind, self.opts = name, files, kind, opts
        self.regex = re.compile(pattern, re.MULTILINE | re.DOTALL)


# Inventory. kind: image (repo + tag_re [+ floating tag, digest only]), release (GitHub releases), chart (OCI helm chart
# whose appVersion names the image whose digest is also pinned). File | group(s) | resolved by:
#   service.Containerfile  RUNTIME_IMAGE tag+digest   | skopeo list-tags + inspect
#   web.Containerfile      NGINX_IMAGE tag (even minor)| skopeo list-tags
#   values.yaml            redis tag, redpanda tag+digest, mailpit tag | skopeo
#   ci.yml images.yml sbom.sh aquasec/trivy tag       | skopeo list-tags (Docker Hub)
#   sbom.sh                cyclonedx-cli, oras tag+digest | skopeo
#   semgrep.yml            semgrep tag+digest         | skopeo
#   ci.yml zap-api-scan.sh zaproxy:stable digest      | skopeo inspect (floating tag)
#   kind/up.sh             Envoy Gateway, CNPG, ESO   | GitHub releases API
#   kind/up.sh             Reloader chart+digest+image digest | skopeo (OCI chart, appVersion)
# Gateway API (up.sh) is NOT bumped here: it must match Envoy Gateway's compatibility matrix (ADR-0031), by hand.
SEMVER = r"^v?(\d+\.\d+\.\d+)$"
PINS = [
    Pin("ubi9 openjdk-21-runtime", ["deploy/containers/service.Containerfile"],
        rf"openjdk-21-runtime:(?P<tag>[\w.\-]+)@(?P<digest>{DIGEST})", "image",
        repo="registry.access.redhat.com/ubi9/openjdk-21-runtime", tag_re=r"^(\d+\.\d+)$"),
    Pin("nginx-unprivileged", ["deploy/containers/web.Containerfile"],
        r"nginxinc/nginx-unprivileged:(?P<tag>[\w.\-]+)\n", "image",
        repo="docker.io/nginxinc/nginx-unprivileged", tag_re=r"^(\d+\.\d+)-alpine$", even_minor=True),
    Pin("redis (chart)", ["deploy/helm/hoops/values.yaml"],
        r"repository: docker\.io/library/redis, tag: (?P<tag>[\w.\-]+),", "image",
        repo="docker.io/library/redis", tag_re=r"^(\d+\.\d+\.\d+)-alpine$"),
    Pin("redpanda (chart)", ["deploy/helm/hoops/values.yaml"],
        rf"repository: docker\.io/redpandadata/redpanda\n\s+tag: (?P<tag>[\w.\-]+)\n\s+digest: (?P<digest>{DIGEST})",
        "image", repo="docker.io/redpandadata/redpanda", tag_re=SEMVER),
    Pin("mailpit (chart)", ["deploy/helm/hoops/values.yaml"],
        r"repository: docker\.io/axllent/mailpit, tag: (?P<tag>[\w.\-]+)\}", "image",
        repo="docker.io/axllent/mailpit", tag_re=SEMVER),
    Pin("trivy", [".github/workflows/ci.yml", ".github/workflows/images.yml", "scripts/sbom.sh"],
        r"aquasec/trivy:(?P<tag>[\w.\-]+)", "image", repo="docker.io/aquasec/trivy", tag_re=SEMVER),
    Pin("semgrep", [".github/workflows/semgrep.yml"],
        rf"semgrep/semgrep:(?P<tag>[\w.\-]+)@(?P<digest>{DIGEST})", "image",
        repo="docker.io/semgrep/semgrep", tag_re=SEMVER),
    Pin("cyclonedx-cli", ["scripts/sbom.sh"],
        rf"cyclonedx/cyclonedx-cli:(?P<tag>[\w.\-]+)@(?P<digest>{DIGEST})", "image",
        repo="docker.io/cyclonedx/cyclonedx-cli", tag_re=SEMVER),
    Pin("oras", ["scripts/sbom.sh"],
        rf"oras-project/oras:(?P<tag>[\w.\-]+)@(?P<digest>{DIGEST})", "image",
        repo="ghcr.io/oras-project/oras", tag_re=SEMVER),
    Pin("zaproxy stable", [".github/workflows/ci.yml", "scripts/zap-api-scan.sh"],
        rf"zaproxy/zaproxy:stable@(?P<digest>{DIGEST})", "image",
        repo="ghcr.io/zaproxy/zaproxy", floating="stable"),
    Pin("Envoy Gateway", ["deploy/kind/up.sh"], r'^ENVOY_GATEWAY_VERSION="(?P<tag>[^"]+)"', "release",
        gh="envoyproxy/gateway"),
    Pin("CloudNativePG", ["deploy/kind/up.sh"], r'^CNPG_VERSION="(?P<tag>[^"]+)"', "release",
        gh="cloudnative-pg/cloudnative-pg"),
    Pin("External Secrets Operator", ["deploy/kind/up.sh"], r'^ESO_VERSION="(?P<tag>[^"]+)"', "release",
        gh="external-secrets/external-secrets"),
    Pin("Stakater Reloader", ["deploy/kind/up.sh"],
        rf'image digest \((?P<app>v[\d.]+)\)\..*?^RELOADER_CHART_VERSION="(?P<tag>[^"]+)"\n'
        rf'RELOADER_CHART_DIGEST="(?P<digest>{DIGEST})"\nRELOADER_IMAGE_DIGEST="(?P<image_digest>{DIGEST})"',
        "chart", chart="ghcr.io/stakater/charts/reloader", image="ghcr.io/stakater/reloader",
        tag_re=r"^(\d+\.\d+\.\d+)$"),
]


def vtuple(text):
    return tuple(int(p) for p in re.findall(r"\d+", text))


def skopeo(*args):
    engine = os.environ.get("CONTAINER_ENGINE", "podman")
    cmd = [engine, "run", "--rm", SKOPEO_IMAGE, *args]
    done = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if done.returncode != 0:
        raise RuntimeError(f"{' '.join(args)}: {done.stderr.strip()[-300:]}")
    return done.stdout


def image_digest(repo, tag):
    return skopeo("inspect", "--format", "{{.Digest}}", f"docker://{repo}:{tag}").strip()


def chart_digest(repo, tag):
    return "sha256:" + hashlib.sha256(skopeo("inspect", "--raw", f"docker://{repo}:{tag}").encode()).hexdigest()


def pick(tags, tag_re, current, major, even_minor=False):
    """Highest tag matching tag_re; same major as `current` unless major is True. Returns (best, best_any)."""
    rx = re.compile(tag_re)
    cands = [(vtuple(m.group(1) if m.groups() else t), t) for t in tags if (m := rx.match(t))]
    if even_minor:
        cands = [c for c in cands if len(c[0]) < 2 or c[0][1] % 2 == 0]
    cur = vtuple(current)
    pool = [c for c in cands if major or c[0][0] == cur[0]]
    best = max(pool)[1] if pool else current
    anyv = max(cands)[1] if cands else current
    return best, anyv


def github_releases(repo):
    req = urllib.request.Request(f"https://api.github.com/repos/{repo}/releases?per_page=100",
                                 headers={"Accept": "application/vnd.github+json", "User-Agent": "hoops-bump-pins"})
    if os.environ.get("GITHUB_TOKEN"):
        req.add_header("Authorization", "Bearer " + os.environ["GITHUB_TOKEN"])
    with urllib.request.urlopen(req, timeout=30) as resp:  # nosemgrep: fixed https URL
        return [r["tag_name"] for r in json.load(resp) if not r["prerelease"] and not r["draft"]]


def resolve(pin, current, major):
    """Returns (new values for the pin's groups, release link, note)."""
    o, new, note = pin.opts, dict(current), ""
    if pin.kind == "image":
        if "floating" in o:
            new["digest"] = image_digest(o["repo"], o["floating"])
        else:
            tags = json.loads(skopeo("list-tags", f"docker://{o['repo']}"))["Tags"]
            new["tag"], anyv = pick(tags, o["tag_re"], current["tag"], major, o.get("even_minor", False))
            if "digest" in current:
                new["digest"] = image_digest(o["repo"], new["tag"])
            note = f"major {anyv} available (--major)" if anyv != new["tag"] and not major else ""
        return new, f"https://{o['repo'].replace('docker.io/', 'hub.docker.com/r/')}", note
    if pin.kind == "release":
        prefix = "v" if current["tag"].startswith("v") else ""
        tags = [t for t in github_releases(o["gh"]) if re.match(SEMVER, t)]
        best, anyv = pick(tags, SEMVER, current["tag"], major)
        new["tag"] = prefix + best.lstrip("v")
        note = f"major {anyv} available (--major)" if vtuple(anyv)[0] != vtuple(best)[0] and not major else ""
        return new, f"https://github.com/{o['gh']}/releases/tag/{prefix}{best.lstrip('v')}", note
    tags = json.loads(skopeo("list-tags", f"docker://{o['chart']}"))["Tags"]
    new["tag"], anyv = pick(tags, o["tag_re"], current["tag"], major)
    new["digest"] = chart_digest(o["chart"], new["tag"])
    new["app"] = json.loads(skopeo("inspect", "--config", "--raw", f"docker://{o['chart']}:{new['tag']}"))["appVersion"]
    new["image_digest"] = image_digest(o["image"], new["app"])
    note = f"major {anyv} available (--major)" if anyv != new["tag"] and not major else ""
    return new, f"https://github.com/stakater/Reloader/releases/tag/{new['app']}", note


def read_groups(pin, root):
    found = []
    for rel in pin.files:
        m = pin.regex.search((root / rel).read_text())
        if not m:
            raise RuntimeError(f"{pin.name}: pattern not found in {rel} (pin format changed?)")
        found.append(m.groupdict())
    if any(f != found[0] for f in found):
        raise RuntimeError(f"{pin.name}: the files disagree: {found}")
    return found[0]


def rewrite(pin, root, new):
    """Replace the named groups of every match of the pin in each of its files."""
    for rel in pin.files:
        path = root / rel
        text = path.read_text()
        spans = []
        for m in pin.regex.finditer(text):
            spans += [(m.start(n), m.end(n), new[n]) for n in pin.regex.groupindex]
        for start, end, value in sorted(spans, reverse=True):
            text = text[:start] + value + text[end:]
        path.write_text(text)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="list outdated pins, exit 1 if any")
    mode.add_argument("--apply", action="store_true", help="rewrite the files")
    ap.add_argument("--major", action="store_true", help="allow major version bumps")
    ap.add_argument("--markdown", action="store_true", help="markdown table (PR body)")
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent), help="repository root to read/write")
    args = ap.parse_args()
    root, rows, failed = Path(args.root), [], False
    for pin in PINS:
        try:
            cur = read_groups(pin, root)
            new, link, note = resolve(pin, cur, args.major)
        except (RuntimeError, OSError, ValueError) as err:
            print(f"ERROR {pin.name}: {err}", file=sys.stderr)
            failed = True
            continue
        changed = new != cur
        if changed and args.apply:
            rewrite(pin, root, new)
        show = lambda g: " ".join(str(g.get(k, ""))[:19] for k in ("tag", "digest") if g.get(k))  # noqa: E731
        rows.append((pin.name, show(cur), show(new) if changed else "", link, note, ", ".join(pin.files)))
    outdated = [r for r in rows if r[2]]
    if args.markdown:
        print("| Pin | Current | New | Release | Files |\n|---|---|---|---|---|")
        for n, c, nw, link, note, files in outdated:
            print(f"| {n} | `{c}` | `{nw}` | {link} | {files} |")
    else:
        for n, c, nw, link, note, _ in rows:
            line = f"OUTDATED {n}: {c} -> {nw}  {link}" if nw else f"ok       {n}: {c}"
            print(line + (f"  [{note}]" if note else ""))
        print(f"{len(outdated)} outdated of {len(rows)} pins")
    if failed:
        return 2
    return 1 if args.check and outdated else 0


if __name__ == "__main__":
    sys.exit(main())
