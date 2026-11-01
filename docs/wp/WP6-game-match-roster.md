# WP6 — game-service: match & roster CRUD, RosterPort REST adapter

Model: Sonnet. Depends on: WP2a, WP2b (contracts); runtime depends on core `/internal` (mock with WireMock in tests).
Lane GAME. Contract: `libs/contracts/openapi/game.yaml`. Skills: test-driven-development, quarkus-hexagonal-service,
tenant-isolation-testing.

## Scope
- Module `services/game-service`, package `com.hoopsacademy.game`, datasource `game_app`, Flyway as `game_migrator`.
- Flyway V1: `match` (team_id, season_id, opponent_name, home_away, scheduled_at, venue, status, period_count,
  period_minutes, started_at, finished_at, created_by, version), `match_roster` (match, player_id, display_name,
  jersey_number, is_starter), `sync_receipt` placeholder (WP7). RLS on all.
- `RosterPort` (application port): `teamRoster(teamId)`, `players(ids)`, `authzContext(sub, tenantId)`; adapter =
  Quarkus REST client to core `/internal/**` with `ServiceTokenClientFilter`, Caffeine cache 30 s, 2 s timeout → 503
  Problem; `AuthzContextResolver` for the common tenant filter delegates to it (also honours tenant status).
- Use cases: create match (staff of team or admin), get/list (by team/season/status), patch, start/finish/cancel
  (state machine), put roster (snapshot names/jerseys from RosterPort; validate players belong to the team or are
  explicitly allowed play-up guests), get roster; `/internal/usage/{tenantId}` (match counts).

## Acceptance
- [x] state machine tests (SCHEDULED→LIVE→FINISHED, CANCELLED from SCHEDULED/LIVE; invalid → 409)
- [x] role matrix: parent/player cannot create/start; staff of another team → 403; cross-tenant → 404
- [x] RosterPort adapter: WireMock happy path, 404 mapping, timeout → 503 Problem, cache hit avoids second call
- [x] RLS suites for schema `game`; contract validation on responses; verify green, coverage ≥ 80 %

## Handover

### Built
`services/game-service` (replaces the placeholder pom; root pom untouched), package `com.hoopsacademy.game`, port 8082.
- **domain**: `Match` aggregate (state machine SCHEDULED -> LIVE -> FINISHED, CANCELLED from SCHEDULED/LIVE, idempotent
  start of a LIVE match, `update` rules: periods only while SCHEDULED, nothing once FINISHED/CANCELLED), `MatchRoster`,
  `RosterEntry`, `JerseyNumber`, value objects `MatchId/TeamId/PlayerId/SeasonId`. Illegal moves throw common
  `ConflictException` (409, code `INVALID_STATE`); no framework imports.
- **application**: use cases `CreateMatch, GetMatch, ListMatches, UpdateMatch, StartMatch, FinishMatch, CancelMatch,
  GetMatchRoster, ReplaceMatchRoster, GetUsage` (all `@Transactional`, authz via `MatchPermissions`); ports
  `MatchRepository`, `RosterPort{teamRoster, players, authzContext}`, `UsageCounter`; `UpstreamUnavailableException`.
- **adapters.in.rest**: `MatchResource` (list/create/get/patch/start/finish/cancel), `MatchRosterResource` (get/put),
  DTO records, `UpstreamExceptionMapper` (503 Problem, code `UPSTREAM_UNAVAILABLE`). **adapters.in.internal**:
  `UsageResource` (`@RolesAllowed("service")`, `TenantScope.runAs`). **adapters.out.persistence**: `MatchEntity`,
  `MatchRosterEntity` (`@TenantId String tenantId`, ADR-0011), `JpaMatchRepository`, `JpaUsageCounter`.
  **adapters.out.client**: `CoreInternalClient` (Quarkus REST client, `ServiceTokenClientFilter`), `RestRosterPort`
  (Caffeine 30 s per call, 2 s connect/read timeout), `RosterAuthzResolver` (SUSPENDED/WITHDRAWN tenant -> no membership).
- **Flyway** `V1__match.sql`: `game.match` (+ `cancelled_at`, `cancel_reason`, needed by the contract), `game.match_roster`,
  `game.sync_receipt`; all three through `app.enable_tenant_rls`; composite tenant-scoped FKs; check constraints.
- `application.properties` per the WP2a handover (game_app / game_migrator, OIDC `game-service`, oidc-client, `hoops.core.url`,
  timeouts, `%test` settings); `README.md` in the module.

### Verified (fresh `source scripts/env.sh && ./mvnw -pl services/game-service clean verify`, read in full)
BUILD SUCCESS, **87 tests, 0 failures, 0 errors, 0 skipped**, JaCoCo "All coverage checks have been met": lines
**99.8 %** (508/509; domain 99.3 %, every other package 100 %), gate `jacoco.line.minimum` 0.80 (root default); no compiler warnings.
Test classes: `MatchTest` 16 + `MatchRosterTest` 3 (state machine, domain), `MatchResourceTest` 29, `MatchRosterResourceTest` 11
(role matrix, contract, cross-tenant), `UsageResourceTest` 5, `RestRosterPortTest` 11 (WireMock), `RosterAuthzResolverTest` 3,
`RealAuthzResolverTest` 4, `GameRlsSchemaMetaTest` 1, `GameRlsIsolationTest` 3 (match, match_roster, sync_receipt), `ArchitectureTest` 1.
Negative control: forcing `seasonId` to null in `MatchDto` made the contract filter fail the create test
(`validation.response.body.schema.type /seasonId`); reverted.

### Acceptance checklist
- [x] State machine tests: `MatchTest` (valid chain, cancel from SCHEDULED/LIVE, start/finish/cancel from wrong states -> `ConflictException`)
      and over REST `staffStartsFinishesAMatch`, `cannotFinishAMatchThatIsNotLive` (409 `INVALID_STATE`), `startWithoutStarterIs422`.
