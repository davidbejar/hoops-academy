# Mutation testing (PIT)

Line coverage says a line ran; mutation testing says a test would notice if the line were wrong. PIT changes the
compiled code one small fault at a time (a `<` becomes `<=`, a condition is forced true, a return value becomes
`null`, …) and reruns the unit tests that cover it. A mutant that no test notices **survives** and points at a missing
assertion.

Decision of 2026-11-05 (WP37): PIT is **not** part of every build. It runs on demand and once a month on the pure rule
code of four modules; a baseline per module makes a later run fail when the score drops. Decision 56 of 2026-11-06
(WP88): rule code that only container tests reached is extracted into framework-free classes and added to the scope,
the baselines are the scores themselves (rounded down to a whole percent), and the web rule code gets the same
treatment with a Dart mutation tool ([Web rule code](#web-rule-code-dart-mutation-tool)).

## What runs where

| Module | Mutated classes (`pit.targetClasses`) | Tests PIT runs (`pit.targetTests`) | Mutants | Runtime¹ | Baseline |
|---|---|---|---|---|---|
| `common-quarkus` | `TenantId`, `TenantContext`, `AuthzContext`, `Problem`, `ProblemType`, `CoreRosterClient`, `RosterAuthzResolver`, `TenantHeaderPropagationFilter`, `ServiceTokenClientFilter`, `AuthzDenial`, `DenialKind`, `TokenFailureReason` (WP85) + `ExclusiveLocks`, `TenantScopedPaths`, `ProblemMapping` (WP88) + `UnsafeText`, `PageOffset` (WP84) | their plain unit tests | 313 | 25 s | 99 |
| `core-service` | `core.domain.*` + `LoginProvisioning`, `TemporaryPasswordGenerator`, `AuthzCache`, `AuditActorKind`, `AuditFilter`, `AuditAction`, the event classes `EventTopic`, `RosterPayloads`, `RosterEventAppender`, `EventEnvelopes`, `TenantEvents` (WP67), `KafkaEventBroker` (WP81) + `BackfillPlan`, `DecideAcademyRequest`, `ChangedFields`, `AuditEntry`, `PatchBody` (WP88) | `core.domain.*` tests + the tests of those classes | 778 | 103 s | 99 |
| `game-service` | `game.domain.*` + `EventAuthorization`, `StatVisibility`, the replica rules `ReplicaAuthzResolver`, `ReplicaRosterPort`, `ReplicaPlayer`, `ReplicaTenant`, `ReplicaPerson` (WP68), `ReplicaRetention`, `ParkedPosition` (WP82) + `EventAdmission`, `EventLedger`, `MatchEventDecoder`, `RosterEventDecoder` (WP88) | `game.domain.*` tests + the tests of those classes | 550 | 78 s | 99 |
| `athlete-service` | `athlete.domain.*` + the replica rules `ApplyRosterEvent`, `ReplicaRetention`, `ParkedPosition`, `RosterChange`, `RosterTopic` and the adapters' parsers `CoreEventDecoder`, `AcceptLanguage`, `PatchBody`, `RosterSource` (WP88) | `athlete.domain.*` tests + `ApplyRosterEventRulesTest`, `ReplicaRetentionRulesTest`, `CoreEventDecoderTest`, `AcceptLanguageTest`, `PatchBodyTest`, `RosterSourceTest` | 713 | 114 s² | 100 |

¹ Wall clock of `just mutation <module>` including compilation, on the development Mac (Apple M1 Pro, 10 cores, shared
with other work), `threads = 4`, measured in WP88 (2026-11-07). All four modules in turn (`just mutation`): 281 s.

Latest scores (2026-11-07, WP84): common-quarkus 312/313 (99.7 %; the scope grew by the SD-01/SD-02 rules and the
`ProblemMapping` additions), core-service 777/778 (99.9 %), game-service 548/550 (99.6 %), athlete-service 687/687
(100 %). WP88 (same day): common-quarkus 210/211, the other three as now. Before WP88 (same day, scopes of round 4 plus WP78–WP90): common 172/173,
core 622/629, game 469/471, athlete 495/495.
WP92 (2026-11-10): athlete-service 713/713 (100 %; the scope grew by the exercise catalogue: `Exercise`, `ExerciseId`,
`ItemContent` and the exercise reference of `PlanItem`).

² WP92, 2026-11-10, host shared with four other worktrees.

Settings (root `pom.xml` `pluginManagement`, PIT 1.30.1 + JUnit 5 plugin 1.2.3): `STRONGER` mutators (they stay far
below the ~10 min per module budget), HTML + XML reports in `<module>/target/pit-reports` without timestamps, never
bound to a lifecycle phase. Each module's `mutation` profile sets `pit.skip=false` and its baseline
(`pit.mutationThreshold`); the targets are module properties because the default build reads them too (below).

**Not mutated**: `@QuarkusTest` code paths (Quarkus boot + Postgres per mutant would take minutes each), adapters
except the pure parsers listed above, generated code (`libs/contracts`, Dart clients). The decisions of container code
are extracted into pure classes instead ([Extractions](#extractions-wp88)); what stays behind (transactions, advisory
locks, JAX-RS responses, repository calls) is covered by the RLS and integration suites. The Flutter app's rule code
runs through the Dart tool below; its widgets do not.

## Running it

```
just mutation                  # every configured module, one after the other
just mutation core-service     # one module (artifactId)
```

The recipe runs `./mvnw -Dmutation=<artifactId> -pl :<artifactId> -am test-compile
org.pitest:pitest-maven:mutationCoverage`. The `-Dmutation=<artifactId>` property activates only that module's
`mutation` profile, so the upstream modules `-am` builds are compiled but not mutated. `-Pmutation` activates the
profile in every module (e.g. `./mvnw -Pmutation test-compile org.pitest:pitest-maven:mutationCoverage` from the
root). PIT is CPU-heavy: run one module at a time on a shared machine.

The GitHub workflow `.github/workflows/mutation.yml` runs `just mutation <module>` for the four modules (matrix) on
`workflow_dispatch` and at 03:00 UTC on the 1st of each month, fails below a baseline and uploads each
`target/pit-reports` as the artifact `pit-reports-<module>`. It is not part of `ci.yml`.

**When to run**: before a release, and after changing domain or rule code (eligibility, roles, projections, norms,
plans…) — preferably before opening the PR, so new rules arrive with assertions that kill their mutants.

## Keeping container tests out

PIT runs every selected test once per mutant it covers, so one `@QuarkusTest` among them would boot Quarkus and Dev
Services thousands of times. The selection is therefore an explicit list of globs per module (`pit.targetTests`), and
`MutationScopeTest` in each module (default build, about a second) passes it to `MutationTestScope`
(`common-quarkus` test-jar), which fails when a matched test class — or its enclosing class or a superclass — uses
`io.quarkus.test.*` (any `@QuarkusTest`, `@QuarkusIntegrationTest`, `@QuarkusComponentTest`, test resources) or
`org.testcontainers.*`, when a glob matches no test (a typo would silently shrink the run) and when a glob carries
whitespace (PIT does not trim, so it would never match — keep each list on one line). A container test can only reach
PIT by breaking the default build.

To widen the scope: add the class glob to `pit.targetClasses`, its pure unit test to `pit.targetTests`, run
`just mutation <module>` and kill or document what survives.

## Extractions (WP88)

Decision logic of classes PIT cannot run (CDI beans with transactions, JAX-RS mappers, use cases) moved into
framework-free classes next to them; the container class now delegates, and ArchUnit stays green (domain classes have
no framework import, the application ones no CDI).

| Pure class (new) | Taken from | Rule |
|---|---|---|
| common `tenancy.ExclusiveLocks` | `TenantScope` | advisory key of a lock name (first 8 bytes of its SHA-256); the lock transaction's timeout in whole seconds, capped at `Integer.MAX_VALUE` |
| common `problem.ProblemMapping` | `ProblemExceptionMappers` | a lost `@Version` race found in the cause chain (self-causing chains end); violations ordered by field; ROLE vs FINE_GRAINED denial |
| core `application.events.BackfillPlan` | `BackfillRosterEvents` (WP81) | topic order, live aggregates without an event, the id each event is keyed by, chunks per transaction |
| core `domain.roster.EndedSeasons` | `PastSeasons` (WP80) | which of some seasons have ended on a day |
| game `application.EventAdmission` | `IngestEventBatch` | duplicate, cancelled match, authz matrix, season closed, device sequence taken — in that order |
| game `domain.SeasonClose` | `PastSeasons` (WP80) | a season closes at the start of the day after its last day in the academy's zone |

Classes that were already pure but outside the scope joined it with their unit tests: `TenantScopedPaths` (own test now),
core `DecideAcademyRequest` (WP90), `ChangedFields`, `AuditEntry`, `PatchBody`; game `EventLedger`, `MatchEventDecoder`,
`RosterEventDecoder`; athlete `ApplyRosterEvent`, `ReplicaRetention` (the WP82 rules, now also tested without a database
as in game), `CoreEventDecoder`, `AcceptLanguage`, `PatchBody`, `RosterSource`.

## Reading a report

Open `<module>/target/pit-reports/index.html`: one row per package and class with line coverage and mutation
coverage; the class page shows the source with each line coloured (green: every mutant killed, red: a mutant
survived or had no coverage) and the mutants listed under it. `mutations.xml` holds the same data for scripts
(status, class, method, line, mutator, killing test).

| Status | Meaning |
|---|---|
| `KILLED` | a test failed against the mutant — good |
| `TIMED_OUT` | the mutant looped forever (e.g. a retry loop that never exits); counts as detected |
| `SURVIVED` | every covering test passed: an assertion is missing, or the mutant is equivalent |
| `NO_COVERAGE` | no selected unit test executes the line |

Score = detected / all mutants; PIT reports it rounded down to a whole percent and compares it with
`mutationThreshold`. A survivor in rule code is a spec for a missing assertion: write the test that kills it (TDD
rhythm, the mutant is the failing case), preferably by strengthening an existing test. An equivalent mutant (no
observable behaviour change) is excluded with a reason or, when PIT cannot exclude it on its own, listed below.

## Before and after (2026-11-06, STRONGER)

| Module | Before | After | Domain packages only (before → after) |
|---|---|---|---|
| `common-quarkus` | 95.4 % (104/109) | 99.1 % (108/109) | — (no domain package) |
| `core-service` | 92.9 % (460/495) | 99.6 % (492/494) | 93.3 % → 99.6 % |
| `game-service` | 87.3 % (350/401) | 99.5 % (399/401) | 86.8 % → 99.5 % |
| `athlete-service` | 76.7 % (330/430) | 100 % (430/430) | 76.7 % → 100 % |

Surviving and uncovered mutants of the first run, per class:

- **common-quarkus** (5): `CoreRosterClient` 4 (cache hit of a membership, `clearCache` of members and players, the
  blank time-zone check), `ServiceTokenClientFilter` 1 (refresh interval before expiry).
- **core-service** (35): `Person` 4, `PlayerStatus` 5, `TemporaryPassword` 3, `AgeCategory` 2, `Season` 2, `Require` 2,
  `AuditFilter` 2, `TemporaryPasswordGenerator` 2, and 1 each in `ApprovalPayload`, `ApprovalRequest`, `Eligibility`,
  `EligibilityCase`, `ImageFormat`, `ImageFormat$3` (WEBP), `LogoImage`, `GuardianLinkId`, `JerseyNumber`,
  `SeasonChanges`, `TeamPlayer`, `TenantSettings`, `AuthzCache`.
- **game-service** (51): `Match` 15, `MatchRules` 8, `JerseyNumber` 3, `MatchEvent$Shot` 3, `MatchEvent$OpponentScore` 2,
  `MatchId` 2, `ProjectionRun` 2, and 1 each in `EventAuthorization`, `EventVisibility`, `SeasonId`, `TeamId`,
  `SeasonLine`, `StatLine`, `VoidResolution` and the `type()` of `MatchEvent$Assist`, `$Block`, `$Foul`, `$Rebound`,
  `$Steal`, `$SubIn`, `$SubOut`, `$Turnover`, `$Void`.
- **athlete-service** (100): `PhysicalTestType` 15, `PhysicalTestResult` 14 (no unit test at all), `TrainingPlan` 8,
  `BandResolver` 7, `BodyMeasurement` 7, `Injury` 7, `PhysicalTestNorm` 7, `PlanItem` 6, `Actor` 3, `Attendance` 2,
  `Duration15to480` 2, `PlanProgress` 2, `TestResultId` 2, and 1 each in `AttendanceSheet`, `PlannedAbsence`,
  `SessionMaterialiser`, `TrainingSchedule`, `TrainingRuleViolation`, `TrainingStateConflict` and ten identifier
  `toString()`s.

The typical gaps were inclusive range ends never tested from the inside (age 3/99, season year 2000/2100, late
threshold 0, period count 1/8, minutes late 1/480, title 120 characters …), null inputs only tested as blank,
cached answers whose value was never asserted, ordering tie-breaks and accessors only read by adapters. No mutant
exposed a production defect: **no production code was changed** in WP37.

## Excluded and accepted equivalent mutants

| Where | Mutant | Why it is equivalent | Handling |
|---|---|---|---|
| core `TemporaryPassword.hashCode` | return 0 | `hashCode` only has to agree with `equals`; a constant does | `pit.excludedMethods=hashCode` in core's `mutation` profile |
| core `Eligibility.reasons()` (default method) | `instanceof Ineligible` forced false | `Ineligible` is a record whose component accessor `reasons()` overrides the default, so that branch is unreachable | listed; excluding the method would also drop its killed mutant (PIT cannot exclude a single mutant) |
| common `CoreRosterClient.zoneOf` | blank check forced false | `ZoneId.of(" ")` throws `DateTimeException`, which the method maps to the same empty result (only a log line differs) | listed; excluding `zoneOf` would hide its 4 killed mutants |
| game `EventVisibility.visible` | `seesAll()` fast path forced false | a viewer who sees all players sees every player event through the slow path as well | listed; the method has 11 detected mutants |
| game `ProjectionRun.apply` | `lastClock` updated while no period runs | `lastClock` is only read by `finish` while a period runs, and every period start sets it first | listed; the method has 14 killed mutants |

Not equivalent: core `ApprovalPayload.empty()` (no coverage) was not called anywhere — dead code, deleted in WP38.

Removed instead of listed (WP88): a branch whose mutant cannot change behaviour is redundant code, so it went:
`TenantScopedPaths` (a blank exempt path filter: "" is never tenant scoped), core and athlete `PatchBody` (`reject`
returned the empty Optional the caller returns anyway; an `isTextual` check before the e-mail pattern; athlete: a
non-object check, a body without members is an empty patch either way), the decoders' `length <= max ? s : cut`
(`Math.min`), athlete `CoreEventDecoder.text` (`Optional.ofNullable`), the "resource missing" guards of the three event
decoders (`Objects.requireNonNull`, the startup fails either way). Since then each module's survivors are exactly the
rows above (core 1, game 2, common 1, athlete 0; the uncovered `KafkaEventBroker` producer factory is now run by a unit test).

## Web rule code (Dart mutation tool)

Dart has no mature mutation tool, so WP88 wrote a small one (plain Dart, no Node): `apps/web/tool/mutation/`.

```
just web-mutation                                  # every file of the manifest, 3 workers
just web-mutation --workers 2                      # fewer parallel flutter test runs
just web-mutation --target lib/core/session/capabilities.dart
just web-mutation --list                           # print the mutants (line:column), run nothing
```

- **Manifest** `tool/mutation/manifest.json`: per rule file the tests that must notice its mutants and, optionally,
  the top-level declarations to mutate (`only`, e.g. the two counter helpers of `usage_trend.dart`); the accepted
  equivalent mutants (file, operator, trimmed source line, replacement, column when the line holds the mutant twice,
  reason); `baseline` (percent) and `timeoutFactor`.
- **Operators** (`mutation.dart`, a small lexer that skips comments and strings): *negate condition* (`if (c)` /
  `while (c)` to `!(c)`, `==` and `!=` swapped, a prefix `!` removed), *swap comparison* (`<` and `<=`, `>` and `>=`,
  `&&` and `||`; only spaced binary operators, so generics never), *remove statement* (an expression statement of a
  code block becomes `;`), *boundary* (an integer literal one up and one down), *boolean flip*.
- **Run** (`run.dart`): the manifest's files are copied into one private copy of `apps/web` per worker (system temp,
  deleted afterwards); each file's tests first run unmutated (they must pass; the duration times `timeoutFactor`, at
  least 60 s, is the timeout of one mutant); then each mutant is written into a copy and `flutter test --no-pub` runs
  that file's tests. A failing run **kills** the mutant, a passing one lets it **survive**, a run over the timeout
  **times out** (detected, as in PIT), a mutant that does not compile (typically `!= null` swapped where null safety
  then refuses the code) is **not viable** and left out of the score. Score = (killed + timed out) / viable, rounded
  down; below `baseline` the run exits 1. Report: `apps/web/build/mutation/report.json` (counts per file, survivors with
  line and column, the equivalents with their reason).
- **CI**: the `web` job of `mutation.yml` (same triggers as PIT) runs `just web-mutation --workers 2` and keeps the
  report as the artifact `web-mutation-report`.
- The tool's own rules are unit tested in `apps/web/test/mutation/mutation_test.dart` (part of `just web-test`).

**Files and baseline** (manifest of 2026-11-07, WP88):

| Area | Files (`lib/…`) | Tests the mutants run against |
|---|---|---|
| offline sync / outbox merge | `features/match/domain/projector/merge.dart`, `features/match/application/sync/backoff.dart`, `…/sync/sync_status.dart` | `sync_worker_test`, `backoff_test`, `sync_status_test` |
| cache scoping | `features/match/data/local/match_store.dart` | `match_store_test`, `match_store_scope_test`, `match_store_wipe_test` |
| match clock and score | `features/match/application/game_clock.dart`, `…/projector/event_ordering.dart`, `…/projector/projector.dart`, `…/projector/team_figures.dart`, `features/match/domain/scoring_rights.dart`, `…/feed_visibility.dart` | `game_clock_test`, `event_ordering_test`, `projector_vectors_test`, `projector_rules_test`, `team_figures_test`, `scoring_rights_test`, `feed_visibility_test` |
| eligibility views / rights | `core/session/capabilities.dart` | `capabilities_test`, `capabilities_matrix_test` |
| usage counters | `features/platform/presentation/usage_trend.dart` (`counterIn`, `counterKeys` only) | `platform_test` |
| locale negotiation | `core/l10n/locale_controller.dart`, `core/http/interceptors.dart` (`_LocaleInterceptor`, `_TenantInterceptor` only) | `locale_test`, `interceptors_test` |

First run: 280 of 442 viable mutants detected (63 %; 30 not viable), 478 s with 4 workers — the Capabilities matrix,
the game-order tie-breaks and the Java UUID order, Backoff, SyncStatus and the game clock had almost no assertions.
After the new tests (`capabilities_matrix_test`, `event_ordering_test`, `backoff_test`, `sync_status_test`,
`projector_rules_test`, more cases in `game_clock_test`, `team_figures_test`, `match_store_test`,
`scoring_rights_test`; no `lib/` change was needed) and 12 accepted equivalents: **430/430 detected (100 %; 428
killed, 2 timed out), 30 not viable, 617 s with 3 workers** (`just web-mutation`, development Mac shared with other
work). **Baseline 100.**

Accepted equivalents (`equivalent` in the manifest, with the full reasons): `backoff.dart` `attempt >= 20` as `> 20`
or `>= 21` (at attempt 20 both branches give `1 << 20`); `game_clock.dart` `seconds < 0` as `<= 0` or `< 1` (0 maps to
0 either way) and the `_remaining = 0` after the last tick (it is exactly 0 there); `event_ordering.dart` `radix: 16`
as 17 (the same for hex digits); `projector.dart` the fold's `?? 0` as `-1`, the `_enteredAt` initial value, `max(0, …)`
as `max(-1, …)` and the `_enteredAt = clock` after an accrual (the Dart twins of the Java `ProjectionRun` case: the
value is always set before it is read, and game order never lets the clock go up).

## Changing the baseline

Each threshold is the achieved score rounded down to a whole percent (decision 56, WP88; until then a multiple of 5).
Raise it when a module's score settles higher; lower it only with a reason recorded here (for example a new equivalent
mutant PIT cannot exclude). A scheduled run
that fails below the baseline means a recent change added rule code without the assertions that pin it: open the
module's report, kill the survivors, keep the threshold.
