# WP22 — Super admin manages academy administrators; login e-mail sync

Model: Opus. Depends on: WP3, WP17, WP21, ADR-0005, ADR-0013, ADR-0017, ADR-0021. Contract: `libs/contracts/openapi/core.yaml`.
Skills: test-driven-development, quarkus-hexagonal-service, tenant-isolation-testing, owasp-security, clean-code,
verification-before-completion.

The platform super admin can create/suspend/withdraw academies and set the first admin only. They must be able to
**list, add, edit and remove the administrators of any academy**, and an e-mail edit must move the Keycloak login
(username = e-mail) for both editors (super admin and academy admin).

## Decisions taken with the product owner (2026-11-02)
- **Remove** = drop the ADMIN role only; if ADMIN was the person's only role, deactivate the membership (existing
  `MemberCommands.deactivate`). The Keycloak login is never deleted or disabled (it may be used in other academies).
- **Last admin**: never removable, also not by the super admin (existing `LastAdminRule`, 409 `LAST_ADMIN`). The Problem
  `detail` must say why: an academy needs at least one active administrator; add another one first. (WP23 shows it.)
- **E-mail sync for both editors**: changing the e-mail of a person who has a login updates `core.person.email`,
  `core.app_user.email` and the Keycloak user (username = email, `emailVerified=false`, `VERIFY_EMAIL` actions mail).
  An **academy admin's** change is refused with 409 `LOGIN_SHARED` when that login is also linked to an active person in
  another tenant (no cross-tenant account takeover); the **super admin** path always syncs. Closes FOLLOW-UPS
  "Member e-mail changes are not synced to Keycloak".

## Scope
- Contract first, under `/platform/tenants/{tenantId}` (super_admin only, no `X-Tenant-Id`):
  - `GET …/admins` -> active ADMIN members: `personId, givenName, familyName, email, invitationStatus, otherRoles[]`.
    Narrow, documented exception to "super admin cannot read tenant content" (admins' identity only).
  - `POST …/admins` `{email, givenName, familyName, locale?}`: an active member with that e-mail gains ADMIN (200);
    otherwise a new member is invited with ADMIN through the existing saga (201). 409 `EMAIL_TAKEN` (inactive person) /
    `LOGIN_ALREADY_MEMBER`, 422, 502 `IDENTITY_PROVIDER_UNAVAILABLE`.
  - `PATCH …/admins/{personId}` (merge patch: `givenName`, `familyName`, `email`), 404 if not an active admin.
  - `DELETE …/admins/{personId}` (204; 409 `LAST_ADMIN`).
  - `POST …/admins/{personId}/resend-invitation` (202; 409 `INVITATION_NOT_PENDING`).
  - Tenant missing -> 404; WITHDRAWN -> 409 `TENANT_WITHDRAWN`; ACTIVE and SUSPENDED are allowed.
- core-service, hexagonal, reuse first:
  - `adapters/in/platform/PlatformAdminResource` (`@RolesAllowed(CallerIdentity.SUPER_ADMIN)`, like `PlatformTenantResource`).
  - `application/platform/ManageTenantAdmins`: tenant writes through `TenantScope.runAs(tenantId, …)` (the pattern of
    `CreateTenant` / `TenantContentProvisioning`), reusing `InviteMember`, `LoginProvisioning`, `MemberProvisioning`,
    `MemberCommands.replaceRoles/deactivate/updateData`, `LastAdminRule`, `MemberQueries`. No new grants for `core_platform`.
  - `IdentityProviderPort.updateLogin(subject, email, givenName, familyName)`; Keycloak adapter sets username = email,
    email, names, `emailVerified=false`, then sends `VERIFY_EMAIL`; 409 when another Keycloak user owns the e-mail.
    **Start with a `-Pkeycloak-it` test** proving the username actually changes on Keycloak 26.8.1 with the current realm.
    If the Admin API ignores username edits (`editUsernameAllowed` default false), set realm
    `registrationEmailAsUsername: true` (formalises email-as-login), apply it to a live realm in
    `infra/keycloak/seed-users.sh` like `loginTheme`, sync chart copies, record it in the ADR.
  - E-mail change in `MemberCommands.updateData` (shared path): DB updates first, Keycloak call last, DB rolled back if
    Keycloak fails (502). `LOGIN_SHARED` check for the academy-admin path: how to see other tenants' links without
    leaking them (e.g. the membership index, or a narrow `security definer` function returning a boolean) is your
    call; any new function/table needs the RLS suites (`tenant-isolation-testing` skill).
  - Audit via `AuditLog` inside `runAs` (actor = super admin `sub`, no personal data in metadata): `admin.added`,
    `admin.updated`, `admin.removed`, `admin.invitation_resent`, `member.login_email_changed`.
- Docs: ADR-0023 (super admin manages academy admins; email-as-login; shared-login rule); ADR-0021 §8 and
  `docs/domain/authz-matrix.md` super-admin row; `docs/guides/super-admin.{en,es,id}.md` and `admin.*` (e-mail edit
  behaviour); `docs/runbooks/onboard-tenant.md`; `docs/wp/FOLLOW-UPS.md` (close the e-mail sync item, add what remains).
- Out of scope: the Flutter console (WP23), disabling Keycloak accounts on removal.

## Acceptance
- [ ] Contract updated and every new call validated with `Contract.CORE` (or `Contract.FAILURES` for 502 paths)
- [ ] `PlatformAdminResourceTest`: list; add new (saga, setup mail stub) / promote existing member; edit names and e-mail
      (Keycloak update + verify mail stubs; Keycloak failure -> 502, DB unchanged); remove (role dropped / membership
      deactivated when no role left); last admin 409 with explanatory detail; resend (PENDING only); withdrawn 409;
      unknown tenant 404; non-super-admin 403; anonymous 401; audit rows (`CoreDb.auditActions`)
- [ ] `MemberResourceTest`: academy-admin e-mail edit syncs Keycloak; 409 `LOGIN_SHARED` for a login used in another tenant
- [ ] `KeycloakIdentityProviderKeycloakTest` (`-Pkeycloak-it`): updateLogin changes username + e-mail on a real Keycloak
- [ ] RLS suites green (and extended if a function/table was added); ArchUnit green
- [ ] e2e `JourneyTest`: super admin adds a second admin, edits it, removes it; removing the last admin is refused
- [ ] `just test` green with coverage gates; `./mvnw -pl services/core-service verify -Pkeycloak-it` green; `just e2e` green
- [ ] Docs and ADR-0023 written; handover appended

## Handover
