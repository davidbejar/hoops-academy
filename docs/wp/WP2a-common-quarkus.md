# WP2a — libs/common-quarkus: tenant context, RLS, authz, Problem+JSON, test fixtures

Model: Opus. Depends on: WP0. Parallel with WP1, WP2b. ADRs: 0005, 0006. Skills: tenant-isolation-testing,
quarkus-hexagonal-service, owasp-security.

## Scope (main jar)
- `TenantId`, `TenantContext` (@RequestScoped), `AuthzContext` record {sub, personId, tenantId, roles (EnumSet<TenantRole>),
  staffTeamIds, linkedPlayerIds, ownPlayerId}; `TenantRole` enum (ADMIN, COACH, ASSISTANT_COACH, PARENT, PLAYER).
- `TenantHeaderFilter` (ContainerRequestFilter, priority AUTHENTICATION+10) for `/api/**`: requires authenticated JWT,
  parses `X-Tenant-Id` (400 if missing/malformed), resolves `AuthzContext` through an `AuthzContextResolver` port
  (implemented by each service: core from DB, others via RosterPort), non-member → 404 Problem. Skips `/platform/**`,
  `/internal/**`, `/q/**`.
- `@RequiresTenantRole({…})` interceptor (any-of semantics) → 403 Problem when the context lacks the role; `Authz` helper
  (`isStaffOf(teamId)`, `isGuardianOf(playerId)`, `isSelf(playerId)`).
- `TenantTransactionInterceptor`: bound to `@Transactional` (priority after Narayana), executes
  `select set_config('app.tenant_id', ?, true)` on the current connection when a TenantContext is present;
  `TenantScope.runAs(TenantId, Supplier)` for jobs (own transaction, sets variable, clears context after).
- Hibernate `TenantResolver` (`quarkus.hibernate-orm.multitenant=DISCRIMINATOR`) returning the context tenant.
- `ServiceTokenClientFilter` (client-credentials via `quarkus-oidc-client`) + `TenantHeaderPropagationFilter` for REST clients.
- Problem+JSON exception mappers: `NotFoundException`→404, `ConflictException`→409, `DomainRuleViolation`→422,
  `ConstraintViolationException`→400, fallback→500 without details; `traceId` field from OpenTelemetry context if present.
- Config: `hoops.tenancy.header=X-Tenant-Id`.

## Scope (test-jar)
- `PostgresRlsResource` (QuarkusTestResourceLifecycleManager): Testcontainers `postgres:17` with
  `infra/db/init/01_roles_schemas.sql` mounted (path resolved relative to the module), exposes datasource URLs for
  `migrator` and `app` roles; Flyway configured to run as migrator (`quarkus.flyway.username`) while the default
  datasource uses the app role.
- `RlsSchemaMetaTest`, `GenericRlsIsolationTest` abstract classes (see skill tenant-isolation-testing).
- `@TenantUser(tenant, roles, personId…)` composed test annotation using `@TestSecurity` + `@OidcSecurity` claims, plus a
  test `AuthzContextResolver` that reads a static registry populated by the annotation.
- ArchUnit rule set as a reusable `HoopsArchitectureRules` (layering, no @Transactional in resources, no native SQL
  outside repositories, no `tenantId` field without `@TenantId`).

## Acceptance (all as tests in the module)
- [x] filter: missing header 400; malformed 400; non-member 404; member → context populated; `/platform` skipped
- [x] interceptor: variable set within tx, not visible after commit; `REQUIRES_NEW` gets its own value; `runAs` clears
- [x] sample migration in test resources (table `sample.widget`) → meta-test passes; dropping the policy makes it fail
- [x] generic isolation test passes against the sample table for A/B tenants, incl. 42501 on cross insert and raise when unset
- [x] Problem+JSON shape verified for each mapper; no stack traces
- [x] module coverage ≥ 85 %

## Handover

