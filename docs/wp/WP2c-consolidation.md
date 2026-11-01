# WP2c — Consolidation: cross-cutting follow-ups (libs, contracts, services)

Model: Opus. Depends on: WP2a, WP2b, WP3–WP10, WP15. Skills: test-driven-development, quarkus-hexagonal-service,
tenant-isolation-testing, clean-code, verification-before-completion.

## Brief (as given by the orchestrator)
Close the cross-cutting gaps collected in `docs/wp/FOLLOW-UPS.md` across `libs/common-quarkus`, `libs/contracts` and
the three services. Repo `/Users/davidbejar/code/hoops-academy`. Editable: `libs/common-quarkus/**`, `libs/contracts/**`
(not `vectors`), `services/{core,game,athlete}-service/**`, the root `pom.xml` (validator artifact rename only),
`infra/compose/nginx.conf` (only if `events:batch` routing needs a fix), `docs/wp/FOLLOW-UPS.md`, this file, a new ADR.
Not: `apps/web`, `deploy/`, `scripts/gen-api.sh` (the orchestrator regenerates the Dart packages), no git commands.
Scope: every "Open" follow-up concerning libs, contracts or services, except items assigned to WP14/WP16/WP17/WP18.

Work items, in order, build green after each:
1. **Contracts** — shared 503 `ServiceUnavailable` (all peer-calling game/athlete/core operations, documented); 502
   `UpstreamIdentityProvider` on createTenant / inviteMember; `AuthzContext` (`/internal/authz`) and the `/me` membership
   summary gain `timezone`, `playerTeamIds`, own `playerId` (check what exists); athlete: `GET
   /players/{playerId}/availability` (implemented shape), `bandStatus` MATCHED|NO_NORM|MISSING_PLAYER_DATA + nullable
   `ageAtMeasurement`, plan `:archive` / `:unarchive`, `GET /plan-assignments/{id}/progress`; game: fixed `type` per
   MatchEvent variant, reasons `EVENT_ID_REUSED` and `MATCH_NOT_STARTED` (server keeps accepting SCHEDULED; document),
   `StatLine.technicalFouls/unsportsmanlikeFouls`, remove `BoxScore.opponentFouls` or add `OPPONENT_FOUL` (cheap only;
   document); core: `PlayerStatus.REJECTED` (preferred) used by reject, `/platform/tenants/{id}/usage/history`, required
   reject note, `/internal/usage` unknown tenant = 200 zero counters. Keep the JSON Schema / OpenAPI consistency test
   green; document the allOf request-body quirk and the `events:batch` colon in libs/contracts/README.md.
