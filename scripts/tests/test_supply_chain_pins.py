"""Supply-chain pins (WP152; TM-04, TM-05, AG-12): what builds an image, runs in CI or runs in an agent's shell is held
by a digest or a checksum, and scripts/bump_pins.py tracks each one so the weekly bump moves it.
- every registry image reference of the build and deploy files carries `@sha256:` (a short allow-list says why not);
- the Maven wrapper checks its distribution, Maven fails on a checksum mismatch;
- every package resolution (`flutter pub get`) is held to pubspec.lock;
- the CloudNativePG manifest comes from the release tag and is checked against its SHA-256 before it is applied;
- Flutter is installed from its release archive and checked against a SHA-256 (like Go, setup-go);
- Semgrep's registry rulesets are fetched against pinned hashes, the pre-commit hooks are pinned by commit SHA, the docs
  site's Python dependencies by hash.
Run: python3 -I -m unittest discover -s scripts/tests"""
import hashlib
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import bump_pins  # noqa: E402

SHA256 = r"[0-9a-f]{64}"
DIGEST = r"sha256:[0-9a-f]{64}"
# registry-qualified references, plus the one Docker Hub reference that is written without its registry
IMAGE = re.compile(r"(?<![\w./-])((?:(?:docker\.io|quay\.io|ghcr\.io|gcr\.io)/|aquasec/)[a-z0-9][a-z0-9._/-]*):"
                   r"([A-Za-z0-9_][A-Za-z0-9_.-]*)(@sha256:[0-9a-f]{64})?")
SCANNED = [".github", "scripts", "deploy", "infra/compose", "infra/tofu/check.sh", "apps/web/tool"]
SKIPPED_PARTS = {"tests", "snapshots"}
# (file, image) pairs that stay by tag, each with the reason; a new reference must not join without one
BY_TAG = {
    ("infra/compose/compose.yaml", "docker.io/library/postgres:19.0-trixie"):
        "the owner's dev database: one version pin over five files (postgres pin), tracked by tag on purpose",
    ("infra/compose/compose.yaml", "docker.io/library/nginx:1.30-alpine"): "dev reverse proxy of the local stack",
    (".github/workflows/images.yml", "docker.io/library/postgres:19.0-trixie"):
        "throw-away test database of the finance image check (postgres pin)",
    ("apps/web/tool/lighthouse.sh", "docker.io/library/nginx:1.27-alpine"): "local Lighthouse run, nothing shipped",
    ("apps/web/tool/lighthouse.sh", "docker.io/femtopixel/google-lighthouse:v11.7.1"):
        "local Lighthouse run on the developer's machine, nothing shipped",
}


def text(rel):
    return (ROOT / rel).read_text()


def pin(name):
    return next(p for p in bump_pins.PINS if p.name == name)


def scanned_files():
    out = subprocess.run(["git", "ls-files", "--", *SCANNED], cwd=ROOT, capture_output=True, text=True,
                         check=True).stdout.split()
    return [rel for rel in out if not SKIPPED_PARTS & set(pathlib.PurePath(rel).parts)
            and not rel.endswith((".png", ".json"))]


class ImagesCarryADigest(unittest.TestCase):
    def test_every_registry_image_reference_has_a_digest(self):
        bare = []
        for rel in scanned_files():
            for m in IMAGE.finditer(text(rel)):
                if not m[3] and (rel, f"{m[1]}:{m[2]}") not in BY_TAG:
                    bare.append(f"{rel}: {m[1]}:{m[2]}")
        self.assertEqual(bare, [], "images by tag only (pin the digest and add the file to a bump_pins entry)")

    def test_the_allow_list_has_no_stale_entry(self):
        for rel, image in BY_TAG:
            with self.subTest(file=rel, image=image):
                self.assertIn(image, text(rel))

    def test_the_container_files_name_their_builder_by_digest(self):
        self.assertRegex(text("deploy/containers/service.Containerfile"),
                         rf"(?m)^ARG MAVEN_IMAGE=docker\.io/library/maven:\d+\.\d+\.\d+-eclipse-temurin-25@{DIGEST}$")
        self.assertRegex(text("deploy/containers/web.Containerfile"),
                         rf"(?m)^ARG NGINX_IMAGE=docker\.io/nginxinc/nginx-unprivileged:\d+\.\d+-alpine@{DIGEST}$")
        self.assertRegex(text("deploy/containers/web.Containerfile"),
                         rf"(?m)^ARG FLUTTER_IMAGE=ghcr\.io/cirruslabs/flutter:\d+\.\d+\.\d+@{DIGEST}$")

    def test_the_chart_pins_redis_mailpit_keycloak_and_the_database_image_by_digest(self):
        self.assertRegex(text("deploy/helm/hoops/values.yaml"),
                         rf"repository: docker\.io/library/redis, tag: [\w.\-]+, digest: {DIGEST}\}}")
        self.assertRegex(text("deploy/helm/hoops/values.yaml"),
                         rf"repository: docker\.io/axllent/mailpit, tag: [\w.\-]+, digest: {DIGEST}\}}")
        self.assertRegex(text("deploy/helm/hoops/charts/keycloak/values.yaml"),
                         rf'(?m)^  tag: "[\d.]+"\n  digest: {DIGEST}$')
        self.assertRegex(text("deploy/helm/hoops/charts/databases/values.yaml"),
                         rf"(?m)^imageName: ghcr\.io/cloudnative-pg/postgresql:[\w.\-]+@{DIGEST}$")

    def test_the_keycloak_templates_render_the_digest(self):
        self.assertIn("digest", text("deploy/helm/hoops/charts/keycloak/templates/keycloak.yaml"))
        self.assertIn("digest", text("deploy/helm/hoops/templates/mailpit.yaml"))


