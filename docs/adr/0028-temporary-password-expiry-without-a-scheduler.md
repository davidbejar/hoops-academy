# ADR-0028: Temporary passwords expire after three days, swept on events instead of a scheduler

- Status: Accepted
- Date: 2026-11-05
- Records: the product owner's decision 4 of the 2026-11-05 interview (`docs/wp/FOLLOW-UPS.md`, "Plan (2026-11-05)")
- Amends: ADR-0024 Consequences ("a temporary password does not expire by itself")
- Related: ADR-0005 (Keycloak authentication only), ADR-0016 (job lock `runExclusive`), ADR-0022 (branded login),
  ADR-0024 (temporary password), ADR-0025 (easy sign-up), ADR-0026 (per-statement tenant binding), WP32; security review
  F-23

## Context
Since ADR-0024 a new login gets a temporary password that the creator passes on privately. Keycloak keeps a temporary
credential until it is used or replaced, so a password passed on and never used stays valid for ever (F-23, Low). The
product owner decided that a temporary password older than **3 days** is expired, and does **not** want a cron job: the
clean-up runs in the background when an infrequent event happens.

Core never sees the sign-in itself: Keycloak's login page handles the temporary password and the forced update, and
the app calls core only afterwards (`GET /api/core/me`, where a PENDING invitation becomes ACCEPTED). Keycloak has no
expiry for temporary credentials.

## Decision
1. **State on the login.** `core.app_user` (global, no RLS, V2) gets `temporary_password_issued_at` and
   `temporary_password_expired_at` (V10). `TemporaryPasswords.issue` — the single place every path goes through (invite,
   approve, player with e-mail, tenant admin add/promote, re-issue) — sets the issue time, clears the expiry and, when the
   login had expired, **enables** it again in Keycloak (after the new temporary password; Keycloak stays last, ADR-0024).
   The first sign-in (`/me` accepting an invitation) clears the issue time: Keycloak issues no token before the person
   has chosen their own password, so nothing is left to expire.
2. **The sweep** (`application/identity/ExpireTemporaryPasswords`): for each login with an issue time older than
   `hoops.temporary-password.ttl` (default `P3D`) and no expiry, one transaction with **no tenant bound**: lock the row and
   re-check it (a concurrent re-issue wins); if the person has a password of their own (`hasOwnPassword`), only forget the
   issue time; otherwise set the expiry, write `member.temporary_password_expired` (target: the person, actor `system`,
   no personal data) to every academy where the login links an active **PENDING** person, then **disable** the Keycloak
   login last. A Keycloak failure rolls that login back and is logged; the next sweep retries it; other logins go on.
3. **Per-academy audit rows inside the sweep's transaction.** `PendingLoginPersons` (adapter
   `JpaPendingLoginPersonRepository`) reads the login's membership index rows through the `own_memberships` subject policy
   (nil tenant + `app.subject`, as `/me`), then binds `app.tenant_id` to each academy for two native statements (the
   PENDING probe and `AuditLog.recordFor`) under that academy's RLS policies, and restores both settings — the mechanism
   of ADR-0026, without a home tenant. No new grants, no `security definer`, no RLS change.
4. **Triggers, no scheduler.** Both events — a temporary password issued, an invitation accepted at the first sign-in —
   call the port `TemporaryPasswordSweeps.request()`. Its adapter (`TemporaryPasswordSweepJob`) registers an
   after-commit synchronisation on the request's transaction and hands the sweep to one background thread; the sweep runs
   under `TenantScope.runExclusive("core.temporary_password_sweep", …)`, so one replica sweeps at a time and another
   skips. At most one sweep waits behind the running one in a replica. The request never waits for the sweep and a sweep
   failure never fails it. `hoops.temporary-password.sweep-on-events=false` turns the triggers off (tests do; they call
   the sweep directly).
5. **Disable the login rather than delete the credential.** A disabled login cannot obtain a token by any flow, the
   state is visible in Keycloak's admin console, and re-enabling is one call; deleting the credential would leave a login
   that Keycloak treats as "no password" and would not let the login page explain why. The branded login theme `hoops`
   overrides `accountDisabledMessage` (es/en/id): "Your temporary password has expired. Ask your academy administrator for
   a new one." The theme cannot tell a login disabled for another reason apart, so **every disabled login shows this
   text**; today the sweep is the only thing in the platform that disables logins.
6. **Contract** core 2.4.0 (additive): `Member.temporaryPasswordStatus` and `TenantAdmin.temporaryPasswordStatus`
   (`ACTIVE | EXPIRED | NONE`) so the consoles label an expired pending person next to the existing re-issue action;
   the re-issue operations are unchanged (their description says they also renew an expired password).

## Rejected alternatives
- **A cron job** (`@Scheduled`, like the other jobs): rejected by the product owner.
- **Expiry checked at sign-in**: core never sees the sign-in; it would need a Keycloak extension (SPI), which ADR-0005
  keeps out.
- **Per-academy `TenantScope.runAs` for the audit rows**: separate transactions; a crash between them and the expiry
  would lose rows or leave them without an expiry.

## Consequences
- **Accepted gap**: a temporary password expires at the first event after its 3 days, not at exactly 3 days. In a quiet
  platform it can keep working longer; any issue or first sign-in anywhere closes the gap. The status shows `ACTIVE`
  until then (it is still valid).
- A re-issue is still allowed only while the invitation is PENDING and the person has no password of their own
  (ADR-0024); it is how an expired login comes back.
- Realm/theme changes need a Keycloak restart (compose mounts the theme; Helm ships the message files in the theme
  ConfigMap). Realm import is unchanged.
- Expiry is per login, not per academy: a login shared by several academies is disabled for all of them, and each academy
  where the person is still PENDING gets the audit row.
