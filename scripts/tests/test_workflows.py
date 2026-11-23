"""Structure of .github (stdlib only, no YAML parser): what a reviewer would otherwise have to check by eye.
- every third-party action is pinned to a full commit SHA (an annotated tag's SHA is not a commit: dereference it);
- every local composite action exists, and a job runs actions/checkout before it uses one (the action files are in the
  checkout);
- the heavy workflows cancel a superseded pull request run, and never a run on main, a schedule or a dispatch (CI-03);
- `dependency-check` does not run the static gates a second time (CI-02), `trivy-fs` does not package the reactor (CI-01).
Run: python3 -I -m unittest discover -s scripts/tests"""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
GITHUB = ROOT / ".github"
WORKFLOWS = sorted((GITHUB / "workflows").glob("*.yml"))
ACTIONS = sorted((GITHUB / "actions").glob("*/action.yml"))
SHA = re.compile(r"^[0-9a-f]{40}$")
USES = re.compile(r"^\s*(?:-\s+)?uses:\s*(\S+)")
CANCELLING = ["ci.yml", "e2e.yml", "codeql.yml", "semgrep.yml"]


def uses_of(path):
    return [m[1] for line in path.read_text().splitlines() if (m := USES.match(line))]


def jobs_of(path):
    """{job id: [uses of its steps in order]} of a workflow file."""
    jobs, current, in_jobs = {}, None, False
    for line in path.read_text().splitlines():
        if re.match(r"^jobs:\s*$", line):
            in_jobs = True
        elif in_jobs and (m := re.match(r"^  ([\w-]+):\s*$", line)):
            current = jobs.setdefault(m[1], [])
        elif in_jobs and current is not None and (m := USES.match(line)):
            current.append(m[1])
    return jobs


def job_block(path, job):
    """The lines of one job of a workflow."""
    lines = path.read_text().splitlines()
    start = next(i for i, line in enumerate(lines) if line == f"  {job}:")
    end = next((i for i in range(start + 1, len(lines)) if re.match(r"^  [\w-]+:\s*$", lines[i])), len(lines))
    return "\n".join(lines[start:end])


class ActionsArePinned(unittest.TestCase):
    def test_third_party_actions_use_a_commit_sha(self):
        for path in WORKFLOWS + ACTIONS:
            for ref in uses_of(path):
                if ref.startswith("./"):
                    continue
                with self.subTest(file=path.name, uses=ref):
                    self.assertRegex(ref.split("@", 1)[1] if "@" in ref else "", SHA)

    def test_local_actions_exist(self):
        for path in WORKFLOWS + ACTIONS:
            for ref in uses_of(path):
                if ref.startswith("./"):
                    with self.subTest(file=path.name, uses=ref):
                        self.assertTrue((ROOT / ref / "action.yml").is_file())

    def test_checkout_comes_before_the_first_local_action_of_a_job(self):
        for path in WORKFLOWS:
            for job, uses in jobs_of(path).items():
                local = [i for i, ref in enumerate(uses) if ref.startswith("./")]
                if local:
                    with self.subTest(file=path.name, job=job):
                        first_checkout = next((i for i, ref in enumerate(uses) if ref.startswith("actions/checkout@")), None)
                        self.assertIsNotNone(first_checkout)
                        self.assertLess(first_checkout, local[0])


class DependabotKeepsTheCompositeActionsCurrent(unittest.TestCase):
    def test_the_github_actions_entry_scans_the_composite_actions_too(self):
        text = (GITHUB / "dependabot.yml").read_text()
        entry = text[text.index("package-ecosystem: github-actions"):]
        entry = entry.split("\n  - package-ecosystem:")[0]
        self.assertIn("/.github/actions/*", entry)


class HeavyWorkflowsCancelSupersededPullRequestRuns(unittest.TestCase):
    def test_concurrency_group_per_pull_request_and_unique_elsewhere(self):
        for name in CANCELLING:
            with self.subTest(workflow=name):
                body = (GITHUB / "workflows" / name).read_text()
                top = re.search(r"(?m)^concurrency:\n((?:  .*\n)+)", body)
                self.assertIsNotNone(top, "no top-level concurrency")
                block = top[1]
                # a pull request shares a group per ref and is cancelled; every other event gets a group of its own
                self.assertIn("github.event_name == 'pull_request'", block)
                self.assertIn("github.run_id", block)
                self.assertRegex(block, r"cancel-in-progress: \$\{\{ github\.event_name == 'pull_request' \}\}")


def maven_commands(block):
    """The ./mvnw invocations of a job (a command may continue on the next line with a trailing backslash)."""
    return [m[0].replace("\\\n", " ") for m in re.finditer(r"\./mvnw[^\n]*(?:\\\n[^\n]*)*", block)]


class GatesRunOnce(unittest.TestCase):
    def test_dependency_check_calls_its_goal_and_not_the_static_gates(self):
        commands = maven_commands(job_block(GITHUB / "workflows/ci.yml", "dependency-check"))
        self.assertEqual(len(commands), 1)
        self.assertIn("org.owasp:dependency-check-maven:aggregate", commands[0])
        self.assertIsNone(re.search(r"\b(verify|package|install)\b", commands[0]))

    def test_trivy_fs_resolves_the_dependencies_without_packaging_the_reactor(self):
        commands = maven_commands(job_block(GITHUB / "workflows/ci.yml", "trivy-fs"))
        self.assertEqual(len(commands), 1)
        self.assertIn("dependency:go-offline", commands[0])
        self.assertIsNone(re.search(r"\b(verify|package|install)\b", commands[0]))

    def test_the_charts_job_of_images_is_gone(self):
        self.assertNotIn("deploy/helm/tests/run.sh", (GITHUB / "workflows/images.yml").read_text())


if __name__ == "__main__":
    unittest.main()
