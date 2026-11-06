# WP75 — Web redesign: admin, platform, audit, profile, tenant and auth screens

Model: Sonnet. Wave 2 (2026-11-06, fifth round): starts after wave 1 is merged (WP72 design system); runs alongside
WP73 (training/health/roster), WP74 (match), WP80, WP86, WP89. You own
`apps/web/lib/features/{admin,platform,audit,profile,me,tenant}/**`, their tests, the goldens
`test/golden/audit_golden_test.dart`, `platform_admins_golden_test.dart`, `temporary_password_golden_test.dart`
(+ their files under `test/golden/goldens/`). Not yours: `features/landing` (WP77 later; the landing is the
reference), `lib/app` (WP72 restyled the shell and sign-in flow screens under `lib/app/screens`: if a sign-in /
loading screen is still unstyled, tell the orchestrator instead of editing it). Shared: `lib/core/ui` only as the
rule below says; `lib/l10n/*.arb` keys next to the feature's keys, never at the end. Depends on: WP72 (ADR-0040).
Skills: flutter-feature, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp75-web-redesign-admin`, branch `wp75-web-redesign-admin`.

Decision 52 of 2026-11-06: every screen takes the design system of WP72 (ADR-0040; tokens in `lib/core/design`,
kit in `lib/core/ui`, the wave 2 checklist in the WP72 handover). Rules for every redesign WP: no behaviour change
(the existing widget tests stay green unless they assert on looks); replace ad-hoc styling with the kit widgets and
tokens (no colours, sizes or paddings inline); every screen in light and dark; responsive (phone width 360 to desktop);
goldens of your features re-recorded and reviewed (describe what changed); the demo mock is the data source for
goldens; `apps/web/assets/landing/*.png` are the reference and must not be modified (decision 57). If the kit lacks a
widget you need, add it to `lib/core/ui` in a SEPARATE commit named `feat(web): kit: <widget>` so the other redesign WPs
can cherry-pick it, and tell the orchestrator.

## Scope
1. **Admin**: members list and detail, member dialog, temporary password dialog flow, academy settings/contact,
   seasons.
2. **Platform** (super admin): academies list and usage, admins, the "platform usage" screen must match the landing
   mock-up `platform_usage.png` closely (one of the four showcased screens).
3. **Audit**, **profile** (`/me`, locale, academy switcher entry), **tenant** (academy pages).
4. Widget tests kept green; goldens re-recorded.

## Acceptance
- [ ] Every screen of your features uses the kit and tokens (grep proof in the handover)
- [ ] Platform usage screen visually matches its mock-up (golden image paths in the handover)
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals); goldens listed
- [ ] `tool/web_smoke.sh` green; handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built: admin (hub, members list/detail/invite, academy profile + logo, seasons + rollover, age categories), platform
  (academies list, academy detail with admins section, usage dashboard, usage trend), audit log, profile, me / my
  players hub and tenant avatar now use the kit and tokens: `PageBody` + `PageHeader`, `ListRow` + `InitialsAvatar`,
  `SectionCard`, `StatusChip`, `NoticeBanner`, `HoopsSpace/HoopsRadius`; `AppTokens`, `Card`, `ListTile`, `InfoChip`,
  `CircleAvatar` and raw `colorScheme` meanings are gone from the six features (grep proof: no match for
  `AppTokens|Card(|ListTile(|InfoChip|ChipTone|Color(0x|fontSize|CircleAvatar|colorScheme.|EmptyView` in
  `lib/features/{admin,platform,audit,profile,me,tenant}`; the only `*ListTile` left are `CheckboxListTile` in the
  rollover wizard and the audit action filter dialog). `TenantAvatar` (API unchanged) now draws `InitialsAvatar`.
  Platform usage: per-service `SectionCard` with label / value / single-hue bar rows, a warning `NoticeBanner` for
  unavailable services, the trend card below, as in `platform_usage.png`. New kit widget `IconTile` (commit
  `feat(web): kit: IconTile`, with test and light/dark golden), used by the admin hub, audit entries and profile.
- Verified (all fresh, in the worktree): `dart format --set-exit-if-changed lib test` 0 changed; `flutter analyze` no
  issues; `flutter test` 877 passed, 0 failed; `tool/web_smoke.sh` (mock journey in Chrome) "All tests passed". Goldens re-recorded and
  viewed: `test/golden/goldens/audit_activity_{360x780,360x780_dark,1024x768}.png`,
  `platform_admins_{360x780,360x780_dark,1024x768,last_360x780}.png`, `platform_admin_add_360x780.png`,
  `temporary_password_{360x780,360x780_dark,1024x768}.png`; new `test/golden/platform_usage_golden_test.dart` with
  `platform_usage_{360x1900,360x1900_dark,1024x1400}.png` and `platform_list_360x780{,_dark}.png`;
  `goldens/kit/icon_tile_{light,dark}.png`. Changed outside my files only because my screens appear in them:
  `home_admin_*` / `home_parent_360x780` (admin hub, shell avatar), `teams_list_360x780`, `training_week_360x780`,
  `live_match_360x780` (the shell's academy avatar is now the kit one). Merge note: WP73 / WP74 re-record the last
  three too; on a PNG conflict re-run `flutter test --update-goldens` of that file after the merge.
- Decisions/ADRs: none new (ADR-0040 applies). Status chips never sit next to a long name on a phone: the member row
  shows one chip (inactive, else password expired, else pending), the detail page shows all, the chip is capped to
  120 px and wraps. The platform "add administrator" button moved from the card header into the card body (the header
  row overflowed at 360). Pages are lazy lists, so widget tests that tap a control far down now use a taller view
  (`size: Size(360, 1100)`) or `scrollUntilVisible` (`tapKeyScrolling` in members_test); `mock_mode_test` asserts
  `ListRow` instead of `ListTile` on the platform activity page.
- Open points / follow-ups: `AsyncBody` still renders `EmptyView` for empty lists (core, not mine): switching it to
  `EmptyState` would restyle every empty list. The usage trend chart card (`GrowthChart`) belongs to the health
  feature (WP73) and keeps its own card look; bars use the chart palette (blue series, as in the mock-up), not the
  accent. Sign-in / loading screens under `lib/app/screens` were already styled: nothing to report. `CheckboxListTile`
  inside a `SectionCard` needs a transparent `Material` ancestor (kit follow-up: let `SectionCard` provide one).
