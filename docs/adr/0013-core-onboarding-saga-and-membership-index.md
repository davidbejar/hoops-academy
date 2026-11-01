# ADR-0013: core onboarding saga, platform datasource reach and the cross-tenant membership index

- Status: Accepted
- Date: 2026-11-01

## Context
WP3 had to make three decisions ADR-0005/0006 leave open:
1. **CreateTenant / InviteMember touch three systems** — Keycloak (Admin API), the `platform` datasource
   (`core_platform`: tenant registry, billing) and the tenant's own rows (`core_app`, RLS). Two non-XA datasources
   cannot share a JTA transaction, and Keycloak is not transactional at all.
2. **`GET /api/core/me` reads across tenants** (the tenant switcher), but every tenant table is RLS-bound to one
   `app.current_tenant()`, which raises when unset, and the platform role must never read tenant content.
3. **What the platform role may touch** in `core`, and where per-tenant roster rules live.

## Decision
**Saga (orchestrated, Keycloak first, compensate on failure)** — `LoginProvisioning` + `CreateTenant` / `InviteMember`:
1. validate input and pre-check conflicts (slug, e-mail) — 409/422 before any side effect;
2. provision the login: find the Keycloak user by e-mail or create it (enabled, no password, e-mail unverified).
   A Keycloak failure → 502 `IDENTITY_PROVIDER_UNAVAILABLE`, nothing written;
3. CreateTenant only: platform transaction inserts `core.tenant` + `billing.tenant_subscription`;
4. tenant transaction (`TenantScope.runAs(newTenant)` for onboarding, the request transaction for invites):
   settings, provisioning hooks, person + roles (+ player), `app_user`, membership index, outbox events, and —
   as the LAST statement before commit — the execute-actions e-mail (`UPDATE_PASSWORD`, `VERIFY_EMAIL`);
5. on failure of 3 or 4: delete the registry row (CreateTenant; `core_platform` holds DELETE on `core.tenant`,
   but the FK from `tenant_settings` makes it impossible once provisioning committed) and delete the Keycloak user
   **only if step 2 created it** (an existing login belongs to another academy).
Consequences accepted: a crash between steps 3 and 4 leaves a tenant row without settings/admin (detectable:
`tenant` without `tenant_settings`); a commit failure after the e-mail was sent leaves a dangling e-mail whose link
targets a deleted user. Both are rare and visible; a PROVISIONING status would need a contract change.

**Membership index with a subject-scoped read policy** — `core.user_membership_index(tenant_id, keycloak_sub,
person_id)` is a normal tenant table (standard `tenant_isolation` policy, covered by the generic RLS suites),
maintained in the tenant's own transaction (invite, onboarding, deactivation). One extra permissive policy
`own_memberships FOR SELECT TO core_app USING (keycloak_sub = current_setting('app.subject', true))` serves /me:
the use case binds the **nil tenant** (so `tenant_isolation` matches nothing instead of raising) and
`app.subject = <caller sub>` in its own transaction. Without `app.subject` nothing is visible (fail closed). /me then
reads each listed tenant's details inside that tenant's own `TenantScope` (users belong to a handful of academies).
Rejected: querying with `core_platform` (would grant it person data); a global index without RLS (lists every
user's tenants to any bug); a per-request scan of all tenants (O(tenants)).

**Platform reach and settings placement** — `core_platform` gets explicit grants on `core.tenant`
(select/insert/update + compensation-only delete), `core.usage_snapshot` (select/insert), `core.outbox` (INSERT
only, for lifecycle events in the same transaction) and `billing.*`; nothing else. `core.tenant` keeps its own
policies (`core_app`: own row only, column-level UPDATE grant on profile columns; `core_platform`: all rows).
`age_rule` / `max_play_up_levels` live in `core.tenant_settings` (tenant content), not in the registry row.
`core.app_user` stays global without RLS but holds only id, sub, e-mail, locale and is never listed.

## Consequences
CreateTenant and invites are all-or-nothing from the caller's view, tested for both failure orders (Keycloak
before / after the database work). /me needs no platform privileges and cannot leak other users' memberships
(`MembershipIndexRlsTest`, `MeResourceTest`). New tenant tables need nothing special; only tables read by /me
across tenants would need a similar subject policy.
