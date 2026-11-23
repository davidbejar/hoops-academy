# WP133 — CI and scripts: concurrency groups, gates run once, pins, composite actions, generator version

Model: Sonnet · high. Wave 2 (2026-11-23, ninth round): starts after wave 1 is merged; runs alongside WP130 (library,
game, athlete), WP131 (finance), WP132 (pdf). You own `.github/**`, `scripts/**` (not `scripts/hooks`), the
`justfile`, `e2e/bin`; nobody else touches them in this wave. Not the poms, not `deploy/**`, not `infra/**` (one line
in `infra/tofu/check.sh` only if CI-05 needs it). Depends on: ADR-0045, ADR-0052, ADR-0055. Skills: work-package,
owasp-security, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp133-ci-gates-once-pins-composite-actions`, branch `wp133-ci-gates-once-pins-composite-actions`.

Decision 104 of 2026-11-23: everything confirmed in CI and the scripts is fixed. ADR-0065 is reserved for you if a
decision is needed.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `scripts-ci.md`
(CI-01..14), verification `verify-deploy-infra-ci.md`; LIB-09 in `libs.md`, verification
`verify-cross-cutting-libs.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Cheap first**: CI-03 (concurrency groups on `ci`, `e2e`, `codeql`, `semgrep`; never cancel a run on `main`),
   CI-02 (`dependency-check` calls its goal directly, the static gates run once), CI-12 (delete the `charts` job in
   `images.yml`).
2. **Pins (CI-05)**: the Trivy pin in `infra/tofu/check.sh` joins `bump_pins.py`; a test like the JDK one keeps the Go
   and Rust pins equal across their files (their hand-bumps stay: ADR-0052, ADR-0055).
3. **Compiles (CI-01, as corrected)**: only part b: `trivy-fs` without a full Quarkus package; CodeQL keeps its own
   build; do not chain `e2e` behind `backend`.
