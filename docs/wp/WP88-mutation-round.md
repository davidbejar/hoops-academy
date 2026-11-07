# WP88 — Mutation round: wider PIT scope, baselines raised, Dart mutation tool for the web rule code

Model: Opus. Wave 4 (2026-11-06, fifth round): starts after wave 3 is merged; the only agent on the backend (refactors
touch the three services and `libs/common-quarkus`); WP77 runs on `apps/web/lib/features/landing` at the same time:
in `apps/web` you own ONLY `apps/web/tool/mutation/**` (new), `apps/web/test/mutation/**` (new) and the test files
you add for killed mutants under `apps/web/test/core/**` and `test/features/{match,training,roster,health}/**`
(tests only, no `lib/` edits unless a mutant reveals a real bug: then the fix, one commit, named in the handover).
You own the root `pom.xml` PIT section, every `services/*` and `libs/common-quarkus` main and test code,
`docs/quality/mutation.md`, `justfile` mutation recipes, `.github/workflows/mutation.yml`. Depends on: WP37
(PIT), `docs/quality/mutation.md` (scopes and baselines), WP67–WP69/WP82 (new rule code). Skills:
test-driven-development, clean-code, quarkus-hexagonal-service, verification-before-completion. Worktree:
`~/code/hoops-wt/wp88-mutation-round`, branch `wp88-mutation-round`.

Decision 56 of 2026-11-06: extract pure rules so PIT covers use cases and container-only code; baselines raised to
the current scores (core 99.6, game 99.5, athlete 100); a Dart mutation tool (no Node) for the web rule code with
its own baseline; survivors killed.

## Scope
1. **Scope widening** (per service): list the rule-bearing classes outside PIT's scope today (use cases, `TenantScope`,
   `ProblemExceptionMappers`, the athlete replica apply rules, the WP78 search/copy rules, WP80 season rules, WP81
   backfill ordering, WP82 retention); extract pure decision logic into framework-free classes where it is not yet
   (hexagonal: domain or application without CDI), add them to `pit.targetClasses` with unit tests; ArchUnit stays
   green. Record each extraction (class, from, to) in `mutation.md`.
2. **Baselines**: `mutation.md` table and `justfile` thresholds raised to the current scores; equivalent mutants
   listed with justification; survivors killed with tests (red first for real gaps).
3. **Dart mutation tool** (`apps/web/tool/mutation/`): a Dart script (no Node) that applies a small operator set
   (negate condition, swap comparison, remove statement, boundary ±1, boolean literal flip) to the web rule files
   listed in a manifest (offline sync/outbox merge, match clock and score rules, eligibility views, usage counters,
   locale negotiation, cache scoping), runs the matching `flutter test` subsets per mutant with a time cap, reports
   killed/survived/timeouts, and enforces a baseline; `just web-mutation` recipe; documented in `mutation.md`; the
   first run's score becomes the baseline after survivors are killed or justified. Runtime target under 30 min.
4. **CI**: `mutation.yml` (manual + monthly) gains the Dart job.

## Acceptance
- [x] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals; ArchUnit green after the
      extractions)
- [x] `just mutation` for the three services at or above the new baselines (scores and mutant counts recorded)
- [x] `just web-mutation` runs end to end with its baseline recorded; `flutter analyze` and `just web-format-check`
      clean; `just web-test` green (fresh; totals)
