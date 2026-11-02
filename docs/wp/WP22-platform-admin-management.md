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
- [x] Contract updated and every new call validated with `Contract.CORE` (or `Contract.FAILURES` for 502 paths)
- [x] `PlatformAdminResourceTest`: list; add new (saga, setup mail stub) / promote existing member; edit names and e-mail
      (Keycloak update + verify mail stubs; Keycloak failure -> 502, DB unchanged); remove (role dropped / membership
      deactivated when no role left); last admin 409 with explanatory detail; resend (PENDING only); withdrawn 409;
      unknown tenant 404; non-super-admin 403; anonymous 401; audit rows (`CoreDb.auditActions`)
- [x] `MemberResourceTest`: academy-admin e-mail edit syncs Keycloak; 409 `LOGIN_SHARED` for a login used in another tenant
- [x] `KeycloakIdentityProviderKeycloakTest` (`-Pkeycloak-it`): updateLogin changes username + e-mail on a real Keycloak
- [x] RLS suites green (and extended if a function/table was added); ArchUnit green
- [x] e2e `JourneyTest`: super admin adds a second admin, edits it, removes it; removing the last admin is refused
- [x] `just test` green with coverage gates; `./mvnw -pl services/core-service verify -Pkeycloak-it` green; `just e2e` green
- [x] Docs and ADR-0023 written; handover appended

## Handover

- Built:
  - Contract `core.yaml` 2.2.0: `/platform/tenants/{tenantId}/admins` `GET` (paged `TenantAdminPage`), `POST`
    (`AddTenantAdminRequest`; 200 promoted / 201 invited), `/{personId}` `PATCH` (`UpdateTenantAdminRequest`, merge patch,
    `additionalProperties: false`) and `DELETE` (204), `/{personId}/resend-invitation` `POST` (202 + `TenantAdmin`; a
    bodyless 202 violates `OpenApiConventionsTest.everySuccessResponseIsTyped`). `updateMember` documents the login move,
    `LOGIN_SHARED`, `LOGIN_REQUIRES_EMAIL` and gains 502.
  - core: `PlatformAdminResource` (`@RolesAllowed(super_admin)`), `ManageTenantAdmins` (registry check on the platform
    datasource -> 404 / 409 `TENANT_WITHDRAWN` via `Tenant.requireManageable`; all tenant work in `TenantScope.runAs`
    reusing `InviteMember`, `MemberCommands`, `LoginProvisioning`/`MemberProvisioning`, `LastAdminRule`; audit
    `admin.added|updated|removed|invitation_resent`). A promoted member without a login is given one (setup e-mail),
    otherwise ADMIN would be unusable. `LoginEmailSync` (plan before writes, apply last: `app_user.email`, audit
    `member.login_email_changed`, Keycloak) used by `MemberCommands.updateData` for both editors (`SharedLogin.REFUSE` for
    academy admins, `SYNC` for the super admin). `IdentityProviderPort.updateLogin(LoginUpdate)`: username = e-mail,
    e-mail, names, `emailVerified=false`, then `VERIFY_EMAIL` (setup actions while PENDING); restores the previous user if
    that mail fails; Keycloak 409 -> `EMAIL_TAKEN`. `MembershipRepository.linkedInAnotherTenant` (shared-login probe),
    `PersonRepository.findByEmail`, `MergePatch.allowOnly`, `AppUser.withEmail`; `LastAdminRule` detail now "An academy
    needs at least one active administrator: add another administrator first".
  - Realm: `registrationEmailAsUsername: true` in `infra/keycloak/realm-academy.json` (chart copy synced, helm snapshots
    updated: the flag + `checksum/realm` only), applied to the live realm by `seed-users.sh` (`just seed-users` run;
    kcadm shows `registrationEmailAsUsername: true`).
  - Tests: `PlatformAdminResourceTest` (18), `MemberResourceTest` (+7 e-mail sync / `LOGIN_SHARED`), `SharedLoginProbeTest`
    (2, `@Tag("rls")`), `KeycloakIdentityProviderTest` (+5 WireMock), `KeycloakLoginUpdateKeycloakTest` (3, `-Pkeycloak-it`,
    real Keycloak 26.8.1 + MailHog on a shared Testcontainers network via `KeycloakContainerResource` init arg
    `mail=true`), domain tests (`TenantTest`, `LastAdminRuleTest`, `AppUserTest`, `MergePatchTest`); e2e step 31
    `superAdminAddsEditsAndRemovesAnAcademyAdminButNeverTheLastOne`.
  - Docs: ADR-0023, ADR-0021 §8, `authz-matrix.md` row, `super-admin.{en,es,id}.md` (new section), `admin.{en,es,id}.md`
    (e-mail edit behaviour), `runbooks/onboard-tenant.md`, `conformance.md` S-38, `FOLLOW-UPS.md` (e-mail sync closed,
    two new items).
- Verified (fresh, this session):
  - Keycloak finding first: with the old realm `KeycloakLoginUpdateKeycloakTest` failed with 400
    `{"field":"username","errorMessage":"error-user-attribute-read-only"}`; with `registrationEmailAsUsername: true` it
    passes (username and e-mail moved, old e-mail no longer found, VERIFY_EMAIL mail in MailHog).
  - `just test`: exit 0, coverage gates met; surefire totals common-quarkus 168, contracts 99, core 469, game 193,
    athlete 578 = 1,507 tests, 0 failures/errors/skips (ArchUnit and the RLS suites included).
  - `./mvnw -pl services/core-service verify -Pkeycloak-it`: 5 tests (2 + 3), 0 failures, BUILD SUCCESS.
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED; `scripts/sync-chart-files.sh --check` clean.
  - `just e2e`: `JourneyTest` 21 tests, 0 failures, 0 skipped (new step ran, 2.6 s); services restarted afterwards with
    the new jars (`e2e/bin/services-up.sh --no-build`, core/game/athlete ready).
  - Red first: the IT test against a stub, the 6 new `MemberResourceTest` cases, 17/18 `PlatformAdminResourceTest`
    cases (the 404 one passed by routing); mutation checks on the restore/verify-mail adapter paths and the
    `app.subject` restore of the probe made their tests fail.
- Decisions (ADR-0023): narrow platform exception (admins' identity only, no new `core_platform` grants); e-mail as
  username (`registrationEmailAsUsername`); one e-mail sync path, Keycloak last; `LOGIN_SHARED` via the membership index
  subject policy (one `exists` statement with `app.subject` bound, restored afterwards; only a boolean leaves the
  repository) instead of a `security definer` function. Keycloak conflict reuses `EMAIL_TAKEN`. Name-only edits never
  call Keycloak. A member with a login cannot lose the e-mail (422 `LOGIN_REQUIRES_EMAIL`). All five endpoints answer
  409 for a WITHDRAWN tenant, including `GET`.
- Open points: shared login moved by the super admin keeps the other tenants' `person.email` (FOLLOW-UPS); no repair for
  Keycloak ahead of the database after a commit failure (FOLLOW-UPS); Dart client not regenerated and console not built
  (WP23: `just gen-api` for core 2.2.0); the access token keeps the old `email` claim until the next login.
