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
- [ ] Contract 2.3.0 updated; every changed call validated against it
- [ ] No `executeActionsEmail` / setup or verify mail left in core-service
- [ ] Keycloak IT: temporary password forces `UPDATE_PASSWORD`; existing logins keep their password
- [ ] Value never in logs, audit, outbox, DB, errors (asserted in tests); `Cache-Control: no-store`
- [ ] Re-issue endpoints for platform and academy admins, authz matrix updated and covered by the role-matrix tests
- [ ] `just test` green with coverage gates; `./mvnw -pl services/core-service verify -Pkeycloak-it` green; `just e2e` green
- [ ] ADR-0024 + docs; handover appended
