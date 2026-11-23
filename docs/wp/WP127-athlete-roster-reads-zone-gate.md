# WP127 — Athlete: roster reads per request, tenant zone from the context, the 90 % domain gate, one test group

Model: Opus · high. Wave 1 (2026-11-23, ninth round): runs alongside WP126 (game), WP128 (core), WP129 (web). You own
`services/athlete-service/**` including its `pom.xml`; nobody else touches it. You do not touch `libs/**`, the other
services or the root `pom.xml`. Depends on: ADR-0037, WP98. Skills: work-package, quarkus-hexagonal-service,
tenant-isolation-testing, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp127-athlete-roster-reads-zone-gate`, branch `wp127-athlete-roster-reads-zone-gate`.

Decision 104 of 2026-11-23: everything confirmed in athlete-service is fixed. ADR-0059 is reserved for you if a
decision is needed.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `athlete-service.md`
(ATH-01..19), verification `verify-game-athlete.md`; X-03 in `cross-cutting.md`, verification
`verify-cross-cutting-libs.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Roster reads (ATH-01)**: on the replica path the roster is re-read per request with no cache (160 statements for
   a parent's plan list). A request-scoped memo with a fallback outside requests, or a `teamsOf(players)` query. Do
   **not** use `playerTeamIds` for parents: it hides teams whose season ended.
2. **Authz resolver (ATH-04)**: two season queries on every request; game has a `seasonEnds` map. Keep the rule itself
   as it is: WP134 moves it to the library.
3. **Tenant zone (ATH-03, with its bug)**: take the zone from `AuthzContext.timezone()`, drop the read of
   `tenant_registry` per call and the "older core" fallback (the contract requires `timezone`); keep a last-resort
   default for a zone the JVM does not know; the API tests must exercise the real branch.
4. **Domain gate (X-03)**: the pom has only the parent's 80 % rule: add the >= 90 % `domain` rule as game has it, with
   the tests it needs. Say in the handover that `docs/conformance.md:163` was wrong until now.
5. **Test groups (ATH-07)**: the 17 Postgres-only test classes join the main group, as game did.
6. **Locale (from CORE-09)**: `PlanJpaRepository` lower-cases without a fixed locale: failing test, fix.
7. **The rest**: every other ATH finding of your scope, and ATH-19 (the service README).

Not yours: ATH-02 and ATH-05 (WP130), ATH-06, ATH-08, ATH-09, ATH-13, ATH-17 (WP137), ATH-15 (ADR-0037 keeps the REST
client as the fallback: leave).

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] the jacoco check fails when a `domain` class drops below 90 % (show it once, red)
- [ ] `just mutation athlete-service` at or above the baseline (record the score)
- [ ] `just isolation-check` and `just db-role-check` run by hand in the worktree (results in the handover)
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
- **Built**
  - **Roster reads (ATH-01)**: the produced `RosterPort` (`RosterSourceProducer`) is wrapped in `RequestMemoRosterPort`:
    each `teamRoster` answer (roster or "not found") is kept per tenant and team in a `@RequestScoped` map for the rest
    of the request, on both sources; outside a request context (nightly job, consumer) every call reads the source; a
    503 is not kept. New `RosterPort.teamsOf(tenant, players, candidates)`: the replica answers with one query that
    follows its roster rules (open, valid assignments of complete players, known team, ACTIVE tenant); the default
    (REST) fans out over the cached rosters. `ManageAssignments.forPlayers` (the parent's 160-statement case) and
    `PlanAccess.isStaffOfPlayer` use it; `playerTeamIds` is not used (it hides ended seasons). The replica's
    `teamRoster` folds the tenant check into the team query (4 -> 3 statements). Tests: `RequestMemoRosterPortTest`
    (now in PIT scope), `RequestMemoWiringTest`, `RosterPortContract.teamsOfAreTheCandidatesWithOneOfThePlayersOnTheirRoster`
    (both sources), `ReplicaRosterRulesTest.teamsOfFollowsTheRostersRules`.
  - **Authz resolver (ATH-04)**: `ReplicaMembershipReads.seasonEnds(teams)` replaces `seasonNotEnded` + `seasonEnded`;
    the resolver partitions in Java as game does. Rule unchanged (`ReplicaAuthzRulesTest`, `ReplicaMembershipContractTest`).
  - **Tenant zone (ATH-03, a bug)**: `TenantClock.zoneOf(AuthzContext)` / `today(AuthzContext)` read the caller's zone
    without a query; `zoneOf(TenantId)` (registry) is for the nightly job only; `hoops.athlete.default-timezone` is the
    last resort for a zone the JVM does not know. `registerIfAbsent` and the "older core" branch are gone; `TenantZones`
    registers the zone requests use, and the upsert writes nothing when the zone is unchanged. Materialisation after a
    schedule change uses the caller's zone. `ApiSupport.member(...)` contexts carry `Europe/Madrid`, so the API suite
    takes the real branch (`@TenantUser` without `timezone` takes the last resort). Red first:
    `SessionApiTest.calendarDatesFollowTheZoneOfTheCallersContext` (a stale registry zone won),
    `RegistryTenantClockTest`, `TenantRegistryRepositoryTest` (every create rewrote the row).
  - **Domain gate (X-03)**: the pom appends game's PACKAGE rule (>= 90 % lines on `com.hoopsacademy.athlete.domain*`).
    Domain coverage is 100 % today. Shown red once with an untested 80-method probe class in `domain` (not committed):
    `Rule violated for package com.hoopsacademy.athlete.domain: lines covered ratio is 0.86, but expected minimum is
    0.90`, BUILD FAILURE; before the rule the same probe passed. **`docs/conformance.md:163` ("JaCoCo gates (>= 80 %,
    domain >= 90 %) met") was wrong for athlete until now**: nothing checked its domain.
  - **Test groups (ATH-07)**: the 17 Postgres-only `@QuarkusTest` classes also list `CoreMockResource` (game's
    precedent): Quarkus boots per module run 4 -> 3, module time 5:23 -> 3:47 min with the same 1003 tests.
  - **Locale (CORE-09)**: `LikePattern.contains` (root locale, escaped) serves the plan and exercise searches. Red first:
    `TrainingPlanApiTest.theSearchDoesNotDependOnTheJvmsDefaultLocale` (Turkish default locale).
  - **The rest**: ATH-10 `PagedQuery` for five paged searches; ATH-11 one query for the stored attendance rows,
    `SessionRepository.insertAll` without per-row lookups; ATH-12 dead methods removed, `bandsAreOrdered` moved into
    `NormSeedTest`; ATH-16 `CoreStubs.reset()` clears common's client cache (27 classes lose the adapter injection and
    the clear); ATH-18 `V11__plan_completion_player_index.sql` (red first: `ListingIndexSchemaTest`); ATH-19 module
    README, pom description, `RosterPort` javadoc, properties comment. Model diagrams regenerated (`just diagrams`).
  - Found on the way: `ScheduleApiTest.changingTheWeekdayMovesUntouchedSessionsButKeepsEditedOnes` failed on Mondays
    after 17:00 Madrid (today's session had started, so it was not moved); its weekdays are now relative to today.
- **Verified** (2026-11-23, on the last code commit `75de4ea5`)
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`: BUILD SUCCESS, 14:21 min, all coverage checks met.
    Tests: contracts 346, common-quarkus 403, core 1225, game 541, athlete 1023 (was 1003), e2e 38 (32 skipped);
    0 failures, 0 errors. athlete lines 97.7 %, domain 100 % (the new 90 % rule passes).
  - `just mutation athlete-service`: 671/671 killed (100 %, baseline 100), 109 s.
  - `just isolation-check` (by hand in the worktree): 6 tests + 4 Go tests passed. `just db-role-check`: 13 tests + 2
    Go tests passed. (The commit hook's run during the first full build failed once: Keycloak's container did not
    come up under load; the hand runs after the build were green.)
  - `scripts/model-diagrams.sh --check`: pages up to date; strict Zensical docs build: no issues.
  - A first full run had two athlete failures: the Monday-evening `ScheduleApiTest` flake (fixed, above) and a
    broker publish timeout in `CoreRosterConsumerTest.setUp` under load (passed when re-run alone and in the fresh run).
- **Decisions/ADRs**: ADR-0059 (per-request roster answers, `teamsOf`, the context's tenant zone), indexed in
  `docs/adr/README.md`.
- **Open points / follow-ups** (for the docs pass at merge time)
  - `docs/conformance.md:163`: the athlete domain gate exists only since this WP.
  - `docs/quality/mutation.md`: athlete 671/671 (100 %) on 2026-11-23, scope plus `RequestMemoRosterPort`, fewer
    mutants because the dead domain methods went (recorded in the pom comment; the page is not edited here to avoid a
    merge clash).
  - A `@QuarkusTest` method runs in a request context, so the roster memo spans the whole test method (README testing
    notes); tests of the REST cache use `CoreRosterAdapter` directly.
  - The `@WithTestResource` meta-annotation (ATH-07/16 option) was not tried: unverified Quarkus support, two lines of
    gain per class.

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| ATH-01 | Done | Request memo of `teamRoster` on both sources; `RosterPort.teamsOf` (one replica query); tenant check folded into the team query |
| ATH-03 | Done | Zone from `AuthzContext`; registry for the jobs; last-resort default kept; no-op upsert; API tests on the real branch |
| ATH-04 | Done | One `seasonEnds` query, partitioned in Java |
| ATH-07 | Done | 17 classes join the main boot (4 -> 3 boots) |
| ATH-10 | Done | `PagedQuery` (absence, injury, session, test result, completion) and `LikePattern`; plan (select-only parameter), exercise (constant JPQL by design) and assignment search (own tested clause builder) keep their shape |
| ATH-11 | Done | Attendance: one read of the stored rows; materialised sessions persisted directly (`insertAll`) |
| ATH-12 | Done | `uuids`, `isValidOn`, `overlaps`, `clearCache` removed; `bandsAreOrdered` moved into `NormSeedTest` |
| ATH-14 | Skipped | Per the verification a deliberate symmetry with game (ADR-0037 WP82): marginal gain against a migration and the RLS meta tests' global-table list |
| ATH-16 | Done (partly) | Cache clear in `CoreStubs.reset()`; resource meta-annotation not done (unverified support) |
| ATH-18 | Done | `V11` index `(tenant_id, player_id, marked_at desc)` |
| ATH-19 | Done | README, pom description, `RosterPort` javadoc, properties comment |
| X-03 | Done | 90 % domain PACKAGE rule, shown red once |
| CORE-09 (athlete) | Done | Root-locale lower-casing in the plan search |
| ATH-02, ATH-05 | Skipped | WP130 |
| ATH-06, ATH-08, ATH-09, ATH-13, ATH-17 | Skipped | WP137 |
| ATH-15 | Skipped | ADR-0037 keeps the REST fallback |