2. **common-quarkus** — `TenantScopedPaths` exemption list `hoops.tenancy.exempt-paths` (`/api/core/me`);
   `UnauthorizedException` → 401 Problem; optimistic-lock → 409 `CONCURRENT_MODIFICATION` (delete game's); RLS
   `nullableTenantTables()` hook with the separate-policy expectation (no forced renames); `TenantScope.runExclusive`
   with `pg_try_advisory_xact_lock`; shared `CoreInternalClient` / `RestRosterPort` / `RosterAuthzResolver` in
   `com.hoopsacademy.common.client` (`hoops.core.url`, cache TTL), services keep thin `RosterPort` wrappers;
   `AuthzContext` gains `timezone`, `playerTeamIds`, `playerId`. Update common tests and the skill docs.
3. **core** — timezone / playerTeamIds / own player in `/internal/authz` and `/me`; drop the `/me` reroute filter;
   REJECTED on reject; usage history endpoint; required reject note; jobs on `runExclusive`.
4. **game** — shared client (delete duplicates), drop the local 409 mapper, StatLine foul counts, new reasons, contract
   validation of event batch / feed bodies re-enabled.
5. **athlete** — shared client, availability contract-validated, `bandStatus` / nullable age, plan archive / unarchive /
   progress wired, materialisation on `runExclusive`, tenant `timezone` from `AuthzContext` for `tenant_registry`
   (default stays as fallback), PARENT/PLAYER session lists without `teamId` via `playerTeamIds`.
6. Root pom: `swagger-request-validator-restassured` → `openapi-request-validator-restassured` (Maven Central version).
7. nginx: `/api/game/matches/<id>/events:batch` must pass through (curl if the stack is up, else reason from config).

Process: TDD (first failing test per item in the handover), RLS / role-matrix / contract suites and coverage gates
green; finish with a fresh `./mvnw -q verify` from the root, per-module test counts, FOLLOW-UPS.md updated, this
handover (per module, verification, decisions, open items, note that Dart packages must be regenerated with
`just gen-api` and `apps/web` re-tested).

## Handover

### Built, per module
**libs/contracts** (common 1.1.0; core, game, athlete 2.0.0 — ADR-0016)
- `common.yaml`: responses `ServiceUnavailable` (503, `UPSTREAM_UNAVAILABLE`) and `UpstreamIdentityProvider` (502,
  `IDENTITY_PROVIDER_UNAVAILABLE`); `UsageReport` documents every service's counter keys (+ core `playersRejected`) and
  "unknown tenant = 200 with zero counters".
- 503 on every `/api/game/**` and `/api/athlete/**` operation (their tenant filter calls core's `/internal/authz`).
  core: no operation fails with 503 (`getTenantUsage` lists peers in `unavailableServices`); `createTenant` and
  `inviteMember` declare 502.
- core: `AuthzContext` and `AuthzSummary` require `timezone` + `playerTeamIds` (`ownPlayerId` already existed = the own
  player id, so no second `playerId`); `PlayerStatus.REJECTED`; `RejectApprovalRequest` (note required, minLength 1);
  `GET /platform/tenants/{id}/usage/history` (`TenantUsageHistory` / `TenantUsageSnapshot`, from/to UTC days, default
  last 90 days, ≤ 366); `/internal/usage` unknown tenant → 200 zeros.
- game: each `<Type>Event` fixes `type` (`allOf: [MatchEventType]` + `enum: [<TYPE>]`, see decisions); reasons
  `EVENT_ID_REUSED`, `MATCH_NOT_STARTED` (reserved, documented); `StatLine.technicalFouls` / `unsportsmanlikeFouls`
  (required); `BoxScore.opponentFouls` removed. JSON Schema and vectors unchanged.
- athlete: `getPlayerAvailability` (`PlayerAvailability {playerId, available, expectedReturnOn?, injuries[]}`),
  `archiveTrainingPlan` / `unarchiveTrainingPlan` (`:archive`, `:unarchive`), `getPlanAssignmentProgress`
  (`PlanProgress`, `PlayerProgress`), `BandStatus` enum + required `bandStatus`, nullable `ageAtMeasurement`,
  `TrainingPlanSummary.archived`.
- `CrossServiceContractTest` (20 tests) guards all of the above; README: upstream-failure rules, unknown-tenant usage,
  relocated validator artifact, the `allOf`/additionalProperties quirk, combinator-resolution side effects, colon paths.

**libs/common-quarkus**
- `tenancy`: `AuthzContext` + `playerTeamIds`, `timezone` (`Optional<ZoneId>`), `isPlayerTeam(team)`; the 7-argument
  constructor stays (empty extras). `TenantScopedPaths` takes the exact-path list `hoops.tenancy.exempt-paths` (default
  `/api/core/me`, slash-normalised). `TenantScope.runExclusive(lockKey, Runnable) → boolean` + public
  `advisoryKey(name)`; `hoops.tenancy.exclusive-lock-timeout` (PT6H).
- `problem`: `UpstreamUnavailableException` (503) + `ProblemType.UPSTREAM_UNAVAILABLE`; mappers for
  `UnauthorizedException` / `AuthenticationFailedException` → 401 (+ `WWW-Authenticate: Bearer`),
  `OptimisticLockException` / `StaleStateException` → 409 `CONCURRENT_MODIFICATION` (also when wrapped in another
  exception), upstream → 503 (detail never contains the internal message).
- `client`: `CoreInternalClient` (REST client, configKey `core`, full paths, no class `@Path`), `CoreRosterClient`
  (cache + error mapping), `CoreMembership`, `RosterAuthzResolver` (`@DefaultBean`). Defaults in
  `microprofile-config.properties`: `hoops.core.url`, `quarkus.rest-client.core.url=${hoops.core.url}`, 2 s timeouts,
  `hoops.core.cache-ttl=30S`. New deps: `quarkus-rest-client-jackson`, `caffeine`.
- test-jar: `RlsSchemaMetaTest.nullableTenantTables()` / `GenericRlsIsolationTest.nullableTenantTables()` + 4-arg
  `RlsSchemaInspector.violations(...)` (uuid owner column, forced RLS, tenant policy, one policy per command, no FOR ALL);
  `@TenantUser(playerTeams, timezone)`. Sample migration `V2__sample_shared_table.sql` demonstrates the hook.
- Skills updated: `tenant-isolation-testing` (shared tables, job lock testing), `quarkus-hexagonal-service` (shared
  client, `runExclusive`, common mappers, exempt paths).

**core-service**: `MembershipLookup` fills `timezone` (tenant profile) and `playerTeamIds` (open, valid assignments of
own + linked players); `/internal/authz` and `/me` expose them. `MePathRewriteFilter` deleted, `MeResource` on
`/api/core/me`. `PlayerStatus.REJECTED` (+ `V8__player_rejected.sql` check constraint, derivation leaves it alone,
not withdrawable, hidden like PENDING_APPROVAL from non-admins, counter `playersRejected`); `RejectRequest` sets it.
`UsageHistory` use case + `UsageSnapshotRepository.history` + `GET /platform/tenants/{id}/usage/history`. `CoreUsage`
answers zeros for unknown tenants. `NightlyEligibilityJob` / `UsageSnapshotJob` run under `runExclusive`
(`core.eligibility-sweep`, `core.usage-snapshot`). Local 401 mapper removed (common's).

**game-service**: `RestRosterPort` is a thin mapping over `CoreRosterClient`; deleted local `CoreInternalClient`,
`RosterAuthzResolver`, `MemberAccess`, `UpstreamUnavailableException`, `UpstreamExceptionMapper`,
`OptimisticLockExceptionMapper` (+ their tests); `RosterPort.authzContext` removed. `StatLineDto` carries the foul
counts, `BoxScoreDto` has no `opponentFouls`; `RejectionReason` + `EVENT_ID_REUSED` (used for an id of another match),
`MATCH_NOT_STARTED` (unused). Batch results omit null `reason` / `message`. Tests: `Contract.EVENTS` validates event
batches and the feed again (request and response).

**athlete-service**: `CoreRosterAdapter` maps `CoreRosterClient`; deleted local client, resolver, `MemberContext`,
`TenantStatus`, `UpstreamUnavailableException`, 401/503 mappers; `RosterPort.authzContext` removed. `TenantZones` uses
`AuthzContext.timezone` (default only as fallback). PARENT/PLAYER session and schedule lists without `teamId` use
`playerTeamIds` (empty result instead of 400); `requireView` accepts a team in `playerTeamIds` before the roster lookup.
Plan `:archive` / `:unarchive`, assignment `progress` resources; `archived` in plan DTOs; `ageAtMeasurement` null when
the birth date is unknown. `NightlyMaterialisationJob` runs under `runExclusive("athlete.materialisation")`.
`AthleteRlsSchemaMetaTest` declares its four shared tables through the new hook.

**Root pom**: `openapi-request-validator-restassured` 3.0.0 (Maven Central metadata: only 3.0.0 exists; it is the
relocation target of `swagger-request-validator-restassured:3.0.0`), property `openapi-request-validator.version`;
the three service poms use the new artifactId. The "artifact relocated" warning is gone.

**nginx**: no change. With the compose stack up, `POST /api/game/matches/<id>/events:batch` and `.../events%3Abatch`
were sent to nginx; its upstream URI (error log, game-service not running) shows both forwarded byte-for-byte
(`proxy_pass http://host:8082;` without a URI part passes the raw request URI). Clients must send the colon unencoded.

### How verified
Fresh `source scripts/env.sh && ./mvnw -q clean verify` from the root (2026-11-02, read in full): **exit 0, BUILD
SUCCESS, every coverage gate met**. Per module (from `target/surefire-reports`):

| Module | Test classes | Tests | Failures / errors / skipped | Lines (JaCoCo) |
|---|---|---|---|---|
| libs/common-quarkus | 24 | 147 | 0 / 0 / 0 | 96.1 % (gate 85 %) |
| libs/contracts | 5 | 99 | 0 / 0 / 0 | – (+ strict `openapi-generator validate` ×3) |
| services/core-service | 55 | 411 | 0 / 0 / 0 | 98.8 %, domain 99.2 % |
| services/game-service | 21 | 186 | 0 / 0 / 0 | 98.5 %, domain 98.8 % |
| services/athlete-service | 33 | 569 | 0 / 0 / 0 | 97.3 %, domain 97.0 % |
| **total** | 138 | **1 412** | 0 | |

(Last reported before WP2c: contracts 79, core 398, game 188, athlete 566; game lost the 4 tests of its deleted local resolver/mapper, athlete the 3 of its local resolver — both are now covered in common.) One assertion
(game 503 `instance` without double slash) was added after game had compiled in that run; `./mvnw -pl
services/game-service verify` afterwards: 186 tests green, coverage met. RLS meta/isolation suites, role matrices and
contract validation suites are part of these counts and green.
Dart: the three final specs were generated with openapi-generator 7.26.0 (dart-dio, the gen-api flags) into the
scratchpad (not into `apps/web`) and `dart analyze` reports **0 errors** for core, game and athlete.

### TDD log (first failing test per item)
| Item | First red |
|---|---|
| Contracts | `CrossServiceContractTest`: 20 run, 18 failures + 2 errors (no 503/502, no shared responses, no new fields/ops) |
| common 401 / 409 / 503 mappers | `ProblemExceptionMappersTest` new cases (compile red on `UpstreamUnavailableException`, then green) |
| exempt paths | `TenantHeaderFilterTest.anExemptApiPathNeedsNoTenantHeader` & co (compile red on the `TenantScopedPaths` ctor) |
| `runExclusive` | `TenantScopeExclusiveTest` compile red; the tx-isolation redesign was red first (`theWorkRunsOutsideTheLockTransaction…`, `callingItInsideATransaction…`: 2 failures) |
| shared client | `CoreRosterClientTest`, `RosterAuthzResolverTest` (compile red); the first full common run then exposed a real defect: the client's class-level `@Path("/internal")` was scanned as a server resource and shadowed `/internal/**` (404 in `InternalTenantScopeTest`, `internalPathsAreSkipped`) |
| RLS hook | `RlsSchemaInspectorTest` new cases + sample meta/isolation tests (compile red) |
| core | 411 run, 11 failures + 10 errors: contract validation of `/internal/authz` and `/me` (missing fields), `TenantUsageHistoryResourceTest` (5), `rejectingAnAddLeavesThePlayerRejected…`, `meIsServedOnItsPublicPathOnly`, both job-lock tests, `anUnknownTenantHasZeroUsage…` |
| game | strict event validation: `MatchEventResourceTest` 12 errors (`OpenApiValidation`); then the `allOf`/enum spelling made 12 fail again (`oneOf … 2 are valid`), fixed by the derived-spec filter |
| athlete | tests written before the code, but **first run only after the implementation** (honest deviation): it failed on 3 tests (two pre-existing tests encoding the old 400 for team-less lists, one test-data overlap) and on a `@Scheduled` method returning `boolean` (Quarkus build error) |
| game reason / fouls | written before the code, first run after the implementation (same deviation) |
| domain `REJECTED` derivation | `PlayerStatusDerivationTest` extended before the enum value existed (compile red) |

### Decisions (ADR-0016)
- **Contracts are 2.0.0** (breaking: `REJECTED`, required note, removed `opponentFouls`, new required fields, new
  response-enum values); services and web ship together, so no `/v2` paths.
- **`opponentFouls` removed** rather than an `OPPONENT_FOUL` event: that needs a new event type in the JSON Schema,
  domain, projector, DB check and the shared vectors — not cheap.
- **`MATCH_NOT_STARTED`** exists only for a future policy; the server still accepts events of SCHEDULED matches.
  `EVENT_ID_REUSED` replaces `CLIENT_SEQ_CONFLICT` for an id already stored for another match (amends ADR-0014 §1).
- **Variant `type` spelling**: `{allOf: [{$ref: MatchEventType}], enum: [<TYPE>]}`. The plain inline enum broke dart-dio
  (missing `MatchEventType` import in every variant, 135 analyzer errors; baseline 0); the chosen form generates
  cleanly. swagger-request-validator 3.0.0 discriminates the `oneOf` only with combinators resolved, which drops the
  sibling enum, so game's `Contract.EVENTS` validates against a derived copy using the plain enum (same constraint);
  without resolution every branch fails on `additionalProperties`.
- **`ownPlayerId` is the own player id** (`/me` and `/internal/authz`); no duplicate `playerId` field.
- **`playerTeamIds`** = teams with an open, valid assignment (what `/internal/teams/{id}/roster` lists) of the own and
  linked players; includes teams of any season with an open assignment.
- **`runExclusive`**: advisory key = first 8 bytes of SHA-256 of the lock name; the lock transaction is suspended
  while the work runs (no shared transaction, no two non-XA datasources in one tx, per-tenant failures stay isolated)
  and rolled back afterwards; it must be called outside a transaction (else `IllegalStateException`).
- **Shared resolver as `@DefaultBean`**: core's database resolver wins in core; the test-jar alternative wins in tests.
  "Not a member" is never cached (game used to cache it for 30 s).
- **Null-omission**: batch results omit null `reason`/`message`; progress lines omit null `status`/`completionId` (both
  optional in the contract) — explicit nulls on `allOf`-wrapped nullable enums do not validate once combinators are
  resolved. `ageAtMeasurement` is always present (required + nullable).
- REJECTED players are hidden from non-admins like PENDING_APPROVAL (except the requesting coach) and are not
  withdrawable (409 `PLAYER_NOT_WITHDRAWABLE`). Existing rejected rows stay WITHDRAWN (no backfill).
- Usage history validates the range in the resource (400 from > to, > 366 days); dates are UTC days.

### Open items (also in FOLLOW-UPS.md)
- **Regenerate the Dart packages with `just gen-api` and re-test `apps/web`** (not done here by instruction). Web code
  must adapt to: `PlayerStatus.REJECTED`, removed `BoxScore.opponentFouls` (also referenced in
  `apps/web/lib/features/match/data/mock_game_api.dart`), `StatLine.technicalFouls`/`unsportsmanlikeFouls`,
  `RejectApprovalRequest` (non-blank note), nullable `ageAtMeasurement` + `bandStatus`, `EVENT_ID_REUSED` /
  `MATCH_NOT_STARTED`, `AuthzSummary.timezone` / `playerTeamIds`, new operations (availability, archive/unarchive,
  progress, usage history), 503/502 Problem responses.
- Not in scope / left open: template `nameKey`; measurement-per-day race → 409; members list filtering of
  pending/rejected persons; player login provisioning; onboarding crash window; > 2 MB uploads Problem; k8s ingress
  must forward colon paths unchanged (WP16).
- `deploy/` sets `HOOPS_CORE_URL`, which still drives the shared client (`quarkus.rest-client.core.url` defaults to
  `${hoops.core.url}`); the old keys `hoops.roster.cache-ttl` / `hoops.athlete.roster-cache-ttl` are gone
  (new: `hoops.core.cache-ttl`). Nothing in `deploy/` referenced the old keys.
- `staffTeamIds` / `playerTeamIds` include teams of ended seasons when an assignment/staff row is still open.
- No git commands were run.