- [x] `docs/quality/mutation.md` updated; handover appended (extractions, equivalents, runtime)

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - **Extractions** (framework-free, unit tested, in the PIT scope; table in `docs/quality/mutation.md` § Extractions):
    common `ExclusiveLocks` (from `TenantScope`: advisory key, lock timeout clamp), common `ProblemMapping` (from
    `ProblemExceptionMappers`: concurrent-modification cause chain, violation order, ROLE/FINE_GRAINED); core
    `BackfillPlan` (from `BackfillRosterEvents`, WP81: topic order, candidates, aggregate ids, chunks), core domain
    `EndedSeasons` (from `PastSeasons`, WP80); game `EventAdmission` (from `IngestEventBatch`: duplicate, cancelled,
    authz, season closed, device sequence), game domain `SeasonClose` (from `PastSeasons`, WP80).
  - **Scope widened** with existing or new pure tests: common `TenantScopedPaths`; core `DecideAcademyRequest` (WP90),
    `ChangedFields`, `AuditEntry`, `PatchBody`; game `EventLedger`, `MatchEventDecoder`, `RosterEventDecoder`; athlete
    `ApplyRosterEvent` + `RosterChange`/`RosterTopic` (new `ApplyRosterEventRulesTest`), `ReplicaRetention`/
    `ParkedPosition` (WP82, new `ReplicaRetentionRulesTest` as in game), `CoreEventDecoder`, `AcceptLanguage`,
    `PatchBody`, `RosterSource`.
  - **Survivors killed**: KafkaEventBroker (metrics bound/removed, interrupt, close without producer, the real producer
    factory), RosterEventAppender (a person alone brings its player), PatchBody bounds/values/messages (core and
    athlete), decoders' reason cut, DecideAcademyRequest.list. Redundant branches whose mutants were equivalent were
    removed rather than listed (listed in mutation.md: PatchBody `reject` return, `isTextual` before the e-mail
    pattern, athlete non-object check, decoders' `Math.min` and `requireNonNull`, `TenantScopedPaths` blank filter).
  - **Bug fix (one commit, 7099b4b)**: athlete `AcceptLanguage` threw `ArrayIndexOutOfBoundsException` (a 500) for an
    entry of parameters only (`"es,;"`: `";".split(";")` is empty); now split with limit -1.
  - **Baselines** = score rounded down to a whole percent (decision 56): common 99, core 99, game 99, athlete 100.
  - **Dart mutation tool** `apps/web/tool/mutation/` (plain Dart, no Node): `mutation.dart` (lexer skipping comments and
    strings; negate condition, swap comparison, remove statement, boundary ±1, boolean flip; regions by top-level
    declaration; manifest with equivalents by file/operator/line/replacement[/column/occurrence]; verdicts incl. "not
    viable" for compile errors; score), `run.dart` (per-worker copies of apps/web in the system temp, unmutated run
    first, timeout = factor × that run ≥ 60 s, `flutter test --no-pub`, report `build/mutation/report.json`, exit 1
    below the baseline), `manifest.json` (14 rule files, 12 equivalents, baseline 100); 20 unit tests in
    `test/mutation/mutation_test.dart`. `just web-mutation [--workers n] [--target f] [--list]`; `mutation.yml` gains
    the `web` job (artifact `web-mutation-report`).
  - **Web tests for the survivors** (tests only, no `lib/` change): `capabilities_matrix_test` (13 personas × 40
    affordances, equality), `event_ordering_test`, `backoff_test`, `sync_status_test`, `projector_rules_test`, more
    cases in `game_clock_test`, `team_figures_test`, `match_store_test`, `scoring_rights_test`.
- Verified (2026-11-07, fresh):
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`: BUILD SUCCESS in 6:05 min — common 274, contracts 279,
    core 992, game 466, athlete 905, e2e 31 (25 skipped without a stack), 0 failures/errors; ArchUnit, SpotBugs and
    JaCoCo gates green. (Run after the last backend code change; only a pom comment changed afterwards.)
  - `just mutation` (281 s): common-quarkus 210/211 (99.5 %, 25 s; was 172/173), core-service 777/778 (99.9 %, 103 s;
    was 622/629), game-service 548/550 (99.6 %, 78 s; was 469/471), athlete-service 687/687 (100 %, 75 s; was
    495/495); every module at or above its new threshold. Survivors left are the listed equivalents only
    (CoreRosterClient.zoneOf, Eligibility.reasons, ProjectionRun.apply, EventVisibility.visible).
  - `just web-mutation`: first run 280/442 (63 %, 30 not viable, 478 s, 4 workers); final 430/430 (100 %; 428 killed,
    2 timed out), 30 not viable, 12 equivalent, 617 s with 3 workers (target < 30 min met). Temp copies deleted.
  - `flutter analyze` no issues; `just web-format-check` 0 changed (368 files); `just web-test` 1069 passed (81 s).
- Decisions/ADRs: no ADR (decision 56 already covers it). Thresholds are the floor of the score, not a multiple of 5
  (documented in mutation.md § Changing the baseline). An equivalent mutant caused by redundant code is fixed by
  removing the redundancy (a refactor, behaviour unchanged) instead of listing it; in `apps/web/lib` such mutants are
  listed in the manifest instead (no `lib/` edits outside bug fixes). The web baseline is 100 like athlete: any new
  survivor in the listed rule files fails the monthly run.
- Open points / follow-ups:
  - The decoders now fail with `NullPointerException` (message names the resource) instead of
    `IllegalStateException` when the contracts jar is missing at startup.
  - Equivalent mutants in `apps/web/lib` could be removed by small refactors (`backoff.dart` `1 << min(attempt, 20)`,
    `game_clock.dart` clamp, projector's dead initial values) — not done, `lib/` was out of scope except bug fixes.
  - Not yet mutated: athlete `HealthAccess`/`TrainingAccess`/`PlanAccess` (access rules, tested only through
    `@QuarkusTest`), core `RolloverSeason`, `EligibilityEngine`, `ManageTenantAdmins`; the web roster/training
    providers. Candidates for the next round (pure unit tests with mocks, as done for `ApplyRosterEvent`).
  - `ReplicaRetention` is a copy in game and athlete (and now so is its rules test).
