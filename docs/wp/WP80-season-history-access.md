# WP80 — Season history: read-only access to past seasons for former staff and admins (core, game, athlete)

Model: Opus. Wave 2 (2026-11-06, fifth round): starts after wave 1 is merged; runs alongside WP73/74/75 (web
redesign), WP86 (chart), WP89 (CI). You own `libs/contracts/openapi/{core,game,athlete}.yaml` and the three Dart
packages, `services/core-service`, `services/game-service`, `services/athlete-service` (authz rules, queries,
replica authz resolvers of WP68/69), `libs/common-quarkus` authz context if the rule lives there, Flyway core `V16`,
game `V5`, athlete `V8` (reserved, if needed), `docs/domain/authz-matrix.md` (the "ended season" rule rows). NOT the
web (the "past seasons" selector in the lists is WP76's in wave 3: write in your handover exactly what the web must
send). Depends on: WP58 (decision 40: ended seasons drop access), ADR-0037 (replica authz mirrors core's
`/internal` rules: change both sides in step), WP2c/WP22 membership cache. ADR-0042 reserved for you. Skills:
quarkus-hexagonal-service, tenant-isolation-testing, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp80-season-history`, branch `wp80-season-history`.

Decision 62 of 2026-11-06: past seasons' teams, matches, attendance and health records are readable (never editable)
by the coaches who were staff of the team then and by admins; players and parents keep today's rules.

## Scope
1. **Rule** (ADR-0042): a team whose season has ended is "historic": readable by ADMIN and by the persons who were
   staff of that team (the staff row stays, WP58 only excluded it from "current" teams); every write on a historic team
   (and its matches, sessions, attendance, plans assignments, health records bound to it) is refused with 409
   `SEASON_ENDED` (or 403? pick one Problem type and document it); today's "current" views are unchanged by default.
2. **Contracts** (core 3.1.0 → 3.2.0, game 2.2.0 → 2.3.0, athlete 2.3.0 → 2.4.0, each only if a parameter or field is added; WP81 took core 3.1.0): list endpoints gain
   `seasonId` / `includeEnded` (pick one; the same name in the three APIs), `/me`'s team lists expose historic teams
   separately (e.g. `historicTeams`), responses carry `seasonEnded: true` where useful. Document the rule in each
   description. `UpdateRequestClearListContractTest` pins updated.
3. **Services**: red tests per rule (former staff reads, cannot write; admin reads; a coach never staffed cannot
   read: 404; the game and athlete replica resolvers give the same answers as core's `/internal`: contract tests
   on both sources, WP68/69 style); the authz-matrix rows.
4. **Docs**: ADR-0042; authz matrix; handover with the exact web contract for WP76.

## Acceptance
- [x] Contracts validated; the three Dart packages regenerated and committed (only those); `pubspec.lock` updated
- [ ] Red tests first; `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals) — all modules green except athlete's WP87 container flake, see Verified
- [x] `just mutation core-service`, `game-service`, `athlete-service` at or above baseline (record); `just e2e`
      23/23 on compose (tell the orchestrator before you start it; WP86 does not use compose)
