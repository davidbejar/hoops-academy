# WP37 — Mutation testing: measure, kill the mutants that matter, keep a baseline

Model: Opus. Wave 4: starts after WP35 is merged (it touches tests in every service); may run alongside WP36
(disjoint files). Depends on: nothing else. Skills: test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp37-mutation`, branch `wp37-mutation`.

Decision of 2026-11-05: mutation testing is **not** part of every build. It runs on demand (and on a slow schedule)
where it pays off most; the surviving mutants that reveal weak tests get fixed; a baseline score is kept so a later
run shows a regression.

## Starting point
Root `pom.xml` `pluginManagement` has `pitest-maven` 1.30.1 + `pitest-junit5-plugin` 1.2.3, `targetClasses =
com.hoopsacademy.*.domain.*`, `mutationThreshold = 70`, not bound to any phase and not declared by any module. No run
has ever been recorded (FOLLOW-UPS "PIT").

## Where it pays off (measure first, then decide)
Pure code with pure unit tests, where PIT is fast and the logic is what the product is about:
- `core` domain: eligibility rules, age categories, membership/roles, `TemporaryPassword`, value objects.
- `game` domain: stat events → box score / stat lines, client sequence rules, match state.
- `athlete` domain: fitness bands (norms), availability, plan progress.
- `libs/common-quarkus`: tenancy helpers (`TenantScope`, tenant id parsing) and the problem mapping, if they have
  pure unit tests — isolation code deserves strong tests.
Not in scope: `@QuarkusTest` classes (containers, minutes per mutant), adapters, generated code, Flutter (no mature
Dart mutation tool; say so in the doc).

## Scope
1. **Wiring**: a root profile `mutation` that declares `pitest-maven` in the modules with pure domain tests, with
   `targetClasses` per module (domain + the application-layer rule classes you find worth it), `targetTests`
   limited to pure unit tests (exclude `@QuarkusTest` classes by name pattern or a JUnit tag — pick the mechanism
   that cannot silently include a container test), `mutators` = DEFAULTS (STRONGER if it stays under ~10 min per
   module), `timestampedReports=false`, HTML + XML output under `target/pit-reports`. `just mutation [module]`
   recipe (`./mvnw -Pmutation -pl <module> -am test-compile org.pitest:pitest-maven:mutationCoverage` or the
   equivalent that works). Document the runtime per module.
2. **First run**: record the per-module score and the list of surviving mutants (counts per class) in
   `docs/quality/mutation.md` as the "before" column.
3. **Fix what matters**: for each surviving mutant in rule code (not in `toString`/`equals`/logging): write the test
   that kills it, in the TDD rhythm (the mutant is the spec of the missing assertion). Prefer strengthening an
   existing test's assertions over adding near-duplicate tests. Equivalent mutants (no observable behaviour
   change) are excluded with a reason, not tolerated silently: PIT `excludedMethods` / `avoidCallsTo` in the pom
   with a comment, or an annotation if the plugin version supports one; list them in `mutation.md`.
4. **Baseline**: set each module's `mutationThreshold` to the achieved score rounded down to a multiple of 5, so a
   future run fails below it. Keep the threshold out of the default build (profile only).
5. **Schedule**: a GitHub workflow `mutation.yml` with `workflow_dispatch` and a monthly `schedule`, running
   `just mutation` for every configured module, uploading `target/pit-reports` as artifacts, failing on the
   threshold; `actionlint` clean. Not part of `ci.yml`.
6. **Docs**: `docs/quality/mutation.md` (what runs where, how to read a report, when to run: before a release and
   after domain changes, before/after table, excluded mutants with reasons); CLAUDE.md command list gains
   `just mutation`; FOLLOW-UPS "PIT" item resolved by WP37 (note it in your handover — WP26 owns FOLLOW-UPS, the
   orchestrator will move it).

## Acceptance
- [ ] `just mutation` runs each configured module to completion on this machine; runtimes recorded
- [ ] Before/after scores per module in `mutation.md`; every "after" score ≥ 80 % in domain packages or the
      shortfall explained mutant by mutant
- [ ] Every new or strengthened test committed before the (rare) production change it required; production code
      changes only when a mutant exposed a real defect — list those explicitly
- [ ] `./mvnw -B -ntp -T 1C verify` green (fresh; totals); the default build time is unchanged (profile only)
- [ ] `actionlint .github/workflows/mutation.yml` clean; the workflow runs green once via `gh workflow run` after
      the orchestrator pushes (note in the handover that this step is the orchestrator's)
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected,
  do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
