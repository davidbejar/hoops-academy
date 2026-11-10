# ADR-0049: Contexts: the academies of a login plus the application admin, each with its own menu

- Status: Accepted (WP99, web only; core 3.4.0 for `GET /platform/users` and `PATCH /me`)
- Date: 2026-11-10
- Records: decisions 71 and 73 of 2026-11-10 (`docs/wp/FOLLOW-UPS.md`)
- Related: ADR-0005 (Keycloak authentication only), ADR-0023 (super admin manages administrators), ADR-0044 (sign-up
  requests), WP14 (platform console), WP75 (academy admin hub), WP90 (requests workbench)

## Context
A login can belong to several academies, and a super admin (a Keycloak realm role) administers the application. Until
now the web app chose one academy (a switcher screen) and showed the platform console only to a super admin without
academies, or through Profile > Platform. Nothing said what a super admin could do, and one login with three academies
and the realm role had no way to move between "the application" and "an academy".

## Decision
1. **A context is one academy of the login, or "Application admin" for a super admin.** The list is derived from `/me`
   (memberships) plus its `superAdmin` flag; the web only decides which menu to show, the server stays the authority
   (non-members get 404, tenant roles get 403 on `/platform/**`). Application admin comes first in the switcher.
2. **Each context has its own menu.** An academy keeps the role menu of WP11; Application admin has the hub
   (`/app-admin`) and four areas as navigation: Academies, Users, Pending approvals (badge = pending requests),
   Audit trail. Billing is a placeholder reached from the hub only.
3. **Landing.** No context (a login without access): `/no-access`. Exactly one: that context. Several: the last used
   one if still valid, else the chooser. A super admin who also has one academy has two contexts and therefore chooses
   once. The last used context is stored per browser under the existing key (`hoops.selectedTenantId`: a tenant id or
   the literal `platform`), cleared at sign-out, ignored when no longer valid.
4. **The tenant header follows the context.** Application admin has no academy: no `X-Tenant-Id` is sent, nothing of
   an academy is shown, and cached reads stay scoped by tenant and person as before (F-07).
5. **Routes.** The platform console moved to `/app-admin/**` (`academies`, `academies/:tenantId`, `users`, `requests`,
   `activity`, `billing`). The old `/platform...` links redirect to the matching screen; for a super admin working in an
   academy, following such a link is an explicit choice of the Application admin context (remembered). A regular member
   is bounced to the home of their own context as for any other foreign route.
6. **Own name** (decision 73): every member edits their first and last name in the profile with `PATCH /me` (the body
   carries the academy). Only the changed field is sent, because `/me` has no separate given and family name: the form
   starts from the display name split at the first space.

## Consequences
- One switcher serves every login; the "Platform console" entry of the profile is gone.
- A super admin with one academy no longer lands in it directly (two contexts); the choice is remembered.
- The Users area needs no new authorisation: `GET /platform/users` is super admin only (core 3.4.0, ADR-0029
  amendment).
- Open: `/me` could return the person's given and family name per membership, which would make the form exact.
