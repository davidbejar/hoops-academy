"""The PostgreSQL version is pinned in five places (compose, the databases sub-chart, the Java and Go test harnesses,
the images workflow) and scripts/bump_pins.py tracks it (WP142): a newer minor of the pinned major is reported and
applied, a newer major is only reported, and a pin that names the major alone ("17", a floating tag) is left as it is.
The version itself is moved by hand (WP144), never by the bumper.
Run: python3 -I -m unittest discover -s scripts/tests"""
import pathlib
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import bump_pins  # noqa: E402

NAME = "postgresql"
IMAGE = r"(library/postgres|cloudnative-pg/postgresql):[0-9]"
TAGS = ["16.9", "17", "17.5", "17.6", "17.6-bookworm", "18", "18.1", "19", "19.0", "latest"]


def pin():
    return next(p for p in bump_pins.PINS if p.name == NAME)


def files_naming_a_postgres_image():
    """Tracked files outside the documentation and the recorded snapshots that name a PostgreSQL image version."""
    out = subprocess.run(["git", "grep", "-lE", IMAGE, "--", ".", ":!docs", ":!deploy/helm/tests/snapshots",
                          ":!scripts/tests"], cwd=ROOT, capture_output=True, text=True, check=True).stdout
    return set(out.split())


class WhereItIsPinned(unittest.TestCase):
    def test_the_pin_exists(self):
        self.assertEqual([p.name for p in bump_pins.PINS].count(NAME), 1)

    def test_every_file_that_names_a_postgres_image_belongs_to_the_pin(self):
        self.assertEqual(files_naming_a_postgres_image() - set(pin().files), set())

    def test_the_pin_names_only_files_that_name_it(self):
        self.assertEqual(set(pin().files) - files_naming_a_postgres_image(), set())

    def test_every_mention_is_matched_and_the_copies_agree(self):
        for rel in pin().files:
            text = (ROOT / rel).read_text()
            self.assertEqual(len(list(pin().regex.finditer(text))), len(re.findall(IMAGE, text)), rel)
        bump_pins.read_groups(pin(), ROOT)  # raises when the files disagree


class Resolution(unittest.TestCase):
    def resolve(self, current, major=False):
        original = bump_pins.skopeo
        bump_pins.skopeo = lambda *a: '{"Tags": %s}' % __import__("json").dumps(TAGS)
        try:
            return bump_pins.resolve(pin(), {"tag": current}, major)
        finally:
            bump_pins.skopeo = original

    def test_a_newer_minor_of_the_same_major_is_the_new_tag(self):
        new, _, note = self.resolve("17.5")
        self.assertEqual(new["tag"], "17.6")
        self.assertIn("19", note)

    def test_an_up_to_date_minor_only_reports_the_newer_major(self):
        new, _, note = self.resolve("17.6")
        self.assertEqual(new["tag"], "17.6")
        self.assertIn("major 19.0 available", note)

    def test_a_new_major_is_applied_only_with_the_major_flag(self):
        self.assertEqual(self.resolve("17.5", major=True)[0]["tag"], "19.0")

    def test_a_pin_naming_the_major_alone_stays_and_reports_the_newer_major(self):
        new, _, note = self.resolve("17")
        self.assertEqual(new["tag"], "17")
        self.assertIn("major 19", note)

    def test_a_major_only_pin_on_the_newest_major_has_no_note(self):
        self.assertEqual(self.resolve("19")[2], "")


class Rewrite(unittest.TestCase):
    def test_a_minor_bump_rewrites_every_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            for rel in pin().files:
                (root / rel).parent.mkdir(parents=True, exist_ok=True)
                (root / rel).write_text(re.sub(r"(postgres(?:ql)?):17\b", r"\1:17.5", (ROOT / rel).read_text()))
            bump_pins.rewrite(pin(), root, {"tag": "17.6"})
            for rel in pin().files:
                text = (root / rel).read_text()
                self.assertNotRegex(text, r"(library/postgres|cloudnative-pg/postgresql):17\.5", rel)
                self.assertRegex(text, r"(library/postgres|cloudnative-pg/postgresql):17\.6", rel)
            self.assertEqual(bump_pins.read_groups(pin(), root), {"tag": "17.6"})


if __name__ == "__main__":
    unittest.main()
