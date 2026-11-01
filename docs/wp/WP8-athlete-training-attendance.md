# WP8 — athlete-service: schedules, sessions, attendance, absences

Model: Sonnet. Depends on: WP2a, WP2b. Lane ATHLETE. Contract: `libs/contracts/openapi/athlete.yaml`. Plan §2 "Training".
Skills: test-driven-development, quarkus-hexagonal-service, tenant-isolation-testing.

## Scope
- Module `services/athlete-service`, package `com.hoopsacademy.athlete`, datasource `athlete_app`, Flyway as `athlete_migrator`;
  `RosterPort` adapter identical in shape to game's (consider copying the pattern; shared code may move to common later —
  note it in handover rather than modifying common-quarkus).
- Flyway V1: `training_schedule` (team_id, weekday, start_time, duration_min, location, valid_from, valid_to),
  `training_session` (team_id, schedule_id null, starts_at, ends_at, location, plan_id null, status, notes),
  `planned_absence` (player_id, from_date, to_date, reason, created_by), `attendance` (session_id, player_id, status
  PRESENT|LATE|ABSENT|EXCUSED, minutes_late, note, recorded_by; pk session+player). RLS on all.
- Use cases: schedules CRUD (staff/admin), `MaterialiseSessions` (8 weeks ahead, idempotent, tenant timezone, DST-safe;
  nightly job + on schedule change), sessions list by team/date range, ad-hoc create, patch, cancel; attendance put
  (staff), absences CRUD (parent for linked, player self, staff any); session attendance view overlays planned
  absences as EXPECTED_ABSENT; `/internal/usage/{tenantId}`.

## Acceptance
- [x] materialisation idempotent (re-run → no duplicates), handles DST transition in Europe/Madrid and Asia/Jakarta
- [x] role matrix for attendance/absences (parent linked only; player self only; staff any)
- [x] RLS suites; cross-tenant 404; contract validation; verify green, coverage ≥ 80 %

## Handover

### Built
`services/athlete-service` (port 8083, module README included). Package `com.hoopsacademy.athlete`:
- **domain** (no framework imports): `TrainingSchedule`, `TrainingSession`, `Attendance`, `PlannedAbsence`, `AttendanceSheet`
  (planned-absence overlay), `SessionMaterialiser` (pure; `ZonedDateTime` in the tenant zone), id value objects, `Actor`.
- **application**: `ManageSchedules`, `MaterialiseSessions`, `NightlyMaterialisation`, `ManageSessions`, `ManageAttendance`,
  `ManagePlannedAbsences`, `ReportUsage`, `TrainingAccess` (the authz matrix), `TenantZones`; ports `ScheduleRepository`,
  `SessionRepository`, `AttendanceRepository`, `AbsenceRepository`, `RosterPort{teamRoster, players, authzContext}`,
  `TenantClock`, `TenantRegistry`.
- **adapters**: `in.rest` (schedules, sessions, attendance, planned absences; PATCH distinguishes absent from null),
  `in.internal` (`/internal/usage/{tenantId}`, `@RolesAllowed("service")`), `in.job` (`@Scheduled` nightly),
  `out.persistence` (Hibernate entities with `@TenantId String tenantId`; JDBC for the registry), `out.client`
  (`CoreRosterAdapter`: Quarkus REST Client + `ServiceTokenClientFilter`, Caffeine 30 s per tenant/team/player/subject,
  2 s connect+read timeout; 404 -> `NotFoundException`; timeout/5xx/anything else -> 503 `UPSTREAM_UNAVAILABLE`;
  failures and 404 never cached; `RosterAuthzResolver` only resolves members of an ACTIVE tenant), `out.time`.
- Flyway `V1__training.sql` (migrator): `training_schedule`, `training_session`, `planned_absence`, `attendance`, all with
  `app.enable_tenant_rls`, tenant-scoped composite FKs, `unique (schedule_id, starts_at) where schedule_id is not null`,
  checks (weekday 1..7, duration 15..480, `to_date >= from_date`, LATE <=> minutes_late). Extra columns beyond the brief:
  `training_session.cancel_reason`, `manually_edited`; `*_by_name` snapshots on attendance/absence; global `tenant_registry`.
- Contract operations implemented: all of `TrainingSchedules`, `TrainingSessions`, `Attendance`, `PlannedAbsences`,
  `/internal/usage/{tenantId}` (counters `trainingSessions`, `attendanceRecords`, `trainingSchedules`, `plannedAbsences`).
  WP9/WP10 operations are not implemented.

