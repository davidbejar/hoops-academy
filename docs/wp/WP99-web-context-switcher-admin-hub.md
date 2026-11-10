# WP99 — Web: context switcher, application admin hub, own-name edit

Model: Sonnet · effort high. Wave 2 (2026-11-10, sixth round): starts after WP91 and WP95 are merged; runs alongside
WP97 (it owns `lib/core/export`, the export buttons in `features/match` and `features/training`, a new dependency
in `pubspec.yaml`), WP96 (core), WP98 (game, athlete). You own `apps/web/lib/features/platform/**`,
`apps/web/lib/features/profile/**`, `apps/web/lib/app/router.dart`, `apps/web/lib/app/shell.dart`,
`apps/web/lib/app/screens/tenant_switcher_screen.dart`, `apps/web/lib/core/navigation`, `apps/web/packages/core`
(regenerate with `scripts/gen-api.sh core` only, to core 3.4.0), the core part of `apps/web/lib/core/mock`, the
platform step of `web_smoke.sh`, their tests and goldens. `apps/web/lib/l10n/*.arb`: keys next to the related
feature's keys, never at the end. `apps/web/pubspec.lock`: only the core package bump. ADR-0049 is reserved for you
if the navigation model needs a decision record. Depends on: decisions 71 and 73, WP91's handover (shapes of
`GET /platform/users` and `PATCH /me`), WP75 (admin hub look), WP90 (requests workbench), WP34 (platform activity),
WP14 (Profile → Platform). Skills: systematic-debugging (step 1), flutter-feature, clean-code,
test-driven-development, verification-before-completion. Worktree: `~/code/hoops-wt/wp99-web-admin-hub`, branch
`wp99-web-admin-hub`.

Decision 71 of 2026-11-10: one context switcher lists each academy the login belongs to (for example "Hangtuah",
"Dewa United", "Baskonia") plus "Application admin" for a super admin; each context has its own menu. The
application admin context is a hub: Academies, Users, Pending approvals (with a badge), Audit trail, Billing
(placeholder). Decision 73: a member edits their own first and last name in the profile.

## Scope
1. **Find out first** (report it at the top of the handover before restructuring): the owner signs in as
   `superadmin@hoops-academy.com` and lands on the platform audit trail, while the router is meant to send a super
   admin without memberships to the academies list. Reproduce with the seeded dev users on the mock and, if the
   compose stack is up, for real: memberships of that login, a stored last route, a deep link, the redirect order.
   Write a failing test for the cause before changing the routing.
2. **Contexts**: the list comes from `/me` (memberships with roles) plus the `super_admin` realm role. The server
   stays the authority (non-members get 404): the web only decides which menus to show. One switcher in the shell
   (rail on wide screens, a sheet on narrow ones) shows every context with the academy name and the role, and
   "Application admin" for a super admin; switching changes the tenant header, the menu and the landing route;
   cached reads stay scoped by tenant and person as today (F-07). The last used context is remembered per browser
   and ignored when it is no longer valid.
3. **Landing**: a super admin without memberships lands on the application admin hub; a login with exactly one
   context lands in it; with several, in the last used one, else on the switcher.
4. **Application admin hub** (like the academy admin hub of WP75; one sub-screen per area): **Academies** (the
   current list and detail), **Users** (new: search with debounce, paging, each login with its memberships per
   academy; a membership links to that academy's detail), **Pending approvals** (the WP90 requests workbench; the
   pending count as a badge on the hub and in the navigation), **Audit trail** (the current platform activity),
   **Billing** ("coming soon" placeholder; no backend call).
5. **Own name**: the profile edits first and last name through `PATCH /me` for every role, with validation and the
   offline rule of the feature skill; the academy's member list shows the new name after a refresh.
6. **Everything else**: es / en / id; mock parity for the two contract changes; goldens for the hub, the Users
   screen, the switcher (wide and 360 px, three languages for the switcher); `web_smoke.sh` platform step; deep
   links to the old `/platform…` routes keep working (redirects).

## Acceptance
- [ ] The cause of step 1 written down with its failing test, then fixed
- [ ] Red tests committed before each change; router tests for every landing case of step 3 and for a super admin
      who is also a member of two academies
