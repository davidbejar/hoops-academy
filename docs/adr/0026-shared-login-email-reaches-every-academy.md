# ADR-0026: A shared login's e-mail change reaches every academy, in one transaction

- Status: Accepted
- Date: 2026-11-05
- Amends: ADR-0023 §(e-mail sync: the super admin path updated only the edited academy's person row)
- Related: ADR-0006 (RLS), ADR-0011 (tenant binding in transactions), ADR-0013 (membership index), ADR-0017 (audit), WP31

## Context
Decision 7 of 2026-11-05: one person, one e-mail. When the super admin changes the e-mail of a login that active
persons of several academies link (`PATCH /platform/tenants/{id}/admins/{personId}`), Keycloak and
`core.app_user.email` moved, but only the edited academy's `core.person.email` changed. The other academies' rows live
under their own RLS policies. The brief asked for the update "in the same transaction that updates Keycloak and
`app_user`", using the mechanism `/platform/**` already uses for cross-tenant work, without bypassing RLS or widening
the app role.

The existing mechanisms do not do both:
- `core_platform` has no privileges on `core.person` or `core.audit_event` reads (V4; ADR-0023 kept it that way).
- `TenantScope.runAs(tenant, …)` (what `ManageTenantAdmins` uses) always opens its **own** transaction
  (`QuarkusTransaction.requiringNew()`), on another connection. Nested inside the edited academy's transaction, the
  other academies' rows would commit first: a later Keycloak failure (502) rolls the edited academy back but leaves the
  others on the new address; run after the edit, a failure there leaves Keycloak and the edited academy ahead.

## Decision
1. **Same transaction, per-statement tenant binding.** `LoginEmailSync` (super admin path, `SharedLogin.SYNC`) plans
   the move: `MembershipRepository.inOtherTenants(sub)` lists the active persons of other academies that link the login
   (the membership index, read through its `own_memberships` subject policy exactly like the `LOGIN_SHARED` probe of
   ADR-0023, `app.subject` restored afterwards). Applying it, after `app_user` and the edited academy's audit row and
   before Keycloak, `SharedLoginPersons` (adapter `JpaSharedLoginPersonRepository`) flushes the bound tenant's pending
   entity writes, sets `app.tenant_id` to the other academy (`set_config(…, true)`, transaction-local as in ADR-0011),
   runs its native statements as **core_app** under that academy's RLS policies, and sets the bound tenant back. So all
   academies' rows, `app_user` and the audit rows commit or roll back together, and Keycloak stays last.
2. **Narrow.** Only two statements run under the other binding: `exists` another person with the e-mail, and
   `update core.person set email … where id = :person and user_id = :login and active` (a row that does not link the
   login is never touched), followed by that academy's audit row. Hibernate's `@TenantId` filter stays on the bound
   tenant, so no entity code runs under the other binding; a call for the bound tenant itself is refused.
3. **Audit.** One `member.login_email_changed` row per academy (target: that academy's person; no e-mail in metadata;
   actor = the super admin's `sub`, no person) via `AuditLog.recordFor(tenant, event)`.
4. **E-mail uniqueness per academy.** If another person of an academy that shares the login already uses the new
   address, the move is refused with 409 `EMAIL_TAKEN` before any write (no academy is named).
5. **Active memberships only.** An academy where the person was deactivated (no index row) keeps its record: a former
   academy does not learn the new address. This matches the `LOGIN_SHARED` definition of ADR-0023.
6. **Academy admins unchanged**: a shared login is still refused with 409 `LOGIN_SHARED`; that path never rebinds.

## Rejected alternatives
- Per-academy `TenantScope.runAs` (separate transactions): not atomic with the edit and Keycloak (see Context).
- A `security definer` function or new `core_platform` grants on `core.person`: widens a role or bypasses RLS.
- A generic "run as another tenant inside this transaction" in `TenantScope`: entity code inside it would still be
  filtered on the bound tenant by Hibernate; too easy to misuse for one use case.
- Updating deactivated persons too: requires scanning every academy and discloses the new address to academies the
  person left.

## Consequences
- The `/platform/**` edit stays one database transaction regardless of how many academies share the login.
- The academy-admin path and the tenant RLS policies are unchanged; no migration, no new grants.
- `SharedLoginProbeTest` / `SharedLoginPersonsTest` (`@Tag("rls")`) prove the binding is restored and that only linked
  rows change; `PlatformAdminResourceTest` proves the behaviour end to end, including Keycloak failure and `EMAIL_TAKEN`.
