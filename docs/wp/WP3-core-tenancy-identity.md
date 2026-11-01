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
- [x] `RlsSchemaMetaTest` + `GenericRlsIsolationTest` subclasses pass for schema `core` (+ `billing` global tables allow-listed)
- [x] cross-tenant 404 tests for every resource; role-matrix tests for members/guardian-links/tenant profile/logo
- [x] super_admin without membership → 404 on `/api/core/**`; non-super_admin → 403 on `/platform/**`
- [x] logo: PNG/JPEG/WebP accepted, SVG/GIF/oversize rejected (415/413 Problem), ETag/304 works, parent gets 403 on PUT
- [x] CreateTenant is atomic (Keycloak failure → no tenant row); suspended tenant → 404 for members
- [x] every response validated against core.yaml with swagger-request-validator; `./mvnw -pl services/core-service verify` green, coverage ≥ 80 %

## Handover

### Built
Module `services/core-service` (Quarkus 3.40.1, port 8081), package `com.hoopsacademy.core`, hexagonal:
- `domain` (pure): `tenant` (`Tenant` lifecycle ACTIVE→SUSPENDED→ACTIVE / →WITHDRAWN with retention, `TenantSlug`,
  `TenantProfile`(+`Changes`), `TenantSettings`, `AgeRule`, `TenantStatus`), `identity` (`AppUser`, `UserId`),
  `membership` (`Person` with additive roles + PLAYER invariant, `PersonalData`(+`Changes`), `LastAdminRule`,
  `GuardianLink`, ids `PersonId`/`PlayerId`/`GuardianLinkId`, `Gender`, `InvitationStatus`, `PlayerStatus`),
  `logo` (`LogoImage`: magic bytes PNG/JPEG/WebP, ≤ 524 288 bytes, ETag = quoted sha256, If-None-Match matching),
  `shared` (`AppLocale`, merge-patch `Patch<T>`, `Require` guards).
- `application`: use cases `platform` (`CreateTenant` saga, `TenantRegistration`, `TenantContentProvisioning`,
  `TenantLifecycle`, `PlatformTenantQueries`), `tenant` (profile, settings, logo), `members` (`InviteMember`,
  `MemberProvisioning`, `LoginProvisioning`, `MemberQueries`, `MemberCommands`, `GuardianLinkService`), `me`
  (`GetMe`, `MeLookup`), `authz` (`MembershipLookup`, `CoreAuthzContextResolver`, `AuthzCache`, `InternalAuthz`),
  `usage` (`CoreUsage`, `AggregateTenantUsage`). Ports: `TenantRepository` (platform registry),
  `SubscriptionRepository`, `TenantProfileRepository`, `TenantSettingsRepository`, `LogoRepository`,
  `AppUserRepository`, `PersonRepository`, `PlayerRepository`, `GuardianLinkRepository`, `MembershipRepository`
  (cross-tenant index), `IdentityProviderPort`, `EntitlementService`, `OutboxWriter` + `PlatformOutboxWriter`,
  `UsageCounter`, `RemoteUsagePort`, `UsageSnapshotRepository`, `StaffTeamsQuery`; extension points
  `TenantProvisioningHook`, `TenantSettingsListener`.
- `adapters`: `in/rest` (`/api/core/me`, `/tenant`, `/tenant/settings`, `/tenant/logo`, `/members/**`,
  `/guardian-links/**`), `in/platform` (`/platform/tenants/**` incl. `reactivate` and `usage`, `@RolesAllowed
  super_admin`), `in/internal` (`/internal/authz/{tenantId}/{sub}`, `/internal/usage/{tenantId}`, role `service`),
  `in/shared` (merge-patch reader, Problem mappers for 401/413/415/502/400, caller identity); `out/persistence`
  (default PU, `core_app`, `@TenantId String tenantId` entities), `out/platform` (PU `platform` on datasource
  `platform` = `core_platform`), `out/keycloak` (quarkus-keycloak-admin-rest-client), `out/client` (game/athlete
  usage REST clients with `ServiceTokenClientFilter`), `out/billing` (`NoopEntitlementService`, `@DefaultBean`).
- Flyway (as `core_migrator`, schemas `core,billing`): `V1__tenancy` (tenant + own policies, tenant_settings,
  tenant_logo), `V2__identity` (app_user, person, membership_role, player, guardian_link, user_membership_index +
  `own_memberships` policy), `V3__platform` (usage_snapshot, outbox, billing.plan seeded `FREE`,
  billing.tenant_subscription), `V4__grants` (core_platform).
- `application.properties` (two datasources from env, OIDC realm academy / client core-service / roles
  `realm_access/roles`, oidc-client, Keycloak admin client, `%test` per WP2a), `README.md`, ADR-0013.