class EveryDigestIsTracked(unittest.TestCase):
    """A digest that no PINS entry moves goes stale unseen: each image below belongs to an entry with a digest group."""
    WITH_DIGEST = ["maven builder image", "nginx-unprivileged", "flutter image (container)", "trivy", "keycloak",
                   "redis (chart)", "mailpit (chart)", "cloudnative-pg postgresql image"]

    def test_the_pins_exist_and_carry_a_digest(self):
        for name in self.WITH_DIGEST:
            with self.subTest(pin=name):
                self.assertIn("digest", pin(name).regex.groupindex)
                self.assertIn("digest", bump_pins.read_groups(pin(name), ROOT))

    def test_every_file_naming_a_keycloak_image_belongs_to_the_pin(self):
        named = set(subprocess.run(["git", "grep", "-lE", r"quay\.io/keycloak/keycloak", "--", ".", ":!docs",
                                    ":!scripts/tests", ":!scripts/bump_pins.py", ":!deploy/helm/tests/snapshots",
                                    ":!audit"], cwd=ROOT, capture_output=True, text=True).stdout.split())
        covered = set(pin("keycloak").files) | set(pin("keycloak (appVersion, tests)").files)
        self.assertEqual(named - covered - {"services/core-service/README.md"}, set())

    def test_the_multi_arch_scan_covers_the_actions_and_the_chart(self):
        sys.path.insert(0, str(ROOT / "scripts/tests"))
        import test_pins_multiarch
        self.assertTrue({".github/actions", "deploy/helm/hoops", "deploy/lib"} <= set(test_pins_multiarch.SCANNED))

    def test_the_bump_prefers_a_tag_published_for_amd64_and_arm64(self):
        self.assertTrue(pin("maven builder image").opts.get("multiarch"))

    def test_the_flavour_digest_follows_the_postgres_tag(self):
        # the database image's digest is recomputed for whatever tag the postgres pin wrote (same file, earlier entry)
        names = [p.name for p in bump_pins.PINS]
        self.assertLess(names.index("postgresql"), names.index("cloudnative-pg postgresql image"))


class MavenIntegrity(unittest.TestCase):
    def test_the_wrapper_checks_the_maven_distribution(self):
        props = text(".mvn/wrapper/maven-wrapper.properties")
        self.assertRegex(props, rf"(?m)^distributionSha256Sum={SHA256}$")

    def test_maven_fails_on_a_checksum_mismatch(self):
        config = text(".mvn/maven.config").split()
        self.assertTrue({"-C", "--strict-checksums"} & set(config), config)

    def test_the_wrapper_pin_is_tracked(self):
        self.assertIn("sha256", pin("maven wrapper").regex.groupindex)
        self.assertIn("sha256", bump_pins.read_groups(pin("maven wrapper"), ROOT))


class PubIsHeldToTheLockFile(unittest.TestCase):
    ALLOWED = {"scripts/gen-api.sh": "`dart pub get` in the generated client packages, which have no lock file"}

    def test_every_flutter_pub_get_enforces_the_lock_file(self):
        out = subprocess.run(["git", "grep", "-nE", r"(^|[^`])flutter pub get([^`]|$)", "--", ".github", "scripts", "deploy",
                              "justfile", "Tiltfile", "start.sh", "apps/web/tool", ":!scripts/tests"],
                             cwd=ROOT, capture_output=True, text=True).stdout.splitlines()
        self.assertTrue(out)
        loose = [line for line in out if "--enforce-lockfile" not in line]
        self.assertEqual(loose, [])

    def test_the_allow_list_is_current(self):
        for rel in self.ALLOWED:
            self.assertIn("pub get", text(rel))


