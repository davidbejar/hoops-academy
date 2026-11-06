"""Black-box tests of scripts/zap-gate.py (run: python3 -m unittest discover -s scripts/tests)."""
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

GATE = pathlib.Path(__file__).resolve().parents[1] / "zap-gate.py"


def alert(pluginid, name, riskcode, *uris):
    return {"pluginid": str(pluginid), "name": name, "riskcode": str(riskcode), "count": str(len(uris)),
            "instances": [{"uri": u} for u in uris]}


class ZapGateTest(unittest.TestCase):
    def run_gate(self, alerts, conf_lines, *extra):
        with tempfile.TemporaryDirectory() as tmp:
            report = pathlib.Path(tmp, "zap.json")
            report.write_text(json.dumps({"site": [{"alerts": alerts}]}))
            conf = pathlib.Path(tmp, "rules.conf")
            conf.write_text("\n".join(["# header"] + conf_lines) + "\n")
            done = subprocess.run([sys.executable, "-I", str(GATE), str(report), str(conf), *extra],
                                  capture_output=True, text=True)
            return done.returncode, done.stdout + done.stderr

    def test_a_medium_alert_without_acceptance_blocks(self):
        code, out = self.run_gate([alert(10038, "CSP Header Not Set", 2, "http://h/api/x")], ["10038\tWARN\t(CSP)"])
        self.assertEqual(1, code, out)
        self.assertIn("BLOCKING Medium: 10038", out)

    def test_low_and_informational_alerts_never_block(self):
        code, out = self.run_gate([alert(10096, "Timestamp", 1, "http://h/"), alert(10109, "Modern", 0, "http://h/")], [])
        self.assertEqual(0, code, out)
        self.assertIn("Low=1", out)

    def test_an_ignore_line_with_justification_accepts_the_alert(self):
        code, out = self.run_gate([alert(10038, "CSP Header Not Set", 2, "http://h/api/x")],
                                  ["10038\tIGNORE\t(CSP)\tAccepted: JSON API responses are not rendered"])
        self.assertEqual(0, code, out)

    def test_url_and_alert_tags_narrow_the_acceptance(self):
        conf = ["10055\tIGNORE\t(CSP)\t[alert=CSP: style-src unsafe-inline][url=/auth/] Accepted: Keycloak pages"]
        accepted = alert(10055, "CSP: style-src unsafe-inline", 2, "http://h/auth/realms/a")
        other_url = alert(10055, "CSP: style-src unsafe-inline", 2, "http://h/index.html")
        other_alert = alert(10055, "CSP: Wildcard Directive", 2, "http://h/auth/realms/a")
        self.assertEqual(0, self.run_gate([accepted], conf)[0])
        self.assertEqual(1, self.run_gate([other_url], conf)[0])
        self.assertEqual(1, self.run_gate([other_alert], conf)[0])

    def test_an_acceptance_holds_until_its_expiry_date_inclusive(self):
        conf = ["40018\tIGNORE\t(SQLi)\t[expires=2026-12-15] Accepted until WP84: false positive under review"]
        found = [alert(40018, "SQL Injection", 3, "http://h/api/core/players")]
        self.assertEqual(0, self.run_gate(found, conf, "--today", "2026-12-15")[0])
        code, out = self.run_gate(found, conf, "--today", "2026-12-16")
        self.assertEqual(1, code, out)
        self.assertIn("EXPIRED", out)
        self.assertIn("2026-12-15", out)

    def test_expires_combines_with_the_other_tags(self):
        conf = ["40018\tIGNORE\t(SQLi)\t[url=/api/core/][expires=2026-12-15] Accepted until WP84"]
        found = [alert(40018, "SQL Injection", 3, "http://h/api/core/players")]
        self.assertEqual(0, self.run_gate(found, conf, "--today", "2026-11-06")[0])
        self.assertEqual(1, self.run_gate([alert(40018, "SQL Injection", 3, "http://h/api/game/x")], conf,
                                          "--today", "2026-11-06")[0])

    def test_an_ignore_line_without_justification_is_a_configuration_error(self):
        code, out = self.run_gate([], ["10038\tIGNORE\t(CSP)", "10020\tIGNORE\t(X-Frame)\t[url=/auth/]"])
        self.assertEqual(2, code, out)
        self.assertIn("10038", out)
        self.assertIn("10020", out)

    def test_a_malformed_expiry_is_a_configuration_error(self):
        code, out = self.run_gate([], ["10038\tIGNORE\t(CSP)\t[expires=next-month] Accepted for now"])
        self.assertEqual(2, code, out)


if __name__ == "__main__":
    unittest.main()
