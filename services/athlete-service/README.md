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
| `adapters.out.client` | `CoreRosterAdapter` (RosterPort mapping over common-quarkus' shared `CoreRosterClient`; the membership resolver is common's `RosterAuthzResolver`). |
| `application.replica`, `adapters.in.messaging` | roster replica (WP69, ADR-0037): `CoreRosterConsumer` (channel `core-roster`, seven `core.*` topics) -> `CoreEventDecoder` (contract validation, key check) -> `ApplyRosterEvent` (event's tenant, idempotent, `occurredAt`-ordered); `ReplicaAuthzResolver` (membership like core's `/internal/authz`). |
| `adapters.out.persistence` (replica) | `RosterReplicaRepository` (upserts of `athlete.*_ref`, V6), `ReplicaRosterRepository` (RosterPort on the replica), `ReplicaMembershipRepository`, `ParkedEventRepository` (plain JDBC, insert only). |
| `adapters.config` | `RosterSourceProducer`: `hoops.roster.source` picks the `RosterPort` and the tenant filter's `AuthzContextResolver`. |
| `adapters.out.time` | `RegistryTenantClock`, `Clock` producer. |

New WP9/WP10 code adds sibling packages/classes in the same layers (e.g. `domain.plan`, `application.ManagePlans`,
entities + `V2__...sql`) and reuses `TrainingAccess`, `RosterPort`, `CallerActor`, `PatchBody`, `PageDto`.

## Operations (WP17)
- `/q/health/live`, `/q/health/ready` (datasource check + `core-service` indicator), `/q/health/started`
  (`quarkus-smallrye-health`). The core indicator (`com.hoopsacademy.common.client.CoreReachabilityCheck`, shared from common-quarkus) is always UP and only
  reports `data.core = reachable|unreachable` from core's `/q/health/live` (timeout `hoops.core.health-timeout`, 1 s;
  cached `hoops.core.health-cache-ttl`, 10 s): a core outage must not take this service out of rotation, requests
  answer 503 Problems on their own. Helm probes use the http paths.
- `/q/metrics` (Prometheus), OpenTelemetry (SDK off unless `QUARKUS_OTEL_SDK_DISABLED=false`), JSON logs in prod with
  `tenantId`/`traceId` MDC, security headers, CORS allow-list and the 2 MB body limit come from common-quarkus defaults.
- Credentials have no fallback values: `*_PASSWORD` / `*_CLIENT_SECRET` must be set in the environment (a missing
  variable fails the start; `NoBuiltInCredentialsTest`).

## Configuration
| Property | Default | Meaning |
|---|---|---|
| `quarkus.datasource.*` | user `athlete_app`, `ATHLETE_APP_PASSWORD`, `ATHLETE_DB_URL` | runtime datasource (non-owner role, RLS applies) |
| `quarkus.flyway.*` | user `athlete_migrator`, `ATHLETE_MIGRATOR_PASSWORD` | migrations |
| `quarkus.oidc.*` / `quarkus.oidc-client.*` | `KEYCLOAK_URL`, client `athlete-service`, `ATHLETE_SERVICE_CLIENT_SECRET` | end-user JWT validation / client credentials for `/internal` calls |
| `hoops.core.url` | `http://localhost:8081` | core-service base URL |
| `hoops.core.cache-ttl` | `30S` | cache of the shared core client (common-quarkus default) |
| `hoops.athlete.default-timezone` | `Europe/Madrid` | tenant zone only when the caller's `AuthzContext` carries none (older core) |
| `hoops.athlete.horizon-weeks` | `8` | materialisation horizon |
| `hoops.athlete.materialise.cron` | `0 15 2 * * ?` | nightly job (`off` disables) |
| `hoops.roster.source` | `rest` (`ATHLETE_ROSTER_SOURCE`) | `rest` = core's `/internal` API; `replica` = local replica (needs the consumer) |
| `hoops.roster.consumer.enabled` | `true` (`ATHLETE_ROSTER_CONSUMER_ENABLED`) | the replica consumer (group `athlete-service.roster`); off in the default test profile |
| `hoops.roster.replica.max-attempts` | `5` | tries per record on a database failure before the channel fails |
| `kafka.bootstrap.servers` | `KAFKA_BOOTSTRAP_SERVERS`, `localhost:19092` (prod) | broker; `KAFKA_SECURITY_PROTOCOL`, `KAFKA_SASL_USERNAME` (`athlete-service`), `KAFKA_SASL_PASSWORD` for the chart |

