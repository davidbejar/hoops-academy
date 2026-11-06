# ADR-0035: Core 3.0.0 removes the deprecated `resendTenantAdminInvitation` alias

- Status: Accepted
- Date: 2026-11-06
- Completes: ADR-0024 §7 (the alias "is removed in core 3.0.0")
- Related: decision 41 of 2026-11-06, WP59, WP24, WP25, ADR-0016 (template of a major contract change),
  ADR-0027, versioning policy in `libs/contracts/README.md`

## Context
ADR-0024 renamed `POST /platform/tenants/{tenantId}/admins/{personId}/resend-invitation` to `…/temporary-password`
(`issueTenantAdminTemporaryPassword`, 200) because nothing is sent any more, and kept the old path as a deprecated
alias (`resendTenantAdminInvitation`, 202, same behaviour) so core 2.3.0 stayed additive while the web build switched.
WP25 switched the platform admin screen to the new operation; since then nothing in the repository calls the alias.
It still doubled the surface that issues a temporary password (two paths, two status codes, two tests to keep in step)
and generated a deprecated method into the Dart client. Removing an operation is a major change under the versioning
policy, so it waited for a deliberate bump.

## Decision
1. **Core 3.0.0.** The only breaking item: the path `/platform/tenants/{tenantId}/admins/{personId}/resend-invitation`
   and its operation `resendTenantAdminInvitation` are removed from `core.yaml`. Every other operation, schema and
   status code is unchanged; game, athlete and common keep their versions. The contracts tests that pin
   "core ≥ 2.x" keep passing; `TemporaryPasswordContractTest` asserts the path and the operation are gone.
2. **Service.** `PlatformAdminResource` loses the alias method; the old path answers 404 (no route) and changes
   nothing (no Keycloak call, no audit row), covered by `PlatformAdminResourceTest`. The behaviour of
   `issueTenantAdminTemporaryPassword` and its tests are untouched.
3. **No parallel path, no redirect.** Services and the web app are released together from the monorepo (versioning
   policy), and there is no client outside this repository, so the path is not kept alive in any form.

## Consequences (migration note)
- **Clients:** replace `POST …/admins/{personId}/resend-invitation` (202) by
  `POST …/admins/{personId}/temporary-password` (200); the body (`TenantAdminWithPassword`, `Cache-Control:
  no-store`) and the errors (404, 409 `INVITATION_NOT_PENDING` / `TENANT_WITHDRAWN`, 502) are the same.
  In the generated Dart client `PlatformApi.resendTenantAdminInvitation` becomes
  `PlatformApi.issueTenantAdminTemporaryPassword`.
- **This repository:** `just gen-api` regenerates `apps/web/packages/core` (3.0.0) and `apps/web/pubspec.lock`; the web
  app needs no code change (it already uses the new operation). Outside this repository: none.
- The web demo backend (`apps/web/lib/core/mock/mock_platform_api.dart`) still answers the old path as well; it is
  never reached by the generated client and is dropped by the mock's owner.
- No database migration, no grant, no Keycloak change.

## Alternatives considered
- Keep the alias indefinitely — rejected: a second write path for temporary passwords with no caller.
- Answer 410 Gone on the old path for a release — rejected: no external client exists, and an extra route would need
  its own contract entry and tests.