### How verified (fresh `source scripts/env.sh && ./mvnw -pl services/athlete-service clean verify`, 2026-11-01)
**BUILD SUCCESS, 181 tests, 0 failures, 0 errors, 0 skipped, no compiler warnings. JaCoCo lines 95.7 % (959/1002), branches 87.2 %
(258/296); `domain` 97.3 %, `application` 97.4 %; gate `jacoco.line.minimum=0.80` (parent default) passed.** Uncovered: the 5-line
`NightlyMaterialisationJob` trigger (cron is `off` in tests; the use case it calls is tested directly).
| Area | Tests |
|---|---|
| Pure domain: `SessionMaterialiserTest` (15), `DomainModelTest` (13) | Madrid spring-forward (167 h week) and fall-back (169 h), non-existent 02:30 -> 03:30, repeated hour -> earlier offset, session spanning the gap, Asia/Jakarta (no DST, every spacing 168 h, always 09:00Z), week boundary Sunday 23:30 / Monday 00:15, inclusive window/validity, 8-week horizon |
| RLS: `AthleteRlsSchemaMetaTest` (1), `AthleteGenericRlsIsolationTest` (4 tables) | meta-test with `athlete.tenant_registry` declared global; generic isolation with fixtures for check constraints and the composite FK |
| Idempotency/materialisation: `ScheduleApiTest` (14), `NightlyMaterialisationTest` (2) | re-run creates 0; cancelled session not recreated; weekday change moves untouched sessions but keeps a patched one; location change keeps ids; ending keeps sessions with attendance; nightly job iterates registry, refills a wiped horizon, 2nd run creates 0; Jakarta zone from core -> 11:00Z |
| Role matrix: `RoleMatrixTest` (73 cases) + per-resource tests | ADMIN, COACH/ASSISTANT of team, COACH of another team, PARENT linked/unlinked, PLAYER self/other, unions (COACH+PARENT, ADMIN+PLAYER), role-less member for: create schedule/session, record attendance, cancel, read sheet, read session, create/delete absence |
| API: `SessionApiTest` (13), `AttendanceApiTest` (10), `PlannedAbsenceApiTest` (6), `UsageAndInternalApiTest` (4), `UpstreamFailureApiTest` (2) | ranges (366-day limit, inclusive), paging, PATCH null/absent, 409 on cancelled, overlay as `expectedAbsent`, LATE rules, PLAYER_NOT_IN_TEAM, cross-tenant 404 (non-member and RLS), usage via `TenantScope`, 401/403 on `/internal`, 503 on core error/timeout |
| RosterPort adapter (WireMock): `CoreRosterAdapterTest` (15) | happy path with bearer token, 404, 2 s timeout -> 503 (< 3.5 s), 500 -> 503 not cached, cache hit (1 core call for 2 reads), per-tenant cache, batch + per-player cache, unknown players omitted, authz mapping incl. optional `timezone`, non-member not cached, token fetched once |
| Production resolver: `RosterAuthzResolverTest` (3, Mockito) + `RealResolverApiTest` (5) | see "Testing the real resolver" |
| Architecture: `AthleteArchitectureTest` | `HoopsArchitectureRules.checkProductionCode` |
Every REST Assured call goes through `ApiSupport.api(...)`: request and response validated against `/openapi/athlete.yaml`.

### Acceptance checklist
- [x] materialisation idempotent, DST Madrid + Jakarta: `SessionMaterialiserTest`, `ScheduleApiTest.materialisationIsIdempotent`, `cancelledSessionsAreNotRecreated`, `NightlyMaterialisationTest`
- [x] role matrix attendance/absences (parent linked only, player self only, staff any): `RoleMatrixTest`, `PlannedAbsenceApiTest`, `AttendanceApiTest`
- [x] RLS suites, cross-tenant 404, contract validation, verify green, coverage >= 80 %: see counts above (95.7 %)

