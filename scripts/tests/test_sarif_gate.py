"""Black-box tests of scripts/sarif-gate.py (run: python3 -m unittest discover -s scripts/tests)."""
import hashlib
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

GATE = pathlib.Path(__file__).resolve().parents[1] / "sarif-gate.py"
SOURCE = "class A {\n    void f(String s) {\n        em.createQuery(\"x\" + s);\n    }\n}\n"


def fingerprint(line_text):
    return hashlib.sha256(" ".join(line_text.split()).encode()).hexdigest()[:16]


def result(rule, level=None, path="src/A.java", line=3, suppressed=False):
    r = {"ruleId": rule, "message": {"text": "m"},
         "locations": [{"physicalLocation": {"artifactLocation": {"uri": path, "uriBaseId": "%SRCROOT%"},
                                             "region": {"startLine": line}}}]}
    if level:
        r["level"] = level
    if suppressed:
        r["suppressions"] = [{"kind": "external", "status": "accepted"}]
    return r


def sarif(results, rules=()):
    return {"version": "2.1.0", "runs": [{"tool": {"driver": {"name": "t", "rules": list(rules)}}, "results": results}]}


def rule(rule_id, severity=None, level=None):
    r = {"id": rule_id, "properties": {}}
    if severity is not None:
        r["properties"]["security-severity"] = str(severity)
    if level:
        r["defaultConfiguration"] = {"level": level}
    return r


class SarifGateTest(unittest.TestCase):
    def run_gate(self, report, accepted, *args):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            (root / "src").mkdir()
            (root / "src/A.java").write_text(SOURCE)
            (root / "r.sarif").write_text(json.dumps(report))
            (root / "accepted.json").write_text(json.dumps({"accepted": accepted}))
            done = subprocess.run([sys.executable, "-I", str(GATE), "--baseline", str(root / "accepted.json"),
                                   "--root", str(root), *args, str(root / "r.sarif")], capture_output=True, text=True)
            return done.returncode, done.stdout + done.stderr

    def entry(self, rule_id="java/sql-injection", expires="2099-01-01", **over):
        e = {"rule": rule_id, "path": "src/A.java", "fingerprint": fingerprint('em.createQuery("x" + s);'),
             "reason": "callers pass constants", "expires": expires}
        e.update(over)
        return e

    # --- CodeQL: security-severity >= 7.0 (High, Critical) blocks
    def test_a_high_security_severity_result_blocks(self):
        code, out = self.run_gate(sarif([result("java/sql-injection")], [rule("java/sql-injection", 8.8)]), [],
                                  "--fail-on", "high")
        self.assertEqual(1, code, out)
        self.assertIn("BLOCKING", out)
        self.assertIn("java/sql-injection", out)
        self.assertIn("src/A.java:3", out)

    def test_rules_of_tool_extensions_count_as_codeql_reports_them(self):
        report = {"version": "2.1.0", "runs": [{"tool": {"driver": {"name": "CodeQL", "rules": []},
                                                          "extensions": [{"name": "codeql/java-queries",
                                                                          "rules": [rule("java/sql-injection", 8.8)]}]},
                                                 "results": [result("java/sql-injection")]}]}
        code, out = self.run_gate(report, [], "--fail-on", "high")
        self.assertEqual(1, code, out)

    def test_medium_and_unscored_results_do_not_block_on_high(self):
        report = sarif([result("java/weak"), result("java/style", level="error")],
                       [rule("java/weak", 5.0), rule("java/style")])
        code, out = self.run_gate(report, [], "--fail-on", "high")
        self.assertEqual(0, code, out)

    def test_an_accepted_result_does_not_block_and_survives_a_line_shift(self):
        report = sarif([result("java/sql-injection", line=3)], [rule("java/sql-injection", 9.1)])
        self.assertEqual(0, self.run_gate(report, [self.entry()], "--fail-on", "high")[0])

    def test_an_acceptance_of_another_line_text_does_not_cover_the_result(self):
        report = sarif([result("java/sql-injection", line=3)], [rule("java/sql-injection", 9.1)])
        other = self.entry(fingerprint=fingerprint("something else"))
        self.assertEqual(1, self.run_gate(report, [other], "--fail-on", "high")[0])

    def test_an_expired_acceptance_blocks_again(self):
        report = sarif([result("java/sql-injection")], [rule("java/sql-injection", 9.1)])
        accepted = [self.entry(expires="2026-12-15")]
        self.assertEqual(0, self.run_gate(report, accepted, "--fail-on", "high", "--today", "2026-12-15")[0])
        code, out = self.run_gate(report, accepted, "--fail-on", "high", "--today", "2026-12-16")
        self.assertEqual(1, code, out)
        self.assertIn("EXPIRED", out)

    def test_a_result_suppressed_in_the_sarif_does_not_block(self):
        report = sarif([result("java/sql-injection", suppressed=True)], [rule("java/sql-injection", 9.1)])
        self.assertEqual(0, self.run_gate(report, [], "--fail-on", "high")[0])

    # --- Semgrep: level error blocks (result level, else the rule's default level)
    def test_an_error_level_result_blocks_on_error(self):
        report = sarif([result("semgrep.rules.x", level="error"), result("semgrep.rules.y")],
                       [rule("semgrep.rules.x"), rule("semgrep.rules.y", level="warning")])
        code, out = self.run_gate(report, [], "--fail-on", "error")
        self.assertEqual(1, code, out)
        self.assertIn("semgrep.rules.x", out)
        self.assertNotIn("BLOCKING semgrep.rules.y", out)

    def test_the_rule_default_level_counts_when_the_result_has_none(self):
        report = sarif([result("semgrep.rules.x")], [rule("semgrep.rules.x", level="error")])
        self.assertEqual(1, self.run_gate(report, [], "--fail-on", "error")[0])

    # --- baseline hygiene
    def test_an_entry_without_reason_or_expiry_is_a_configuration_error(self):
        code, out = self.run_gate(sarif([]), [self.entry(reason=" "), {"rule": "r", "path": "p", "fingerprint": "f",
                                                                      "reason": "x"}], "--fail-on", "high")
        self.assertEqual(2, code, out)
        self.assertIn("reason", out)
        self.assertIn("expires", out)

    def test_an_entry_that_matches_nothing_is_reported_as_stale(self):
        code, out = self.run_gate(sarif([]), [self.entry()], "--fail-on", "high")
        self.assertEqual(0, code, out)
        self.assertIn("STALE", out)

    def test_suggest_prints_baseline_entries_for_the_blocking_results(self):
        report = sarif([result("java/sql-injection")], [rule("java/sql-injection", 8.8)])
        code, out = self.run_gate(report, [], "--fail-on", "high", "--suggest")
        self.assertEqual(1, code, out)
        self.assertIn(fingerprint('em.createQuery("x" + s);'), out)


if __name__ == "__main__":
    unittest.main()