4. **Composite actions (CI-04, CI-07)**: image push / Trivy / SBOM, and the pinned tool set-up. Every third-party
   action stays pinned to a commit SHA (an annotated tag's SHA is not a commit: dereference it).
5. **Generator (LIB-09)**: `gen-api.sh` reads the openapi-generator version from the root `pom.xml` and fails loudly
   on a mismatch; fix the README lines that say otherwise.
6. **The rest**: every other CI finding of your scope; scripts nothing calls are deleted only when the grep over
   justfile, workflows, docs and scripts is in the handover.

Not yours: CI-08 (ADR-0045 keeps the passive baseline in `ci.yml`): leave. INF-02 (login helper) is WP139.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `scripts/tests` green (`python3 -m pytest scripts/tests` or the just recipe; totals)
- [ ] `actionlint` clean on every workflow if the tool is installed, otherwise say so
- [ ] the orchestrator watches the first CI run after the merge: list what to look at
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points, ID table (work-package skill). -->

- Built: concurrency groups on `ci`, `e2e`, `codeql`, `semgrep` (a pull request run is cancelled by a newer push; a run on
  main, a schedule or a dispatch gets its run id as group, so it is never cancelled or replaced); `dependency-check` runs
  `compile` + `dependency-check:aggregate` instead of `verify`; `trivy-fs` populates `~/.m2` with `dependency:go-offline`
  instead of a Quarkus `package`; the `charts` job of `images.yml` is gone; composite actions `setup-java`,
  `setup-flutter`, `setup-pinned-chrome`, `setup-go`, `setup-chart-tools` (kubeconform + gitleaks now verified against the
  SHA-256 of their release archives, taken from the releases' own checksum files) and `image-publish` (Trivy scan, SBOM,
  upload, push; secrets arrive as inputs and reach the shell through `env`, not interpolation); a `scripts` job in `ci.yml`
  (Python tests of `scripts/tests` + the stubbed doctor test) replaces the step in `semgrep.yml`; `docs-site`, `pages`,
  `model-diagrams` and `flutter` call `just docs-build / diagrams-check / web-format-check / web-test`; `infra/tofu/check.sh`
  joined the Trivy pin of `bump_pins.py`; Dependabot also scans `.github/actions/*`; `gen-api.sh` reads the generator
  version from the root pom and stops on a mismatch (READMEs of `libs/contracts` and `apps/web` no longer name a version
  and list finance); `scripts/lib/throwaway-pg.sh` is the one throwaway-PostgreSQL helper. New tests:
  `test_gen_api.py`, `test_toolchain_pins.py` (Trivy, Go, Rust, Chrome, chart tools), `test_workflows.py` (SHA pins,
  local actions exist and come after checkout, concurrency, gates once, Dependabot); `test_jdk_pins.py` now checks the one
  `setup-java` action and that no workflow names a JDK.
- Verified: `python3 -I -m unittest discover -s scripts/tests`: 70 tests, OK (1 skipped, the online multi-arch check; was
  49 before). The same suite passes 69/69 in an Ubuntu 24.04 container (git repo, jq, python3), i.e. as the `scripts` job
  will run it. `actionlint` (installed at /opt/homebrew/bin, run with shellcheck) clean on all 8 workflows; every workflow,
  action and `dependabot.yml` parses as YAML (`actionlint` does not read `action.yml`). Shell tests: tenancy-gate 55/55,
  doctor drop-in 5/5, env-jdk 3/3 on macOS. `events-drift.test.sh` 49/49 after the helper move; `model-diagrams.sh --check`
  prints the same diff before and after the move (the pages were already stale at the base). CI-01 b: with a fresh local
  repository Trivy (0.76.1) gave the same 11 targets, identical packages and vulnerabilities after `package` and after
  `dependency:go-offline`, with the same 10 unresolved-snapshot messages. CI-02: `compile` + the direct goal reaches the NVD
  step with no "could not be resolved ... reactor" warning (a direct call without `compile` prints it and skips
  `common-quarkus`/`contracts`); the scan itself needs the NVD data and was not run. Workflows cannot be run here.
- Decisions/ADRs: ADR-0065.
- Open points / follow-ups:
  - First CI run after the merge: see the final report (watch list).
  - `scripts/tests/env-jdk.test.sh` fails 2 of 3 and `scripts/hooks/tenancy-gate.test.sh` 1 of 55 on Linux (the first needs a
    real JDK 25 outside `PATH`; the second cuts a string with a multi-byte character). Not in CI; `scripts/hooks` is not mine.
  - `docs/domain/*-model.md` is stale at the base commit (`model-diagrams.sh --check` exits 1: `TenantSettings.requireCurrent()`
    and others), so the `model-diagrams` job of `ci` is red until someone runs `just diagrams`.
  - The `bump-pins` PR still leaves `ci.yml` (a workflow) to be bumped by hand for the Trivy tag, while the action,
    `sbom.sh` and `check.sh` are in the same pin: under `--skip-workflows` the whole pin is listed as manual (unchanged rule).
  - `docs/runbooks/release.md` pin table updated (Trivy files, hand-bumped tools).
  - No script was deleted: the audit found every script referenced, and none was removed.
- Skipped, with reasons: CI-01 part a (not wanted, brief) and CodeQL keeps its own build; CI-06 (a cache or image hand-over
  between `e2e` and `images`, medium risk, cannot be tried without a run; ADR-0054/service.Containerfile make the in-container
  Maven the reproducible build); CI-08 (ADR-0045 keeps the passive baseline in `ci.yml`, brief); CI-13 (root `pom.xml`, not
  mine: delete `failsafe-plugin.version`, `skipITs` and the failsafe `pluginManagement` entry there); the `podman build` lines
  of `images.yml` vs `scripts/build-images.sh` (different tags and build-arg sets, only run on main, no way to test) and
  folding web/pdf/finance into one matrix (different start checks and build steps; the repeated part is now the action).

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| CI-01 | Done (part b) | `trivy-fs` uses `dependency:go-offline`; parts a and c as the brief says |
| CI-02 | Done | `dependency-check`: `compile` + direct `dependency-check:aggregate`, no second SpotBugs/PMD/CPD |
| CI-03 | Done | concurrency on ci, e2e, codeql, semgrep; main never cancelled; `test_workflows.py` |
| CI-04 | Done | `image-publish` composite action in the four image jobs; no matrix fold, build lines stay |
| CI-05 | Done | check.sh in the Trivy pin; `test_toolchain_pins.py` for Go, Rust, Chrome, chart tools; hand-bumps stay |
| CI-06 | Skipped | medium risk, untestable here; see above |
| CI-07 | Done | `setup-java`, `setup-flutter`, `setup-pinned-chrome`, `setup-go`; JDK test follows |
| CI-08 | Skipped | ADR-0045, brief |
| CI-09 | Done | docs-build, web-format-check, web-test, diagrams-check called from CI; the `e2e` recipe differs on purpose |
| CI-10 | Done in part | Python tests + doctor test in a `scripts` job, `test_model_diagrams` runs once; env-jdk and tenancy-gate tests fail on Linux, stay local |
| CI-11 | Done | `scripts/lib/throwaway-pg.sh`; the readiness loop of the finance check in `images.yml` stays (a different container) |
| CI-12 | Done | `charts` job deleted; `setup-chart-tools` (with SHA-256) for ci and bump-pins |
| CI-13 | Skipped | root pom, outside this WP |
| CI-14 | Done | `just docs-build` in ci and pages |
| LIB-09 | Done | `gen-api.sh` reads the pom and fails; READMEs fixed incl. `apps/web/README.md`; `test_gen_api.py` |
