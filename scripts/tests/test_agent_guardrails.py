"""Guards of what steers the agents (WP154, ADR-0078; docs/security/agentic-threat-model.md):
- AG-03: the gitleaks config has no path allow-list for docs/ or .claude/ (agents write Markdown there; Pages publishes
  docs/), and no allow-list regex that would let a real-looking token through.
- AG-11: every vendored third-party skill folder has a checksum in .claude/skills/THIRD_PARTY_SKILLS.md, and the folder
  still matches it.
- AG-07: a runbook line that removes the database volume says it is the owner's step.
Run: python3 -I -m unittest discover -s scripts/tests"""
import hashlib
import pathlib
import re
import subprocess
import tomllib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SKILLS = ROOT / ".claude/skills"
THIRD_PARTY = SKILLS / "THIRD_PARTY_SKILLS.md"
GUARDED_SAMPLES = ("docs/wp/WP154-agent-guardrails-enforced.md", "docs/runbooks/e2e.md", "docs/index.md",
                   ".claude/skills/wp-round/SKILL.md", ".claude/skills/clean-code/SKILL.md", ".claude/hooks/x.sh")


def allowlists(config):
    """Every allow-list table of a gitleaks config: the global one (old and new form) and those of each rule."""
    found = [config.get("allowlist", {}), *config.get("allowlists", [])]
    for rule in config.get("rules", []):
        found += [rule.get("allowlist", {}), *rule.get("allowlists", [])]
    return [entry for entry in found if entry]


def folder_digest(folder):
    """sha256 over `shasum -a 256` lines of the folder's tracked files, sorted, paths relative to .claude/skills:
    cd .claude/skills && git ls-files -z -- <folder> | LC_ALL=C sort -z | xargs -0 shasum -a 256 | shasum -a 256"""
    out = subprocess.run(["git", "ls-files", "-z", "--", folder], cwd=SKILLS, capture_output=True, check=True).stdout
    files = sorted(name for name in out.decode().split("\0") if name)
    lines = "".join(f"{hashlib.sha256((SKILLS / name).read_bytes()).hexdigest()}  {name}\n" for name in files)
    return hashlib.sha256(lines.encode()).hexdigest()


def table_rows(text, heading):
    """The first column and the rest of each row of the first Markdown table after the heading."""
    section = text.split(heading, 1)[1] if heading in text else ""
    rows = []
    for line in section.splitlines():
        if line.startswith("|") and not line.startswith("|---"):
            cells = [cell.strip() for cell in line.strip("|").split("|")]
            rows.append(cells)
        elif rows and not line.startswith("|"):
            break
    return rows[1:]  # without the header row


class GitleaksConfig(unittest.TestCase):
    def setUp(self):
        self.config = tomllib.loads((ROOT / ".gitleaks.toml").read_text())

    def test_no_path_allowlist_covers_docs_or_the_agent_files(self):
        for entry in allowlists(self.config):
            for pattern in entry.get("paths", []):
                for sample in GUARDED_SAMPLES:
                    self.assertIsNone(re.search(pattern, sample),
                                      f"allow-list path {pattern!r} skips {sample}: use a fingerprint in .gitleaksignore")

    def test_no_allowlist_regex_lets_a_real_looking_token_through(self):
        token = "ghp_" + "Zq4" * 12  # built here, so no token-shaped literal sits in the repository
        for entry in allowlists(self.config):
            for pattern in entry.get("regexes", []) + entry.get("stopwords", []):
                self.assertIsNone(re.search(pattern, token), f"allow-list entry {pattern!r} matches a GitHub token")

    def test_the_example_env_file_stays_allowed(self):
        paths = [p for entry in allowlists(self.config) for p in entry.get("paths", [])]
        self.assertTrue(any(re.search(p, ".env.example") for p in paths), paths)


class VendoredSkills(unittest.TestCase):
    def setUp(self):
        self.text = THIRD_PARTY.read_text()
        self.vendored = [row[0].strip("`/") for row in table_rows(self.text, "# Third-party skills vendored")]
        self.recorded = {row[0].strip("`/"): row[1].strip("`") for row in table_rows(self.text, "## Checksums")}

    def test_the_list_names_the_vendored_folders(self):
        self.assertGreaterEqual(len(self.vendored), 5, self.vendored)
        for folder in self.vendored:
            self.assertTrue((SKILLS / folder).is_dir(), folder)

    def test_every_vendored_folder_has_a_checksum(self):
        self.assertEqual(sorted(self.recorded), sorted(self.vendored))

    def test_every_vendored_folder_matches_its_checksum(self):
        for folder in self.vendored:
            actual = folder_digest(folder)
            self.assertEqual(self.recorded.get(folder), actual,
                             f"{folder} changed: re-vet it, then record | `{folder}/` | `{actual}` | in {THIRD_PARTY.name}")


class OwnerSteps(unittest.TestCase):
    def test_a_runbook_that_drops_the_database_volume_says_it_is_the_owner_step(self):
        for page in sorted((ROOT / "docs/runbooks").glob("*.md")):
            for number, line in enumerate(page.read_text().splitlines(), 1):
                if re.search(r"podman volume rm hoops_pgdata", line):
                    self.assertIn("owner", line, f"{page.name}:{number}: say it is the owner's step (AG-07)")


if __name__ == "__main__":
    unittest.main()
