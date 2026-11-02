# Runbook: onboard a tenant (academy)

A **super admin** creates the academy together with its first ADMIN. Core-service runs one saga (ADR-0013): create the
Keycloak login (no password) -> insert the tenant and its FREE subscription -> create settings, default age categories,
the ADMIN membership -> send the Keycloak "execute actions" e-mail (`UPDATE_PASSWORD`, `VERIFY_EMAIL`) as the last step
before commit. A failure undoes the steps and deletes the Keycloak user only if this call created it.

Verification status: the saga, the REST contract and the MailHog step are exercised by `JourneyTest` step 1
(`docs/runbooks/e2e.md`; per `docs/wp/WP18-e2e.md` the e2e journey was not complete when that handover was written, but
step 1 passed). The UI path is described from the implemented screens and was not clicked through by the author.

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
3. **Create**. Expected: academy listed as **Active**; the first admin is ADMIN with invitation **PENDING**.
4. The first admin opens the e-mail, sets a password (policy: at least 12 characters, not equal to the user name or
   e-mail) and signs in. The invitation becomes **ACCEPTED** on their first `GET /api/core/me`.

## Steps (API)
`POST /platform/tenants` with a super admin bearer token (no `X-Tenant-Id`). Body per `CreateTenantRequest` in
`libs/contracts/openapi/core.yaml`:
```json
{"slug":"demo-academy","name":"Demo Academy","timezone":"Europe/Madrid","defaultLocale":"es",
 "firstAdmin":{"email":"admin@example.org","givenName":"Ada","familyName":"Admin"}}
```
Answers: 201 (tenant), 409 (slug or e-mail conflict, before any side effect), 422 (validation), 502
`IDENTITY_PROVIDER_UNAVAILABLE` (Keycloak down; nothing was written).

## Reading the first admin e-mail locally (MailHog)
Keycloak sends through SMTP `mailhog:1025` (realm setting). Open http://localhost:8025 (UI) or query the API:
```bash
curl -s 'http://localhost:8025/api/v2/messages?limit=5' | jq -r '.items[] | .Content.Headers.To[0], .Content.Headers.Subject[0]'
```
The message carries the set-password link. The e2e suite reads the same API (`MailHog.latestTo`).
On kind the chart ships mailpit under the Service name `mailhog` (UI on its 8025; port-forward `svc/mailhog 18025:8025`).
No e-mail arrives if the login already existed in Keycloak (the existing account is reused, invitation `ACCEPTED`).

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
  Keycloak username and e-mail follow (ADR-0023) and, while the invitation is PENDING, the set-password e-mail goes to the
  new address; `POST .../admins/{personId}/resend-invitation` sends it again.

## Managing the academy's administrators later (API)
`/platform/tenants/{id}/admins` with a super admin token (no `X-Tenant-Id`); ACTIVE and SUSPENDED tenants only (WITHDRAWN →
409 `TENANT_WITHDRAWN`, unknown → 404). Contract: `listTenantAdmins`, `addTenantAdmin`, `updateTenantAdmin`,
`removeTenantAdmin`, `resendTenantAdminInvitation` in `libs/contracts/openapi/core.yaml`.
- `GET` → active admins (`personId, givenName, familyName, email, invitationStatus, otherRoles`), paged.
- `POST {"email","givenName","familyName","locale"?}` → 200 when an active member with that e-mail is promoted, 201 when
  a new member is invited (same saga as onboarding); 409 `EMAIL_TAKEN` (deactivated member), `LOGIN_ALREADY_MEMBER`;
  502 `IDENTITY_PROVIDER_UNAVAILABLE` (nothing kept).
- `PATCH /{personId}` (merge patch of `givenName`, `familyName`, `email`) → 200; 404 if not an active admin; 409
  `EMAIL_TAKEN` (another member or Keycloak login has the address); 502 (nothing changed).
- `DELETE /{personId}` → 204 (ADMIN role dropped; deactivated if it was the only role; Keycloak login kept); 409
  `LAST_ADMIN`.
- `POST /{personId}/resend-invitation` → 202 (PENDING only, else 409 `INVITATION_NOT_PENDING`).
Every call is audited in the tenant's trail (`admin.*`, actor = the super admin's `sub`).

Realm prerequisite: `registrationEmailAsUsername: true` (realm JSON; existing realms get it from `just seed-users`).
Without it Keycloak refuses the username change with 400 `error-user-attribute-read-only` and the edit fails with 502.
