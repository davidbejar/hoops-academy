"""The database roles come from one list (INF-03): the `roles` block of infra/db/init/01_roles_schemas.sql.

The SQL derives every grant, limit and search_path from it; 02_passwords.sh asks the database for the roles the SQL
marked; infra/db/roles.sh prints the list for shell scripts and workflows; the Java and Go test harnesses read it from
the SQL. The lists that must stay literal (compose's environment, .env.example, the chart's CNPG roles and Secrets,
kind's secrets.sh and env-keys.sh) are compared with it here.
Run: python3 -I -m unittest discover -s scripts/tests"""
import pathlib
import re
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SQL = ROOT / "infra/db/init/01_roles_schemas.sql"
CHART_SQL = ROOT / "deploy/helm/hoops/charts/databases/files/01_roles_schemas.sql"
PASSWORDS = ROOT / "infra/db/init/02_passwords.sh"
EXPECTED = ["core_migrator", "core_app", "core_platform", "game_migrator", "game_app", "athlete_migrator", "athlete_app",
            "finance_migrator", "finance_app"]
ROLE = re.compile(r"\b(?:core|game|athlete|finance)_(?:app|migrator|platform)\b")


def block(text):
    m = re.search(r"-- roles: begin\n(.*?)-- roles: end\n", text, re.S)
    if not m:
        raise AssertionError("no `-- roles: begin` / `-- roles: end` block in the SQL")
    return m


def listed():
    """(name, connection limit) per row of the list, in order."""
    return [(n, int(lim)) for n, lim in re.findall(r"\(\s*'([a-z_]+)',\s*'[^']*',\s*(-?\d+)", block(SQL.read_text()).group(1))]


def password_vars(text):
    return set(re.findall(r"\b((?:CORE|GAME|ATHLETE|FINANCE)_(?:APP|MIGRATOR|PLATFORM)_PASSWORD)\b", text))


def env_names():
    return {n.upper() + "_PASSWORD" for n, _ in listed()}


class TheList(unittest.TestCase):
    def test_the_sql_lists_the_nine_roles_once(self):
        self.assertEqual([n for n, _ in listed()], EXPECTED)

    def test_roles_sh_prints_the_list(self):
        out = subprocess.run([str(ROOT / "infra/db/roles.sh")], capture_output=True, text=True, check=True).stdout
        self.assertEqual(out.split(), EXPECTED)

    def test_no_statement_of_the_sql_names_a_role_outside_the_list_and_the_schema_rows(self):
        text = SQL.read_text()
        outside = text[:block(text).start()] + text[block(text).end():]
        statements = [line for line in outside.splitlines() if not line.lstrip().startswith("--")]
        literal = [line for line in statements if ROLE.search(line) and not re.match(r"\s+\('\w+',\s+'\w+',\s+'\w+'\)", line)
                   and "core_platform" not in line]
        self.assertEqual(literal, [], "grants and search paths come from the list")

    def test_the_chart_carries_the_same_sql(self):
        self.assertEqual(CHART_SQL.read_text(), SQL.read_text())


class PasswordScripts(unittest.TestCase):
    def test_02_passwords_names_no_role(self):
        text = PASSWORDS.read_text()
        self.assertIsNone(ROLE.search(text))
        self.assertEqual(password_vars(text), set())

    def test_the_finance_only_path_is_gone(self):
        self.assertFalse((ROOT / "infra/compose/finance-db.sh").exists())
        db_roles = (ROOT / "infra/compose/db-roles.sh").read_text()
        self.assertIn("02_passwords.sh", db_roles)
        self.assertIsNone(ROLE.search(db_roles))

    def test_compose_passes_every_password_and_requires_each(self):
        compose = (ROOT / "infra/compose/compose.yaml").read_text()
        postgres = compose[compose.index("  postgres:"):compose.index("  keycloak:")]
        self.assertEqual(password_vars(postgres), env_names())
        for var in env_names():
            self.assertIn(f"{var}: ${{{var}:?set in .env}}", postgres)


class LiteralLists(unittest.TestCase):
    def test_env_example(self):
        self.assertEqual(password_vars((ROOT / ".env.example").read_text()), env_names())

    def test_kind_secrets_and_env_keys(self):
        self.assertEqual(password_vars((ROOT / "deploy/kind/secrets.sh").read_text()), env_names())
        self.assertEqual(password_vars((ROOT / "deploy/kind/env-keys.sh").read_text()), env_names())

    def test_chart_cnpg_roles_with_the_same_connection_limits(self):
        values = (ROOT / "deploy/helm/hoops/charts/databases/values.yaml").read_text()
        roles = [(n, int(lim)) for n, lim in re.findall(r"\{name: ([a-z_]+),\s+secret: [a-z-]+,\s+connectionLimit: (-?\d+)\}",
                                                         values)]
        self.assertEqual(roles, listed())

    def test_chart_external_secrets(self):
        values = (ROOT / "deploy/helm/hoops/values.yaml").read_text()
        self.assertEqual(set(re.findall(r"literals: \{username: ([a-z_]+)\}", values)) - {"keycloak"}, set(EXPECTED))


if __name__ == "__main__":
    unittest.main()
