# WP3 — core-service: tenancy, identity & membership, platform endpoints, logo

Model: Opus. Depends on: WP1, WP2a, WP2b. Lane CORE. ADRs: 0005, 0006, 0007, 0009. Contract: `libs/contracts/openapi/core.yaml`.
Skills: test-driven-development, quarkus-hexagonal-service, tenant-isolation-testing, owasp-security (uploads, authz).

## Scope
- Module `services/core-service` (Quarkus: rest-jackson, hibernate-orm-panache or plain JPA, jdbc-postgresql, flyway, oidc,
  oidc-client, rest-client-jackson, scheduler, smallrye-openapi, smallrye-health, micrometer-registry-prometheus,
  hibernate-validator, keycloak-admin-client). Package `com.hoopsacademy.core`. Two datasources: default (`core_app`),
  `platform` (`core_platform`). Flyway as `core_migrator`.
- Flyway V1–V4: `tenant` (id, slug unique, name, status, timezone, age_rule, max_play_up_levels, default_locale es|en|id,
  created_at, withdrawn_at; policy: app role sees `id = app.current_tenant()`, platform role sees all),
  `tenant_settings`, `tenant_logo` (ADR-0009), `app_user` (keycloak_sub unique, email; not tenant-scoped; policy: readable
  only through person joins — restrict with a policy allowing rows referenced by a person of the current tenant),
  `person`, `membership_role`, `player`, `guardian_link`, `usage_snapshot`, `outbox`, `billing.plan`,
  `billing.tenant_subscription`; all tenant tables via `app.enable_tenant_rls`; explicit grants to `core_platform`.
- Use cases: CreateTenant (platform: tenant + default settings + seeded age categories placeholder hook for WP4 + first
  ADMIN person+membership + Keycloak user provisioning with required action email), SuspendTenant, WithdrawTenant,
  GetMe (memberships across tenants from `app_user` → persons), tenant profile get/patch, logo upload/get/delete
  (magic-byte sniffing, ≤ 512 KB, ETag = sha256, Cache-Control private max-age=86400, 304 on If-None-Match),
  members (list/invite/get/patch roles/deactivate; invite = create person (+ app_user placeholder) + Keycloak user +
  execute-actions email), guardian links CRUD, `/internal/authz/{tenantId}/{sub}` (AuthzContext: roles, staffTeamIds
  (from WP4 tables — return empty until WP4), linkedPlayerIds, ownPlayerId), `/internal/usage/{tenantId}` (counts),
  `AuthzContextResolver` implementation reading the DB (with a 10 s request-scoped cache), `EntitlementService` port +
  `NoopEntitlementService`, `OutboxWriter` (insert only; publisher is WP19).
- Suspended/withdrawn tenant: tenant filter returns 404 for `/api/**` (treat as non-member) — implement in the
  core resolver and expose `status` in `/internal/authz` so other services do the same.
- Keycloak adapter: `keycloak-admin-client` with service-account credentials; wrap in `IdentityProviderPort`; WireMock
  in tests; a CI-only `@Tag("keycloak")` test with `testcontainers-keycloak` realm import.

## Acceptance
- [ ] `RlsSchemaMetaTest` + `GenericRlsIsolationTest` subclasses pass for schema `core` (+ `billing` global tables allow-listed)
- [ ] cross-tenant 404 tests for every resource; role-matrix tests for members/guardian-links/tenant profile/logo
- [ ] super_admin without membership → 404 on `/api/core/**`; non-super_admin → 403 on `/platform/**`
- [ ] logo: PNG/JPEG/WebP accepted, SVG/GIF/oversize rejected (415/413 Problem), ETag/304 works, parent gets 403 on PUT
- [ ] CreateTenant is atomic (Keycloak failure → no tenant row); suspended tenant → 404 for members
- [ ] every response validated against core.yaml with swagger-request-validator; `./mvnw -pl services/core-service verify` green, coverage ≥ 80 %
