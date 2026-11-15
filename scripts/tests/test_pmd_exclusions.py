"""The acceptance files of the PMD / CPD gate (WP113, ADR-0053) stay reviewable and cannot open the gate by accident:
every entry follows a comment with its reason, names main classes that exist, and the CPD file has no blank line
(maven-pmd-plugin 3.28 reads a blank line as an empty class name, which accepts every duplication inside one file).
Run: python3 -I -m unittest discover -s scripts/tests"""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
PMD = ROOT / "config/pmd/exclude-pmd.properties"
CPD = ROOT / "config/pmd/exclude-cpd.properties"
MAIN_ROOTS = [p for p in ROOT.glob("*/*/src/main/java")] + [p for p in ROOT.glob("*/src/main/java")]


def is_entry(line):
    return bool(line.strip()) and not line.startswith("#")


def entries(path):
    """(line number, entry, the line that opens its group) for every non-comment line; entries that follow each
    other share the comment above the first of them."""
    lines = path.read_text().split("\n")
    result = []
    for n, line in enumerate(lines):
        if is_entry(line):
            start = n
            while start > 0 and is_entry(lines[start - 1]):
                start -= 1
            result.append((n + 1, line, lines[start - 1] if start else ""))
    return result


def classes(path, entry):
    names = entry.split("=")[0] if path == PMD else entry
    return [name.strip() for name in names.split(",")]


def is_main_class(name):
    relative = name.replace(".", "/") + ".java"
    return any((root / relative).is_file() for root in MAIN_ROOTS)


class PmdExclusions(unittest.TestCase):
    def test_the_cpd_file_has_no_blank_line(self):
        text = CPD.read_text()
        blank = [n + 1 for n, line in enumerate(text.rstrip("\n").split("\n")) if not line.strip()]
        self.assertEqual(blank, [], f"{CPD.name}: blank lines accept every same-file duplication")

    def test_every_entry_carries_a_reason(self):
        for path in (PMD, CPD):
            for number, entry, before in entries(path):
                with self.subTest(file=path.name, line=number):
                    self.assertTrue(before.startswith("#") and len(before.strip("# ")) > 0,
                                    f"{path.name}:{number} '{entry}' has no reason comment above it")

    def test_every_entry_names_existing_main_classes(self):
        for path in (PMD, CPD):
            for number, entry, _ in entries(path):
                for name in classes(path, entry):
                    with self.subTest(file=path.name, line=number, name=name):
                        self.assertTrue(is_main_class(name), f"{path.name}:{number} {name} is not a main class")

    def test_pmd_entries_name_rules_of_the_ruleset(self):
        ruleset = (ROOT / "config/pmd/ruleset.xml").read_text()
        for number, entry, _ in entries(PMD):
            for rule in entry.split("=")[1].split(","):
                with self.subTest(line=number, rule=rule):
                    self.assertIn(f"/{rule.strip()}\"", ruleset, f"exclude-pmd.properties:{number}")


if __name__ == "__main__":
    unittest.main()