## Materialisation
`MaterialiseSessions` creates sessions for the next 8 weeks. A `(schedule_id, starts_at)` pair is unique in the
database and checked in the use case, so re-running creates nothing and a CANCELLED session (its row stays) is never
recreated. On schedule create/update untouched future sessions (PLANNED, never patched, no attendance) are moved or
removed to match; sessions staff edited (`manually_edited`) or that have attendance are kept. Ending a schedule
deletes its future PLANNED sessions without attendance.

The nightly job needs the list of tenants. This service has no platform datasource, so it keeps the global table
`athlete.tenant_registry (id, timezone)` (no `tenant_id` column, no RLS, declared in `RlsSchemaMetaTest.globalTables()`).
A tenant is registered (with the zone from the caller's `AuthzContext.timezone`) when a schedule or ad-hoc session is
created. The job runs under `TenantScope.runExclusive("athlete.materialisation", ...)` (one replica at a time, Postgres
advisory lock) and each tenant through `TenantScope.runAs` so RLS applies.

## Training plans (WP9)
`training_plan` / `plan_item` hold the tenant's plans and the global templates (`owner_tenant_id is null`, seeded by the
repeatable `R__plan_templates.sql`, English, `locale = 'en'`; the UI translates template names by id). The owner column
is not called `tenant_id` and the tables use per-command policies (read: templates + own; write: own only), so they are
declared in `AthleteRlsSchemaMetaTest.nullableTenantTables()` (owner column `owner_tenant_id`; the common inspector checks
forced RLS and one policy per command) and proved by `TemplateRlsIsolationTest`. Their JPA entities carry
no `@TenantId` (Hibernate's discriminator filter would hide templates). Templates are copied on use (`POST
/training-plans/{id}:copy`); direct edits answer 403 `PLAN_IS_TEMPLATE`. Assignments are `team xor player`; a team
assignment is expanded against the CURRENT roster when read. `POST /training-plans/{id}:archive|:unarchive` toggles
`archived` (archived plans leave lists and cannot be assigned); `GET /plan-assignments/{id}/progress` returns counts by
status plus one line per visible target.

## Contract notes (WP2c closed the earlier gaps)
1. **Tenant time zone** comes from `AuthzContext.timezone` (core); `hoops.athlete.default-timezone` is only a fallback.
2. **Teams of a player**: `AuthzContext.playerTeamIds` (core). PARENT/PLAYER list calls without `teamId` return the
   sessions/schedules of those teams (empty when there are none); single-team access accepts a team in
   `playerTeamIds` and otherwise still looks for the caller's players in `GET /internal/teams/{id}/roster`.
3. **Person display names**: `PersonRef.displayName` for `recordedBy` is a snapshot of the token's `name`
   (fallback `preferred_username`, then `Member`) stored in `*_by_name` columns.
4. **503** (`UPSTREAM_UNAVAILABLE`) is declared on every `/api/athlete/**` operation (`common.yaml` `ServiceUnavailable`).

## Testing notes
* `@TenantUser` (common test-jar) drives auth. The test-jar's `TestAuthzContextResolver` overrides the production
  `RosterAuthzResolver` (common-quarkus) in every `@QuarkusTest`; the production resolver is unit-tested in common and
  exercised here by `RealResolverApiTest` (`@TestProfile` that sets `quarkus.arc.exclude-types` for the test
  resolver, with membership served by WireMock).
* core-service and the Keycloak token endpoint are WireMock (`CoreMockResource`, stubs via `CoreStubs`); the adapter
  cache is cleared with `CoreRosterAdapter.clearCache()` between tests.
* All REST Assured calls go through `ApiSupport.api(tenant)`, which validates request and response against
  `/openapi/athlete.yaml` (swagger-request-validator); `lenient(...)` validates only the response, for deliberately
  invalid requests.
* RLS: `AthleteRlsSchemaMetaTest`, `AthleteGenericRlsIsolationTest`.
* Roster replica: `RosterPortContract` / `MembershipContract` (application test package) run on both sources
  (`Rest*ContractTest` with WireMock, `Replica*ContractTest` fed with `CoreEvents`, records built and validated against
  libs/contracts/events). The Kafka tests (`CoreRosterConsumerTest`, `RosterReplayTest`, `ReplicaSourceApiTest`) use
  `ReplicaProfile` (consumer on, `source=replica`, no core) and publish with `CoreTopics` to Dev Services Redpanda.
