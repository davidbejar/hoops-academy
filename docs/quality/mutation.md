# Mutation testing (PIT)

Line coverage says a line ran; mutation testing says a test would notice if the line were wrong. PIT changes the
compiled code one small fault at a time (a `<` becomes `<=`, a condition is forced true, a return value becomes
`null`, …) and reruns the unit tests that cover it. A mutant that no test notices **survives** and points at a missing
assertion.

Decision of 2026-11-05 (WP37): PIT is **not** part of every build. It runs on demand and once a month on the pure rule
code of four modules; a baseline per module makes a later run fail when the score drops.

## What runs where

| Module | Mutated classes (`pit.targetClasses`) | Tests PIT runs (`pit.targetTests`) | Mutants | Runtime¹ | Baseline |
|---|---|---|---|---|---|
| `common-quarkus` | `TenantId`, `TenantContext`, `AuthzContext`, `Problem`, `ProblemType`, `CoreRosterClient`, `RosterAuthzResolver`, `TenantHeaderPropagationFilter`, `ServiceTokenClientFilter` | their plain unit tests | 109 | 11 s | 95 |
| `core-service` | `core.domain.*` + `LoginProvisioning`, `TemporaryPasswordGenerator`, `AuthzCache`, `AuditActorKind`, `AuditFilter`, `AuditAction` + the event classes `EventTopic`, `RosterPayloads`, `RosterEventAppender`, `EventEnvelopes`, `TenantEvents` (WP67) | `core.domain.*` tests + the tests of those classes (`EventTopicTest`, `RosterEventAppenderTest`, `EventEnvelopesTest` for the event ones) | 560 | 68 s² | 95 |
| `game-service` | `game.domain.*` + `EventAuthorization`, `StatVisibility` + the replica rules `ReplicaAuthzResolver`, `ReplicaRosterPort`, `ReplicaPlayer`, `ReplicaTenant`, `ReplicaPerson` (WP68) | `game.domain.*` tests + `EventAuthorizationTest`, `StatVisibilityTest`, `ReplicaAuthzResolverTest`, `ReplicaRosterPortTest` | 440 | 42 s² | 95 |
| `athlete-service` | `athlete.domain.*` (the WP69 replica code is in `application`/adapters, outside the scope) | `athlete.domain.*` tests | 471 | 34 s² | 100 |

¹ Wall clock of `just mutation <module>` including compilation, on the development Mac (Apple M1 Pro, 10 cores, shared
with other work), `threads = 4`. All four modules in turn: about 2.5 minutes.
² Runtime measured in WP37 with the mutant counts of then (core 494, game 401, athlete 430); not re-measured.

Latest scores (2026-11-06, round 4): core-service 558/560 (99.6 %, WP67), game-service 438/440 (99.5 %, WP68),
athlete-service 471/471 (100 %, WP61, WP62 and WP69), common-quarkus 108/109 (99.1 %, WP37; not re-run since).

Settings (root `pom.xml` `pluginManagement`, PIT 1.30.1 + JUnit 5 plugin 1.2.3): `STRONGER` mutators (they stay far
below the ~10 min per module budget), HTML + XML reports in `<module>/target/pit-reports` without timestamps, never
bound to a lifecycle phase. Each module's `mutation` profile sets `pit.skip=false` and its baseline
(`pit.mutationThreshold`); the targets are module properties because the default build reads them too (below).

**Not mutated**: `@QuarkusTest` code paths (Quarkus boot + Postgres per mutant would take minutes each), adapters,
generated code (`libs/contracts`, Dart clients), and the Flutter app — Dart has no mature mutation tool. Rule code
that only container tests reach (`TenantScope`, `ProblemExceptionMappers`, the use cases) is covered by the RLS and
integration suites instead.

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

## Changing the baseline

Each threshold is the achieved score rounded down to a multiple of 5. Raise it when a module's score settles higher;
lower it only with a reason recorded here (for example a new equivalent mutant PIT cannot exclude). A scheduled run
that fails below the baseline means a recent change added rule code without the assertions that pin it: open the
module's report, kill the survivors, keep the threshold.