### How verified (fresh, 2026-11-02)
`source scripts/env.sh && ./mvnw -pl services/core-service clean verify` → exit 0, **BUILD SUCCESS, Tests run: 168,
Failures: 0, Errors: 0, Skipped: 0; "All coverage checks have been met": lines 98.6 % (1383/1403), branches 89.9 %,
domain 98.2 % (every domain package ≥ 95.7 %)**; gates in the module pom: bundle lines ≥ 0.80, `domain*`
packages ≥ 0.90. No compiler warnings.
`./mvnw -pl services/core-service test -Pkeycloak-it -Dtest=KeycloakIdentityProviderKeycloakTest` → 2/2 green against
`quay.io/keycloak/keycloak:26.8.1` with `infra/keycloak/realm-academy.json` imported (create/find/delete user,
locale attribute, failing setup e-mail → `IdentityProviderException`).
Red checks (each seen failing, then restored): RLS removed from `core.player` → meta-test + isolation test fail;
mutants in the resolver status filter, the `own_memberships` policy (`using (true)`), the compensation guard
(`created()`), the WebP magic check → each caught (`RealAuthzResolverTest`, `MembershipIndexRlsTest`,
`PlatformTenantResourceTest`/`LoginProvisioningTest`, `LogoImageTest`). The RLS and domain tests were seen red
(compile failure) before the code existed; for the REST slices tests and code were written in the same step, so the
mutation checks above are the evidence that those tests bite. (`MeResourceTest` alone does not catch the policy
mutant because the /me query also filters by sub — the policy is the second layer, pinned by `MembershipIndexRlsTest`.)

| Acceptance item | Evidence |
|---|---|
| RLS suites for `core` (+ `billing`, global tables allow-listed) | `CoreRlsSchemaMetaTest` (core+billing; global: `core.tenant`, `core.app_user`, `billing.plan` with reasons), `CoreRlsIsolationTest` (10 tables incl. `billing.tenant_subscription`), plus `TenantRegistryRlsTest` (5: app sees own row only, cannot insert/delete/change status; platform sees all, cannot read any tenant-content table, may append but not read outbox) and `MembershipIndexRlsTest` (2) |
| cross-tenant 404 for every resource; role matrix for members / guardian links / profile / logo | `anotherTenantsMembersAreNotFound`, `anotherTenantsLinksAreNotFound`, `anotherTenantsLogoIsNotFound`, `nonMembersGetNotFoundAndNeverSeeAnotherTenantsProfile`; `@ParameterizedTest` over ADMIN, COACH, ASSISTANT_COACH, PARENT, PLAYER, ADMIN+COACH, COACH+PARENT (`Members.roleSetsWithAdminFlag`) in `MemberResourceTest`, `GuardianLinkResourceTest`, `TenantResourceTest`, `TenantLogoResourceTest` |
| super_admin without membership → 404 on `/api/core/**`; non-super_admin → 403 on `/platform/**` | `RealAuthzResolverTest.superAdminWithoutMembershipGetsNotFound` (real DB resolver); `PlatformTenantResourceTest.nonSuperAdminIsForbidden` (+ anonymous 401) |
| logo PNG/JPEG/WebP accepted, SVG/GIF/oversize → 415/413 Problem, ETag/304, parent 403 on PUT | `TenantLogoResourceTest` (16): 3 formats, declared-vs-detected type, SVG/GIF by bytes and by Content-Type → 415, 524 289 B → 413 / 524 288 B → 200, 304 incl. `W/`, Cache-Control/nosniff, matrix (PARENT PUT 403) |
| CreateTenant atomic (Keycloak failure → no tenant row); suspended tenant → 404 | `keycloakFailureLeavesNoTenantBehind`, `setupEmailFailureRollsBackTheTenantAndDeletesTheNewKeycloakUser`, `databaseFailureAfterKeycloakRollsBackAndCompensatesTheKeycloakUser`, `anExistingKeycloakUserIsNeverDeletedByTheCompensation`; `RealAuthzResolverTest.suspendedAndWithdrawnTenantsAnswerNotFound` |
| every response validated against core.yaml; verify green, coverage ≥ 80 % | every REST-assured call uses `Contract.CORE` / `RESPONSES_ONLY` (forbidden request bodies) / `FAILURES` (undeclared 502/500); verify green, 98.6 % |

### Decisions (ADR-0013 unless noted)
- **Saga**: Keycloak first (find-or-create user), then the platform tx (tenant + FREE subscription), then the tenant
  tx in `TenantScope.runAs(newTenant)` (settings, hooks, person/ADMIN, `app_user`, index, outbox `tenant.created` +
  `member.invited`, setup e-mail LAST before commit). Failure → delete the registry row (`core_platform` DELETE,
  made impossible after provisioning by the FK `tenant_settings → tenant`) and delete the Keycloak user only if this
  call created it. `InviteMember` uses the same `LoginProvisioning`. Keycloak errors → **502**
  `IDENTITY_PROVIDER_UNAVAILABLE`. An e-mail that already exists in Keycloak is reused (no e-mail sent, invitation
  `ACCEPTED`); new logins start `PENDING` and become `ACCEPTED` on the first `GET /me`.
