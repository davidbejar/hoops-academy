"""Every place that names the JDK major agrees with `maven.compiler.release` in the root pom.xml: the build and runtime
images of the service Containerfile, the `setup-java` composite action of the workflows, and the JDK that scripts/env.sh selects.
Also: every pin that scripts/bump_pins.py maintains is still found in its files (else the weekly bump fails).
Run: python3 -I -m unittest discover -s scripts/tests"""
import pathlib
import re
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import bump_pins  # noqa: E402

SETUP_JAVA = ".github/actions/setup-java/action.yml"  # the one place CI names the JDK


def release():
    return re.search(r"<maven\.compiler\.release>(\d+)</maven\.compiler\.release>", (ROOT / "pom.xml").read_text())[1]


class JdkPinsAgree(unittest.TestCase):
    def test_service_images_use_the_release(self):
        text = (ROOT / "deploy/containers/service.Containerfile").read_text()
        self.assertEqual(re.findall(r"ARG MAVEN_IMAGE=\S+:\d+\.\d+\.\d+-eclipse-temurin-(\d+)@sha256:", text), [release()])
        self.assertEqual(re.findall(r"ARG RUNTIME_IMAGE=gcr\.io/distroless/java(\d+)-debian\d+:nonroot@", text),
                         [release()])

    def test_the_weekly_bump_follows_the_runtime_image(self):
        # ADR-0054: distroless publishes floating tags only, so the bump moves the digest of `nonroot`; the pin's repo
        # must be the one the Containerfile names, or a JDK or Debian change would leave the bump on the old image.
        text = (ROOT / "deploy/containers/service.Containerfile").read_text()
        image = re.search(r"ARG RUNTIME_IMAGE=(\S+)\n", text)[1]
        pins = [p for p in bump_pins.PINS if p.name == "distroless java25 nonroot"]
        self.assertEqual(len(pins), 1)
        digest = bump_pins.read_groups(pins[0], ROOT)["digest"]
        self.assertEqual(f"{pins[0].opts['repo']}:{pins[0].opts['floating']}@{digest}", image)

    def test_the_setup_java_action_uses_the_release(self):
        self.assertEqual(re.findall(r"java-version: '(\d+)'", (ROOT / SETUP_JAVA).read_text()), [release()])

    def test_no_workflow_names_its_own_jdk(self):
        for path in sorted((ROOT / ".github/workflows").glob("*.yml")):
            with self.subTest(workflow=path.name):
                self.assertNotIn("java-version", path.read_text())

    def test_env_sh_selects_the_release(self):
        self.assertRegex((ROOT / "scripts/env.sh").read_text(), rf"(?m)^_JDK_MAJOR={release()}$")


class BumpPinsStillMatch(unittest.TestCase):
    def test_every_pin_is_found_in_its_files(self):
        for pin in bump_pins.PINS:
            with self.subTest(pin=pin.name):
                bump_pins.read_groups(pin, ROOT)


if __name__ == "__main__":
    unittest.main()