class FlutterIsInstalledFromItsArchive(unittest.TestCase):
    ACTION = ".github/actions/setup-flutter/action.yml"

    def test_the_action_follows_no_channel_and_checks_a_sha256(self):
        body = text(self.ACTION)
        self.assertNotIn("channel: stable", body)
        self.assertNotIn("subosito", body)
        self.assertRegex(body, rf"FLUTTER_VERSION: \d+\.\d+\.\d+\n\s+FLUTTER_SHA256: {SHA256}")
        self.assertIn("sha256sum -c", body)

    def test_the_pin_is_tracked(self):
        groups = bump_pins.read_groups(pin("flutter sdk (CI)"), ROOT)
        self.assertEqual(set(groups), {"tag", "sha256"})


class CloudNativePgManifestIsChecked(unittest.TestCase):
    PLATFORM = "deploy/lib/platform.sh"

    def test_it_is_fetched_from_the_release_not_a_branch(self):
        body = text(self.PLATFORM)
        self.assertNotIn("CNPG_BRANCH", body)
        self.assertRegex(body, r"releases/download/v\$\{CNPG_VERSION\}/cnpg-\$\{CNPG_VERSION\}\.yaml")
        self.assertRegex(body, rf'(?m)^CNPG_MANIFEST_SHA256="{SHA256}"$')

    def test_the_pin_tracks_the_version_and_the_checksum(self):
        self.assertEqual(set(bump_pins.read_groups(pin("CloudNativePG"), ROOT)), {"tag", "sha256"})

    def run_install(self, served, expected):
        """install_cnpg with a stub curl (writes `served`) and a stub kubectl; returns (exit code, kubectl calls)."""
        with tempfile.TemporaryDirectory() as tmp:
            calls = pathlib.Path(tmp) / "calls"
            script = (f'set -euo pipefail\ncd "{ROOT}"\n. {self.PLATFORM}\nCNPG_MANIFEST_SHA256="{expected}"\n'
                      f'curl() {{ while [ "$#" -gt 0 ]; do [ "$1" = -o ] && {{ printf %s "$SERVED" > "$2"; }}; shift; done; }}\n'
                      f'stubctl() {{ echo "$*" >> "{calls}"; }}\ninstall_cnpg stubctl\n')
            done = subprocess.run(["bash", "-c", script], env={**os.environ, "SERVED": served}, capture_output=True,
                                  text=True)
            return done.returncode, calls.read_text() if calls.exists() else ""

    def test_a_matching_manifest_is_applied_from_a_file(self):
        code, calls = self.run_install("kind: Namespace\n", hashlib.sha256(b"kind: Namespace\n").hexdigest())
        self.assertEqual(code, 0)
        self.assertRegex(calls, r"apply --server-side --force-conflicts -f \S+")

    def test_a_manifest_that_does_not_match_is_never_applied(self):
        code, calls = self.run_install("kind: Namespace\n# tampered\n", hashlib.sha256(b"kind: Namespace\n").hexdigest())
        self.assertNotEqual(code, 0)
        self.assertEqual(calls, "")


