# WP24 — First login with a temporary password (no setup e-mail, no e-mail verification)

Model: Opus. Depends on: WP3, WP5, WP17, WP22, ADR-0013, ADR-0017, ADR-0023. Contract: `libs/contracts/openapi/core.yaml`.
Skills: test-driven-development, quarkus-hexagonal-service, tenant-isolation-testing, owasp-security, clean-code,
verification-before-completion.

Today every new login is created without a password and gets an account-setup e-mail (`UPDATE_PASSWORD` +
`VERIFY_EMAIL`, `KeycloakIdentityProvider.SETUP_ACTIONS`). Until that mail is used the person cannot sign in at all
(locally the mail only lands in MailHog). Seen live: admins `admin1@ht.co.id` and `admin@hangtuah.co.id` created from the
super admin console are stuck PENDING without a password.

## Decision taken with the product owner (2026-11-02)
- **No e-mail verification and no setup e-mail.** A new login gets a **server-generated temporary password** that is
  shown **once** to whoever created it (super admin, academy admin, approver), who passes it on privately. At the first
  sign-in Keycloak forces "set a new password" (credential `temporary: true` -> required action `UPDATE_PASSWORD`).
- Rejected: signing in with the e-mail alone and choosing a password then (anyone knowing the e-mail could take over the
  account, including an academy admin's).

## Scope
- **Identity port / Keycloak adapter** (`IdentityProviderPort`, `KeycloakIdentityProvider`):
  - replace `sendAccountSetupEmail(subject)` by `setTemporaryPassword(subject, TemporaryPassword)` (Admin API
    `resetPassword` with `CredentialRepresentation{type=password, temporary=true}`); no `executeActionsEmail` anywhere.
  - `updateLogin` moves username/e-mail/names only: no `VERIFY_EMAIL` mail, no `emailVerified=false` requirement (keep
    the 409 `EMAIL_TAKEN` mapping; the mail-failure compensation goes away with the mail). The realm already has
    `verifyEmail: false`.
  - never reset the password of an **existing** login (`ProvisionedIdentity.created() == false`, e.g. a person who is
    already a member of another academy): no temporary password then, the person signs in with the password they have.
- **Generator** (`TemporaryPassword` value object + a generator in `application`, `SecureRandom`): satisfies the realm
  policy `length(12) and maxLength(128) and notUsername and notEmail` (e.g. 16 characters, unambiguous alphabet, mixed
  classes); `toString()` must not reveal the value.
- **Every path that creates a login** returns the temporary password in its response, only when this request created
  the login: `CreateTenant` (first admin), `ManageTenantAdmins.add` (invite), `InviteMember` / `MemberProvisioning`
  (academy admin invites with `sendInvitation`), `approvals/PlayerLogin` (player login on approval). Keep the existing
  saga ordering (Keycloak work last, DB rolled back and the created login deleted on failure).
- **Re-issue while PENDING** (also repairs the two stuck admins above): the platform
  `POST /platform/tenants/{tenantId}/admins/{personId}/resend-invitation` becomes "issue a new temporary password"
  (rename the path/operation if you think it reads better, e.g. `…/temporary-password`; record it in the ADR) and an
  equivalent for academy admins on any PENDING member under `/api/core/members/{personId}/…` (`@RequiresTenantRole`
  ADMIN, authz matrix row). 409 `INVITATION_NOT_PENDING` once the person has signed in (ACCEPTED) or has no login.
- **Contract first** (core 2.3.0): a `temporaryPassword` field (`readOnly`, documented "shown once, never stored") on the
  affected responses, or a small wrapper schema where the current response has no room; Problem+JSON unchanged.
  Update descriptions that mention the setup / verification e-mail. Validate every changed call with `Contract.CORE`.
- **Security** (owasp-security skill): the value never reaches logs, audit metadata, outbox events, the database,
  exceptions or Problem+JSON; responses carrying it send `Cache-Control: no-store`; brute-force protection stays on.
  Audit `member.temporary_password_issued` / `admin.temporary_password_issued` without the value.
- **Tests**: `-Pkeycloak-it` test on the real Keycloak 26.8.1 proving that a login with the temporary password is held
  at `UPDATE_PASSWORD` (direct grant answers "Account is not fully set up") and that the username/e-mail move needs no
  mail; WireMock adapter tests; resource tests for each path (value present only for created logins, absent for
  existing ones, absent from the audit rows and logs, `no-store` header); re-issue tests (PENDING ok, ACCEPTED 409, other
  tenant 404, non-admin 404/403 per matrix); generator unit tests (policy, randomness/uniqueness, `toString`).
  e2e `JourneyTest`: adapt to the new responses (it may keep setting final passwords through the Admin API).
- **Docs**: ADR-0024 (temporary password replaces the setup e-mail; supersedes the e-mail parts of ADR-0023 and any
  older ADR that mentions the setup mail); `docs/domain/authz-matrix.md`; guides `docs/guides/{super-admin,admin}.{en,es,id}.md`
  (how to pass the password on, what the person sees at first sign-in); `docs/runbooks/onboard-tenant.md`;
  `docs/conformance.md`; `docs/wp/FOLLOW-UPS.md`.
- Out of scope: the Flutter screens (WP25). Do not run `just gen-api` (WP25 does it).

## Acceptance
- [x] Contract 2.3.0 updated; every changed call validated against it
- [x] No `executeActionsEmail` / setup or verify mail left in core-service
- [x] Keycloak IT: temporary password forces `UPDATE_PASSWORD`; existing logins keep their password
- [x] Value never in logs, audit, outbox, DB, errors (asserted in tests); `Cache-Control: no-store`
- [x] Re-issue endpoints for platform and academy admins, authz matrix updated and covered by the role-matrix tests
- [x] `just test` green with coverage gates; `./mvnw -pl services/core-service verify -Pkeycloak-it` green; `just e2e` green
- [x] ADR-0024 + docs; handover appended

## Handover

- Built:
  - Contract `core.yaml` **2.3.0** (additive): schema `TemporaryPassword` (string, `readOnly`, 12..128, "shown once, never
    stored"); `temporaryPassword` on `TenantWithPassword` (= `Tenant` + field, `createTenant` 201),
    `TenantAdminWithPassword` (`addTenantAdmin` 200/201, re-issue), `MemberWithPassword` (`inviteMember` 201, re-issue),
    `PlayerCommandResult.temporaryPassword` (`createPlayer` 201), `ApprovalRequestWithPassword`
    (`approveApprovalRequest` 200); response header `Cache-Control` (`NoStore`) on all of them. New operations
    `POST /platform/tenants/{tenantId}/admins/{personId}/temporary-password` (`issueTenantAdminTemporaryPassword`, 200)
    and `POST /api/core/members/{personId}/temporary-password` (`issueMemberTemporaryPassword`, 200);
    `resendTenantAdminInvitation` kept as `deprecated: true` alias (202, same behaviour). Descriptions no longer promise
    any e-mail (`TemporaryPasswordContractTest`, 14 cases; `CrossServiceContractTest` 502 list extended).
  - core: `TemporaryPassword` (domain VO, `toString()` redacted, no `@`), `TemporaryPasswordGenerator` (16 chars,
    `SecureRandom`, 57-char alphabet without look-alikes, mixed classes), `TemporaryPasswords` (audit
    `member.temporary_password_issued` without the value, then Keycloak — last step of the transaction),
    `IssueTemporaryPassword` (PENDING + active + login + no own password, `LOGIN_SHARED` for academy admins),
    `WithTemporaryPassword<T>` result, `WithPasswordDto` (`@JsonUnwrapped` body + `temporaryPassword`, `noStore`).
    `IdentityProviderPort`: `setTemporaryPassword` (reset-password, `temporary: true`) and `hasOwnPassword` (password
    credential without pending `UPDATE_PASSWORD`) replace `sendAccountSetupEmail`; `updateLogin` moves
    username/e-mail/names only (no mail, no restore compensation; `LoginUpdate.setupPending` removed). Wired into
    `CreateTenant`/`TenantContentProvisioning`, `InviteMember`/`MemberProvisioning`, `ManageTenantAdmins` (invite,
    promoted member without login, `issueTemporaryPassword` with audit `admin.temporary_password_issued`, replaces
    `admin.invitation_resent`), `PlayerLogin`/`CreatePlayer`/`ApproveRequest`; `hoops.keycloak.setup-email-lifespan` removed.
  - Tests: `TemporaryPasswordTest` (4), `TemporaryPasswordGeneratorTest` (204 incl. 200 repeated policy draws, 10,000
    unique, uniformity), `RealmPasswordPolicyTest` (2), `KeycloakIdentityProviderTest` (WireMock, now 11),
    `KeycloakTemporaryPasswordKeycloakTest` (3, real Keycloak 26.8.1: direct grant with the temporary password answers
    "Account is not fully set up", a wrong one "Invalid user credentials", own password after the update; provisioning an
    existing login keeps its password; a stuck login without credential is repaired), `KeycloakLoginUpdateKeycloakTest`
    (move keeps the temporary password, MailHog empty for old and new address), resource tests in
    `PlatformTenantResourceTest`, `PlatformAdminResourceTest`, `MemberResourceTest` (role matrix row for the new
    endpoint), `PlayerResourceTest`, `ApprovalRequestResourceTest`: value present only for created logins and equal to
    what Keycloak received, absent for existing logins, `no-store`, `PasswordLeaks` (scan of every `core` table + log
    capture) and the Problem body of the failure path. Test support: `LogCapture`, `PasswordLeaks`,
    `CoreDb.tablesContaining`, Keycloak stubs for reset-password/credentials, a test-only direct-grant client in
    `KeycloakContainerResource`. e2e: steps 1-3 now create the tenant, sign the first admin in with the temporary password
    through Keycloak's update-password page (`KeycloakUserTokens.firstLogin`) and check no mail; step 31 re-issues for a
    pending admin, signs in with it, then gets 409 `INVITATION_NOT_PENDING`. e2e `Contracts` fixed to ignore IGNORE-level
    request messages (they made allOf-only response reports fail).
  - Docs: ADR-0024 (+ amendment notes in ADR-0013/0017/0020/0023), `authz-matrix.md` (new row + admins row),
    guides `super-admin.{en,es,id}.md` (first sign-in section, add/edit/resend) and `admin.{en,es,id}.md`,
    `runbooks/onboard-tenant.md` (saga, lost password / stuck admins, API), `runbooks/e2e.md`, `runbooks/troubleshooting.md`,
    `conformance.md` (S-38, deviation row), `FOLLOW-UPS.md` (pre-account hijacking, no expiry, alias removal, F-11).
- Verified (fresh, this session, 2026-11-02):
  - Red first: contract test 14/14 failing; generator/VO tests failing against stubs; resource/adapter tests failing
    against the old code (42 failures + 3 errors, e.g. 502 because no execute-actions stub exists). The Keycloak ITs were
    committed with the red tests but only run after the implementation.
  - `just test` (`./mvnw -q -T 1C verify`, services on 8081-8083 stopped first because common-quarkus binds 8081): exit 0,
    JaCoCo gates met (core lines 98.7 %, domain 99.4 %); surefire common-quarkus 168, contracts 120, core 688, game 193,
    athlete 578 = **1,747 tests**, 0 failures/errors/skips (ArchUnit and RLS suites included).
  - `./mvnw -pl services/core-service verify -Pkeycloak-it`: 6 tests (1 + 3 + 2), 0 failures, BUILD SUCCESS.
  - `just e2e`: `JourneyTest` **21 tests**, 0 failures/errors/skips (68.5 s); afterwards `e2e/bin/services-up.sh
    --no-build` → core/game/athlete ready on 8081-8083 with the new jars.
  - Live realm, read-only: `admin1@ht.co.id` and `admin@hangtuah.co.id` have no credential and no required action, so
    the re-issue endpoint accepts them (not executed: the password would have to be shown to the product owner).
  - `grep` of `services/core-service/src/main`: no `executeActionsEmail`, `VERIFY_EMAIL` or setup e-mail left.
- Decisions (ADR-0024): temporary password only for logins created by the request; Keycloak last in the transaction;
  re-issue requires PENDING **and** no own password in Keycloak (PENDING is per tenant; a person may have signed in
  through another academy), academy admins also `LOGIN_SHARED`; path renamed to `…/temporary-password` with the old one
  as deprecated alias so 2.3.0 stays additive; `emailVerified` stays `false` on created and moved logins (truthful;
  `verifyEmail` is off); audit `member.temporary_password_issued` on every issue (also at creation).
- Open points: pre-account hijacking accepted with the no-verification decision (FOLLOW-UPS, Medium); temporary passwords
  never expire; alias removal in core 3.0.0; the two stuck admins still need a re-issue (console after WP25, or the
  API); `apps/web` not touched and `just gen-api` not run (WP25). An existing login linked into a new tenant keeps no
  temporary password even if it never had a password (its owner, or the academy that created it, re-issues).
