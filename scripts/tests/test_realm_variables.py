"""One name for the realm URL and one for the Keycloak admin base URL (decision 110, ADR-0071).

OIDC_AUTH_SERVER_URL is the realm as the process reaches it (http://localhost:8080/auth/realms/academy on `just up`);
KEYCLOAK_ADMIN_URL is the Keycloak base its Admin API client uses (http://localhost:8080/auth). Before WP139 game and
athlete took KEYCLOAK_URL as a base and appended the realm themselves, with a default on localhost:8180 where nothing
runs; core read KEYCLOAK_URL as its admin base and the e2e suite E2E_KEYCLOAK_ADMIN_URL. None of those may come back.
Run: python3 -I -m unittest discover -s scripts/tests"""
import pathlib
import re
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
REALM_URL, ADMIN_URL = "OIDC_AUTH_SERVER_URL", "KEYCLOAK_ADMIN_URL"
REALM_DEFAULT, ADMIN_DEFAULT = "http://localhost:8080/auth/realms/academy", "http://localhost:8080/auth"
# Old names and the stale port. History (ADRs, work-package records) keeps them; this file names them on purpose.
RETIRED = r"(^|[^A-Z_])(KEYCLOAK_URL|E2E_KEYCLOAK_ADMIN_URL)([^A-Z_]|$)|localhost:8180([^0-9]|$)"
# Files that name an old variable on purpose: this one, and the two Java tests that set it to show it has no effect.
PROVE_THE_OLD_NAME_IS_IGNORED = [
    "scripts/tests/test_realm_variables.py",
    "libs/common-quarkus/src/test/java/com/hoopsacademy/common/testing/LibraryDefaultsContract.java",
    "services/core-service/src/test/java/com/hoopsacademy/core/config/KeycloakAdminUrlTest.java",
]
LIBRARY = "libs/common-quarkus/src/main/resources/META-INF/microprofile-config.properties"
SERVICES = ["core", "game", "athlete"]


def git_grep(pattern, *pathspecs):
    out = subprocess.run(["git", "grep", "-nE", pattern, "--", *pathspecs], cwd=ROOT, capture_output=True, text=True)
    if out.returncode not in (0, 1):
        raise RuntimeError(out.stderr)
    return out.stdout.splitlines()


def text(rel):
    return (ROOT / rel).read_text()


class RetiredNames(unittest.TestCase):
    def test_no_tracked_file_names_an_old_variable_or_port_8180(self):
        hits = git_grep(RETIRED, ".", ":!docs/adr", ":!docs/wp", *(f":!{rel}" for rel in PROVE_THE_OLD_NAME_IS_IGNORED))
        self.assertEqual(hits, [])


class QuarkusServices(unittest.TestCase):
    def test_the_library_defines_both_realm_keys_once_with_the_compose_default(self):
        lib = text(LIBRARY)
        for key in ("quarkus.oidc.auth-server-url", "quarkus.oidc-client.auth-server-url"):
            self.assertIn(f"\n{key}=${{{REALM_URL}:{REALM_DEFAULT}}}\n", lib, key)

    def test_no_service_sets_the_realm_url_itself(self):
        for s in SERVICES:
            props = text(f"services/{s}-service/src/main/resources/application.properties")
            self.assertIsNone(re.search(r"(?m)^quarkus\.oidc(-client)?\.auth-server-url=", props), s)

    def test_core_reads_the_admin_base_from_one_variable(self):
        props = text("services/core-service/src/main/resources/application.properties")
        self.assertIn(f"quarkus.keycloak.admin-client.server-url=${{{ADMIN_URL}:{ADMIN_DEFAULT}}}", props)


class Deployments(unittest.TestCase):
    def test_the_compose_default_is_where_keycloak_listens(self):
        compose = text("infra/compose/compose.yaml")
        self.assertIn("KC_HTTP_RELATIVE_PATH: /auth", compose)
        self.assertIn('"127.0.0.1:8080:8080"', compose)
        self.assertEqual(REALM_DEFAULT, ADMIN_DEFAULT + "/realms/academy")

    def test_env_example_documents_both_names_with_their_defaults(self):
        env = text(".env.example")
        for name, default in ((REALM_URL, REALM_DEFAULT), (ADMIN_URL, ADMIN_DEFAULT)):
            self.assertTrue(re.search(rf"(?m)^#? ?{name}={re.escape(default)}$", env), name)

    def test_the_chart_sets_the_realm_url_once_for_the_three_quarkus_services(self):
        values = text("deploy/helm/hoops/values.yaml")
        self.assertEqual(len(re.findall(rf"(?m)^\s+{REALM_URL}:", values)), 1)
        self.assertEqual(len(re.findall(rf"(?m)^\s+{ADMIN_URL}:", values)), 1)


if __name__ == "__main__":
    unittest.main()