- [ ] Dart core package 3.4.0 regenerated and committed (only yours)
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] Handover appended: the navigation model in ten lines (the docs pass rewrites the super admin guide from it),
      routes that changed, what a screenshot refresh of the landing page would need

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.

## Handover

### Step 1: why the owner lands on the audit trail (not reproduced; read before trusting)
- **Result: no path through the code lands a super admin on the audit trail.** I could not reproduce it, so there is no
  failing test for "the cause" and nothing was fixed for it. Checked with the real router and the seeded mock/fake
  users (`test/app/context_landing_test.dart`, group "landing"): a super admin with 0 academies lands on the academies
  list (`/platform`, now the hub) from the landing page, `/login`, `/splash`, `/` and from a cold start at
  `/platform/activity`; with 1 academy he landed in that academy (`/admin`), with 2 on the chooser (`/tenants`).
  The audit trail is `/platform/activity` (or `/admin/activity` of an academy); only a click on the old "Academies'
  activity" header button of the academies list leads there. There is no stored last route in the app
  (`hoops.selectedTenantId` and `hoops.locale` are the only preferences) and a cold start drops any deep link (the guard
  parks on `/splash`, then goes home). Keycloak client redirects and `manifest.json` `start_url` carry no path.
- The compose stack was up (Postgres, Keycloak) but no service, and the local DB has no `superadmin@hoops-academy.com`
  row, so I could not look at the owner's real `/me` or drive a browser. **Unverified hypothesis**: the page the owner
  sees first is the old "Platform" page whose two outlined header buttons ("Requests", "Academies' activity") sit above
  the list; at 360 px they stack as the first elements. The hub removes that page as a landing. If it happens again
  after this WP: ask for the account's academies and the URL in the address bar (`#/...`) at that moment.
- Kept as regression tests (they pass, they are not red-first): the landing cases above and the new characterisation
  of cold starts at `/platform/activity`, `/app-admin/activity`, `/login`, `/splash`, `/`.

### Built (web only, `apps/web`; core client regenerated to 3.4.0, `pubspec.lock` only that bump)
- **Navigation model (ADR-0049)**
  1. A *context* is one academy of the login (`/me.memberships`) or "Application admin" (`/me.superAdmin`).
     `contextsOf(user)` lists Application admin first; `sessionFor(user, selected)` is the pure resolver.
  2. Landing: no context -> `/no-access`; exactly one -> it; several -> the remembered one if still valid, else the
     chooser (`/tenants`, also reachable from Profile). A super admin with one academy has two contexts and chooses once.
  3. The choice is remembered per browser in the old key `hoops.selectedTenantId` (a tenant id, or the literal
     `platform`); sign-out clears it; an invalid value is ignored.
  4. Menus: academy = role menu as before; Application admin = bottom bar / rail Overview (hub), Academies, Users,
     Approvals (badge = pending requests), Audit; Billing only from the hub (placeholder, no backend call).
  5. Tenant header: Application admin has no academy (`activeTenantIdProvider` null, no `X-Tenant-Id`); caches stay
     keyed by tenant and person as before.
  6. Switcher: the shell chip opens a bottom sheet (< 720 px) or a panel beside the rail (rail button "Switch context");
     the same `ContextList` is the chooser page; every row shows name plus role ("Hangtuah / Administrador",
     "Administración de la aplicación / Super administrador"). Picking a context goes to `/` and so to its home.
  7. Routes: the platform console moved to `/app-admin/**`; old `/platform...` links redirect (super admin only).
  8. A link to `/app-admin/**` or an old `/platform/**` followed by a super admin who works in an academy switches
     to Application admin (a navigation to a new location only, never on a refresh) and is remembered.
  9. Own name (decision 73): Profile -> "Your name" for every role with an academy, `PATCH /me` with `tenantId`; only
     the changed field is sent; save is disabled offline (message) and while unchanged; the member list and `/me`
     are re-read after saving.
  10. The server stays the authority; `/platform/**` is still 403 for tenant roles, enforced by the existing guards.
- **Screens**: `app_admin_hub_screen.dart`, `platform_users_screen.dart` (search with 350 ms debounce, `q` only from 2
  characters, 25 per page, a membership opens `/app-admin/academies/:id`), `billing_screen.dart`,
  `profile_name_section.dart`, `core/navigation/context_switcher.dart`, `core/session/app_context.dart`.
