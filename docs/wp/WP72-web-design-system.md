# WP72 — Web: design system to the landing-page look (tokens, theme, shared widgets, shell)

Model: Opus. Wave 1 (2026-11-06, fifth round): runs alongside WP78 (athlete contract + the session dialog under
`features/training`), WP81 (core), WP83 (workflows), WP87 (chart). You own `apps/web/lib/app/theme.dart`,
`apps/web/lib/app/shell.dart` and `lib/app/screens`, `apps/web/lib/core/ui/**`, a new `apps/web/lib/core/design/**`
(tokens), `apps/web/test/golden/home_shell_golden_test.dart` + its goldens, `apps/web/assets/fonts` if you add any.
You do NOT edit `lib/features/**` (the feature screens are restyled in wave 2 by WP73/74/75 using your widgets) except
to keep them compiling when a shared widget's API changes (minimal, mechanical edits; list them in the handover). WP78
edits `features/training/presentation/session_*.dart`: do not touch those files. `apps/web/lib/l10n/*.arb`: keys next
to the related feature's keys, never at the end. `apps/web/assets/landing/*.png` are the reference and must not be
modified (decision 57). Depends on: WP70 (landing page, `features/landing` for the look), ADR-0040 reserved for you.
Skills: flutter-feature, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp72-web-design-system`, branch `wp72-web-design-system`.

Decision 52 of 2026-11-06: the whole app takes the landing page's look this round; this WP builds the design system
and restyles the shell; the feature screens follow in wave 2 with your widgets.

## Scope
1. **Design tokens** (`lib/core/design/`): colour (the landing orange `#E8590C` family, neutrals, semantic success /
   warning / danger / info, chart colours already in `core/ui/chart_tokens.dart`), type scale, spacing, radii,
   elevation, motion durations; light and dark; derived from what `features/landing` and the four mock-up PNGs show
   (`apps/web/assets/landing/`: training week, live match, player health, platform usage). Contrast: every text /
   background pair at AA (4.5:1; the landing's white-on-orange buttons were about 3.6:1, pick a darker orange or a
   dark label for buttons and record it). Write the tokens as a Dart API (`HoopsTokens`), no magic numbers in widgets.
2. **Theme** (`lib/app/theme.dart`): `ThemeData` light/dark from the tokens (Material 3 `ColorScheme`, component
   themes for app bar, nav bar/rail, cards, chips, buttons, inputs, dialogs, snack bars, list tiles, tabs, data tables).
3. **Shared widgets** (`lib/core/ui/`): a widget kit the feature WPs will use: page scaffold with header/actions (keep
   `page_scaffold.dart` API or migrate callers mechanically), stat/KPI tile, section card with title and actions,
   empty state, status chip (role, availability, match state), list row with leading avatar/initials, responsive grid,
   form dialog (keep `form_dialog.dart`), bottom sheet action list, device-aware spacing. Each widget: a widget test and
   a golden in light and dark.
4. **Shell**: app bar, navigation (rail on wide, bar on narrow), academy switcher, profile menu, offline banner,
   restyled; `home_shell_golden_test.dart` goldens re-recorded. Keep every route and behaviour.
5. **Docs**: ADR-0040 (design system: tokens, theme, kit, contrast rule, how feature screens adopt it) and
   `apps/web/README.md` section "Design system" (how to use the kit; what wave 2 must do). A short checklist for the
   feature WPs: which old widgets to replace with which kit widgets.

## Acceptance
- [ ] Tokens, theme and kit with widget tests and light/dark goldens; contrast rule proven by a test over the token
      pairs (a Dart test computing WCAG contrast)
- [ ] Shell restyled; every existing test green: `flutter analyze` clean; `just web-format-check` clean;
      `just web-test` green (fresh; totals); goldens re-recorded only where the shell or kit changed (list them)
- [ ] `tool/web_smoke.sh` green; ADR-0040 written and indexed (append at the end of `docs/adr/README.md`)
- [ ] Handover appended: the kit's widget list and the wave 2 checklist

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
- Built:
  - **Tokens** `apps/web/lib/core/design/` (import `tokens.dart`): `HoopsColors` (ThemeExtension, light + dark: canvas
    `#FAF7F2`/`#0E0F11`, surface, surfaceMuted, surfaceRaised, ink, inkMuted, border, borderStrong, accent/onAccent,
    accentText, accentSoft/onAccentSoft, inverse, brand `#E8590C`, tones neutral/success/warning/danger/info as
    `ToneColors`, the WP14 `ChartPalette` carried), `HoopsTone`, `HoopsSpace`, `HoopsRadius`, `HoopsElevation`,
    `HoopsMotion`, `HoopsSize`, `WidthClass` (720 / 1024, gutters 16/24/32), `HoopsType`, `contrastRatio`,
    `HoopsTokens.colorsOf(context)`. `AppTokens` kept as aliases onto the new scale.
  - **Theme** `lib/app/theme.dart`: `hoopsColorScheme` (every role from a token, no seed, no surface tint) +
    component themes (app bar, navigation bar/rail, cards, chips, filled/outlined/text/elevated/icon buttons, FAB,
    segmented buttons, outlined inputs, dialogs, bottom sheets, popup menus/menus, snack bars, tooltips, list tiles,
    tabs, data tables, dividers, progress, badges, expansion tiles).
  - **Kit** `lib/core/ui/` (import `kit.dart`): `PageHeader`, `PageBody`, `ContentFrame` (device-aware gutters),
    `SubPage` (API kept), `SectionCard`, `StatTile`, `EmptyState`, `StatusChip` (`InfoChip`/`ChipTone` kept, mapped
    onto it: good → success, warn → warning, bad → danger), `ListRow` + `InitialsAvatar`, `ResponsiveGrid`,
    `NoticeBanner`, `showActionSheet` + `SheetAction` + `ActionSheetList`, `FormDialog` (API kept).
    `AppErrorView`, `EmptyView`, `ModulePlaceholder` now render through `EmptyState` (keys and texts unchanged).
  - **Shell** `lib/app/shell.dart`: canvas app bar with hairline, academy logo/initials + name in the brand line,
    `expand_more` when switchable, profile = the person's initials (`profile-button` kept), offline / demo / update
    notices as `NoticeBanner` (warning / accent / info; keys kept), bottom bar on a surface with a top hairline
    (`nav-bar-frame`), rail from 720 px with the basketball mark (`rail-brand`), extended with labels from 1024 px.
    `screens/`: login (brand tile, heavy title, full-width button), tenant switcher (`PageHeader` + `ListRow`, keys
    kept), not-a-member and no-access (`EmptyState`). Every route and behaviour unchanged.
  - No `lib/features/**` file was edited (no shared API broke, so no mechanical edits were needed). No font added.
