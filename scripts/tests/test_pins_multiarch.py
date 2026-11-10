"""Every image pin that CI or a script executes must be a multi-arch index (amd64 and arm64), never one platform's
manifest: a single-platform digest fails with "Exec format error" on the other architecture (bump-pins run 42629848979).

Offline: the index check on fixtures and the pin scan. Online (BUMP_PINS_ONLINE=1, needs podman or CONTAINER_ENGINE and
network): `skopeo inspect --raw` of every pin found in the repository.
Run: python3 -m unittest discover -s scripts/tests"""
import json
import os
import pathlib
import re
import subprocess
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import bump_pins  # noqa: E402

REF = re.compile(r"(?<![\w./-])(?P<repo>[a-z0-9](?:[a-z0-9.-]*/)+[a-z0-9._-]+)(?::[\w.\-]+)?@(?P<digest>sha256:[0-9a-f]{64})")
SCANNED = [".github/workflows", "scripts", "deploy/containers", "deploy/kind"]
INDEX_TYPES = {"application/vnd.oci.image.index.v1+json", "application/vnd.docker.distribution.manifest.list.v2+json"}
NEEDED = {"amd64", "arm64"}


def platforms(raw):
    """Architectures of an index, or None when the document is a single-platform manifest."""
    doc = json.loads(raw)
    if doc.get("mediaType") not in INDEX_TYPES:
        return None
    return {m["platform"]["architecture"] for m in doc.get("manifests", []) if "platform" in m}


def pins_in_repo():
    found = {}
    for base in SCANNED:
        for path in sorted((ROOT / base).rglob("*")):
            if not path.is_file() or "tests" in path.parts or path.suffix in {".pyc"}:
                continue
            for m in REF.finditer(path.read_text(errors="ignore")):
                found.setdefault((m["repo"], m["digest"]), path.relative_to(ROOT))
    return found


class IndexParsing(unittest.TestCase):
    def test_index_lists_platforms(self):
        raw = json.dumps({"mediaType": "application/vnd.oci.image.index.v1+json", "manifests": [
            {"platform": {"architecture": "amd64"}}, {"platform": {"architecture": "arm64"}}]})
        self.assertEqual(platforms(raw), NEEDED)

    def test_single_platform_manifest_is_not_an_index(self):
        raw = json.dumps({"mediaType": "application/vnd.oci.image.manifest.v1+json", "config": {}})
        self.assertIsNone(platforms(raw))

    def test_scan_finds_the_skopeo_pin(self):
        digest = bump_pins.SKOPEO_IMAGE.split("@")[1]
        self.assertIn(digest, {d for (_, d) in pins_in_repo()})


class WorkflowPinsStayManual(unittest.TestCase):
    def test_a_pin_in_a_workflow_file_is_by_hand_only_when_asked(self):
        in_workflow = [p for p in bump_pins.PINS if any(f.startswith(".github/workflows/") for f in p.files)]
        elsewhere = [p for p in bump_pins.PINS if p not in in_workflow]
        self.assertTrue(in_workflow and elsewhere)
        self.assertTrue(all(bump_pins.by_hand(p, True) for p in in_workflow))
        self.assertFalse(any(bump_pins.by_hand(p, True) for p in elsewhere))
        self.assertFalse(any(bump_pins.by_hand(p, False) for p in bump_pins.PINS))


@unittest.skipUnless(os.environ.get("BUMP_PINS_ONLINE") == "1", "set BUMP_PINS_ONLINE=1 to inspect the registries")
class PinsAreMultiArch(unittest.TestCase):
    def test_every_executed_pin_is_an_index_with_amd64_and_arm64(self):
        # Only two literal engine names reach the command line (the env value itself never does: Semgrep taint rule).
        engine = "docker" if os.environ.get("CONTAINER_ENGINE") == "docker" else "podman"
        bad = []
        for (repo, digest), where in pins_in_repo().items():
            done = subprocess.run([engine, "run", "--rm", "--entrypoint", "skopeo", bump_pins.SKOPEO_IMAGE.split("@")[0],
                                   "inspect", "--raw", f"docker://{repo}@{digest}"], capture_output=True, text=True)
            self.assertEqual(done.returncode, 0, f"{repo}@{digest}: {done.stderr[-200:]}")
            arch = platforms(done.stdout)
            if arch is None or not NEEDED <= arch:
                bad.append(f"{where}: {repo}@{digest} has {arch}")
        self.assertEqual(bad, [], "single-platform or incomplete pins")


if __name__ == "__main__":
    unittest.main()
