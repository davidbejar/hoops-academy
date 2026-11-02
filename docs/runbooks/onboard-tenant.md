# Runbook: onboard a tenant (academy)

A **super admin** creates the academy together with its first ADMIN. Core-service runs one saga (ADR-0013): create the
Keycloak login (no password) -> insert the tenant and its FREE subscription -> create settings, default age categories,
the ADMIN membership -> set a server-generated **temporary password** on the new login (Keycloak `reset-password`,
`temporary: true`) as the last step before commit (ADR-0024). A failure undoes the steps and deletes the Keycloak user
only if this call created it. No e-mail is sent; the response carries `temporaryPassword` once (`Cache-Control:
no-store`), the platform never stores it. A login that already existed keeps its password and gets none.

Verification status: the saga, the REST contract and the first sign-in with the temporary password (Keycloak's
update-password page) are exercised by `JourneyTest` steps 1-3 (`docs/runbooks/e2e.md`, WP24). The UI path is described
from the implemented screens; the dialog that shows the temporary password comes with WP25.

## Prerequisites
- Local stack up with `.env` filled (`docs/runbooks/local-stack.md`): `source scripts/env.sh && just up && just seed-users`.
- core-service running (`./mvnw -pl services/core-service quarkus:dev`, or `just services-up`) so that `/platform/**`
  answers on :8081 through nginx.
- Keycloak realm re-imported after WP17 (tokens must carry `sub`, see `troubleshooting.md`).
- A super admin account. Local: the seeded `superadmin@hoops-academy.com` (password `DEV_USER_PASSWORD` from `.env`). Elsewhere: create a
  Keycloak user in realm `academy` and grant the realm role `super_admin`.

## Steps (UI)
1. Sign in as the super admin (`apps/web`, see root `README.md`). With no academy membership you land on **Platform**.
2. **Platform > New academy**. Fill name, identifier (slug, `^[a-z0-9][a-z0-9-]{1,48}[a-z0-9]$`), time zone (IANA, e.g.
   `Europe/Madrid`; an unknown zone is 422 `INVALID_TIMEZONE`), default language, and the first admin's e-mail and names.
3. **Create**. Expected: academy listed as **Active**; the first admin is ADMIN with invitation **PENDING**; the
   temporary password is shown once. Pass it on privately (not in the same message as the e-mail address).
4. The first admin signs in with their e-mail and the temporary password; Keycloak asks for a new password at once
   (policy: at least 12 characters, not equal to the user name or e-mail). The invitation becomes **ACCEPTED** on their
   first `GET /api/core/me`.

## Steps (API)
`POST /platform/tenants` with a super admin bearer token (no `X-Tenant-Id`). Body per `CreateTenantRequest` in
`libs/contracts/openapi/core.yaml`:
```json
{"slug":"demo-academy","name":"Demo Academy","timezone":"Europe/Madrid","defaultLocale":"es",
 "firstAdmin":{"email":"admin@example.org","givenName":"Ada","familyName":"Admin"}}
```
Answers: 201 (tenant + `temporaryPassword` when the admin's login was created; absent when the e-mail already had a
login, invitation `ACCEPTED`), 409 (slug or e-mail conflict, before any side effect), 422 (validation), 502
`IDENTITY_PROVIDER_UNAVAILABLE` (Keycloak down; nothing was written). Do not paste the response into tickets or logs.

## Lost temporary password / admin who never got one
While the invitation is PENDING and the person has not chosen a password yet, issue a new one:
`POST /platform/tenants/{id}/admins/{personId}/temporary-password` → 200 `TenantAdminWithPassword` (the previous temporary
password stops working). The same call repairs administrators created before WP24 (setup e-mail never used, no password
at all), e.g. the two stuck local admins `admin1@ht.co.id` and `admin@hangtuah.co.id`. 409 `INVITATION_NOT_PENDING` once
the person signed in (or chose a password through another academy), or when the admin has no login. Academy admins have
the same for their members: `POST /api/core/members/{personId}/temporary-password` (409 `LOGIN_SHARED` for a login used
in another academy). MailHog stays in the stack for Keycloak's own "forgot password" flow; onboarding sends nothing.

## After onboarding
- The admin follows `docs/guides/admin.en.md` (profile and logo, members, seasons, teams).
- Check usage: **Platform > academy detail > Usage** or `GET /platform/tenants/{id}/usage`.

## Suspend, reactivate, withdraw
`POST /platform/tenants/{id}/suspend|reactivate|withdraw`; suspend and withdraw need `{"reason": "..."}`. Suspended or
withdrawn: members get 404 everywhere (game/athlete caches up to 30 s) and `/me` omits the membership. Withdrawn keeps the
data until `retainUntil` (`hoops.tenant.withdrawn-retention`, default `P365D`); no purge job yet (`docs/roadmap.md`).

## Recovery
- Crash between the registry and tenant transactions: a tenant without settings blocks its slug. `OnboardingRepairJob`
  (every 10 min, 15 min grace) removes it; an orphaned Keycloak login is logged for manual deletion (ADR-0017).
- Wrong first-admin e-mail: correct it with `PATCH /platform/tenants/{id}/admins/{personId}` `{"email": "..."}`. The
  Keycloak username and e-mail follow (ADR-0023); no e-mail is sent and the temporary password stays valid (ADR-0024);
  `POST .../admins/{personId}/temporary-password` issues a new one if needed.

## Managing the academy's administrators later (API)
`/platform/tenants/{id}/admins` with a super admin token (no `X-Tenant-Id`); ACTIVE and SUSPENDED tenants only (WITHDRAWN →
409 `TENANT_WITHDRAWN`, unknown → 404). Contract: `listTenantAdmins`, `addTenantAdmin`, `updateTenantAdmin`,
`removeTenantAdmin`, `issueTenantAdminTemporaryPassword` (`resendTenantAdminInvitation` is its deprecated alias) in
`libs/contracts/openapi/core.yaml`.
- `GET` → active admins (`personId, givenName, familyName, email, invitationStatus, otherRoles`), paged.
- `POST {"email","givenName","familyName","locale"?}` → 200 when an active member with that e-mail is promoted, 201 when
  a new member is invited (same saga as onboarding); `temporaryPassword` when this call created the login (also for a
  promoted member without a login); 409 `EMAIL_TAKEN` (deactivated member), `LOGIN_ALREADY_MEMBER`; 502
  `IDENTITY_PROVIDER_UNAVAILABLE` (nothing kept).
- `PATCH /{personId}` (merge patch of `givenName`, `familyName`, `email`) → 200; 404 if not an active admin; 409
  `EMAIL_TAKEN` (another member or Keycloak login has the address); 502 (nothing changed).
- `DELETE /{personId}` → 204 (ADMIN role dropped; deactivated if it was the only role; Keycloak login kept); 409
  `LAST_ADMIN`.
- `POST /{personId}/temporary-password` → 200 with a new `temporaryPassword` (PENDING and no password chosen yet, else
  409 `INVITATION_NOT_PENDING`); `POST /{personId}/resend-invitation` is the deprecated alias (202, removed in core 3.0.0).
Every call is audited in the tenant's trail (`admin.*`, actor = the super admin's `sub`).

Realm prerequisite: `registrationEmailAsUsername: true` (realm JSON; existing realms get it from `just seed-users`).
Without it Keycloak refuses the username change with 400 `error-user-attribute-read-only` and the edit fails with 502.
