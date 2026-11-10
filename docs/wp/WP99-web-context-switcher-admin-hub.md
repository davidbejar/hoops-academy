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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
