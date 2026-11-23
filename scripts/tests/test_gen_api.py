"""scripts/gen-api.sh takes the openapi-generator version from `openapi-generator.version` in the root pom.xml (the
version the Maven validation runs) and fails when the local generator differs: the Dart clients and the validated
contracts must come from one generator. The READMEs name no literal version, so they cannot drift again (LIB-09).
Run: python3 -I -m unittest discover -s scripts/tests"""
import os
import pathlib
import re
import stat
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/gen-api.sh"


def pom_version():
    return re.search(r"<openapi-generator\.version>([^<]+)</openapi-generator\.version>", (ROOT / "pom.xml").read_text())[1]


def stub_generator(directory, version):
    """A fake `openapi-generator`: prints `version` for `version`, accepts `generate` and does nothing."""
    path = pathlib.Path(directory) / "openapi-generator"
    path.write_text(f'#!/bin/sh\n[ "$1" = version ] && echo {version}\nexit 0\n')
    path.chmod(path.stat().st_mode | stat.S_IXUSR)
    return path


def run_script(generator_version):
    with tempfile.TemporaryDirectory() as tmp:
        env = {**os.environ, "OPENAPI_GENERATOR": str(stub_generator(tmp, generator_version)),
               "GEN_API_BUILD": "0", "API_OUT_ROOT": tmp + "/out"}
        return subprocess.run([str(SCRIPT), "core"], env=env, capture_output=True, text=True, check=False)


class GeneratorVersionFollowsThePom(unittest.TestCase):
    def test_the_script_holds_no_version_literal(self):
        self.assertIsNone(re.search(r'(?m)^EXPECTED_GENERATOR_VERSION="\d', SCRIPT.read_text()))

    def test_the_pom_version_is_accepted(self):
        done = run_script(pom_version())
        self.assertEqual(done.returncode, 0, done.stderr)

    def test_another_version_fails_and_names_both(self):
        done = run_script("0.0.1")
        self.assertNotEqual(done.returncode, 0)
        self.assertIn("0.0.1", done.stderr)
        self.assertIn(pom_version(), done.stderr)

    def test_the_readmes_name_no_generator_version(self):
        for rel in ["libs/contracts/README.md", "apps/web/README.md"]:
            with self.subTest(readme=rel):
                text = (ROOT / rel).read_text()
                self.assertIsNone(re.search(r"openapi-generator`?\*{0,2}\s+\*{0,2}v?\d+\.\d+", text), rel)

    def test_the_readmes_name_every_generated_service(self):
        for rel in ["libs/contracts/README.md", "apps/web/README.md"]:
            with self.subTest(readme=rel):
                self.assertNotIn("{core,game,athlete}", (ROOT / rel).read_text(), rel)


if __name__ == "__main__":
    unittest.main()
