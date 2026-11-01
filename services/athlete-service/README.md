# athlete-service

Training schedules, sessions, attendance and planned absences (WP8). Plans, completions, injuries, body measurements
and physical tests follow in WP9 / WP10 (their operations exist in `libs/contracts/openapi/athlete.yaml` and are not
implemented yet). Port 8083, schema `athlete`, app role `athlete_app`, migrations as `athlete_migrator`.

```
source scripts/env.sh
./mvnw -pl services/athlete-service verify        # tests need Podman (Testcontainers Postgres); no compose stack
./mvnw -pl services/athlete-service quarkus:dev   # needs the compose stack (Postgres, Keycloak) and core-service
```

## Layout (`com.hoopsacademy.athlete`)
| Package | Content |
|---|---|
| `domain` | `TrainingSchedule`, `TrainingSession`, `Attendance`, `PlannedAbsence`, `AttendanceSheet` (planned-absence overlay), `SessionMaterialiser` (pure, `ZonedDateTime` in the tenant zone), id value objects. No framework imports. |
| `application` | use cases (`ManageSchedules`, `MaterialiseSessions`, `NightlyMaterialisation`, `ManageSessions`, `ManageAttendance`, `ManagePlannedAbsences`, `ReportUsage`), `TrainingAccess` (authz matrix), ports `ScheduleRepository`, `SessionRepository`, `AttendanceRepository`, `AbsenceRepository`, `RosterPort`, `TenantClock`, `TenantRegistry`. |
| `adapters.in.rest` | JAX-RS resources, DTOs, `PatchBody` (absent vs null in PATCH), Problem mappers. |
| `adapters.in.internal` | `GET /internal/usage/{tenantId}` (role `service`). |
| `adapters.in.job` | `@Scheduled` nightly materialisation. |
| `adapters.out.persistence` | Hibernate entities (`@TenantId String tenantId`, ADR-0011) and repositories; `TenantRegistryRepository` is plain JDBC. |
| `adapters.out.client` | `CoreRosterAdapter` (RosterPort over REST Client to core `/internal/**`), `RosterAuthzResolver`. |
| `adapters.out.time` | `RegistryTenantClock`, `Clock` producer. |

New WP9/WP10 code adds sibling packages/classes in the same layers (e.g. `domain.plan`, `application.ManagePlans`,
entities + `V2__...sql`) and reuses `TrainingAccess`, `RosterPort`, `CallerActor`, `PatchBody`, `PageDto`.

## Configuration
| Property | Default | Meaning |
|---|---|---|
| `quarkus.datasource.*` | user `athlete_app`, `ATHLETE_APP_PASSWORD`, `ATHLETE_DB_URL` | runtime datasource (non-owner role, RLS applies) |
| `quarkus.flyway.*` | user `athlete_migrator`, `ATHLETE_MIGRATOR_PASSWORD` | migrations |
| `quarkus.oidc.*` / `quarkus.oidc-client.*` | `KEYCLOAK_URL`, client `athlete-service`, `ATHLETE_SERVICE_CLIENT_SECRET` | end-user JWT validation / client credentials for `/internal` calls |
| `hoops.core.url` | `http://localhost:8081` | core-service base URL |
| `hoops.athlete.roster-cache-ttl` | `30S` | RosterPort cache |
| `hoops.athlete.default-timezone` | `Europe/Madrid` | tenant zone until core reports one |
| `hoops.athlete.horizon-weeks` | `8` | materialisation horizon |
| `hoops.athlete.materialise.cron` | `0 15 2 * * ?` | nightly job (`off` disables) |

## Materialisation
`MaterialiseSessions` creates sessions for the next 8 weeks. A `(schedule_id, starts_at)` pair is unique in the
database and checked in the use case, so re-running creates nothing and a CANCELLED session (its row stays) is never
recreated. On schedule create/update untouched future sessions (PLANNED, never patched, no attendance) are moved or
removed to match; sessions staff edited (`manually_edited`) or that have attendance are kept. Ending a schedule
deletes its future PLANNED sessions without attendance.

The nightly job needs the list of tenants. This service has no platform datasource, so it keeps the global table
`athlete.tenant_registry (id, timezone)` (no `tenant_id` column, no RLS, declared in `RlsSchemaMetaTest.globalTables()`).
A tenant is registered the first time a schedule or ad-hoc session is created. The job runs each tenant through
`TenantScope.runAs` so RLS applies.

## Contract gaps (to settle with core / contracts)
1. **Tenant time zone**: core's `AuthzContext` has no `timezone`. The adapter reads an optional `timezone` field
   when core starts sending it (additive, minor version); until then every tenant uses `hoops.athlete.default-timezone`.
2. **Team of a player**: `AuthzContext` has no team membership of linked/own players, so for PARENT/PLAYER the list
   endpoints require `teamId` (400 otherwise) and team access is checked by looking for their players in
   `GET /internal/teams/{id}/roster`.
3. **Person display names**: `PersonRef.displayName` for `recordedBy` is a snapshot of the token's `name`
   (fallback `preferred_username`, then `Member`) stored in `*_by_name` columns.
4. **503** (`UPSTREAM_UNAVAILABLE`) is not among the documented responses of the athlete operations.

## Testing notes
* `@TenantUser` (common test-jar) drives auth. The test-jar's `TestAuthzContextResolver` overrides the production
  `RosterAuthzResolver` in every `@QuarkusTest`; the production resolver is exercised by `RosterAuthzResolverTest`
  (unit, Mockito) and by `RealResolverApiTest` (`@TestProfile` that sets `quarkus.arc.exclude-types` for the test
  resolver, with membership served by WireMock).
* core-service and the Keycloak token endpoint are WireMock (`CoreMockResource`, stubs via `CoreStubs`); the adapter
  cache is cleared with `CoreRosterAdapter.clearCache()` between tests.
* All REST Assured calls go through `ApiSupport.api(tenant)`, which validates request and response against
  `/openapi/athlete.yaml` (swagger-request-validator); `lenient(...)` validates only the response, for deliberately
  invalid requests.
* RLS: `AthleteRlsSchemaMetaTest`, `AthleteGenericRlsIsolationTest`.