- [x] ADR-0042 indexed (append at the end of `docs/adr/README.md`); handover appended

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
- **Built** (decision 62, ADR-0042):
  - Contracts: core **3.2.0** (`AuthzContext` / `AuthzSummary.historicStaffTeamIds`, internal `TeamRoster.seasonEndDate`,
    `Team.seasonEnded`, `listTeams?includeEnded`, 409 `SEASON_ENDED` on the team PATCH, staff PUT/DELETE and the three
    assignment writes), game **2.3.0** (409 on create/update/start/finish/cancel/roster, `MatchEventRejectionReason`
    `SEASON_ENDED`), athlete **2.4.0** (409 on schedule, session, quick-add, attendance, team plan assignment and
    completion writes and on health writes of a coach whose only relation is a past team; history read rules in the
    descriptions). `SeasonHistoryContractTest` (32), version pins in `UpdateRequestClearListContractTest`.
  - common-quarkus: `AuthzContext.historicStaffTeamIds` + `wasStaffOf` (staff role required, never part of
    `staffTeamIds`), `Authz.wasStaffOf`, `SeasonEndedException` (409, code `SEASON_ENDED`), the REST client maps the new
    fields (absent from an older core = empty / not ended); test-jar `@TenantUser(historicStaffTeams=…)`.
  - core: `MembershipLookup` splits the staff rows into current and historic (one query as before); `PastSeasons`
    (`requireOpenForAdmin`, `requireOpenForCoach`: ADMIN and the coach then get 409, others 403); `TeamViews` sets
    `seasonEnded`; `includeEnded` adds the historic staff teams to `staffedByMe`; the internal roster carries the season
    end. Eligibility-case resolution stays allowed (REASSIGNED into a past team is refused by the assignment).
  - game: `TeamRoster.seasonEndDate` (REST + replica), replica resolver computes `historicStaffTeamIds`; `PastSeasons`
    (current staff: no lookup; former staff: 409 at once; ADMIN / parents: one roster lookup, unknown team or no date =
    open); `MatchPermissions` (admin / staff / former staff, then 409), `StatVisibility` and `EventAuthorization` treat
    former staff like staff; the ingest rejects events whose `recordedAtClient` is on or after the day after the season's
    last day (academy zone) with `SEASON_ENDED`, earlier ones still sync.
  - athlete: `TeamRoster.seasonEndDate` (REST + replica), replica resolver `historicStaffTeamIds`
    (`ReplicaMembershipReads.seasonEnded`), `PastSeasons`; `TrainingAccess.requireManage` (403, then 409), `seesAsStaff`
    (whole attendance sheet for former staff), `PlanAccess.requireMayWithdraw` / `requireMayMark`;
    `HealthAccess.historyUntil` (latest season end of a past team whose roster has the player), dated `requireRead`,
    `listScope` returns `Scope(players, until)` (`teamId` of a past team = its roster up to the season end), injury
    search gained `occurredUntil`, measurements / test results cap `to`; health writes by history-only coaches 409.
  - web (to keep `just web-test` green with the regenerated clients; not the WP76 feature): demo mock teams carry
    `seasonEnded: false`, mock `/me` `historicStaffTeamIds: []`, test fixture `team(seasonEnded:)`.
  - `spotbugs-exclude.xml`: my `KafkaEventBroker` entry was dropped in the rebase in favour of main's identical one.
- **Verified** (2026-11-07):
  - After `git rebase main` (6adcae2: WP73, WP81 Dart client, WP86, the orchestrator's single `KafkaEventBroker`
    exclusion kept; ADR index keep-both): fresh `-T 1C clean verify` contracts 272, common 201, core 892, game 423, e2e
    27 (23 skipped) green; athlete hit the same Dev Services boot flake (`ReplicaAuthzRulesTest`, 2375), module alone
    855/855 BUILD SUCCESS, coverage met. `flutter analyze` no issues, `flutter test` 918 passed. Generated packages
    re-checked against the contracts (no diff).
  - Red first: `8e4dbff` (contracts), `8cee2ff` (common), `fa95d37` (core), `65ba4ce` (game), `a45c7ab` (athlete), each
    before its implementation commit.
  - `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` (fresh): contracts 272, common-quarkus 201, core 892,
    game 423, e2e 27 (23 skipped offline), all green, all coverage and SpotBugs checks met; athlete 838 run, 1 error +
    79 skipped: `ReplicaAuthzRulesTest` could not start its Kafka Dev Services container (`localhost:2375 failed to
    respond`, the WP87 Podman idle-timeout flake). It hit 4 of 4 athlete runs this session (also with the module alone
    on a quiet machine), always at that class; the 11 classes of that boot (80 tests: replica rules and contracts,
    `ApplyRosterEventTest`, RLS suites, seeds) then pass alone: `-Dtest=ReplicaAuthzRulesTest,...,TemplateSeedTest` 80/80
    BUILD SUCCESS. Every other athlete test (758) passed in the module run, coverage met.
  - New/extended: `SeasonHistoryContractTest` 32; common `AuthzContextTest` +2, `RequiresTenantRoleTest` +3,
    `SeasonEndedExceptionTest`, `CoreRosterClientTest`; core `SeasonHistoryTest` 5, `InternalResourceTest`,
    `InternalRosterResourceTest`, `MeResourceTest`; game `SeasonHistoryTest` 6, `AuthzContextContractTest` 22 (11 x REST /
    replica, one new case each side), `RosterPortContractTest` 12 (season end on both sources), `StatVisibilityTest`,
    `EventAuthorizationTest`, `ReplicaAuthzResolverTest`; athlete `SeasonHistoryApiTest` 6, `MembershipContract` +1 on
    REST and replica, `RosterPortContract` (season end on both sources).
  - `just mutation core-service` 575/582 (98.8 %; the 7 survivors / no coverage / timeouts are WP81's `KafkaEventBroker`,
    `RosterEventAppender`, `TemporaryPasswordGenerator` and the known `Eligibility.reasons`, none in WP80 code; threshold
    95, BUILD SUCCESS), `game-service` 447/449 (99.6 %, baseline 438/440), `athlete-service` 495/495 (100 %).
  - `just e2e` on compose (up, seeded, services from this branch): JourneyTest 23/23, MailSinkTest 4/4.
  - Web: `just gen-api` (core 3.2.0, game 2.3.0, athlete 2.4.0; whitespace-only regenerations reverted so the diff holds
    only the contract changes), `pubspec.lock` updated, `flutter analyze` no issues, `just web-format-check` clean,
    `just web-test` 910 passed (269 failed before the mock/fixture fix).