- **Mock parity**: `GET /platform/users` (grouped by e-mail, q 2-100 else 400, paging) in `mock_platform_api.dart`;
  `PATCH /me` with a name in `mock_api_adapter.dart` + `mock_core_api.dart` (tenantId required -> 400, e-mail -> 400,
  unknown academy -> 404, member list and `/me.displayName` follow).
- Also touched outside the brief's list, minimal: `core/session/session.dart` and `session_providers.dart` (landing and
  guard), `core/tenancy/tenant_selection.dart` (doc), `features/audit/.../audit_log_screen.dart` (back-arrow paths),
  `features/me/data/me_repository.dart` (`updateName`), `integration_test/journey_smoke_test.dart` (platform step),
  `test/support/harness.dart` (default empty requests repo, `FakeMeRepository.updateName`), `test/support/fake_platform.dart`.
- Removed dead l10n keys (`navPlatform`, `profilePlatform`, `switchAcademy`, `chooseAcademy*`, `platformTitle`,
  `platformActivity`, `platformRequests`, `rolesInAcademy`); added keys next to the related ones.

### Routes that changed
| Old | New |
|---|---|
| `/platform` (academies list) | `/app-admin/academies` (hub at `/app-admin`) |
| `/platform/:tenantId` | `/app-admin/academies/:tenantId` |
| `/platform/:tenantId/activity` | `/app-admin/academies/:tenantId/activity` |
| `/platform/requests` | `/app-admin/requests` |
| `/platform/activity` | `/app-admin/activity` |
| (new) | `/app-admin/users`, `/app-admin/billing` |
The old paths redirect (`legacyPlatformPath`); `AppDestination.platform` became `appAdmin`, `appAcademies`, `appUsers`,
`appRequests`, `appActivity`; `destinationsFor` / `homePathFor` take `applicationAdmin` instead of `superAdmin`.

### Verified
- `flutter analyze`: no issues. `just web-format-check`: 0 changed (399 files). `just web-test` (fresh, last): 1250
  passed, 0 failed (2 min 33 s). `tool/web_smoke.sh --compile-only`: the integration test compiles for the web.
- Not run: the browser smoke itself (`tool/web_smoke.sh`, needs chromedriver) and anything against the real stack; the
  platform step of `journey_smoke_test.dart` was rewritten (switcher -> hub -> academies -> detail) but never executed.
- Goldens added (`test/golden/app_admin_golden_test.dart`): hub 360 / 360 dark / 1024; users 360 / 360 dark / 1024;
  context switcher 360 sheet and 1024 panel in es, en, id (6). Re-recorded (the shell now has the bar or rail with the
  switcher, previously none for a pure super admin): `platform_list` (2), `platform_admins` (5), `platform_usage` (5),
  `platform_requests` (3), `temporary_password` (3), `match/live_match_1024x768` (2, the rail's switch button).
- TDD: red commit first for the session / landing / redirect slice (`c03ab8f5`); the Users screen, hub, switcher, name
  section and mocks were written with their tests in the same slice, not test-first.

### Decisions / ADRs
- ADR-0049 (contexts and the application admin), indexed in `docs/adr/README.md`.

### Open points / for others
- `/me` has no separate given and family name, so the name form splits the display name at the first space and sends
  only changed fields (a family name of several words can show split wrongly; nothing is overwritten unless edited).
  Ask for `givenName` / `familyName` per membership in `/me` (core minor) to make it exact.
- A cold start never keeps a deep link (the guard parks on `/splash` then goes home); the old `/platform` redirects work
  for in-session navigation and for a signed-in super admin following them, not for a bookmark opened cold.
- Super admin guide (`docs/guides/super-admin.*`) is stale ("Profile > Platform console"); rewrite it from the ten-line
  model above. Screenshot refresh of the landing page: the landing now needs a login with a super admin with and
  without academies (switcher, hub); nothing on the public landing page itself changed.
- The wide switcher is a dialog panel aligned top-left, not an anchored popup.
- Users list shows memberships of any academy status and deactivated persons (chips); no e-mail change or temporary
  password from this screen (FOLLOW-UPS wanted them; not in this WP's scope).
- WP97 (exports) and others: `Harness` now overrides `academyRequestRepositoryProvider` by default; pass
  `academyRequests:` instead of `extraOverrides: repo.overrides` for that repository.