### Decisions
- **`athlete.tenant_registry(id, timezone)`** (global, no RLS, no `tenant_id` column so the common meta-test treats it as a
  declared global table; a column named `tenant_id` would be forced to have RLS). Upserted when a schedule or ad-hoc session is
  created (`TenantZones.remember`: zone from core's authz answer, else the configured default is registered once and kept).
  The nightly job lists tenants from it (plain JDBC, works without a bound tenant) and runs each through `TenantScope.runAs`.
  A tenant that never created a schedule has nothing to materialise, so it is not needed.
- **Tenant time zone** is the real contract gap: no internal endpoint exposes it and `AuthzContext` has no `timezone`. The
  adapter reads an optional `timezone` property of the authz answer (additive for core) and falls back to
  `hoops.athlete.default-timezone` (`Europe/Madrid`). Until core adds it every tenant is treated as Madrid time.
- Gap: `AuthzContext` has **no team membership of linked/own players**, so PARENT/PLAYER list calls without `teamId` are a
  400, and single-team access is decided from the roster (`GET /internal/teams/{id}/roster`): player of the caller in the roster
  or 404. Staff roles (ADMIN/COACH/ASSISTANT) read every team; writes need ADMIN or staff of that team (403 otherwise).
- Gap: `PersonRef.displayName` for `recordedBy` is a snapshot of the token `name`/`preferred_username` (fallback `Member`)
  stored with the row, because person data lives in core and no internal person endpoint exists.
- Gap: 503 `UPSTREAM_UNAVAILABLE` is not a documented response of the athlete operations (ADR-0008 requires it).
- Gap in contracts docs: the `allOf` composition (`TrainingSchedule = Input + id`, `PlannedAbsence`) makes
  swagger-request-validator report the other members' properties as "additional properties". The tests therefore set the level of
  `validation.{request,response}.body.schema.additionalProperties` to IGNORE in `ApiSupport` (everything else stays strict).
  The contracts README should say so; also the artifact is flagged as relocated to `openapi-request-validator-restassured`.
- Reconciliation on schedule change moves/removes only future PLANNED sessions with `manually_edited = false` and no attendance;
  WP9 must set `manually_edited` (or equivalent) when it attaches a plan to a materialised session so it survives a re-plan.
- Unknown tenant on `/internal/usage` returns zeros (the service cannot tell "unknown" from "no data"); contract's 404 is unused.
- Calendar defaults (the contract leaves them open): no `from`/`to` = today .. today + 8 weeks; only `from` = 366 days from it;
  only `to` = 366 days back. Dates are tenant-zone calendar days.
- Extra Problem mappings (`AthleteExceptionMappers`): unreadable bodies/unknown enum values -> 400 Problem, role-protected
  401 -> Problem (Quarkus' defaults are `application/json`, which the contract does not allow).
- Process honesty (TDD deviation): production code and tests were written in the same pass per layer, not strictly red-first.
  The suites that ran first against the code (RLS, domain) passed on first run, so they were not seen failing. The API and
  adapter tests did go red and found real defects, all fixed: Hibernate snapshots entity state at `persist` (NOT NULL violations),
  `Optional.map` swallowing "clear to null" in PATCH, a bulk delete after `em.clear()` discarding a pending schedule update,
  Jackson enum errors and role-protected 401s answered as non-Problem JSON.
- No new ADR: nothing here changes a locked decision; the registry and the gaps are recorded here and in the module README.
- Shared code candidate for common: `RosterPort`-style cached REST adapter and `AuthzContextResolver` over it are near-identical in
  game-service; not moved (brief said to note, not modify common-quarkus).

### Testing the real resolver (how)
The test-jar's `TestAuthzContextResolver` is an `@Alternative @Priority(1)` and overrides `RosterAuthzResolver` in every
`@QuarkusTest`. The production resolver is tested (a) as a unit with a mocked `RosterPort` (`RosterAuthzResolverTest`: active,
non-member, SUSPENDED/WITHDRAWN -> empty) and (b) end to end in `RealResolverApiTest` with
`@TestProfile(RealResolverProfile)` that sets `quarkus.arc.exclude-types=com.hoopsacademy.common.testing.TestAuthzContextResolver`;
membership then comes from WireMock `/internal/authz/...` (ACTIVE member, role-driven 403, non-member 404, SUSPENDED 404, core 500 -> 503).
Test plumbing: `CoreMockResource` (WireMock 3.13.2 + token endpoint, as `QuarkusTestResourceLifecycleManager`; tests reach it over HTTP via
`wiremock.port`), `CoreStubs`, `ApiSupport`. Tests that need several roles register memberships with `ApiSupport.member(...)` and a
class-level `@TestSecurity`/`@OidcSecurity`.

### How WP9 / WP10 extend it
- Add `V2__training_plans.sql` / `V3__health.sql` with `app.enable_tenant_rls`; add the new tables' fixtures to
  `AthleteGenericRlsIsolationTest.fixtureOverrides()` (check constraints, composite FKs) — the suites pick up tables automatically.
- New domain/application/adapter classes next to the existing ones (`ManagePlans`, `ManageInjuries`, ...); reuse `TrainingAccess`
  (`relatedPlayers`, `requireManage`, `mayHandleAbsencesOf`), `RosterPort`, `CallerActor`, `PatchBody`, `Patches`, `PageDto`, `Requests`.
  Injury-driven `unavailableInjuryId` of `AttendanceEntry` is not set yet (WP10 hooks it in `AttendanceDtos.Entry`/`ManageAttendance.buildSheet`).
- Plan completion by parents/players must follow the `ManagePlannedAbsences` pattern; session `planId` is already stored (no FK yet).
- Extend `ReportUsage` counters (`trainingPlans`, `physicalTestResults`, `injuries`, `bodyMeasurements`).
- Resources must keep `@RequiresTenantRole(all five roles)` and do fine-grained checks in the use case, never `@Transactional` in resources.

### Open points
- Ask core/contracts owner: add `timezone` (and optionally `playerTeamIds`) to `AuthzContext`, add 503 to the athlete responses, document the validator
  `additionalProperties` handling for `allOf`.
- Nightly job runs on every replica; `concurrentExecution=SKIP` only guards one instance. Idempotency makes duplicates harmless, but a
  unique-violation race with an API call would fail that tenant for the night (logged, retried next night). Use a DB advisory lock if replicas > 1.
- `ServiceTokenClientFilter` is exercised against WireMock (client credentials), not a live Keycloak; roles claim path is `realm_access/roles`.
- Cache invalidation is TTL-only (30 s staleness of membership, as ADR-0005/0008 accept).
- `NightlyMaterialisationJob` scheduling itself is not covered by a test.