class SemgrepRulesArePinned(unittest.TestCase):
    def test_the_workflow_fetches_no_unpinned_ruleset(self):
        body = text(".github/workflows/semgrep.yml")
        self.assertNotRegex(body, r"--config p/")
        self.assertIn("scripts/semgrep-rules.sh", body)

    def test_the_hashes_are_committed_and_tracked(self):
        groups = bump_pins.read_groups(pin("semgrep rulesets"), ROOT)
        self.assertEqual(set(groups), set(bump_pins.SEMGREP_RULESETS))
        for value in groups.values():
            self.assertRegex(value, SHA256)

    def test_the_gate_strips_the_prefix_semgrep_gives_a_config_directory(self):
        body = text(".github/workflows/semgrep.yml")
        self.assertIn("--strip-rule-prefix semgrep-registry.", body)
        self.assertIn("--config semgrep-registry/", body)

    def test_the_fetched_rules_are_not_scanned_themselves(self):
        self.assertIn("semgrep-registry/", text(".semgrepignore"))
        self.assertIn("semgrep-registry/", text(".gitignore"))

    def run_fetch(self, served):
        """scripts/semgrep-rules.sh with a stub curl that writes `served`; returns (exit code, files written)."""
        with tempfile.TemporaryDirectory() as tmp:
            bin_dir = pathlib.Path(tmp) / "bin"
            bin_dir.mkdir()
            stub = bin_dir / "curl"
            stub.write_text('#!/bin/sh\nwhile [ "$#" -gt 0 ]; do [ "$1" = -o ] && printf %s "$SERVED" > "$2"; shift; done\n')
            stub.chmod(0o755)
            out = pathlib.Path(tmp) / "out"
            done = subprocess.run([str(ROOT / "scripts/semgrep-rules.sh"), str(out)], capture_output=True, text=True,
                                  env={**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}", "SERVED": served})
            return done.returncode, done.stderr, sorted(f.name for f in out.glob("*.yml"))

    def test_the_fetch_script_refuses_a_ruleset_that_changed(self):
        code, err, written = self.run_fetch("rules: []\n")
        self.assertEqual(code, 1)
        self.assertIn("changed upstream", err)
        self.assertEqual(written, [])


class PreCommitHooksArePinnedByCommit(unittest.TestCase):
    def test_every_remote_hook_repo_is_a_commit_sha_with_its_tag_in_a_comment(self):
        revs = re.findall(r"(?m)^\s+rev: (\S+)(.*)$", text(".pre-commit-config.yaml"))
        self.assertTrue(revs)
        for rev, comment in revs:
            with self.subTest(rev=rev):
                self.assertRegex(rev, r"^[0-9a-f]{40}$")
                self.assertRegex(comment, r"# frozen: v\d+\.\d+\.\d+")


class DocsRequirementsCarryHashes(unittest.TestCase):
    REQ = "config/docs/requirements.txt"

    def test_every_requirement_has_a_hash_and_pip_requires_them(self):
        body = text(self.REQ)
        names = re.findall(r"(?m)^([A-Za-z][\w.-]*)==", body)
        self.assertGreaterEqual(len(names), 11)
        for name in names:
            with self.subTest(requirement=name):
                block = re.search(rf"(?m)^{re.escape(name)}==[^\n]*(?:\n[ \t]+[^\n]*)*", body)[0]
                self.assertRegex(block, rf"--hash=sha256:{SHA256}")
        self.assertIn("--require-hashes", text("justfile"))

    def test_the_requirements_have_no_unhashed_line(self):
        for line in text(self.REQ).replace("\\\n", " ").splitlines():
            if re.match(r"^[A-Za-z]", line):
                self.assertIn("--hash=sha256:", line, line)


class BumpRewritesWhatItTracks(unittest.TestCase):
    """The weekly bump rewrites each new pin in every file it names, so the copies cannot drift apart."""
    NEW = {
        "maven wrapper": {"tag": "9.9.9", "tag_file": "9.9.9", "sha256": "a" * 64},
        "flutter sdk (CI)": {"tag": "9.9.9", "sha256": "b" * 64},
        "CloudNativePG": {"tag": "9.9.9", "sha256": "c" * 64},
        "semgrep rulesets": {k: "d" * 64 for k in bump_pins.SEMGREP_RULESETS},
        "pre-commit gitleaks": {"tag": "v9.9.9", "sha": "e" * 40},
        "pre-commit hooks": {"tag": "v9.9.9", "sha": "f" * 40},
        "keycloak": {"tag": "9.9.9", "digest": "sha256:" + "1" * 64},
        "cloudnative-pg postgresql image": {"tag": "9.9-minimal-trixie", "digest": "sha256:" + "2" * 64},
        "maven builder image": {"tag": "9.9.9-eclipse-temurin-25", "digest": "sha256:" + "3" * 64},
        "mailpit (chart)": {"tag": "v9.9.9", "digest": "sha256:" + "4" * 64},
    }

    def test_each_pin_is_rewritten_in_all_its_files(self):
        for name, new in self.NEW.items():
            with self.subTest(pin=name), tempfile.TemporaryDirectory() as tmp:
                root = pathlib.Path(tmp)
                for rel in pin(name).files:
                    (root / rel).parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy(ROOT / rel, root / rel)
                bump_pins.rewrite(pin(name), root, new)
                self.assertEqual(bump_pins.read_groups(pin(name), root), new)

    def test_the_maven_wrapper_names_the_new_version_in_the_url_and_the_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            rel = ".mvn/wrapper/maven-wrapper.properties"
            (root / rel).parent.mkdir(parents=True)
            shutil.copy(ROOT / rel, root / rel)
            bump_pins.rewrite(pin("maven wrapper"), root, self.NEW["maven wrapper"])
            self.assertIn("apache-maven/9.9.9/apache-maven-9.9.9-bin.zip", (root / rel).read_text())

    def test_a_tag_that_is_not_published_for_both_architectures_is_skipped(self):
        tags = ["3.10.0-eclipse-temurin-25", "3.10.2-eclipse-temurin-25"]
        rx = r"^(\d+\.\d+\.\d+)-eclipse-temurin-25$"
        newest, _ = bump_pins.pick(tags, rx, "3.10.0-eclipse-temurin-25", False)
        usable, _ = bump_pins.pick(tags, rx, "3.10.0-eclipse-temurin-25", False, usable=lambda t: t.startswith("3.10.0"))
        self.assertEqual((newest, usable), ("3.10.2-eclipse-temurin-25", "3.10.0-eclipse-temurin-25"))


if __name__ == "__main__":
    unittest.main()
