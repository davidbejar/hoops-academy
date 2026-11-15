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
- [x] Red first: the gate fails on a planted violation before it is wired green
- [x] `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` green (fresh; totals, 3,388 tests expected)
- [x] Mutation baselines unchanged for any module whose rule code you refactored (`just mutation <module>`)
- [x] Handover appended: the thresholds, the exclusions, what an agent sees when it breaks the gate and how to fix it

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

- Built: `maven-pmd-plugin` 3.28.0 with PMD 7.29.0 (pinned; parses all Java 25 main code, 0 processing errors) bound
  to `verify` in every module through the root pom (executions `pmd-check`, `cpd-check`; `failurePriority` 5, main
  code only, `target/generated-sources` excluded). Ruleset `config/pmd/ruleset.xml` (single rules): cyclomatic method
  ≥ 15 / class ≥ 65, cognitive ≥ 15, NCSS method ≥ 30 / class ≥ 150, ≥ 12 parameters, unused private field / method /
  local / import, empty catch (commented block allowed); CPD ≥ 100 tokens per module. Measured maxima before/after in
  `docs/quality/pmd.md`. Fixed instead of excluded: `AssignmentJpaRepository.search` (cognitive 18) split test first
  (`AssignmentSearchClauseTest`, 4 tests); the copied outbox insert of `JpaOutboxRepository` / `PlatformOutboxRepository`
  now `OutboxRowRepository` (native SQL stays in a `*Repository`, ArchUnit); 10 unused pattern variables became `_`
  (game `ProjectionRun`, `PlayerTally`, `IngestEventBatch`; core `EligibilityCheckDto`); 4 unused imports removed.
- Exclusions (each with its reason in the file): `exclude-pmd.properties`: `MatchEventJson`, `RosterEventDecoder`,
  `CoreEventDecoder` = CyclomaticComplexity (flat switch, one arm per event type, under mutation testing); `Match` =
  ExcessiveParameterList (`restore`, one parameter per column); `CreatePlayer` = ExcessiveParameterList (12 CDI
  collaborators; may not take a 13th). `exclude-cpd.properties`: `ManageExercises`,`ManagePlans` (two aggregates whose
  six patchable fields coincide).
- Found on the way: the plugin's CPD exclusion loader reads a blank line as an empty class name, which matches every
  path and silently accepts every duplication inside one file (my first CPD proof passed when it should have failed).
  The CPD file has no blank line; `scripts/tests/test_pmd_exclusions.py` guards it (also: a reason above every entry,
  classes exist, rules are in the ruleset); red on a blank line, green now.
- What an agent sees when it breaks the gate: `[WARNING] PMD Failure: <Class>:<line> Rule:<Rule> Priority:3 <message
  with the value and threshold>` and `[ERROR] Failed to execute goal ...maven-pmd-plugin:3.28.0:check (pmd-check) on
  project <module>: PMD 7.29.0 has found N violations`, or `CPD Failure: Found N lines of duplicated code at
  locations:` + the files and lines, then `cpd-check (cpd-check) ... has found N duplication`. Fix: refactor (extract
  named methods, guard clauses, a parameter object, split the use case, a shared helper / `*Repository` for SQL;
  unused pattern variables → `_`), test first; table "When the gate fails" in `docs/quality/pmd.md`. Accept only
  when the code is right as it is: one line in the exclusion file under a reason comment; never raise a threshold for
  one class, never `@SuppressWarnings("PMD…")` / `// NOPMD`.
- Verified: red first: gate without exclusions failed on the 5 expected PMD findings and the 1 CPD duplication; planted
  violations (unused private field + empty catch; a 12-line duplicate) each failed `./mvnw -pl libs/common-quarkus
  verify` at `pmd-check` / `cpd-check`; planted files removed, not committed. Fresh `./mvnw -B -ntp -T 1C clean verify
  -Dquarkus.http.test-port=0`: BUILD SUCCESS, 3,392 tests (3,388 + 4 new), 0 failures, 0 errors, 26 skipped, 12:05
  min wall under the load of three other agents. `just mutation game-service`: 525/527 (99 %), baseline 99 unchanged
  (the only rule code touched; core and athlete changes are outside their mutation scopes). `python3 -I -m unittest
  discover -s scripts/tests`: 38 tests OK (1 skipped). Added build time: compile + gate 10–12 s vs compile alone
  6–10 s on the reactor, about 3–6 s wall. Not run: `just isolation-check` separately (the commit hook runs it),
  `just web-test` (no web change), CI.
- Decisions/ADRs: ADR-0053 (why PMD not SonarQube, the rules, tests out, how to change a threshold); index line
  appended to `docs/adr/README.md`.
- Open points / follow-ups: CPD runs per module, so copies between services (both `PatchBody` classes) are not found;
  splitting `CreatePlayer` (12 collaborators); the exclusion format has no expiry (reviewed each round, as SpotBugs);
  `CLAUDE.md` Definition of Done and `docs/HANDOVER.md` could name the gate (orchestrator's docs pass); PMD warns
  `Adding current platform jrt-fs.jar to auxClasspath` (harmless: build JDK = release 25).