- [x] Role matrix: parent/player create 403 (and core not called), parent/player start/finish/cancel/patch/put roster 403,
      staff of another team 403 (create, start, finish, cancel, patch, roster), cross-tenant 404 (header for a tenant the
      user is not in, and ids of another tenant's match through `TenantScope` seeding) - `MatchResourceTest`, `MatchRosterResourceTest`.
- [x] RosterPort adapter (`RestRosterPortTest`): happy path (token + `tenantId` query + no `X-Tenant-Id` asserted on the request),
      404 -> `NotFoundException` (not cached), 500/403 -> `UpstreamUnavailableException`, 4 s delayed response -> 503 after ~2 s,
      cache hit: `verify(1, ...)` after two identical calls; different team = separate call; also players batch and authz.
      End to end 503 Problem: `coreDownMeansProblem503` (create and roster), `coreDownIsAProblem503` (tenant filter).
- [x] RLS suites for schema `game` (`GameRlsSchemaMetaTest`, `GameRlsIsolationTest`), response contract validation (swagger validator against
      `/openapi/game.yaml` on every REST exchange), verify green, coverage 99.8 % >= 80 %.

### Decisions
- **Visibility**: any tenant member may list/get matches and read rosters. The authz context has no "player's teams" relation, so
  "see matches of their teams" cannot be enforced without a core call; stats visibility (linked/self) is a WP7 concern.
- **Guests**: the contract has no `guest` flag on roster entries, so a player not on the team's current roster is 422 `PLAYER_NOT_IN_TEAM`
  (with a violation per player). Duplicate player: 422 `DUPLICATE_PLAYER`. Jersey: request override, else the team jersey from core.
- **Authz placement**: `MatchPermissions` (application) checks `isAdmin || isStaffOf(match.teamId)` after loading the match, so resources stay thin;
  `@RequiresTenantRole` is not used because every member may read.
- **Season** of a new match comes from `teamRoster(...).seasonId` (contract: "taken from the team"); unknown team -> 404.
- **Test resolver vs real resolver**: the common test-jar's `TestAuthzContextResolver` (`@Alternative @Priority(1)`) serves all REST tests.
  `RealAuthzResolverTest` uses a `QuarkusTestProfile` with `quarkus.arc.exclude-types=...TestAuthzContextResolver` to run the production
  `RosterAuthzResolver` through the real tenant filter against WireMock; `RosterAuthzResolver` is `@Unremovable` because ArC would otherwise drop it
  (the alternative wins the injection point). No `@Alternative` in production code.
- **WireMock**: plain `wiremock-standalone 3.13.2` as a `QuarkusTestResource` (version in this module's pom; not managed by the root) that also serves
  the Keycloak token endpoint, so the real `ServiceTokenClientFilter` is exercised. All `@QuarkusTest` classes carry the same two `@WithTestResource`
  annotations (Postgres + WireMock) so Quarkus does not restart the app between classes.
- `Score` and `lastServerSeq` in `Match` are 0 until WP7. `/internal/usage` emits `matches, scheduledMatches, liveMatches, finishedMatches,
  cancelledMatches` and `matchEvents`/`matchEventsLast30Days` = 0 (WP7 replaces the zeros). Unknown tenant -> zeros, not 404.
- Remote calls to core run inside the use-case transaction (bounded by the 2 s timeout, cached 30 s). Acceptable at current load; revisit if
  connection-pool pressure appears.
- No new ADR: everything follows ADR-0005/0006/0008/0011.

### How WP7 extends it
Add `domain/event` (event types, projection) and `application` use cases (`SubmitMatchEvents`, `GetMatchEvents`, `GetBoxScore`, `GetSeasonStats`);
`adapters.in.rest.MatchEventResource`/`StatisticsResource`; persistence `MatchEventEntity` + `V2__match_event.sql` (use `app.enable_tenant_rls`, add
the table to `GameRlsIsolationTest.fixtureOverrides()` if it has FKs); use the existing `sync_receipt` for `(match, device) -> last_client_seq`.
Fill `MatchDto.score/lastServerSeq` and the two event counters in `JpaUsageCounter`. Reject events for CANCELLED matches (`MATCH_CANCELLED`).
Parent/player authz for events/stats needs `AuthzContext.isGuardianOf/isSelf` plus player ids from `MatchRepository.roster(...)`. Reuse
`MatchSeed`, `CoreStubs`, `Contract` from the test sources; for batch tests ignore request validation on `submitMatchEvents` (see contracts README).

### Open points
- **Contract (WP2b)**: the game operations do not declare `503`, so the 503 Problem is outside the spec (not contract-validated in tests). Suggest a
  shared `ServiceUnavailable` response in `common.yaml` for operations that depend on core.
- `MatchEntity` uses `@Version`, but a concurrent edit surfaces as an unmapped persistence exception (500) rather than 409; add a mapper when
  concurrent editing becomes realistic.
- Authz/roster answers are cached 30 s including "not a member" (ADR-0008 staleness); `RestRosterPort.clearCache()` exists for tests/ops.
- `swagger-request-validator-restassured:3.0.0` (managed in the root pom) prints a Maven relocation warning to `openapi-request-validator-restassured`;
  root pom owner may rename it.
- `quarkus.oidc.roles.role-claim-path=realm_access/roles` is assumed for the `service` role on `/internal/usage`: verify against the real realm
  export (service account of the platform caller must carry the realm role `service`) in the e2e WP.
- First run needs network once (wiremock-standalone ~19 MB) and `./mvnw -N install` of the parent pom into `~/.m2` (done locally here;
  the parent pom was not installed yet).
