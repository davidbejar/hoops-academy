"""The local stack says each thing once (audit 2026-11-23, WP139): compose's hardening and service environment (INF-06),
pinned images, nginx's shared security headers (INF-05) and backend addresses (INF-09), the dev users of compose and kind
(INF-04), the realm retrofit's helpers (INF-07), the web port and the Podman machine check of the scripts (INF-12), and
the realm's audience mappers keep one shape (INF-08).
Run: python3 -I -m unittest discover -s scripts/tests"""
import json
import pathlib
import re
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
COMPOSE = ROOT / "infra/compose/compose.yaml"
NGINX = ROOT / "infra/compose/nginx"
HEADER_FILES = ["web-headers.conf", "redirect-headers.conf", "deny-headers.conf", "keycloak-proxy.conf"]
COMMON = ["X-Content-Type-Options", "Permissions-Policy", "Cross-Origin-Opener-Policy", "Cross-Origin-Resource-Policy"]


def git_grep(*args):
    out = subprocess.run(["git", "grep", *args], cwd=ROOT, capture_output=True, text=True)
    return out.stdout.splitlines()


class Compose(unittest.TestCase):
    def setUp(self):
        self.text = COMPOSE.read_text()

    def test_no_image_floats(self):
        for image in re.findall(r"(?m)^\s+image: (\S+)", self.text):
            if image.startswith("localhost/"):
                continue  # built here
            self.assertRegex(image, r":[\w.-]+(@sha256:[0-9a-f]{64})?$", image)
            self.assertNotIn(":latest", image)
        self.assertRegex(self.text, r"image: docker\.io/mailhog/mailhog:v1\.0\.1@sha256:[0-9a-f]{64}\n")

    def test_the_hardening_block_is_written_once(self):
        self.assertEqual(self.text.count("read_only: true"), 1)
        self.assertEqual(self.text.count("cap_drop: [ALL]"), 1)
        self.assertEqual(self.text.count("<<: *hardened"), 4)

    def test_the_environment_pdf_and_finance_share_is_written_once(self):
        for line in ("OIDC_AUTH_SERVER_URL:", "OTEL_EXPORTER_OTLP_ENDPOINT:", "OTEL_RESOURCE_ATTRIBUTES:", "OTEL_SDK_DISABLED:"):
            self.assertEqual(self.text.count(line), 1, line)
        self.assertEqual(self.text.count("<<: *service-env"), 2)


class Nginx(unittest.TestCase):
    def test_the_shared_headers_live_in_one_include(self):
        common = (NGINX / "common-headers.conf").read_text()
        for header in COMMON:
            self.assertEqual(len(re.findall(rf"(?m)^add_header {header} ", common)), 1, header)
        for name in HEADER_FILES:
            text = (NGINX / name).read_text()
            self.assertIn("include /etc/nginx/hoops/common-headers.conf;", text, name)
            for header in COMMON:
                self.assertNotRegex(text, rf"(?m)^add_header {header} ", f"{name}: {header}")

    def test_backends_are_named_once(self):
        conf = (ROOT / "infra/compose/nginx.conf").read_text()
        self.assertEqual(re.findall(r"proxy_pass http://host\.containers\.internal", conf), [])
        upstreams = dict(re.findall(r"upstream (\w+) \{ server host\.containers\.internal:(\d+); \}", conf))
        self.assertEqual(upstreams, {"core": "8081", "game": "8082", "athlete": "8083", "finance": "8085"})


class Keycloak(unittest.TestCase):
    def test_the_dev_users_are_listed_once(self):
        self.assertEqual(git_grep("-l", "ensure_user superadmin"), ["infra/keycloak/dev-users.sh"])
        for wrapper in ("infra/keycloak/seed-users.sh", "deploy/kind/seed-users.sh"):
            self.assertIn("infra/keycloak/dev-users.sh", (ROOT / wrapper).read_text(), wrapper)

    def test_the_retrofit_reads_the_realm_file_with_one_helper(self):
        text = (ROOT / "infra/keycloak/seed-users.sh").read_text()
        self.assertEqual(text.count("python3 -I"), 1)
        self.assertEqual(text.count("--fields id --format csv --noquotes"), 1)

    def test_every_audience_mapper_has_the_same_shape(self):
        realm = json.loads((ROOT / "infra/keycloak/realm-academy.json").read_text())
        shapes = set()
        for client in realm["clients"]:
            for m in client.get("protocolMappers", []):
                if m["protocolMapper"] == "oidc-audience-mapper":
                    config = {k: v for k, v in m["config"].items() if k != "included.client.audience"}
                    shapes.add((m["protocol"], json.dumps(config, sort_keys=True)))
                    self.assertEqual(m["name"], "audience " + m["config"]["included.client.audience"], client["clientId"])
        self.assertEqual(len(shapes), 1, shapes)


class Scripts(unittest.TestCase):
    def test_the_web_port_and_the_machine_check_are_defined_once(self):
        self.assertEqual(git_grep("-l", "WEB_PORT=5173", "--", "*.sh"), ["scripts/lib/stack.sh"])
        self.assertEqual(git_grep("-l", "machine inspect --format '{{.State}}'", "--", "*.sh"), ["scripts/lib/stack.sh"])
        for script in ("start.sh", "stop.sh", "scripts/doctor.sh", "e2e/bin/services-up.sh"):
            self.assertIn("scripts/lib/stack.sh", (ROOT / script).read_text(), script)


if __name__ == "__main__":
    unittest.main()