- **/me**: `core.user_membership_index(tenant_id, keycloak_sub, person_id)` is a normal RLS tenant table plus a
  SELECT policy on `app.subject`; /me binds the nil tenant + its own sub in a dedicated transaction, then reads each
  tenant's membership (roles, links, own player, profile summary, hasLogo) inside that tenant's `TenantScope`.
  Memberships of SUSPENDED/WITHDRAWN tenants and deactivated persons are omitted. `super_admin` without an
  `app_user` row is registered on first /me (needed by the tenant switcher); anybody else unprovisioned → 404.
- **Tenant registry / platform reach**: `core.tenant` has its own policies (`core_app` own row + column-level UPDATE
  on profile columns only, `core_platform` all, `core_migrator` all) and is allow-listed as global; `core_platform`
  gets tenant, usage_snapshot (select/insert), outbox (insert only), billing.*. `age_rule`/`max_play_up_levels`
  live in `tenant_settings` (tenant content), not in the registry. `app_user` has no RLS but only id/sub/email/locale.
- `GET /api/core/me` carries no `X-Tenant-Id`, but common's `TenantHeaderFilter` treats all `/api/**` as tenant
  scoped: `MePathRewriteFilter` (pre-matching) routes it to the internal path `/account/me`.
- Resolver cache: application-scoped, 10 s TTL (`hoops.authz.cache-ttl`), invalidated per tenant by every
  membership/lifecycle write in this instance (the brief's "request-scoped" cache would not outlive a request).
- Single-row tenant tables (`tenant_settings`, `tenant_logo`) are mapped with the tenant id as `@Id` (no separate
  discriminator field); RLS still applies. All other entities use `@TenantId String tenantId`.
- PATCH bodies are read as JSON merge-patch (`MergePatch`: absent/null/value), syntax errors → 400 with all
  violations, domain rules → 422. Website URLs must be absolute http(s). Unknown time zone → 422 `INVALID_TIMEZONE`.
- Response validation: requests use the swagger validator with one muted key
  (`validation.request.body.schema.additionalProperties`, false positive on the `allOf` InviteMemberRequest);
  responses are validated strictly.

### How WP4 / WP5 extend the module
- Migrations `V5+`; add new tenant tables to `CoreRlsIsolationTest.fixtureOverrides()` when they have FKs/checks
  (helpers `person`/`player` fixtures exist there).
- Replace defaults by providing beans: `StaffTeamsQuery` (team_staff → `/internal/authz` + /me `staffTeamIds`),
  `TenantProvisioningHook` (seed U8…SENIOR categories at onboarding, same tx), `TenantSettingsListener`
  (re-evaluate eligibility on rule change, same tx), `UsageCounter` (teams/seasons counters).
- Packages: `domain.eligibility`, `application.roster` / `application.approvals`, resources in `adapters.in.rest`
  (`/api/core/seasons|age-categories|teams|players|approval-requests|eligibility-cases`), internal roster/batch
  endpoints as another class in `adapters.in.internal` (use `TenantScope.runAs(tenantId query param)` like
  `InternalAuthz`). `PlayerRepository` is the place for roster columns; `POST /api/core/players` (WP5) can reuse
  `MemberProvisioning`.
- Test support: `CoreDb` (fixtures as migrator), `Members.signIn/roleSetsWithAdminFlag`, `Contract.*`,
  `WireMockResource` + `KeycloakStubs`/`UsageStubs`, `RealResolverProfile`.

### Open points
- **infra (realm)**: the `core-service` service account lacks realm-management `manage-users`/`view-users`, so
  provisioning fails against the dev Keycloak until `realm-academy.json` grants them (the keycloak-tagged test adds
  them to its realm copy: `users[service-account-core-service].clientRoles.realm-management`).
- **WP2a (common)**: exempt `/api/core/me` in `TenantScopedPaths` (then drop `MePathRewriteFilter`); add a Problem
  mapper for `io.quarkus.security.UnauthorizedException` (common has none; core's `CoreExceptionMappers` answers 401
  Problem for `/platform` and `/internal` — not verified what common's catch-all would return without it).
- **WP2b (contracts)**: declare 502 on `createTenant`/`inviteMember`; the swagger validator's `allOf` +
  additionalProperties false positive for `InviteMemberRequest`.
- Saga windows (ADR-0013): process crash between registry insert and tenant tx leaves a tenant without settings;
  commit failure after the setup e-mail leaves a dangling e-mail. Member e-mail changes are not synced to Keycloak.
- Uploads above `quarkus.http.limits.max-body-size` (2 MB) are rejected by Vert.x with a plain 413 (no Problem body);
  512 KB–2 MB get the Problem 413.
- Usage snapshots are written on every `GET /platform/tenants/{id}/usage`; scheduled snapshots belong to WP15
  (`quarkus-scheduler` not added yet).
- ADR number 0012 was chosen without seeing the other lanes; renumber on merge if it collides.
- During the red checks a read-only `git diff --stat` was run by mistake (no changes); no other git commands.
