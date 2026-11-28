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
#   service.Containerfile  RUNTIME_IMAGE digest (distroless :nonroot) | skopeo inspect (floating tag)
#   web.Containerfile      NGINX_IMAGE tag (even minor)| skopeo list-tags
#   values.yaml            redis tag, mailpit tag     | skopeo
#   values.yaml compose.yaml consumer_test.go (finance)  redpanda tag+digest (one pin over the three files) | skopeo
#   microprofile-config.properties (common-quarkus)  redpanda tag of the Dev Services | skopeo
#   values.yaml compose.yaml  grafana/otel-lgtm tag+digest (one pin over both files) | skopeo
#   ci.yml image-publish action sbom.sh infra/tofu/check.sh  aquasec/trivy tag | skopeo list-tags (Docker Hub)
#   sbom.sh                cyclonedx-cli, oras tag+digest | skopeo
#   semgrep.yml            semgrep tag+digest         | skopeo
#   ci.yml zap-api-scan.sh zaproxy:stable digest      | skopeo inspect (floating tag)
#   deploy/lib/platform.sh Envoy Gateway, CNPG     | GitHub releases API (kind/up.sh and cloud/install.sh source it)
#   kind/up.sh             ESO                        | GitHub releases API
#   deploy/lib/platform.sh Reloader chart+digest+image digest | skopeo (OCI chart, appVersion)
#   compose.yaml databases values.yaml PostgresRlsResource pgtest.go images.yml  PostgreSQL version (one pin over the
#                          five files; docker.io/library/postgres:<v>-trixie, ghcr.io/cloudnative-pg/postgresql:
#                          <v>-minimal-trixie: the flavour stays outside the group) | skopeo list-tags of both registries:
#                          a version counts only when every registry publishes it in its flavour. Minor of the pinned
#                          major only; a pin naming the major alone ("19") stays and a newer major is only reported. The
#                          major moves by hand (WP144, ADR-0073).
# WP152 (TM-04, TM-05, AG-12): every image of the build carries its digest, and the pins that are not images carry a
# checksum that moves with the version:
#   service.Containerfile  maven builder tag+digest   | skopeo, newest tag published for amd64 and arm64 (multiarch)
#   web.Containerfile      nginx tag+digest, cirruslabs/flutter tag+digest | skopeo
#   keycloak               compose.yaml + chart values tag+digest (appVersion and the Testcontainers name: second entry)
#   databases values.yaml  CNPG postgresql image digest for the tag the postgresql entry wrote (track="digest")
#   values.yaml            redis, mailpit tag+digest
#   .mvn wrapper           Maven version + distributionSha256Sum | Maven Central (zip checked against its SHA-512)
#   setup-flutter action   Flutter version + SHA-256 of the linux archive | releases_linux.json of the stable channel
#   platform.sh            CNPG version + SHA-256 of the release manifest | the release asset's digest (GitHub API)
#   .semgrep/registry-rules.txt  SHA-256 of each registry ruleset | semgrep.dev (scripts/semgrep-rules.sh checks them)
#   .pre-commit-config.yaml  hook repos by commit SHA, tag in a comment | git ls-remote (peeled tag)
# Recorded from the pins, not pins themselves: the chart snapshots (deploy/helm/tests/run.sh --update) and the
# ExternalSecret schema of the ESO version (deploy/helm/tests/schemas/update-eso.sh). bump-pins.yml re-records both.
# Gateway API (platform.sh) is NOT bumped here: it must match Envoy Gateway's compatibility matrix (ADR-0031), by hand.
SEMVER = r"^v?(\d+\.\d+\.\d+)$"
PLATFORM = ["deploy/lib/platform.sh"]
PINS = [
    Pin("maven builder image", ["deploy/containers/service.Containerfile"],
        rf"docker\.io/library/maven:(?P<tag>[\w.\-]+)@(?P<digest>{DIGEST})", "image",
        repo="docker.io/library/maven", tag_re=r"^(\d+\.\d+\.\d+)-eclipse-temurin-25$", multiarch=True),
    Pin("maven wrapper", [".mvn/wrapper/maven-wrapper.properties"],
        r"apache-maven/(?P<tag>[\d.]+)/apache-maven-(?P<tag_file>[\d.]+)-bin\.zip\n.*?^distributionSha256Sum=(?P<sha256>[0-9a-f]{64})$",
        "maven"),
    Pin("flutter sdk (CI)", [".github/actions/setup-flutter/action.yml"],
        r"FLUTTER_VERSION: (?P<tag>\d+\.\d+\.\d+)\n\s+FLUTTER_SHA256: (?P<sha256>[0-9a-f]{64})", "flutter"),
    Pin("distroless java25 nonroot", ["deploy/containers/service.Containerfile"],
        rf"distroless/java25-debian13:nonroot@(?P<digest>{DIGEST})", "image",
        repo="gcr.io/distroless/java25-debian13", floating="nonroot"),
    Pin("nginx-unprivileged", ["deploy/containers/web.Containerfile"],
        rf"nginxinc/nginx-unprivileged:(?P<tag>[\w.\-]+)@(?P<digest>{DIGEST})\n", "image",
        repo="docker.io/nginxinc/nginx-unprivileged", tag_re=r"^(\d+\.\d+)-alpine$", even_minor=True),
    # cirruslabs publishes no newer Flutter than 3.44.0 (2026-11); the stage is built by no pipeline (ADR-0068 DEP-06).
    Pin("flutter image (container)", ["deploy/containers/web.Containerfile"],
        rf"cirruslabs/flutter:(?P<tag>[\w.\-]+)@(?P<digest>{DIGEST})", "image",
        repo="ghcr.io/cirruslabs/flutter", tag_re=SEMVER),
    Pin("redis (chart)", ["deploy/helm/hoops/values.yaml"],
        rf"repository: docker\.io/library/redis, tag: (?P<tag>[\w.\-]+), digest: (?P<digest>{DIGEST})\}}", "image",
        repo="docker.io/library/redis", tag_re=r"^(\d+\.\d+\.\d+)-alpine$"),
    # One Redpanda for the chart, compose and finance-service's Testcontainers broker (deploy/helm/tests/run.sh compares
    # them); the Quarkus Dev Services name the same tag without a digest, hence the second entry.
    Pin("redpanda (chart, compose, finance tests)",
        ["deploy/helm/hoops/values.yaml", "infra/compose/compose.yaml",
         "services/finance-service/internal/adapters/in/events/consumer_test.go"],
        rf"redpandadata/redpanda(?::|\n\s+tag: )(?P<tag>[\w.\-]+)(?:@|\n\s+digest: )(?P<digest>{DIGEST})",
        "image", repo="docker.io/redpandadata/redpanda", tag_re=SEMVER),
    Pin("redpanda (Dev Services)", ["libs/common-quarkus/src/main/resources/META-INF/microprofile-config.properties"],
        r"redpandadata/redpanda:(?P<tag>[\w.\-]+)$", "image", repo="docker.io/redpandadata/redpanda", tag_re=SEMVER),
    # Five places pin the same version (WP142, WP144); scripts/tests/test_postgres_pin.py checks that none is missing and
    # that each registry is named in its flavour.
    Pin("postgresql",
        ["infra/compose/compose.yaml", "deploy/helm/hoops/charts/databases/values.yaml",
         "libs/common-quarkus/src/test/java/com/hoopsacademy/common/testing/PostgresRlsResource.java",
         "services/finance-service/internal/testsupport/pgtest/pgtest.go", ".github/workflows/images.yml"],
        r"(?:library/postgres|cloudnative-pg/postgresql):(?P<tag>\d+(?:\.\d+)?)(?:-[a-z]+)*(?![\w.\-])", "image",
        repo="docker.io/library/postgres", tag_re=r"^(\d+(?:\.\d+)?)$", major_only_stays=True,
        flavours={"docker.io/library/postgres": "{}-trixie", "ghcr.io/cloudnative-pg/postgresql": "{}-minimal-trixie"}),
    # The database image the CNPG Cluster runs: the tag is the postgresql entry's (above, so it runs first), only the
    # digest of that tag is recomputed here.
    Pin("cloudnative-pg postgresql image", ["deploy/helm/hoops/charts/databases/values.yaml"],
        rf"cloudnative-pg/postgresql:(?P<tag>[\w.\-]+)@(?P<digest>{DIGEST})", "image",
        repo="ghcr.io/cloudnative-pg/postgresql", track="digest"),
    Pin("keycloak", ["infra/compose/compose.yaml", "deploy/helm/hoops/charts/keycloak/values.yaml"],
        rf'quay\.io/keycloak/keycloak(?::|\n\s+tag: ")(?P<tag>[\w.\-]+)(?:@|"\n\s+digest: )(?P<digest>{DIGEST})', "image",
        repo="quay.io/keycloak/keycloak", tag_re=SEMVER),
    # the chart's appVersion and the Testcontainers name of the realm tests follow the version above
    Pin("keycloak (appVersion, tests)",
        ["deploy/helm/hoops/charts/keycloak/Chart.yaml",
         "libs/common-quarkus/src/test/java/com/hoopsacademy/common/testing/TestRealm.java"],
        r'(?:appVersion: "|KEYCLOAK_IMAGE = "quay\.io/keycloak/keycloak:)(?P<tag>\d+\.\d+\.\d+)"', "image",
        repo="quay.io/keycloak/keycloak", tag_re=SEMVER),
    Pin("mailpit (chart)", ["deploy/helm/hoops/values.yaml"],
        rf"repository: docker\.io/axllent/mailpit, tag: (?P<tag>[\w.\-]+), digest: (?P<digest>{DIGEST})\}}", "image",
        repo="docker.io/axllent/mailpit", tag_re=SEMVER),
    # WP120: the dev-only Grafana LGTM pod (chart) and container (compose profile observability) move together.
    Pin("grafana otel-lgtm (chart, compose)", ["deploy/helm/hoops/values.yaml", "infra/compose/compose.yaml"],
        rf"grafana/otel-lgtm(?::|\n\s+tag: )(?P<tag>[\w.\-]+)(?:@|\n\s+digest: )(?P<digest>{DIGEST})", "image",
        repo="docker.io/grafana/otel-lgtm", tag_re=r"^(\d+\.\d+\.\d+)$"),
    Pin("trivy", [".github/workflows/ci.yml", ".github/actions/image-publish/action.yml", "scripts/sbom.sh",
                  "infra/tofu/check.sh"],
        rf"aquasec/trivy:(?P<tag>[\w.\-]+)@(?P<digest>{DIGEST})", "image", repo="docker.io/aquasec/trivy",
        tag_re=SEMVER),
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
    # kind and the cloud VM install the same operators from one sourced file (infra/tofu/check.sh, DEP-02).
    Pin("Envoy Gateway", PLATFORM, r'^ENVOY_GATEWAY_VERSION="(?P<tag>[^"]+)"', "release",
        gh="envoyproxy/gateway"),
    Pin("CloudNativePG", PLATFORM,
        r'^CNPG_VERSION="(?P<tag>[^"]+)"\nCNPG_MANIFEST_SHA256="(?P<sha256>[0-9a-f]{64})"', "release",
        gh="cloudnative-pg/cloudnative-pg", asset="cnpg-{version}.yaml"),
    Pin("External Secrets Operator", ["deploy/kind/up.sh"], r'^ESO_VERSION="(?P<tag>[^"]+)"', "release",
        gh="external-secrets/external-secrets"),
    Pin("Stakater Reloader", PLATFORM,
        rf'image digest \((?P<app>v[\d.]+)\)\..*?^RELOADER_CHART_VERSION="(?P<tag>[^"]+)"\n'
        rf'RELOADER_CHART_DIGEST="(?P<digest>{DIGEST})"\nRELOADER_IMAGE_DIGEST="(?P<image_digest>{DIGEST})"',
        "chart", chart="ghcr.io/stakater/charts/reloader", image="ghcr.io/stakater/reloader",
        tag_re=r"^(\d+\.\d+\.\d+)$"),
    Pin("semgrep rulesets", [".semgrep/registry-rules.txt"],
        r"^p/java (?P<java>[0-9a-f]{64})$.*^p/rust (?P<rust>[0-9a-f]{64})$.*^p/golang (?P<golang>[0-9a-f]{64})$.*"
        r"^p/owasp-top-ten (?P<owasp>[0-9a-f]{64})$", "semgrep-rules"),
    Pin("pre-commit gitleaks", [".pre-commit-config.yaml"],
        r"github\.com/gitleaks/gitleaks\n\s+rev: (?P<sha>[0-9a-f]{40}) # frozen: (?P<tag>v[\d.]+)", "git-tag",
        git="https://github.com/gitleaks/gitleaks"),
    Pin("pre-commit hooks", [".pre-commit-config.yaml"],
        r"github\.com/pre-commit/pre-commit-hooks\n\s+rev: (?P<sha>[0-9a-f]{40}) # frozen: (?P<tag>v[\d.]+)",
        "git-tag", git="https://github.com/pre-commit/pre-commit-hooks"),
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


def list_tags(repo):
    return json.loads(skopeo("list-tags", f"docker://{repo}"))["Tags"]


def published_everywhere(flavours):
    """The versions every registry publishes in its flavour ({repo: "{}-minimal-trixie"}), as bare version tags."""
    found = []
    for repo, flavour in flavours.items():
        rx = re.compile("^" + re.escape(flavour).replace(r"\{\}", r"(\d+(?:\.\d+)?)") + "$")
        found.append({m.group(1) for t in list_tags(repo) if (m := rx.match(t))})
    return sorted(set.intersection(*found), key=vtuple)


def image_digest(repo, tag):
    return skopeo("inspect", "--format", "{{.Digest}}", f"docker://{repo}:{tag}").strip()


def chart_digest(repo, tag):
    return "sha256:" + hashlib.sha256(skopeo("inspect", "--raw", f"docker://{repo}:{tag}").encode()).hexdigest()


def pick(tags, tag_re, current, major, even_minor=False, usable=None):
    """Highest tag matching tag_re; same major as `current` unless major is True. Returns (best, best_any).
    `usable(tag)` (optional) skips a tag the caller cannot use, e.g. one not yet published for every architecture."""
    rx = re.compile(tag_re)
    cands = [(vtuple(m.group(1) if m.groups() else t), t) for t in tags if (m := rx.match(t))]
    if even_minor:
        cands = [c for c in cands if len(c[0]) < 2 or c[0][1] % 2 == 0]
    cur = vtuple(current)
    pool = sorted((c for c in cands if major or c[0][0] == cur[0]), reverse=True)
    if usable:
        pool = [c for c in pool if usable(c[1])]
    best = pool[0][1] if pool else current
    anyv = max(cands)[1] if cands else current
    return best, anyv


def has_both_architectures(repo, tag):
    """True when the tag is an index naming linux/amd64 and linux/arm64 (a digest of one platform fails on the other)."""
    doc = json.loads(skopeo("inspect", "--raw", f"docker://{repo}:{tag}"))
    return {"amd64", "arm64"} <= {m.get("platform", {}).get("architecture") for m in doc.get("manifests", [])}


def http_get(url, accept=None):
    req = urllib.request.Request(url, headers={"User-Agent": "hoops-bump-pins", **({"Accept": accept} if accept else {})})
    if os.environ.get("GITHUB_TOKEN") and url.startswith("https://api.github.com/"):
        req.add_header("Authorization", "Bearer " + os.environ["GITHUB_TOKEN"])
    with urllib.request.urlopen(req, timeout=120) as resp:  # nosemgrep: fixed https URLs of the pin inventory
        return resp.read()


def release_asset_digest(gh, tag, name):
    """The SHA-256 GitHub records for a release asset (the publisher's upload), without downloading it."""
    assets = json.loads(http_get(f"https://api.github.com/repos/{gh}/releases/tags/{tag}"))["assets"]
    digest = next(a["digest"] for a in assets if a["name"] == name)
    return digest.removeprefix("sha256:")


def maven_versions():
    xml = http_get("https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/maven-metadata.xml").decode()
    return re.findall(r"<version>(\d+\.\d+\.\d+)</version>", xml)


def maven_distribution_sha256(version):
    """SHA-256 of the -bin.zip, computed on the download that Maven Central's own SHA-512 vouches for."""
    url = f"https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/{version}/apache-maven-{version}-bin.zip"
    data = http_get(url)
    published = http_get(url + ".sha512").decode().split()[0]
    if hashlib.sha512(data).hexdigest() != published:
        raise RuntimeError(f"maven {version}: the download does not match Central's SHA-512")
    return hashlib.sha256(data).hexdigest()


def flutter_releases():
    """[(version, sha256 of the linux archive)] of the stable channel (storage.googleapis.com release manifest)."""
    doc = json.loads(http_get("https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"))
    return [(r["version"], r["sha256"]) for r in doc["releases"]
            if r["channel"] == "stable" and re.fullmatch(r"\d+\.\d+\.\d+", r["version"])]


SEMGREP_RULESETS = {"java": "p/java", "rust": "p/rust", "golang": "p/golang", "owasp": "p/owasp-top-ten"}


def ruleset_sha256(ruleset):
    return hashlib.sha256(http_get(f"https://semgrep.dev/c/{ruleset}")).hexdigest()


def git_tag_commit(url, tag):
    """The commit a tag names: the peeled line of an annotated tag, else the tag's own line (never a tag object)."""
    out = subprocess.run(["git", "ls-remote", "--tags", url, f"refs/tags/{tag}", f"refs/tags/{tag}^{{}}"],
                         capture_output=True, text=True, check=True).stdout.split("\n")
    refs = dict(reversed(line.split("\t")) for line in out if line)
    return refs.get(f"refs/tags/{tag}^{{}}") or refs[f"refs/tags/{tag}"]


def git_tags(url):
    out = subprocess.run(["git", "ls-remote", "--tags", "--refs", url], capture_output=True, text=True, check=True).stdout
    return [line.split("refs/tags/")[1] for line in out.splitlines()]


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
        elif o.get("track") == "digest":  # the tag is another pin's; follow it
            new["digest"] = image_digest(o["repo"], current["tag"])
        else:
            tags = published_everywhere(o["flavours"]) if "flavours" in o else list_tags(o["repo"])
            usable = (lambda t: has_both_architectures(o["repo"], t)) if o.get("multiarch") else None
            new["tag"], anyv = pick(tags, o["tag_re"], current["tag"], major, o.get("even_minor", False), usable)
            if o.get("major_only_stays") and len(vtuple(current["tag"])) == 1 and not major:
                new["tag"] = current["tag"]  # a floating major ("19") has no minor to bump
            if "digest" in current:
                new["digest"] = image_digest(o["repo"], new["tag"])
            note = f"major {anyv} available (--major)" if vtuple(anyv)[0] > vtuple(new["tag"])[0] and not major else ""
        return new, f"https://{o['repo'].replace('docker.io/', 'hub.docker.com/r/')}", note
    if pin.kind == "release":
        prefix = "v" if current["tag"].startswith("v") else ""
        tags = [t for t in github_releases(o["gh"]) if re.match(SEMVER, t)]
        best, anyv = pick(tags, SEMVER, current["tag"], major)
        new["tag"] = prefix + best.lstrip("v")
        if "asset" in o:  # a checksum of the release's manifest travels with the version
            version = new["tag"].lstrip("v")
            new["sha256"] = release_asset_digest(o["gh"], "v" + version, o["asset"].format(version=version))
        note = f"major {anyv} available (--major)" if vtuple(anyv)[0] != vtuple(best)[0] and not major else ""
        return new, f"https://github.com/{o['gh']}/releases/tag/{prefix}{best.lstrip('v')}", note
    if pin.kind == "maven":
        best, anyv = pick(maven_versions(), SEMVER, current["tag"], major)
        new.update(tag=best, tag_file=best, sha256=maven_distribution_sha256(best) if best != current["tag"]
                   else current["sha256"])
        note = f"major {anyv} available (--major)" if vtuple(anyv)[0] > vtuple(best)[0] and not major else ""
        return new, f"https://maven.apache.org/docs/{best}/release-notes.html", note
    if pin.kind == "flutter":
        known = dict(flutter_releases())
        best, anyv = pick(list(known), SEMVER, current["tag"], major)
        new.update(tag=best, sha256=known[best])
        note = f"major {anyv} available (--major)" if vtuple(anyv)[0] > vtuple(best)[0] and not major else ""
        return new, f"https://github.com/flutter/flutter/releases/tag/{best}", note
    if pin.kind == "semgrep-rules":
        new = {name: ruleset_sha256(ruleset) for name, ruleset in SEMGREP_RULESETS.items()}
        return new, "https://semgrep.dev/explore", ""
    if pin.kind == "git-tag":
        best, anyv = pick(git_tags(o["git"]), SEMVER, current["tag"], major)
        new.update(tag=best, sha=git_tag_commit(o["git"], best))
        note = f"major {anyv} available (--major)" if vtuple(anyv)[0] > vtuple(best)[0] and not major else ""
        return new, f"{o['git']}/releases/tag/{best}", note
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


def by_hand(pin, skip_workflows):
    """True for a pin --apply must leave alone: one of its files is a workflow and GITHUB_TOKEN may not push those."""
    return skip_workflows and any(rel.startswith(".github/workflows/") for rel in pin.files)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="list outdated pins, exit 1 if any")
    mode.add_argument("--apply", action="store_true", help="rewrite the files")
    ap.add_argument("--major", action="store_true", help="allow major version bumps")
    ap.add_argument("--markdown", action="store_true", help="markdown table (PR body)")
    ap.add_argument("--skip-workflows", action="store_true",
                    help="--apply leaves pins that live in .github/workflows alone and lists them as manual")
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
        manual = changed and by_hand(pin, args.skip_workflows)
        if changed and args.apply and not manual:
            rewrite(pin, root, new)
        shown = ("tag", "digest", "sha256", "sha", *SEMGREP_RULESETS)  # what a row of the table names
        show = lambda g: " ".join(str(g[k])[:19] for k in shown if g.get(k))  # noqa: E731
        rows.append((pin.name, show(cur), show(new) if changed else "", link, note, ", ".join(pin.files), manual))
    outdated = [r for r in rows if r[2]]
    if args.markdown:
        head = "| Pin | Current | New | Release | Files |\n|---|---|---|---|---|"
        print(head)
        for n, c, nw, link, note, files, manual in outdated:
            if not manual:
                print(f"| {n} | `{c}` | `{nw}` | {link} | {files} |")
        if any(r[6] for r in outdated):
            print("\n**Not in this PR, bump by hand** (workflow files: the Actions token may not push them; run "
                  "`scripts/bump-pins.sh --apply` locally):\n\n" + head)
            for n, c, nw, link, note, files, manual in outdated:
                if manual:
                    print(f"| {n} | `{c}` | `{nw}` | {link} | {files} |")
    else:
        for n, c, nw, link, note, _, _ in rows:
            line = f"OUTDATED {n}: {c} -> {nw}  {link}" if nw else f"ok       {n}: {c}"
            print(line + (f"  [{note}]" if note else ""))
        print(f"{len(outdated)} outdated of {len(rows)} pins")
    if failed:
        return 2
    return 1 if args.check and outdated else 0


if __name__ == "__main__":
    sys.exit(main())
