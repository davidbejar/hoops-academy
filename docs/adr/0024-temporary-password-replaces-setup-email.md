# ADR-0024: Temporary password at first sign-in replaces the setup and verification e-mails

- Status: Accepted; amended by ADR-0035 — the §7 alias `resendTenantAdminInvitation` is removed in core 3.0.0
- Date: 2026-11-02
- Supersedes: the e-mail parts of ADR-0013 §(setup e-mail as the last saga step), ADR-0017 (player logins: setup e-mail
  last), ADR-0020 §5 (setup e-mail last) and ADR-0023 §1 (`resend-invitation`, set-password e-mail) / §2
  (`VERIFY_EMAIL` after a login move). Everything else in those ADRs stands.
- Related: ADR-0005 (Keycloak authentication only), ADR-0022 (branded login), WP24, WP25

## Context
Every new login was created without a password and got Keycloak's "execute actions" e-mail (`UPDATE_PASSWORD`,
`VERIFY_EMAIL`). Until the person used that link they could not sign in at all; locally the mail only lands in MailHog,
and in production it depends on SMTP being configured and delivered. Seen live: two academy administrators created
from the super admin console stayed PENDING with no credential. An e-mail change sent `VERIFY_EMAIL` as well.

The product owner decided (2026-11-02): no e-mail verification and no setup e-mail. Rejected: first sign-in with the
e-mail alone, choosing the password then — anyone who knows an address (including an academy administrator's) could
take the account over.

## Decision
1. **A login created by a request gets a server-generated temporary password**, returned once in that request's response
   (`temporaryPassword`, contract core 2.3.0) to whoever created it (super admin, academy admin, approving admin), who
   passes it on privately. Keycloak stores it as a temporary credential (`reset-password`, `temporary: true`), which adds
   the required action `UPDATE_PASSWORD`: the first sign-in with it lands on Keycloak's "update password" page (direct
   grants answer "Account is not fully set up"). Paths: `createTenant`, `addTenantAdmin` (also a promoted member without
   a login), `inviteMember`, `createPlayer` (ADMIN path), `approveApprovalRequest` (ADD_PLAYER). *Amended (WP58,
   core 2.8.0): also `createGuardian` (a new guardian with an e-mail), and `issueMemberTemporaryPassword` gives an
   active PARENT member with an e-mail and no login a first login (§2 applies: an existing login is linked, ACCEPTED,
   no password; audit `member.invited` + `member.temporary_password_issued`).*
2. **Only for logins this request created** (`ProvisionedIdentity.created()`). An existing login (the e-mail already
   signs in elsewhere) is linked as before (invitation ACCEPTED) and its password is never touched.
3. **Saga unchanged, Keycloak last.** `TemporaryPasswords.issue` is the last statement of the tenant transaction: audit
   row `member.temporary_password_issued` (no value) first, then Keycloak; a failure rolls the transaction back and the
   created login is deleted by the compensation (`LoginProvisioning`).
4. **Generator** (`TemporaryPasswordGenerator`, application layer): 16 characters drawn uniformly by `SecureRandom` from
   57 characters without look-alikes (`0 O 1 l I`) or `@` (≈93 bits), with at least one upper-case letter, lower-case
   letter and digit. It meets the realm policy `length(12) and maxLength(128) and notUsername and notEmail` (no `@`, so
   it can never equal the username = e-mail). `TemporaryPassword` (domain value object) never reveals the value in
   `toString()`; `reveal()` is called only by the Keycloak adapter and the response DTO.
5. **Never stored or logged.** The value is in no table, audit metadata, outbox event, log line, exception or
   Problem+JSON (asserted by `PasswordLeaks` — a scan of every `core` table and a log capture — in the resource tests).
   Responses that can carry it send `Cache-Control: no-store`. Keycloak's brute-force protection stays on
   (`RealmPasswordPolicyTest`).
6. **Re-issue while PENDING.** `POST /platform/tenants/{tenantId}/admins/{personId}/temporary-password` (super admin;
   `issueTenantAdminTemporaryPassword`, audit `admin.temporary_password_issued` + `member.temporary_password_issued`)
   and `POST /api/core/members/{personId}/temporary-password` (academy ADMIN; `issueMemberTemporaryPassword`). Allowed
   only for an active member whose invitation is PENDING **and** whose login has no password of their own
   (`IdentityProviderPort.hasOwnPassword`: a password credential without pending `UPDATE_PASSWORD`); otherwise 409
   `INVITATION_NOT_PENDING` (also: no login). The Keycloak check matters because PENDING is per tenant: a person may
   have signed in through another academy, and resetting their password would lock them out and hand the account to
   the caller. Academy admins additionally get 409 `LOGIN_SHARED` for a login linked to an active person of another
   tenant (same rule and probe as ADR-0023 §4); the super admin may. The re-issue also repairs logins created before
   this change that never got a password.
7. **Renamed path.** `…/resend-invitation` read wrongly once nothing is sent; it stays as a **deprecated alias**
   (`resendTenantAdminInvitation`, 202, same behaviour) so core 2.3.0 is additive and the current web build keeps
   working until WP25 switches; it is removed in core 3.0.0 (FOLLOW-UPS).
8. **No e-mail at all from core.** `updateLogin` moves username, e-mail (unverified) and names only; the password and a
   pending temporary password stay valid. `executeActionsEmail` is gone from core-service, and with it the mail-failure
   compensation of ADR-0023 §2 and `hoops.keycloak.setup-email-lifespan`. The realm keeps `verifyEmail: false`; MailHog
   / SMTP stay for Keycloak's own "forgot password" flow.

## Consequences
- The creator sees the password; the account is only the person's own once they have chosen their password at the
  first sign-in. Until then the creator (and anyone they pass it to) can sign in as that person.
- **Accepted risk — pre-account hijacking** (CWE-287 / OWASP A07:2025): nobody verifies that the e-mail belongs to the
  person. An academy admin can create a login for an address they do not own, sign in with the temporary password and
  choose a password. If another academy later adds the same e-mail, the existing login is linked (ADR-0013) and the
  first academy's admin can enter the second academy as that person. Before WP24 the setup e-mail went to the mailbox
  owner, so this was not possible. Needs a malicious academy admin and a later invitation of the same address elsewhere;
  the product owner accepted it with the no-verification decision. Mitigations to decide (FOLLOW-UPS): require a
  verified e-mail (or a sign-in after the link) before an existing login is linked into another tenant, or notify the
  person when their login is linked.
- A temporary password does not expire by itself (Keycloak has no expiry for temporary credentials); issuing a new one
  invalidates the previous one. *Amended by ADR-0028 (WP32): an unused temporary password expires after 3 days (the login is
  disabled until a new one is issued).*
- The web app must show the value once and never keep or log it (WP25); until WP25 the console does not display it, so
  a temporary password issued from the old UI is lost and has to be issued again.
- Responses reveal whether a login was created (presence of `temporaryPassword`), as the invitation status already did
  (FOLLOW-UPS F-11).
