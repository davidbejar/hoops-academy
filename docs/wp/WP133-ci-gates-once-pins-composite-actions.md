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
