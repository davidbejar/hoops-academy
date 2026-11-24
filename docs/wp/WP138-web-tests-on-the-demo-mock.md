# WP138 — Web: the tests run against the demo mock; the separate test fakes go

Model: Opus · high. Wave 4 (2026-11-23, ninth round): starts after wave 3 is merged; runs alongside WP137 (library,
services, build). You own `apps/web/**` except `apps/web/packages/**` and `apps/web/test/fixtures/vectors/**` with its
test (WP137 owns those); nobody else touches the app. Depends on: WP129, WP135; ADR-0030. Skills: work-package,
flutter-feature, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp138-web-tests-on-the-demo-mock`, branch `wp138-web-tests-on-the-demo-mock`.

Decision 108 of 2026-11-23: the widget tests run against the demo mock, seeded per test; the separate test fakes are
deleted feature by feature. ADR-0070 is reserved for you (write it; it amends ADR-0030).

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `apps-web.md`
(WEB-02), verification `verify-apps-web.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Seeding**: the demo mock gets a small seeding API for tests (empty tenant, one of each, failure injection for the
   error paths the fakes covered) without demo data leaking into tests or test hooks into the release build
   (`build_web.sh` already refuses mock mode for releases: keep that true and add a test or check for it).
2. **Migrate feature by feature**: one commit per feature: tests move to the mock, the feature's fake is deleted. A
   test that only a fake could express (a server error the mock cannot produce) gets failure injection, not a second
   fake. A difference between mock and fake is a finding: decide which was right against the contract and list it in
   the handover.
3. **Stop when it stops paying**: if a feature's fake cannot go without making its tests worse, keep it, say why, and
   state how many of the 3,580 fake lines are left.

