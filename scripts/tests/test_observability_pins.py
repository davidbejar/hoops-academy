"""The Grafana LGTM image (WP120, ADR-0046 amendment) is pinned by tag and index digest in the chart and in compose, the
same in both, and the weekly bump (scripts/bump_pins.py) moves both together: one PINS entry over both files.
Run: python3 -I -m unittest discover -s scripts/tests"""
import pathlib
import re
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import bump_pins  # noqa: E402

REPO = "docker.io/grafana/otel-lgtm"
FILES = {"deploy/helm/hoops/values.yaml", "infra/compose/compose.yaml"}


def lgtm_pins():
    return [p for p in bump_pins.PINS if p.opts.get("repo") == REPO]


class LgtmPin(unittest.TestCase):
    def test_one_pin_covers_the_chart_and_compose(self):
        pins = lgtm_pins()
        self.assertEqual(len(pins), 1)
        self.assertEqual(set(pins[0].files), FILES)
        self.assertEqual(pins[0].kind, "image")

    def test_chart_and_compose_name_the_same_tag_and_digest(self):
        groups = bump_pins.read_groups(lgtm_pins()[0], ROOT)  # raises when the files disagree
        self.assertRegex(groups["tag"], r"^\d+\.\d+\.\d+$")
        self.assertRegex(groups["digest"], rf"^{bump_pins.DIGEST}$")

    def test_every_lgtm_image_in_the_files_is_rewritten_by_the_pin(self):
        pin = lgtm_pins()[0]
        for rel in sorted(FILES):
            text = (ROOT / rel).read_text()
            mentions = len(re.findall(r"grafana/otel-lgtm", text))
            self.assertGreaterEqual(mentions, 1, rel)
            self.assertEqual(len(pin.regex.findall(text)), mentions, rel)

    def test_new_tags_are_plain_releases(self):
        best, _ = bump_pins.pick(["0.41.0", "0.42.0", "0.42.0-rc1", "latest", "1.0.0"], lgtm_pins()[0].opts["tag_re"],
                                 "0.41.0", major=False)
        self.assertEqual(best, "0.42.0")


if __name__ == "__main__":
    unittest.main()