- **Decisions/ADRs:** ADR-0042 (indexed). 409 `SEASON_ENDED` (not 403) for anybody who could otherwise write;
  `historicStaffTeamIds` as a separate set (today's checks untouched); `includeEnded` only on core's `listTeams` (the game
  and athlete lists already return past seasons; `teamId` narrows them); match events cut off by `recordedAtClient`
  (offline sync of the last matches keeps working); health history capped at the season's last day; a staff row of a
  past team cannot be removed (history ends with the staff role or the membership); seasons stay editable (reopen);
  eligibility-case resolution stays allowed. A team core does not know or a roster without `seasonEndDate` (older
  core) counts as open.
- **Open points / follow-ups:**
  - **Web contract for WP76** (the "past seasons" selector):
    - Show it when `GET /api/core/me` → `memberships[].authz.historicStaffTeamIds` is non-empty, or the member is ADMIN.
    - Past teams: coach `GET /api/core/teams?staffedByMe=true&includeEnded=true` (today's and past teams; the past ones
      have `seasonEnded: true`); ADMIN `GET /api/core/teams?seasonId=<past season>`; season names and dates from
      `GET /api/core/seasons`. Roster `GET /api/core/teams/{id}/players` (`includeLeft=true` for leavers), staff
      `GET /api/core/teams/{id}/staff`.
    - Lists for a selected past team: matches `GET /api/game/matches?teamId=<id>` (or `seasonId=`), box score and feed as
      today (former staff see every player); sessions `GET /api/athlete/training-sessions?teamId=<id>&from=<season
      start>&to=<season end>`, attendance `GET .../training-sessions/{id}/attendance` (whole sheet), schedules
      `GET /api/athlete/training-schedules?teamId=<id>`, plan assignments `GET /api/athlete/plan-assignments?teamId=<id>`;
      health `GET /api/athlete/injuries?teamId=<id>` and `GET /api/athlete/physical-test-results?teamId=<id>` (the server
      caps them at the season's last day), `GET /api/athlete/body-measurements?playerId=<id>` (capped likewise).
    - Read-only UI: hide create / edit / delete / record / scoring actions for a team with `seasonEnded: true` (a match:
      its `seasonId`'s season ended, or its team's `seasonEnded`); on any 409 Problem with `code` = `SEASON_ENDED` show
      "Season ended: read only" (es / en / id keys next to the feature's); an `events:batch` result with `reason` =
      `SEASON_ENDED` is final (drop it from the offline queue, like the other REJECTED reasons). Players and parents see
      nothing new.
  - The athlete `ReplicaAuthzRulesTest` boot failure is deterministic on this Mac until WP87's pending user action (Podman
    API `--time=0`) is applied; CI not affected by WP80 code.
  - The three web files (`mock_core_api.dart`, `mock_api_adapter.dart`, `test/support/core_fixtures.dart`) were outside
    the brief's files: one-line additions; rebased onto main with WP73 without conflict.
  - Not done: a `seasonEnded` flag on game's `Match` and athlete's session responses (the web derives it from core's
    team/season); PIT scope unchanged (the new `PastSeasons` classes are covered by API tests, not unit tests).
