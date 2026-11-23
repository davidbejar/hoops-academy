"""A pin that is repeated in another file is bumped in every copy: the weekly bump (scripts/bump_pins.py) must leave
`deploy/helm/tests/run.sh` and `infra/tofu/check.sh` green. PR #6 (2026-11-22) moved Redpanda in the chart and Reloader
in deploy/kind/up.sh only, and main went red on the copies in compose, Dev Services and deploy/cloud/install.sh. Since
WP136 (DEP-02) the operators kind and the cloud VM share are pinned once, in deploy/lib/platform.sh, which both source.
Run: python3 -I -m unittest discover -s scripts/tests"""
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

REDPANDA = "docker.io/redpandadata/redpanda"
KIND, CLOUD = "deploy/kind/up.sh", "deploy/cloud/install.sh"
PLATFORM = "deploy/lib/platform.sh"
# the operators kind and the cloud VM both install, pinned once in PLATFORM (Gateway API is bumped by hand, ADR-0031)
SHARED_OPERATORS = ["Envoy Gateway", "CloudNativePG", "Stakater Reloader"]
SHARED_PIN_VARS = ["ENVOY_GATEWAY_VERSION", "GATEWAY_API_VERSION", "CNPG_VERSION", "RELOADER_CHART_VERSION",
                   "RELOADER_CHART_DIGEST", "RELOADER_IMAGE_DIGEST"]
OLD_DIGEST, NEW_DIGEST = "sha256:" + "0" * 64, "sha256:" + "f" * 64


def pin(name):
    return next(p for p in bump_pins.PINS if p.name == name)


def files_naming_a_redpanda_version():
    """Tracked files outside the documentation and the recorded snapshots that name a Redpanda image version."""
    out = subprocess.run(["git", "grep", "-lE", r"redpandadata/redpanda(:|\s+tag: )v[0-9]", "--", ".",
                          ":!docs", ":!deploy/helm/tests/snapshots", ":!scripts/tests"],
                         cwd=ROOT, capture_output=True, text=True, check=True).stdout
    return set(out.split())


class RedpandaPin(unittest.TestCase):
    def pins(self):
        return [p for p in bump_pins.PINS if p.opts.get("repo") == REDPANDA]

    def test_every_file_that_names_a_redpanda_version_belongs_to_a_pin(self):
        covered = {rel for p in self.pins() for rel in p.files}
        self.assertEqual(files_naming_a_redpanda_version() - covered, set())

    def test_every_mention_in_those_files_is_rewritten(self):
        for p in self.pins():
            for rel in p.files:
                text = (ROOT / rel).read_text()
                mentions = len(re.findall(r"redpandadata/redpanda(?::|\n\s+tag: )v\d", text))
                self.assertGreaterEqual(mentions, 1, rel)
                self.assertEqual(len(list(p.regex.finditer(text))), mentions, rel)

    def test_the_copies_agree(self):
        tags = {bump_pins.read_groups(p, ROOT)["tag"] for p in self.pins()}  # raises when a pin's files disagree
        self.assertEqual(len(tags), 1, tags)


class SharedOperatorPinsInOneFile(unittest.TestCase):
    def test_the_pin_covers_the_platform_file_only(self):
        for name in SHARED_OPERATORS:
            self.assertEqual(pin(name).files, [PLATFORM], name)

    def test_kind_and_cloud_source_it_and_pin_nothing_themselves(self):
        for rel in (KIND, CLOUD):
            text = (ROOT / rel).read_text()
            self.assertRegex(text, r"(?m)^\. deploy/lib/platform\.sh$", rel)
            for var in SHARED_PIN_VARS:
                self.assertNotRegex(text, rf"(?m)^\s*{var}=", f"{rel} sets {var}")

    def test_the_platform_file_pins_them(self):
        bump_pins.read_groups(pin("Stakater Reloader"), ROOT)  # raises when the file lacks the pin
        text = (ROOT / PLATFORM).read_text()
        for var in SHARED_PIN_VARS:
            self.assertRegex(text, rf'(?m)^{var}="[^"]+"$', var)

    def test_a_reloader_bump_rewrites_the_platform_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            (root / PLATFORM).parent.mkdir(parents=True)
            shutil.copy(ROOT / PLATFORM, root / PLATFORM)
            reloader = pin("Stakater Reloader")
            new = {"app": "v9.9.9", "tag": "9.8.7", "digest": NEW_DIGEST, "image_digest": OLD_DIGEST}
            bump_pins.rewrite(reloader, root, new)
            self.assertEqual(bump_pins.read_groups(reloader, root), new)
            text = (root / PLATFORM).read_text()
            self.assertIn('RELOADER_CHART_VERSION="9.8.7"', text)
            self.assertIn(f'RELOADER_CHART_DIGEST="{NEW_DIGEST}"', text)
            self.assertIn(f'RELOADER_IMAGE_DIGEST="{OLD_DIGEST}"', text)


if __name__ == "__main__":
    unittest.main()
