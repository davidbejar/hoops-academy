# ADR-0023: Super admin manages academy administrators; e-mail as login; shared-login rule

- Status: Accepted; amended by ADR-0024 — §1 `resend-invitation` / set-password e-mail and §2 `VERIFY_EMAIL` after a login move are superseded by ADR-0024 (temporary password, no e-mail)
- Date: 2026-11-02
- Related: ADR-0005 (Keycloak authentication only), ADR-0013 (onboarding saga, membership index), ADR-0017 (audit
  trail), ADR-0021 §8 (super_admin and tenant content), WP22

## Context
The platform super admin could create, suspend and withdraw academies and set the first administrator, but had no way
to list, add, correct or remove an academy's administrators afterwards — a typo in the first admin's e-mail could only
be fixed by withdrawing the academy. Independently, an e-mail change of a member (academy admin, `PATCH
/api/core/members/{id}`) only updated `core.person.email`: the Keycloak login (username = e-mail since WP21) and
`core.app_user.email` kept the old address (FOLLOW-UPS "Member e-mail changes are not synced to Keycloak").

Three questions had to be answered:
1. How may the platform role touch tenant data, which ADR-0013 deliberately denies to `core_platform`?
2. Can Keycloak 26.8.1 move a username at all with the realm as configured?
3. One Keycloak login can be linked to people in several academies. If an academy admin could move that login to an
   address they control, they could take over the account's access to the other academies.

## Decision
1. **Narrow exception to "the platform cannot read tenant content"** (ADR-0021 §8): `super_admin` reads and manages the
   *identity of a tenant's administrators* — person id, names, e-mail, invitation status, other role names — through
   `/platform/tenants/{tenantId}/admins` (`GET`, `POST`, `PATCH /{personId}`, `DELETE /{personId}`,
   `POST /{personId}/resend-invitation`). Nothing else of the tenant becomes visible. `core_platform` gets **no new
   grants**: `ManageTenantAdmins` checks the registry on the platform datasource (unknown → 404, WITHDRAWN → 409
   `TENANT_WITHDRAWN`; ACTIVE and SUSPENDED are managed), then runs every tenant read and write inside
   `TenantScope.runAs(tenant)` as `core_app` with the tenant bound, reusing the academy-admin use cases (invite saga,
   role replacement, deactivation, last-admin rule, e-mail sync). Audit rows (`admin.added`, `admin.updated`,
   `admin.removed`, `admin.invitation_resent`) go to the tenant's trail with the super admin's `sub` as actor.
   - *Add*: an active member with the e-mail gains ADMIN (200; a member without a login is given one with the setup
     e-mail); otherwise the invite saga creates a new ADMIN member (201). A deactivated member with the e-mail → 409
     `EMAIL_TAKEN`.
   - *Remove*: drops the ADMIN role; a person whose only role was ADMIN is deactivated. The Keycloak login is never
     deleted or disabled (it may belong to other academies). The last active admin cannot be removed (409
     `LAST_ADMIN`, the detail says to add another administrator first) — also not by the super admin.
2. **E-mail is the login name.** Proved by `KeycloakLoginUpdateKeycloakTest` (`-Pkeycloak-it`): with the previous realm
   defaults (`editUsernameAllowed` and `registrationEmailAsUsername` unset) Keycloak 26.8.1 rejects a username change
   through the Admin API with 400 `error-user-attribute-read-only`. The realm now sets
   `registrationEmailAsUsername: true` (formalises what core and the seed script already do: username = e-mail); with
   it the update changes username and e-mail together. Existing realms get the flag from `infra/keycloak/seed-users.sh`
   (the realm JSON is imported only into an empty volume). `IdentityProviderPort.updateLogin` sets username = e-mail,
   e-mail, names, `emailVerified=false`, then sends `VERIFY_EMAIL` (or the setup actions `UPDATE_PASSWORD` +
   `VERIFY_EMAIL` while the invitation is PENDING, so a corrected invitation address gets a usable link). If that mail
   fails the adapter restores the previous user and fails; Keycloak's 409 (address owned by another login) becomes 409
   `EMAIL_TAKEN`.
3. **One shared path for both editors, Keycloak last.** `MemberCommands.updateData` plans the login move before any
   write (`LoginEmailSync.plan`), updates `core.person`, `core.app_user.email` and the audit trail
   (`member.login_email_changed`, no addresses in metadata), and calls Keycloak as the last statement of the
   transaction: a Keycloak failure (502) or conflict rolls the database back. A person with a login must keep an
   e-mail (422 `LOGIN_REQUIRES_EMAIL`); name-only edits and people without a login never call Keycloak.
4. **Shared-login rule.** An academy admin's e-mail change is refused with 409 `LOGIN_SHARED` when the login is also
   linked to an active person of another tenant; the super admin's path always syncs. The check reuses the membership
   index and its subject policy (ADR-0013) instead of a new function or grant: inside the tenant transaction
   `JpaMembershipRepository.linkedInAnotherTenant` binds `app.subject` to the login's subject for one
   `exists(... tenant_id <> bound tenant)` statement and restores the previous value. Only that boolean leaves the
   repository; the Problem names no academy or address. `SharedLoginProbeTest` proves the answer and that the
   transaction is as tenant-bound afterwards as before. Rejected: a `security definer` function (as the FORCE-RLS
   table owner it would need an extra owner policy on the index, i.e. a broader change for the same boolean) and a
   grant for `core_platform` (ADR-0013 keeps it out of person data).

## Consequences
- WP23 can build the console on the new endpoints (`just gen-api` regenerates the Dart client from core 2.2.0).
- `docs/domain/authz-matrix.md` and ADR-0021 §8 point here for the exception.
- A super admin's e-mail change of a shared login updates `core.person.email` only in the edited tenant; the other
  academies keep their own (per-tenant) contact e-mail for that person. Keycloak and `core.app_user` hold the new one.
- The access token keeps the old `email` claim until the next login; `/me` shows the token's e-mail.
- Same accepted window as ADR-0013: a commit failure after a successful Keycloak update leaves Keycloak ahead of the
  database (detectable: `app_user.email` differs from the Keycloak e-mail); an admin can repeat the edit.