### Built
Main jar `com.hoopsacademy:common-quarkus` is a CDI bean archive (`META-INF/beans.xml`), so services discover its
beans without extra config. Package root `com.hoopsacademy.common`:
- `tenancy`: `TenantId` (strict canonical UUID), `TenantRole`, `AuthzContext` (any-of roles, `isStaffOf`,
  `isGuardianOf`, `isSelf`), `TenantContext` (@RequestScoped), `AuthzContextResolver` port, `TenantHeaderFilter`
  (AUTHENTICATION+10, `/api/**` only: 401 / 400 missing / 400 malformed / 404 non-member), `TenantTransactions` +
  `TenantTransactionInterceptors` (bound to `@Transactional` REQUIRED/REQUIRES_NEW/MANDATORY/SUPPORTS, priority 210),
  `TenantScope.runAs`, `CurrentTenant`, `HibernateTenantResolver`, `TenancyExceptionMappers` (bad tenant param → 400).
- `authz`: `@RequiresTenantRole` + interceptor (priority 100, before transactions; method-level replaces class-level),
  `Authz` (`isAdmin`, `hasAnyRole`, `isStaffOf`, `isGuardianOf`, `isSelf`, `require(allowed, reason)` → 403).
- `problem`: `Problem` record (type `urn:hoops:problem:<slug>` or `about:blank`, title, status, detail, instance,
  traceId, code, violations[{field, code, message}]; nulls omitted), `ProblemType`, `ProblemExceptionMappers`,
  domain exceptions `NotFoundException` 404 / `ConflictException` 409 / `DomainRuleViolation` 422 (+ `reasons`) /
  `AccessDeniedException` 403, all extending `CodedProblemException` (optional `code`). Also mapped:
  `ConstraintViolationException` → 400 validation with violations, `WebApplicationException` → its status,
  Quarkus `ForbiddenException` → 403, anything else → 500 with no detail (logged with traceId).
- `client`: `ServiceTokenClientFilter` (default `quarkus-oidc-client`, token cached until expiry/refresh interval),
  `TenantHeaderPropagationFilter` (forwards the bound tenant; keeps an explicitly set header).
- `META-INF/microprofile-config.properties` (ordinal 100): `hoops.tenancy.header=X-Tenant-Id`,
  `quarkus.hibernate-orm.multitenant=DISCRIMINATOR`, `quarkus.datasource.jdbc.additional-jdbc-properties.stringtype=unspecified`.

Test-jar contains only `com.hoopsacademy.common.testing.*` + `beans.xml` + the JUnit callback service files:
`PostgresRlsResource`, `RlsTestDatabase`, `TestRolePasswords`, `RlsSchemaMetaTest`, `RlsSchemaInspector`,
`GenericRlsIsolationTest`, `RlsIsolationCheck`, `ColumnFixture`, `@TenantUser`, `TenantUserRegistry`,
`TestAuthzContextResolver`, `TenantUserCallback`, `HoopsArchitectureRules`. It does not ship this module's own
tests, `application.properties` or sample migration.

### How verified
`source scripts/env.sh && ./mvnw -pl libs/common-quarkus clean verify` → **BUILD SUCCESS, 112 tests, 0 failures,
0 errors, 0 skipped; JaCoCo lines 97.8 % (269/275), branches 92.1 %; gate `jacoco.line.minimum=0.85` met; 0 compiler
warnings.** Quarkus-loaded classes are counted via `quarkus-jacoco`, which writes to the same `target/jacoco.exec`.
Each item below was written test-first and seen failing before it was implemented.

Acceptance evidence:
- Filter: `TenantHeaderFilterTest` (9): member → context populated (tenant, sub, roles); missing 400; malformed
  400; non-member 404; super_admin without membership 404; unauthenticated 401 Problem; `/platform`, `/internal`
  and the look-alike `/apiary` are skipped. The resolver runs on a worker thread, so a blocking DB resolver is fine.
