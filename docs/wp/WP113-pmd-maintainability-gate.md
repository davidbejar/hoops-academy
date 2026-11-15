# WP113 — Build: PMD and CPD maintainability gate in `verify`

Model: Opus · effort medium. Wave 1 (2026-11-15, eighth round): runs alongside WP111 (Rust service; no `pom.xml`),
WP112 (docs), WP114 (Containerfile) and WP115 (web, nginx). No other WP changes Java or a `pom.xml` in this wave, and
waves 2–4 are written under your gate. You own every `pom.xml`, `config/pmd/**`, `docs/quality/pmd.md`,
`docs/adr/0053-*.md` and the Java sources only where a finding is better fixed than excluded. Depends on: ADR-0045
(exclusions with a reason and, where temporary, an expiry). Skills: clean-code, test-driven-development,
verification-before-completion. Worktree: `~/code/hoops-wt/wp113-pmd`, branch `wp113-pmd`.

Decision 101 of 2026-11-15 (owner): `maven-pmd-plugin` and CPD in `verify`. ADR-0053 is reserved for the ruleset and
thresholds.

## Scope
1. **Ruleset** (`config/pmd/ruleset.xml`, small and explicit, no whole categories): cyclomatic and cognitive
   complexity, method and class length, parameter count, unused code (private members, locals, imports), empty
   catch blocks; CPD for duplicated code with a token threshold. Main code of all Java modules; say in the ADR
   whether tests are in.
2. **Thresholds from today's code**: measure first, set each threshold so the first run is green with few
   exclusions, and record the measured maxima in `docs/quality/pmd.md`. Prefer a small refactor (test first) over an
   exclusion where a method is clearly too long; every exclusion carries a reason.
3. **Gate**: `pmd:check` and `cpd-check` bound to `verify` in the root pom, plugin version pinned, generated code
   excluded; a proof that the gate bites (a temporary violation fails the build; not committed). Report the added
   build time.
4. **Docs**: ADR-0053 (why PMD, not SonarQube; the rules; how to change a threshold), `docs/quality/pmd.md`.

## Acceptance
- [ ] Red first: the gate fails on a planted violation before it is wired green
- [ ] `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` green (fresh; totals, 3,388 tests expected)
- [ ] Mutation baselines unchanged for any module whose rule code you refactored (`just mutation <module>`)
- [ ] Handover appended: the thresholds, the exclusions, what an agent sees when it breaks the gate and how to fix it

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first (JDK 25). Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace in generated files: re-add
  and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit
  (it resyncs the Podman VM clock itself); under load it can time out: retry when a build has finished, never bypass
  it. End every commit message with a `Co-Authored-By:` line that names the model you are.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Gate rules: constant SQL with bound parameters (CodeQL), no nil-tenant bind without a dated acceptance (Semgrep), no
  environment-derived program names in scripts and tests (Semgrep taint). Since WP113 the PMD / CPD gate runs in
  `verify`: stay inside its thresholds, add no exclusion without a reason.
- An OpenAPI generator run can leave whitespace-only diffs in the Dart packages: discard them. Regenerate only your
  package (`scripts/gen-api.sh <svc>`). `apps/web/pubspec.lock`: commit it only with a generated package's version
  bump; revert other drift. `apps/web/lib/l10n/*.arb`: keys next to the feature's existing keys, never at the end.
- Shared index files (`docs/adr/README.md`, `docs/domain/authz-matrix.md`): append at the end, one entry per line.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
