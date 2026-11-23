"""Tool versions that are written in several files stay equal (CI-05, ADR-0052, ADR-0055).
The Trivy tag is bumped weekly by scripts/bump_pins.py: every file that names it belongs to its pin. The Go and Rust
toolchains are bumped by hand (they are not in PINS): go.mod / rust-toolchain.toml, the one composite action that
installs Go for CI and the Containerfile builder image must name the same version, as the JDK pins do
(test_jdk_pins.py). The pinned Chrome and the chart tools live in one composite action each.
Run: python3 -I -m unittest discover -s scripts/tests"""
import pathlib
import re
import subprocess
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import bump_pins  # noqa: E402

GO_ACTION = ".github/actions/setup-go/action.yml"
CHROME_ACTION = ".github/actions/setup-pinned-chrome/action.yml"
CHART_TOOLS_ACTION = ".github/actions/setup-chart-tools/action.yml"


def text(rel):
    return (ROOT / rel).read_text()


def tracked_files_naming(pattern):
    """Tracked files outside docs, the pin script and the tests whose text matches `pattern`."""
    out = subprocess.run(["git", "grep", "-lE", pattern, "--", ".", ":!docs", ":!scripts/bump_pins.py",
                          ":!scripts/tests", ":!audit"], cwd=ROOT, capture_output=True, text=True, check=False).stdout
    return set(out.split())


class TrivyPin(unittest.TestCase):
    def pin(self):
        return next(p for p in bump_pins.PINS if p.name == "trivy")

    def test_every_file_that_names_the_trivy_image_belongs_to_the_pin(self):
        self.assertEqual(tracked_files_naming(r"aquasec/trivy:[0-9]") - set(self.pin().files), set())

    def test_the_pin_rewrites_every_mention_in_its_files(self):
        for rel in self.pin().files:
            with self.subTest(file=rel):
                mentions = len(re.findall(r"aquasec/trivy:[0-9]", text(rel)))
                self.assertGreaterEqual(mentions, 1)
                self.assertEqual(len(list(self.pin().regex.finditer(text(rel)))), mentions)


class GoToolchain(unittest.TestCase):
    def test_go_mod_the_ci_action_and_the_builder_image_agree(self):
        wanted = re.search(r"(?m)^toolchain go(\d+\.\d+\.\d+)$", text("services/finance-service/go.mod"))[1]
        self.assertEqual(re.findall(r"go\.dev/dl/go(\d+\.\d+\.\d+)\.linux-amd64\.tar\.gz", text(GO_ACTION)), [wanted])
        self.assertEqual(re.findall(r"ARG BUILDER_IMAGE=\S+/golang:(\d+\.\d+\.\d+)-", text("deploy/containers/finance.Containerfile")),
                         [wanted])

    def test_only_the_action_downloads_go(self):
        self.assertEqual(tracked_files_naming(r"go\.dev/dl/go[0-9]"), {GO_ACTION})


class RustToolchain(unittest.TestCase):
    def test_the_toolchain_file_and_the_builder_image_agree(self):
        wanted = re.search(r'(?m)^channel = "(\d+\.\d+\.\d+)"$', text("services/pdf-service/rust-toolchain.toml"))[1]
        containerfile = text("deploy/containers/pdf.Containerfile")
        self.assertEqual(re.findall(r"ARG BUILDER_IMAGE=\S+/rust:(\d+\.\d+\.\d+)-", containerfile), [wanted])
        self.assertEqual(re.findall(r"RUSTUP_TOOLCHAIN=(\d+\.\d+\.\d+)", containerfile), [wanted])


class OnePlacePerTool(unittest.TestCase):
    def test_the_pinned_chrome_is_named_once(self):
        self.assertEqual(tracked_files_naming(r"chrome-version:"), {CHROME_ACTION})

    def test_the_chart_tools_are_downloaded_in_one_action(self):
        self.assertEqual(tracked_files_naming(r"yannh/kubeconform/releases"), {CHART_TOOLS_ACTION})
        self.assertEqual(tracked_files_naming(r"gitleaks/gitleaks/releases"), {CHART_TOOLS_ACTION})


if __name__ == "__main__":
    unittest.main()