- Interceptor: `TenantTransactionInterceptorTest` (5) checks that the variable is set in the tx and is gone after
  commit on the same pooled backend (matched by `pg_backend_pid`). REQUIRES_NEW runs on a different backend with
  its own value, and MANDATORY joins the outer tx. With no tenant nothing is set and `app.current_tenant()` raises.
  SUPPORTS without a tx sets nothing. `TenantScopeTest` (6): own tx, clears/restores the context (also when the work
  throws), works with no request context (job thread), RLS isolation A/B, rollback on failure.
  `InternalTenantScopeTest` (2): `runAs` from an `/internal` resource with `?tenantId=` works; malformed → 400.
  `HibernateTenantResolverTest` (2): Hibernate fills `tenant_id`; other tenants' entities are invisible.
- Sample migration `src/test/resources/db/migration/V1__sample_tables.sql`: `core.sample_widget`,
  `core.sample_widget_part` (tenant-scoped composite FK), global `core.sample_colour`. `SampleRlsSchemaMetaTest`
  passes. `RlsSchemaInspectorTest` (8) mutates the schema in rolled-back migrator transactions and detects each
  breakage: dropped policy, policy not using `app.current_tenant()`, NO FORCE, RLS disabled, nullable tenant_id,
  undeclared global table, stale global declaration.
- Generic isolation: `SampleGenericRlsIsolationTest` runs 2 dynamic tests (widget, part with a fixture override).
  Each checks that A sees exactly 1 row, cannot update or delete B's row, gets 42501 on a cross-tenant insert, and
  that a select with the variable unset raises 42501. `RlsIsolationCheckTest` (4) shows the check *fails* for a
  leaky SELECT policy and for `WITH CHECK (true)`, and explains a missing FK override. This caught a real bug:
  a cross-tenant insert with `RETURNING` hides a lax WITH CHECK, because the SELECT policy rejects the returned row.
  The check now inserts without RETURNING.
- Problem+JSON: `ProblemExceptionMappersTest` (15) checks the content type, type/title/status/detail/instance for
  every mapper, `code` and 422 reasons, code omitted when absent, query and body validation, malformed JSON, 405, and
  that a 500 has no detail, exception name or stack trace. `ProblemTest` (9) covers traceId from the MDC and omitted
  nulls.
- Coverage ≥ 85 %: 97.8 %.
- Also: `PostgresRlsResourceTest` (app runs as `core_app`, not superuser, no BYPASSRLS; tables owned by
  `core_migrator`), `HoopsArchitectureRulesTest` (9: good fixture passes, 6 violation fixtures each reported, test
  classes skipped), `CommonLibraryArchitectureTest` (no package cycles), client filter unit tests (7) + wiring test.

### Decisions
- **ADR-0011** (new) records: one interceptor per `TxType`, because `TxType` is a binding member; a
  `TransactionSynchronizationRegistry` marker so nested joins don't repeat `set_config`; always `is_local = true`.
  It also records that entities use `@TenantId String tenantId` over a `uuid` column with `stringtype=unspecified`.
  The reason: Quarkus only passes String tenant ids to Hibernate, and Hibernate rejects them for UUID fields.
  Rejected alternatives are listed in the ADR.
- The sample tables are `core.sample_*`, not `sample.widget`, so the real migrator/app privilege model is exercised.
- `@TenantUser` composes `@TestSecurity(user="tenant-user")` + `@OidcSecurity(sub="tenant-user")`. A JUnit Quarkus
  callback registers the membership. `TestAuthzContextResolver` is `@Alternative @Priority(1)`, so it overrides the
  service's resolver wherever the test-jar is present.
- traceId comes from the logging MDC key `traceId` (set by quarkus-opentelemetry). No otel dependency.
- `Problem` carries the optional `code` and `violations[].code` of `libs/contracts/openapi/common.yaml`.
- Module pom: `assertj-core 3.27.7` and `maven-jar-plugin 3.5.1` have explicit versions here (not managed by the
  parent; the root pom is unchanged). It uses `quarkus-junit`/`quarkus-junit-mockito` (the relocated names of
  `quarkus-junit5*`) and `quarkus-jacoco`.

