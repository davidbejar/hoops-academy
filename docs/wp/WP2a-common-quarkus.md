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
- [ ] filter: missing header 400; malformed 400; non-member 404; member → context populated; `/platform` skipped
- [ ] interceptor: variable set within tx, not visible after commit; `REQUIRES_NEW` gets its own value; `runAs` clears
- [ ] sample migration in test resources (table `sample.widget`) → meta-test passes; dropping the policy makes it fail
- [ ] generic isolation test passes against the sample table for A/B tenants, incl. 42501 on cross insert and raise when unset
- [ ] Problem+JSON shape verified for each mapper; no stack traces
- [ ] module coverage ≥ 85 %