- Verified (2026-11-07, worktree `wp72-web-design-system`):
  - Red first: contrast/theme tests failed to compile before the tokens; kit tests before the widgets; the
    `InfoChip` mapping test failed (orange container) before the mapping; `shell_test` failed (no `nav-bar-frame`,
    `rail-brand`, not extended) before the shell. Mutation check of the contrast test: setting `accent` back to
    `#E8590C` fails it with `onAccent/accent: 3.58`.
  - `flutter analyze`: no issues. `just web-format-check`: 327 files, 0 changed.
  - `just web-test` (fresh): **865 passed**, 0 failed (baseline before WP72: 778). New: 10 `contrast_test`
    (WCAG maths + every token pair light/dark + the theme's on-colours), 19 `theme_test`, 32 kit widget tests in
    `test/core/ui/` (status chip, list row, section card, stat tile, empty state, responsive grid, notice banner,
    action sheet, page layout, form dialog), 5 `shell_test`, 18 kit goldens, 3 shell goldens.
  - `tool/web_smoke.sh` (mock mode, Chrome/chromedriver 156): All tests passed.
  - Goldens: new `goldens/kit/{status_chip,list_row,section_card,stat_tile,empty_state,notice_banner,page_header,
    form_dialog,action_sheet}_{light,dark}.png`, `home_admin_1280x800.png`, `home_admin_360x780_dark.png`,
    `home_admin_1024x768_dark.png`. Re-recorded because the shell / theme changed (every screen inherits it):
    `home_admin_360x780`, `home_admin_1024x768`, `home_parent_360x780`, `audit_activity_{360x780,1024x768}`,
    `growth_chart_360x780`, `live_match_360x780`, `platform_admin_add_360x780`, `platform_admins_{360x780,1024x768}`,
    `platform_admins_last_360x780`, `player_detail_360x780`, `teams_list_360x780`,
    `temporary_password_{360x780,1024x768}`, `training_week_360x780`. Landing goldens unchanged (the label style
    keeps the default line height on purpose). `assets/landing/*.png` untouched.
  - Visual review in real fonts (Roboto from the SDK, demo mock, light + dark, 360 and 1280 px: login, switcher,
    admin, teams, training, health, matches, live match) with a throw-away copy of `landing_screens_capture.dart`
    writing to `build/`; not committed.
- Decisions/ADRs: ADR-0040 (indexed at the end of `docs/adr/README.md`). Button contrast: fills use orange 700
  `#C2410C` + white (5.18:1) in light, `#F2783A` + near-black (6.63:1) in dark; `#E8590C` only for marks (3.35:1 on
  the canvas, fine for non-text); orange text `#B4380A` (5.6:1). Warning text darkened to `#A14A08`.
- Open points / follow-ups:
  - **Wave 2 checklist** (also in `apps/web/README.md` "Design system"): pages → `PageBody` + `PageHeader` (sub-pages
    keep `SubPage`); `Card(ListTile(CircleAvatar))` (47 `Card` / 41 `ListTile` in 20 files) → `ListRow` +
    `InitialsAvatar`; titled card blocks → `SectionCard`; `InfoChip` (47 uses) and coloured `Container` labels →
    `StatusChip` with a `HoopsTone` (LIVE = accent + dot, finished = success, injured = danger, roles = info/neutral);
    counters/KPIs (platform usage, attendance, box totals) → `StatTile` in `ResponsiveGrid`; `EmptyView` / centred
    texts → `EmptyState`; `PopupMenuButton` / `showModalBottomSheet` action lists → `showActionSheet`; raw
    `colorScheme.*` for meaning (22 hits in 15 files) and `Color(0x…)` (`players_screen`, `teams_screen`,
    `live_match_screen`, `plans_screen`) → tokens; `AppTokens.*` → `HoopsSpace.*`; `AlertDialog` forms → `FormDialog`.
    Each WP re-records its own goldens and reviews them in light and dark.
  - After wave 2: delete `AppTokens` and `InfoChip`/`ChipTone` once unused; point `LandingPalette` at `HoopsColors`
    (same values today).
  - `features/tenant/presentation/tenant_avatar.dart` still draws its own `CircleAvatar` (primaryContainer); WP75
    can switch it to `InitialsAvatar(image:)`.
  - The black outline round FABs in goldens is flutter_test's shadow stand-in (`debugDisableShadows`), not a border.
  - The pre-commit isolation hook timed out once on a Testcontainers wait under load (other agents building);
    the retry passed.
