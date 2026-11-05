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

## Handover
- Built:
  - Root `pluginManagement`: shared PIT setup (STRONGER mutators, `threads=4`, HTML + XML in `target/pit-reports`,
    no timestamps, `skip=${pit.skip}` = true by default, never bound to a phase). Each of `common-quarkus`,
    `core-service`, `game-service`, `athlete-service` names its targets in `pit.targetClasses` / `pit.targetTests` and
    has a `mutation` profile (activated by `-Dmutation=<artifactId>` or `-Pmutation`) that sets `pit.skip=false`, the
    baseline `pit.mutationThreshold` and (core) `pit.excludedMethods=hashCode`. `just mutation [module]` runs
    `./mvnw -Dmutation=<m> -pl :<m> -am test-compile org.pitest:pitest-maven:mutationCoverage` per module.
  - Container tests cannot reach PIT: `MutationTestScope` (common-quarkus test-jar, own fixture test) +
    `MutationScopeTest` per module in the default build fail when a `pit.targetTests` glob matches a class (or its
    enclosing class / superclass) using `io.quarkus.test.*` or `org.testcontainers.*`, matches nothing, or carries
    whitespace (PIT does not trim). Surefire passes `pit.targetTests` as a system property.
  - Tests that kill the survivors, committed per module; `.github/workflows/mutation.yml` (`workflow_dispatch` +
    monthly cron, matrix over the four modules, artifacts `pit-reports-<module>`); `docs/quality/mutation.md`;
    `just mutation` in CLAUDE.md.
- Scores (before → after): common-quarkus 95.4 % → 99.1 %, core 92.9 % → 99.6 % (domain 93.3 → 99.6), game
  87.3 % → 99.5 % (domain 86.8 → 99.5), athlete 76.7 % → 100 %. Baselines 95 / 95 / 95 / 100. Runtimes (M1 Pro,
  shared): 11 s / 68 s / 42 s / 34 s.
- Production code: unchanged — no mutant exposed a real defect. Remaining survivors are equivalent and listed with
  reasons in mutation.md (Eligibility.reasons dead branch, CoreRosterClient.zoneOf blank check, EventVisibility
  seesAll fast path, ProjectionRun.apply lastClock); `TemporaryPassword.hashCode` excluded in the pom.
- Verified: `just mutation` (all four modules, thresholds active) BUILD SUCCESS; a threshold above the score fails the
  run ("Mutation score of 99 is below threshold of 100"); `./mvnw -B -ntp -T 1C verify` fresh: BUILD SUCCESS, 1970
  tests, 0 failures/errors, all coverage checks met, 8:46 min wall clock (PIT not in it; the default build only gains
  the new unit tests and four ~1 s scope checks); `actionlint .github/workflows/mutation.yml` clean.
- Decisions/ADRs: no new ADR — the decision of 2026-11-05 (on demand + monthly, baseline per module) is recorded in
  mutation.md together with the mechanism choices (property-activated profiles, explicit test globs + guard,
  STRONGER).
- Open points / follow-ups:
  - Orchestrator: after pushing, run the workflow once (`gh workflow run mutation.yml`) and confirm it is green.
  - FOLLOW-UPS "PIT" item is resolved by WP37 (WP26 owns FOLLOW-UPS; please move it).
  - core `ApprovalPayload.empty()` is never called (dead code; its mutant stays uncovered): delete or use it.
  - Rule code reached only by container tests (`TenantScope`, `ProblemExceptionMappers`, use cases) is outside PIT's
    scope; extracting pure rules from them would let PIT cover them.
  - Commits carry `Co-Authored-By: Claude Opus 5.5` (the model that did the work), not the Fable line from the brief.
