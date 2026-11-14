"""Every place that names the JDK major agrees with `maven.compiler.release` in the root pom.xml: the build and runtime
images of the service Containerfile, `actions/setup-java` in the workflows, and the JDK that scripts/env.sh selects.
Also: every pin that scripts/bump_pins.py maintains is still found in its files (else the weekly bump fails).
Run: python3 -I -m unittest discover -s scripts/tests"""
import pathlib
import re
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import bump_pins  # noqa: E402

WORKFLOWS = ["ci.yml", "e2e.yml", "mutation.yml", "codeql.yml"]


def release():
    return re.search(r"<maven\.compiler\.release>(\d+)</maven\.compiler\.release>", (ROOT / "pom.xml").read_text())[1]


class JdkPinsAgree(unittest.TestCase):
    def test_service_images_use_the_release(self):
        text = (ROOT / "deploy/containers/service.Containerfile").read_text()
        self.assertEqual(re.findall(r"ARG MAVEN_IMAGE=\S+:3-eclipse-temurin-(\d+)\n", text), [release()])
        self.assertEqual(re.findall(r"ARG RUNTIME_IMAGE=\S+/ubi9/openjdk-(\d+)-runtime:", text), [release()])

    def test_every_setup_java_uses_the_release(self):
        for name in WORKFLOWS:
            versions = re.findall(r"java-version: '(\d+)'", (ROOT / ".github/workflows" / name).read_text())
            self.assertTrue(versions, name)
            self.assertEqual(set(versions), {release()}, name)

    def test_env_sh_selects_the_release(self):
        self.assertRegex((ROOT / "scripts/env.sh").read_text(), rf"(?m)^_JDK_MAJOR={release()}$")


class BumpPinsStillMatch(unittest.TestCase):
    def test_every_pin_is_found_in_its_files(self):
        for pin in bump_pins.PINS:
            with self.subTest(pin=pin.name):
                bump_pins.read_groups(pin, ROOT)


if __name__ == "__main__":
    unittest.main()