Not yours: generated clients; goldens change only if the seeded data must differ (list them).

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean
- [ ] test count before and after (no test silently lost: explain every removed test)
- [ ] lines of test fakes before and after
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
- **Built** (all under `apps/web`; ADR-0070)
  - **Seeding (scope 1).** `MockApiAdapter` takes `demo` (false: both academies and the platform start empty;
    `MockAcademy.empty` makes the core, athlete and game mocks skip their seed), `tenantAId` (the test academy's id)
    and `latency` (zero in tests). The mocks expose the collections the tests seed as `@visibleForTesting` (core:
    `auditEvents`; platform: `tenants`, `admins`, `auditEvents`, `academyRequests`, `usageOf`, `historyOf`,
    `logins`; the adapter: `academy(id)`, `platform`). `apiAdapterProvider` (`core/http/dio_provider.dart`) is the
    one seam the app's Dio sends through. `test/support/mock_backend.dart`: `MockBackend`, the empty mock with
    failure injection (`fail` status/code/once, `hang` released on demand, `networkDown`, `heal`), a request log
    (`requestsTo`, `lastQuery`, `lastBody`) and the mock's answers (`lastAnswer`); `coreJson` turns generated models
    into seeds. The `Harness` installs a `MockBackend` (roles, super admin and academy of the test user) behind every
    repository it does not fake. Seed helpers: `audit_seed.dart`, `platform_seed.dart` (the former fixture builders).
  - **Release (scope 1).** `tool/verify_no_mock.dart` (run by `build_web.sh` after the build) fails when
    `main.dart.js` or a deferred part holds a string only the mock API has; `verify_no_mock_test.dart`. Checked on
    real builds: the release build passes, a `HOOPS_MOCK_API=true` build fails on both markers.
  - **Migrated (scope 2), one commit each, fake deleted:** activity log (`fake_audit.dart`, 3 test files), academy
    requests (`fake_academy_requests.dart`, 5 files), platform console (`fake_platform.dart`, 11 files incl.
    `platform_test.dart`, users, goldens, a provider unit test). Failures the mock can produce are produced by it
    (taken slug, request decided meanwhile, invitation accepted meanwhile, last administrator removed meanwhile).
  - **Mock and fake differed (decided against `core.yaml`, red test first, the fake was right each time, mock fixed):**
    1. the academy trail ignored `action` / `from` / `to` (`listAuditEvents`): now filtered, 400 when `from` ≥ `to`;
    2. an e-mail that already signs in still got a temporary password (`createTenant`, `addTenantAdmin`): now none,
       invitation ACCEPTED; 3. the last administrator could be removed: now 409 `LAST_ADMIN` (`removeTenantAdmin`).
- **Verified** (fresh, 2026-11-24): `flutter analyze` no issues; `just web-format-check` 527 files, 0 changed;
  `just web-test` **1939 passed, 0 failed, 0 skipped** (baseline at the start 1921 passed). +18 tests, none removed: 1 trail filter, 3
  administrator rules, 7 `mock_backend_test`, 7 `verify_no_mock_test`; every migrated file has the same test count as
  before (audit 30, requests 63, platform files unchanged; whole suite 1939 after each feature commit, run on a copy
  of the tree). Goldens re-recorded: the three `temporary_password_*` only (the dialog shows the mock's password,
  which wraps on one line fewer); every other golden of the migrated screens passes as recorded.
  - Fake lines (the seven files of the verification): 3,565 at the start (3,580 in the audit, `fake_finance.dart`
    has shrunk since) → **2,937** left (`fake_repos` 825, `fake_athlete` 1,529, `fake_game` 326, `fake_finance`
    257). Added: `mock_backend.dart` 237, `audit_seed.dart` 69, `platform_seed.dart` 162 (about 100 of them the
    moved builders), `problems.dart` 19.
- **Decisions/ADRs**: ADR-0070 (amends ADR-0030), appended to `docs/adr/README.md`.
- **Open points / not done**
  - **Core, athlete, game, finance keep their fakes** (2,937 lines): not done for time, in this order next. Core
    first: the athlete and game mocks take authz (staff rows, guardian links, the own player) and rosters from the
    core mock, so they need a `seedMembership` that makes the core mock's authz match the test membership
    (`staffTeamIds`, `linkedPlayerIds`, `ownPlayerId`) before their tests can move; then roster/admin screens
    (`fake_repos.dart`, 47 files), game (12), athlete (20). Finance: `FakeFinanceRepository` already wraps the real
    repository over the mock (no second imitation of the rules), but over the *demo* seed; moving it means explicit
    finance seeds in an empty academy.
  - `MockAuthService` is compiled into the release bundle (unreachable: the guard refuses mock mode); the new check
    covers the mock API only. Making it drop out needs a const guard that the tests' `appConfigProvider` override
    would no longer reach (owner's call).
  - The platform mock answers 409 `ALREADY_ADMIN` (not in the contract) for an e-mail that is already an
    administrator; no test needs it, left as is.
  - FOLLOW-UPS l.519 (mock 409 vs service 404 for the season balance) belongs to the finance move, still open.

### Part 2 (2026-11-24)
- **Built**
  - **(4) `MockAuthService` out of the release build.** `authServiceProvider` picks it only when `mockBuild` (the
    `HOOPS_MOCK_API` define as a compile-time constant, `core/config/app_config.dart`) and the mock API is on; the
    Keycloak branch is unchanged. `verify_no_mock.dart` gains its token as a third marker (red first on a real release
    build, which held it). Checked on real builds: the release passes, a `HOOPS_MOCK_API=true` build fails on all three
    markers. Tests and the landing capture that run the app in mock mode without the define provide
    `MockAuthService` themselves (`mock_mode_test`, `live_match_golden_test`, `landing_screens_capture`).
  - **(1) Core seeding.** The core mock exposes its data (`@visibleForTesting`: profile, settings, seasons,
    categories, teams, players, members, guardian links, approvals, cases, staff, logo, `requestedLogins`) and takes
    the user's person (`selfId`, also in the adapter and the athlete, game and finance mocks: the tests use the
    membership's `person-me`). `test/support/core_seed.dart` seeds it from the fixtures' models, keeping it coherent (a
    roster is the players' assignments). `seedMembership` makes the mock's authz match the test membership (staff rows
    on `staffTeamIds` / `historicStaffTeamIds`, guardian links to `linkedPlayerIds`, the own player's person); the
    `Harness` runs it for the first membership. `FakeCore` now carries the migrated data and seeds it (plus the teams
    and players of its remaining fakes, so authz and case decisions work on one roster); `pumpAs(prepare:)` injects
    faults before the first frame.
  - **Migrated, one commit each, fake deleted:** academy profile (`FakeAcademyRepository`), seasons and age categories
    (`FakeSeasonsRepository`, `FakeAgeCategoriesRepository`), approval requests and eligibility cases
    (`FakeApprovalsRepository`, `FakeCasesRepository`), with their parts of `notifiers_test`.
  - **Mock and fake differed (decided against `core.yaml`, red test first, the fake was right, mock fixed):**
    4. a player created with a new e-mail (admin) and an approved request that asked for a login got no temporary
       password (`createPlayer`, `approveApprovalRequest`): now answered once, none for an e-mail that already signs
       in; 5. deciding a decided request answered 409 without `NOT_PENDING`; 6. the requesting coach could not cancel
       the own request (403; `cancelApprovalRequest`: the requester).
  - **Found, not changed (owner's call):** the rollover wizard calls `rolloverSeason` with the season it was opened on
    as both the path's *target* and `fromSeasonId`. `core.yaml` and core-service (`RolloverSeason`) treat the path as
    the target and refuse the same season (`ROLLOVER_SAME_SEASON`), so the wizard cannot work against the real
    service. The fake and the mock both accepted it (the mock creates a "next" season and ignores the clone flags).
    Fixing it changes the wizard (it must offer a target season); the mock was left matching the app so the tests
    keep describing today's screen.
- **Verified** (fresh, 2026-11-24): `flutter analyze` no issues; `just web-format-check` clean; `just web-test`
  **1944 passed, 0 failed** (part 2 started at 1939). +5 tests, none removed: 1 marker test, 3 player-login / NOT_PENDING, 1
  coach cancel. Every migrated file keeps its test count (academy 15, seasons/categories 12, approvals/cases 18,
  notifiers 12); the full suite was green after each feature commit (on a copy of the tree). Assertions changed
  only where the mock now shows more than the fake did: after the rollover the cases screen lists the case it opened
  (was "no open cases" from an empty faked list); a coach no longer receives another person's request or another
  team's case at all (the fake listed them and hid the actions). No golden moved.
  - Fake lines: 2,937 at the start of part 2 → **2,700** (`fake_repos` 825 → 588; `fake_athlete` 1,529, `fake_game`
    326, `fake_finance` 257 unchanged). Added: `core_seed.dart` 155.
- **Open points / not done (time)**, in this order next:
  - **Members** (`FakeMembersRepository`, 7 files; `guardian_dialog_test` also has a local `FakeGuardiansRepository`):
    the mock needs "an e-mail that signs in elsewhere" (linked, no password, ACCEPTED) and `LOGIN_SHARED` for a
    member's re-issued password before the tests can move.
  - **Teams and players** (`FakeTeamsRepository`, `FakePlayersRepository`, 13 files): the fakes return whatever each
    test set (eligibility verdicts, rosters independent of players, fixed counts); the mock computes eligibility
    from birth year, category and gender policy and rosters from assignments, so every test needs coherent seeds.
  - **Athlete, game, finance:** unchanged since part 1 (they need the roster above in the mock; finance needs
    explicit finance seeds).

### Part 3 (2026-11-24)
- **Built**
  - **Members.** `MembersData` (`core_seed.dart`) seeds members and guardian links and afterwards reads back the
    mock's state and what the app sent (`invited`, `updates`, `reissuedFor`, `lastQuery`, `calls`, the last
    password); `loginsElsewhere` seeds e-mails that sign in to another academy. `FakeMembersRepository` and the
    guardian dialog's local `FakeGuardiansRepository` go (guardians and first logins are the mock's).
  - **Teams and players.** `TeamsData` / `PlayersData` do the same for teams, rosters (the players' assignments),
    staff and players (`lastCreate`, `lastUpdate`, `rosters`, `lastPreferred`, exports, `noServerFileName`).
    `FakeTeamsRepository` and `FakePlayersRepository` go; `fake_repos.dart` keeps only `FakeCore` (a data bundle) and
    the `Faulty` mixin of the athlete and game fakes. `MockBackend` also records file answers (`lastFile`) and can
    drop a response header (`dropHeaders`). The whole core side of the app now runs on the mock in every widget test.
  - Verdicts the fakes were told are now the mock's, from coherent seeds: birth years place players in categories
    (play-up, too old, gender policy), the jersey rules come from a preferred or a previous number. One fake verdict
    was impossible (a gender-policy reason in a mixed team): that test now opens a girls' team where it holds.
- **Mock and fake differed (decided against `core.yaml`, red test first, the fake was right, mock fixed):**
  7. an e-mail that already signs in elsewhere got a new login and password (`inviteMember`, a guardian's first
     login, `createGuardian`): now linked, ACCEPTED, no password; re-issuing such a shared login is 409
     `LOGIN_SHARED`; 8. a coach who is not staff of a team got 404 for the team, its roster, staff and taken numbers
     (all "any member"); 9. team staff saw only their teams' players (`listPlayers` / `getPlayer`: team staff see
     all; pending ones only to their requester); 10. `listEligibleTeams` listed ineligible teams; 11. a taken jersey
     number was accepted on update (409 `TEAM_PLAYER_CONFLICT`). The mock's own role tests
     (`mock_roles_persistence_test`), which pinned the older rules, now follow the contract.
- **Expectations that follow the mock where a fake made data up:** a linked player shows the player's name ("Leo
  Gil", not "Player p2"); passwords and the roster PDF's server file name are read from the mock's answers; a
  notifier test reads a failure with `AppError.of` as the screens do (the fake threw an `AppError` itself); provider
  tests listen to auto-dispose providers like the screens. **Goldens re-recorded:** `jersey_dialog_*` (3) and
  `assignment_outcome` / `assignment_none` (taken numbers in the contract's order, by value; the fake kept insertion
  order).
- **Verified** (fresh, 2026-11-24): `flutter analyze` no issues; `just web-format-check` clean; `just web-test`
  **1953 passed, 0 failed** (part 3 started at 1944). +9 tests, none removed (5 member/guardian login rules, 4 roster rules).
  Every migrated file keeps its test count; the suite was green after each feature commit (on a copy of the tree).
  - Fake lines: 2,700 → **2,197** (`fake_repos` 588 → 85, of which the `FakeCore` data bundle and `Faulty`;
    `fake_athlete` 1,529, `fake_game` 326, `fake_finance` 257 unchanged). `core_seed.dart` grew to 617.
- **Not done: athlete, game, finance.** I stopped here because my context budget ran out, not at a fake that cannot
  go. What each needs:
  - **Game** (`FakeMatchesRepository`, 12 files): the live-match screens take the box score from the matches
    repository but post events through the events remote (`FakeGameServer`, the sync layer's contract fake, not one
    of the seven files). On the mock, both must go through it (the real `EventsRemote` on the backend) so the box
    score matches the events; `sync_worker_test` and the vectors test (WP137) keep `FakeGameServer`.
  - **Athlete** (`fake_athlete.dart`, 1,529 lines, 20 files): the athlete mock needs the seeding accessors the core
    mock got (sessions, schedules, attendance, plans, assignments, completions, exercises, injuries, measurements,
    tests, norms) and data classes like `TeamsData` for its five repositories.
  - **Finance** (`FakeFinanceRepository`, 11 files): it already wraps the real repository over the mock, but over the
    demo seed; moving it means explicit finance seeds (plans, dues, payments, expenses) in the empty academy.

### Part 4 (2026-11-24)
- **Built**
  - **Finance.** `FinanceData` (`test/support/finance_seed.dart`) seeds the empty test academy explicitly through new
    hooks of `MockFinanceApi` (`seedCurrency`, `seedPlan`, `seedDues`, `seedExpense`, `dues`), which the demo's own
    seed now uses too; `standardFinance` spells out what the tests rely on (EUR, three plans, Mini A's dues for
    September to November 2026, eight expenses), and `financeCore` gains the eight players the dues belong to. Tests
    read what the app sent (`dueQuery`, `expenseQuery`, `sent<T>`, `lastId`, `languageOf`) and what the mock answered
    (`answered<T>`); 501s, 409s, 422s, 403s and hangs are injected in front of it. Provider tests use the app's
    `ApiFinanceRepository` on a seeded backend (`financeBackend`, `FinanceData.overrides`). `FakeFinanceRepository`
    goes.
  - **Matches.** `GameData` (`test/support/game_seed.dart`) seeds matches, rosters and other scorers' events through
    new hooks of `MockGameApi` (`seedMatch`, `seedRoster`, `seedEvent`, `match`, `eventsOf`). The app's
    `ApiMatchesRepository` and `ApiEventsRemote` talk to the mock (in the `Harness`; `GameData.apiOverrides` for the
    controller test), so the box score, the feed and the season statistics come from the same stored events. The
    device's Drift store and the sync timers stay in the test; offline is a dropped connection on the events paths.
    `FakeMatchesRepository`, `FakeGame` and `genBoxScore` go; `FakeGameServer` stays as the sync worker's contract
    fake (`sync_worker_test`, the vectors test).
  - **Athlete, first sub-feature: the exercise catalogue.** `ExercisesData` (`test/support/athlete_seed.dart`) seeds the
    athlete mock's catalogue (now exposed for tests) and reads back the queries (with their language), created,
    changed and archived exercises; `FakeExercisesRepository` goes; the training and plan fakes copy quick-adds from
    the same catalogue. `injectInto` (`core_seed.dart`) is public for it. ADR-0070 amended.
- **Mock and fake differed (decided against the contract):**
  12. the season balance without a currency: the mock answered 409 `CURRENCY_NOT_SET`, which `finance.yaml` does not
      list; finance-service answers 404. Mock fixed, red test first (`mock_finance_reads_test`); this closes the mock
      part of the FOLLOW-UPS finance leftovers (how the balance screen shows that 404 against the real service is
      still to check there);
  13. a parent's live-match feed: the fake gave every caller the whole feed unless told otherwise; ADR-0030 and the
      mock give a parent only team-level events and the linked player's. The fake was wrong: the controller test's
      coach event is now one of the linked player's;
  14. the match list's order: the fake kept insertion order, the mock answers by `scheduledAt` descending, which the
      list and its offline cache assume (`game.yaml` does not state an order). The fake was wrong.
- **Expectations that follow the mock where a fake made data up:** a match's score follows its stored events (no score
  set by hand); the season statistics are computed from seeded events (`statsGame`: two matches, one started) instead
  of a fixture whose totals and averages disagreed; the match sheet's file name and a created exercise's id are read
  from the mock's answers; a rejection for the team's coach comes from a match cancelled meanwhile
  (`MATCH_CANCELLED`), since neither the mock nor the service refuses its staff `NOT_AUTHORIZED`; "a player without
  dues" is Mini B's player (no plan charges Mini B) instead of one of Club Norte; provider tests read a 501 with
  `AppError.of`, like the screens.
- **Goldens re-recorded:** `finance_coach_*` (4) and `finance_family_*` (4): the team screen now lists its roster and
  the hub its player, because the core seed holds the players the dues belong to; `match/match_list_*` (3): the
  `scheduledAt` order; `match/season_stats_*` (2): figures from the seeded events. Every other finance, match and
  exercise golden passes as recorded.
- **Verified** (fresh, 2026-11-24): `flutter analyze` no issues; `just web-format-check` clean; `just web-test`
  **1953 passed, 0 failed** after each of the five commits. A fresh run of `21af40a0` (on a copy of the tree)
  gives 1952 passed, not the 1953 part 3 reported, so: +1 test (the balance's 404), none removed;
  every migrated file keeps its test declarations (checked file by file against `21af40a0`).
  - Fake lines: 2,197 → **1,473** (`fake_athlete` 1,529 → 1,388; `fake_repos` 85: the `FakeCore` data bundle and
    `Faulty`). Deleted: `fake_finance.dart` 257, `fake_game.dart` 326, `FakeExercisesRepository` 141. Added:
    `finance_seed.dart` 266, `game_seed.dart` 270, `athlete_seed.dart` 158.
- **Not done: the rest of athlete** (1,388 fake lines), stopped for my context budget at a clean commit, not at a fake
  that cannot go. In this order:
  - **Health** (`FakeHealthRepository`, about 136 lines; `health_test`, `athlete_notifiers_test`, `profile_test`,
    `availability_badge_test`, `training_health_golden_test`): expose the athlete mock's injuries and measurements and
    add a `HealthData` like `ExercisesData` (`createdInjury`, `lastInjuryUpdate`, `createdMeasurement`,
    `updatedMeasurement` from the requests). The mock checks who may read or write a player (team staff, guardian,
    the player), so `athleteCore()` must hold the tests' players in a team the coach is staff of.
  - **Fitness** (`FakeFitnessRepository`, about 200 lines): test types, norms and results; the tests give each result
    a `band` and a `pending` flag, the mock computes them from the norms, so the seeds need norms that put each result
    in the band the test expects.
  - **Training and plans** (`FakeTrainingRepository` about 320 lines: sessions, schedules, attendance, absences;
    `FakePlansRepository` about 340: plans, assignments, completions, quick-add copies; about 12 test files, built in
    `athlete_scenarios.dart`): the athlete mock needs the seeding accessors for those collections.
  - Then `fake_repos.dart`: `Faulty` goes with the last athlete fake; `FakeCore` is a data bundle, not a fake, and can
    move to `core_seed.dart`.
  - The rollover wizard is unchanged (part 2's finding stands).

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| WEB-02 | Done (part) | Tests on the seeded demo mock (ADR-0070). Part 1: audit, academy-request and platform fakes deleted. Part 2: academy, seasons, categories, approvals, cases; `MockAuthService` out of the release build. Part 3: members, guardians, teams and players: the whole core side runs on the mock. Part 4: finance, matches (real events remote on the mock) and the exercise catalogue. 14 mock/contract differences decided. Left: athlete health, fitness, training and plans fakes (1,473 fake lines with `fake_repos.dart`; see part 4) |
