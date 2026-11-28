---
name: quarkus-hexagonal-service
description: How to add a use case, REST endpoint, persistence adapter or Flyway migration to a Hoops Academy Quarkus service while respecting hexagonal layering, tenancy (RLS) and contract-first rules. Use whenever changing code under services/*.
---

# Adding behaviour to a Quarkus service (Hoops Academy)

## Layering (enforced by ArchUnit in every service)
```
com.hoopsacademy.<svc>
├── domain/            pure Java: entities, value objects, domain services, domain events, ports? NO (ports live in application)
├── application/       use cases (one class per command/query), ports (interfaces) the adapters implement
└── adapters/
    ├── in/rest/       JAX-RS resources, DTO mapping, @RequiresTenantRole, request validation
    ├── out/persistence/  JPA entities + repositories implementing application ports
    ├── out/client/    REST clients to other services (e.g. RosterPort adapter — a thin mapping over
    │                  common-quarkus' shared CoreRosterClient for core /internal/**)
    └── out/keycloak/  Keycloak admin client adapter (core only)
```
- `domain` imports nothing from Jakarta/Quarkus/Hibernate. Identity types are value objects (`TenantId`, `PlayerId`).
- Transactions start in `application` use cases (`@Transactional`), never in resources (the tenant interceptor
  binds to the transaction to run `set_config('app.tenant_id', …, true)`).
- Resources only: parse → authorize (`@RequiresTenantRole`, `Authz`) → call use case → map to DTO.

## Checklist for a new endpoint
1. **Contract first**: add/modify the path in `libs/contracts/openapi/<svc>.yaml` (schemas, Problem responses,
   `X-Tenant-Id` header param). Run `./mvnw -pl libs/contracts verify`.
2. **Red**: write the failing `@QuarkusTest` REST test (REST Assured + `@TenantUser(tenant=A, roles=…)`), including
   the negative role-matrix cases and the cross-tenant 404 case. Add contract validation
   (the service's `Contract` filter in its test support, built on common's `ContractFilters`) to the test.
3. **Red**: write the use-case unit test (pure, Mockito for ports).
4. **Green**: domain → use case → adapter, minimal code.
5. **Migration** (if a table changes): `V<nn>__<name>.sql`; for tenant tables call
   `select app.enable_tenant_rls('<schema>.<table>');` right after `create table`. Grants to `<svc>_app` are
   handled by default privileges in `infra/db/init`; never grant to PUBLIC.
6. Run `just test`. The RLS meta-test will fail if a tenant table lacks RLS.
7. Update the handover section of the current WP file.

## Persistence rules
- Entities with a `tenantId` field annotate it with `@TenantId` (Hibernate discriminator multitenancy).
- Global tables (no tenant column) are listed in `RlsSchemaMetaTest.globalTables()` with a reason; shared
  global+tenant tables (nullable owner) in `nullableTenantTables()` (see the tenant-isolation-testing skill).
- No native SQL outside `*Repository` classes; prefer JPQL/Panache queries. Pagination on every list endpoint:
  build a paged search with common's `persistence.PagedQuery` + `QueryConditions` (constant fragments, bound
  parameters) and answer with `paging.PageRequest` / `PageResult` / `PageMeta` (ADR-0069), not a builder of your own.
- Optimistic locking (`@Version`) on aggregates that are edited concurrently (match, approval request).

## Talking to core (game, athlete)
Use `com.hoopsacademy.common.client`: `CoreRosterClient` (team roster, players batch, membership; 30 s cache
`hoops.core.cache-ttl`, base URL `hoops.core.url`, 2 s timeouts) behind the service's own `RosterPort` adapter.
`RosterAuthzResolver` is common's `@DefaultBean` tenant-filter resolver. The caller's `AuthzContext` carries
`timezone` and `playerTeamIds` (teams of own/linked players) — use them instead of extra core calls.
With the replica source (the default), the event pipeline is common's `com.hoopsacademy.common.replica` (envelope
decoder, consumer loop with one retry policy, meters, history and parking stores, retention run; ADR-0062): a service
writes only its payload mapper (`EventMapper`), its appliers and thin `@Scheduled` / consumer shims. The membership
rule is common's `authz.MembershipRule` (ADR-0066): a service implements `MembershipReads` (replicas) or
`MemberRelations` (core) on its own tables and never re-writes the rule; `MembershipRuleContract` (test-jar) runs the
authz-matrix cases against it. A change of the rule names finance-service's Go copy in the same PR.
Readiness: common's `CoreReachabilityCheck` adds an always-UP `core-service` check (`data.core = reachable|unreachable`)
to every service that depends on common; a service that must not probe core sets
`hoops.core.reachability-check.enabled=false` (build-time, as core does). Database spans (ADR-0074): common sets
`quarkus.datasource.jdbc.telemetry=true` and the `DatabaseSpansNeedAParent` sampler, which refuses to start unless
`quarkus.otel.traces.sampler` is `parentbased_traceidratio`; never put a value into a span attribute (each service's
`DatabaseSpansTest` greps the exported spans). Test lock contention by releasing the other
connection's advisory lock explicitly (`pg_advisory_unlock`), never by closing the connection.

## Scheduled jobs
Wrap multi-tenant jobs in `tenantScope.runExclusive(LOCK, ...)` so only one replica runs them; `@Scheduled` methods
return `void` (call a `boolean run()` from them if tests need the outcome).

## Error handling
Throw common's `com.hoopsacademy.common.problem` exceptions (`DomainRuleViolation` or a subclass of it, 422;
`NotFoundException`, 404; `ConflictException`, 409; `InvalidRequestException` with every violation, 400; ADR-0069);
`common-quarkus` maps them to Problem+JSON, plus a wrong-type body value -> 400 `validation`, `UnauthorizedException` -> 401, `OptimisticLockException`/`StaleStateException` (also
wrapped) -> 409 `CONCURRENT_MODIFICATION`, `UpstreamUnavailableException` -> 503 `UPSTREAM_UNAVAILABLE`. Do not add
service-local mappers for these. Never return stack traces or internal ids of other tenants.

## Shared configuration and helpers (ADR-0069)
Settings every Quarkus service shares (Dev Services topics, broker defaults, db-kind, OIDC role path and realm URL
`OIDC_AUTH_SERVER_URL` (ADR-0071), OTel build keys, the test profile's OIDC and JaCoCo keys) live once in common's
`META-INF/microprofile-config.properties`: do not restate them in a service's `application.properties`, and do not
repeat a property's value as a `@ConfigProperty` `defaultValue` (`LibraryDefaultsContract` checks it). Also shared:
`i18n.AppLanguage` / `AcceptLanguage`, the UTC `Clock` (`time.ClockProducer`, `@DefaultBean`), the pdf-service client
(`client.PdfServiceClients`). Test support in the test-jar: `ContractFilters`, `LogCapture`,
`RlsTestDatabase.bindTenant`, `NoBuiltInCredentialsContract`. Test-library versions and build blocks (surefire groups,
JaCoCo with the 90 % `domain` rule, `keycloak-it`) are in the root pom. Domain code stays per service.

## /api paths without a tenant
Exact `/api/**` paths listed in `hoops.tenancy.exempt-paths` (default `/api/core/me`) skip the tenant filter; annotate
such resources `@Authenticated`.