### How services use it
`pom.xml` (test deps are not transitive through the test-jar, so declare them):
```xml
<dependency><groupId>com.hoopsacademy</groupId><artifactId>common-quarkus</artifactId></dependency>
<dependency><groupId>com.hoopsacademy</groupId><artifactId>common-quarkus</artifactId><type>test-jar</type><scope>test</scope></dependency>
<!-- test: quarkus-junit, quarkus-test-security-oidc, testcontainers-postgresql, rest-assured, archunit-junit5, assertj-core, quarkus-jacoco -->
```
`application.properties`:
```properties
quarkus.datasource.db-kind=postgresql
quarkus.flyway.schemas=game
quarkus.flyway.create-schemas=false
quarkus.hibernate-orm.schema-management.strategy=none
%test.quarkus.datasource.devservices.enabled=false
%test.quarkus.keycloak.devservices.enabled=false
%test.quarkus.oidc.tenant-enabled=false
%test.quarkus.jacoco.data-file=target/jacoco.exec
%test.quarkus.jacoco.reuse-data-file=true
%test.quarkus.jacoco.report=false
# multitenant=DISCRIMINATOR, stringtype=unspecified, hoops.tenancy.header come from the library defaults
```
In the jacoco plugin `prepare-agent` execution, set `<exclClassLoaders>*QuarkusClassLoader</exclClassLoaders>` and
`<append>true</append>`, as this module does. Implement the port:
`@ApplicationScoped class RosterAuthzResolver implements AuthzContextResolver`. It is called with the requested
tenant already bound, so RLS-protected lookups work.

Resource + test:
```java
@Path("/api/game/teams/{teamId}/matches")
@RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH, TenantRole.ASSISTANT_COACH})
public class MatchResource {
  @Inject Authz authz; @Inject CreateMatch createMatch;          // use case is @Transactional
  @POST public MatchDto create(@PathParam("teamId") UUID teamId, @Valid CreateMatchRequest req) {
    authz.require(authz.isAdmin() || authz.isStaffOf(teamId), "Not staff of this team");
    return MatchDto.from(createMatch.handle(teamId, req));      // throw DomainRuleViolation(msg, "PLAYER_INELIGIBLE")
  }
}

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
class MatchResourceTest {
  static final String A = "…uuid…", TEAM = "…uuid…";
  @Test @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
  void coachCreatesMatch() { given().header("X-Tenant-Id", A).contentType(JSON).body(…).post(…).then().statusCode(201); }
}
// plus: class GameRlsSchemaMetaTest extends RlsSchemaMetaTest {}  /  class GameRlsIsolationTest extends GenericRlsIsolationTest { fixtureOverrides() }
// plus: @Test void architecture() { HoopsArchitectureRules.checkProductionCode("com.hoopsacademy.game"); }
```
Jobs and `/internal` endpoints: `tenantScope.runAs(TenantId.parse(tenantIdParam), () -> useCase.run())`. REST
clients: `@RegisterProvider(ServiceTokenClientFilter.class) @RegisterProvider(TenantHeaderPropagationFilter.class)`.
Call them from worker threads, because the token fetch blocks.

### Open points
- Only the default datasource gets `app.tenant_id`. core's `core_platform` datasource is intentionally excluded;
  revisit if a named datasource ever needs tenant data.
- Code that uses `QuarkusTransaction` directly (not `TenantScope`) must call
  `TenantTransactions.bindCurrentTransaction()`.
- With `stringtype=unspecified`, a native query whose string parameter has no type context may need a cast.
- `@TenantUser` gives one membership per test. Register more with `TenantUserRegistry.register(...)`.
  `TestAuthzContextResolver` must be excluded (`quarkus.arc.exclude-types`) in tests that exercise core's real
  resolver.
- `ServiceTokenClientFilter` was verified with unit tests plus CDI wiring only. A live Keycloak round-trip belongs
  in the e2e/WP that adds Keycloak Testcontainers.
- Hibernate discriminator auto-filter is enforced only for entities. Native SQL relies on RLS alone (by design,
  ADR-0006).
