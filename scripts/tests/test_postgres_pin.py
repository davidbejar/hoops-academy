"""The PostgreSQL version is pinned in five places (compose, the databases sub-chart, the Java and Go test harnesses,
the images workflow) and scripts/bump_pins.py tracks it (WP142, WP144). The places name one minor of one major
(ADR-0073: 19) in a flavour per registry: Docker Hub's `<v>-trixie`, CloudNativePG's `<v>-minimal-trixie` (that registry
publishes no plain tag). A newer minor is applied only when every registry publishes it in the pinned flavour; a newer
major is only reported; a pin that names the major alone ("19", a floating tag) is left as it is. The major itself is
moved by hand, never by the bumper. The compose volume carries the major, so a new major starts on a new volume and
the old one is never reused or dropped by compose.
Run: python3 -I -m unittest discover -s scripts/tests"""
import json
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
MAJOR = 19  # decision 114, ADR-0073
IMAGE = r"(library/postgres|cloudnative-pg/postgresql):[0-9]"
MENTION = re.compile(r"(docker\.io/library/postgres|ghcr\.io/cloudnative-pg/postgresql):(\d+(?:\.\d+)?)((?:-[a-z]+)*)")
DOCKER, CNPG = "docker.io/library/postgres", "ghcr.io/cloudnative-pg/postgresql"


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

    def test_the_repo_pins_a_minor_of_the_adopted_major(self):
        self.assertRegex(bump_pins.read_groups(pin(), ROOT)["tag"], rf"^{MAJOR}\.\d+$")

    def test_each_registry_is_named_in_the_flavour_the_pin_resolves_against(self):
        flavours = pin().opts["flavours"]
        self.assertEqual(set(flavours), {DOCKER, CNPG})
        for rel in pin().files:
            for repo, version, suffix in MENTION.findall((ROOT / rel).read_text()):
                self.assertEqual(version + suffix, flavours[repo].format(version), rel)

    def test_a_flavoured_tag_is_one_mention_and_only_its_version_is_the_tag(self):
        text = "a: ghcr.io/cloudnative-pg/postgresql:19.0-minimal-trixie\nb: docker.io/library/postgres:19.0-trixie\n"
        self.assertEqual([m.group("tag") for m in pin().regex.finditer(text)], ["19.0", "19.0"])
        self.assertEqual(list(pin().regex.finditer("docker.io/library/postgres:19.0.1")), [])


class Resolution(unittest.TestCase):
    PUBLISHED = {
        DOCKER: ["17.6-trixie", "18", "18.7-trixie", "19-trixie", "19.0", "19.0-trixie", "19.1", "19.1-trixie",
                 "19.1-bookworm", "20.0-trixie", "latest"],
        CNPG: ["18.7-minimal-trixie", "19-minimal-trixie", "19.0-minimal-trixie", "19.0-standard-trixie",
               "19.1-standard-trixie", "20.0-minimal-bookworm"],
    }

    def resolve(self, current, major=False, published=None):
        published = published or self.PUBLISHED

        def skopeo(*args):
            repo = args[-1].removeprefix("docker://")
            return json.dumps({"Tags": published[repo]})
        original = bump_pins.skopeo
        bump_pins.skopeo = skopeo
        try:
            return bump_pins.resolve(pin(), {"tag": current}, major)
        finally:
            bump_pins.skopeo = original

    def with_cnpg(self, *tags):
        return {DOCKER: self.PUBLISHED[DOCKER], CNPG: self.PUBLISHED[CNPG] + list(tags)}

    def test_a_minor_published_by_one_registry_only_is_not_applied(self):
        new, _, note = self.resolve("19.0")
        self.assertEqual(new["tag"], "19.0")
        self.assertEqual(note, "")

    def test_a_minor_published_by_every_registry_in_the_pinned_flavour_is_applied(self):
        self.assertEqual(self.resolve("19.0", published=self.with_cnpg("19.1-minimal-trixie"))[0]["tag"], "19.1")

    def test_a_newer_major_is_reported_once_every_registry_has_it(self):
        self.assertEqual(self.resolve("19.0")[2], "")
        new, _, note = self.resolve("19.0", published=self.with_cnpg("20.0-minimal-trixie"))
        self.assertEqual(new["tag"], "19.0")
        self.assertIn("major 20.0 available", note)

    def test_a_new_major_is_applied_only_with_the_major_flag(self):
        self.assertEqual(self.resolve("19.0", major=True, published=self.with_cnpg("20.0-minimal-trixie"))[0]["tag"],
                         "20.0")

    def test_a_pin_naming_the_major_alone_stays_and_reports_the_newer_major(self):
        new, _, note = self.resolve("18")
        self.assertEqual(new["tag"], "18")
        self.assertIn("major 19.0 available", note)

    def test_a_major_only_pin_on_the_newest_major_has_no_note(self):
        self.assertEqual(self.resolve("19")[2], "")


class Rewrite(unittest.TestCase):
    def test_a_minor_bump_rewrites_every_file_and_keeps_the_flavours(self):
        current = bump_pins.read_groups(pin(), ROOT)["tag"]
        major, minor = (int(p) for p in current.split("."))
        newer = f"{major}.{minor + 1}"
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            for rel in pin().files:
                (root / rel).parent.mkdir(parents=True, exist_ok=True)
                (root / rel).write_text((ROOT / rel).read_text())
            bump_pins.rewrite(pin(), root, {"tag": newer})
            for rel in pin().files:
                before = MENTION.findall((ROOT / rel).read_text())
                after = MENTION.findall((root / rel).read_text())
                self.assertEqual(after, [(repo, newer, suffix) for repo, _, suffix in before], rel)
            self.assertEqual(bump_pins.read_groups(pin(), root), {"tag": newer})


class ComposeVolume(unittest.TestCase):
    """From PostgreSQL 18 the official image keeps its cluster in /var/lib/postgresql/<major>/docker and declares the
    volume at /var/lib/postgresql; a mount at .../data is refused. The volume name carries the major (ADR-0073)."""

    def setUp(self):
        compose = (ROOT / "infra/compose/compose.yaml").read_text()
        self.service = compose[compose.index("  postgres:"):compose.index("  keycloak:")]
        self.volumes = compose[compose.index("\nvolumes:\n"):]

    def test_the_data_volume_is_mounted_where_the_image_keeps_its_clusters(self):
        self.assertIn(f"      - pgdata-{MAJOR}:/var/lib/postgresql\n", self.service)
        self.assertNotIn("/var/lib/postgresql/data", self.service)

    def test_compose_declares_the_volume_of_the_pinned_major_only(self):
        major = bump_pins.read_groups(pin(), ROOT)["tag"].split(".")[0]
        self.assertEqual(re.findall(r"(?m)^  (pgdata[\w-]*):", self.volumes), [f"pgdata-{major}"])


if __name__ == "__main__":
    unittest.main()
