# WP12 — Flutter: admin & roster, academy profile + logo, approvals inbox, orphan cases, invitations

Model: Sonnet. Depends on: WP11, WP3–WP5 contracts. Lane WEB. Skills: flutter-feature, test-driven-development.

## Scope (features/admin, features/roster)
- Academy profile: name, timezone, age rule, max play-up, default locale, **logo upload** (image picker, client-side
  size/type check, preview, PUT, cache-busting via ETag), logo shown in app bar/tenant switcher.
- Members: list/search, invite (email, roles), edit roles, deactivate; guardian links editor.
- Seasons (create, rollover wizard showing orphan list), age categories editor, teams (CRUD, gender policy, category),
  team staff, team roster (assign with eligibility check showing eligible teams only; play-up badge), players
  (list/filter by team/category/status, create → admin direct or coach request), approvals inbox (admin: approve/reject
  with note; coach: my requests + cancel), eligibility cases dashboard (open cases → reassign flow).
- Role-aware: coach sees own teams' actions only; assistant read-only here; parent/player do not see this module.

## Acceptance
- [ ] widget tests per screen (loading/empty/error/populated/role variants); golden for teams list & player detail (360 px)
- [ ] logo upload rejects > 512 KB / wrong type client-side with localized message; success updates header
- [ ] all strings localized (es/en/id key parity test still green); `flutter analyze && flutter test` green
