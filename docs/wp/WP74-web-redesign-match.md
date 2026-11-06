# WP74 — Web redesign: live match, match list, match setup, box score and season statistics

Model: Opus. Wave 2 (2026-11-06, fifth round): starts after wave 1 is merged (WP72 design system); runs alongside
WP73 (training/health/roster), WP75 (admin/platform/auth), WP80, WP86, WP89. You own `apps/web/lib/features/match/**`,
its tests, the goldens `test/golden/live_match_golden_test.dart` (+ its files under `test/golden/goldens/`). Shared:
`lib/core/ui` only as the rule below says; `lib/l10n/*.arb` keys next to the match keys, never at the end. Depends on:
WP72 (ADR-0040), WP13/WP52 (live match behaviour, offline sync banner: unchanged). Skills: flutter-feature,
test-driven-development, clean-code, verification-before-completion. Worktree: `~/code/hoops-wt/wp74-web-redesign-match`,
branch `wp74-web-redesign-match`.

Decision 52 of 2026-11-06: every screen takes the design system of WP72 (ADR-0040; tokens in `lib/core/design`,
kit in `lib/core/ui`, the wave 2 checklist in the WP72 handover). Rules for every redesign WP: no behaviour change
(the existing widget tests stay green unless they assert on looks); replace ad-hoc styling with the kit widgets and
tokens (no colours, sizes or paddings inline); every screen in light and dark; responsive (phone width 360 to desktop);
goldens of your features re-recorded and reviewed (describe what changed); the demo mock is the data source for
goldens; `apps/web/assets/landing/*.png` are the reference and must not be modified (decision 57). If the kit lacks a
widget you need, add it to `lib/core/ui` in a SEPARATE commit named `feat(web): kit: <widget>` so the other redesign WPs
can cherry-pick it, and tell the orchestrator.

## Scope
1. **Live match**: the scoreboard, clock, event entry (one-hand phone use: large targets, bottom action area), bench /
   on-court roster, sync banner, undo; it must match the landing mock-up `live_match.png` closely (one of the four
   showcased screens). Offline behaviour unchanged (the sync and conflict tests stay green).
2. **Match list, setup and edit dialog, box score, season statistics**: kit widgets, stat tiles, data tables.
3. Widget tests kept green; goldens re-recorded.

## Acceptance
- [x] Every screen of your feature uses the kit and tokens (grep proof in the handover)
- [x] Live match screen visually matches its mock-up (golden image paths in the handover)
- [x] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals); goldens listed
- [ ] `tool/web_smoke.sh` and `tool/offline_cold_start.sh` green; handover appended (web smoke green, handover
  appended; offline cold start fails before the match screens, see Handover)

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
- Built (worktree `wp74-web-redesign-match`, rebased onto main `81a595a` (WP75 merged)):
  - **Kit** (separate commit `698c6d5 feat(web): kit: SheetAction key`, cherry-pickable): `SheetAction(key:)`, default
    stays `sheet-action-<value>`; lets a popup menu become `showActionSheet` and keep its keys (`menu-*`, `sub-out-*`).
  - **Live match** (matches `assets/landing/live_match.png`): `live_match_screen.dart` (screen, staff menu as an
    action sheet, tabs) split into `live_scoreboard.dart` (surface band with hairline: both scores `displaySmall` in
    tabular figures, period, clock -10/+10 + orange start/pause, or the state chip for others; scoring strip of
    48 px buttons: period start/end in soft orange, opponent +1/+2/+3 outlined, timeout and undo outlined icon
    buttons; cached / parent mode / read-only as `StatusChip`s), `court_panel.dart` (on-court tiles in `accentSoft`
    with the jersey large, bench cards with an `InitialsAvatar` number badge, `ResponsiveGrid` 2 columns on a phone,
    4 from tablets; the stat sheet `StatEntrySheet` at the bottom: 56 px buttons, made shots filled, missed outlined,
    plays tonal, fouls in the danger tone; substitution and timeout via `showActionSheet`) and `event_log.dart`
    (gutter-aligned lines, rejected state in danger, `EmptyState` before the first event). Sync banner =
    `NoticeBanner` (warning; danger when paused for auth or rejected; retry action). No roster = `EmptyState`.
  - **Match list**: `PageHeader` (title + academy zone as subtitle) with the team filter and the cached chip, one
    `ListRow` per match (`InitialsAvatar` of the opponent from 720 px; phones give the text the width),
    `statusChip` = `StatusChip` (LIVE accent + dot, finished success, cancelled danger, scheduled neutral) + score.
    Create dialog: `formGap` between fields, the date as `DateField` (same picker and range).
  - **Box score**: period scores and the table (`DataTable` themed, totals row on `surfaceMuted`) on `SectionCard`s,
    team totals PTS/REB/AST/TOV as `StatTile`s, warnings in the warning tone. **Season stats**: `PageBody`,
    `PageHeader` (games), averages as `StatTile`s in a `ResponsiveGrid`, matches as `ListRow`s, totals `SectionCard`
    last. **Setup**: rows on cards (outline stronger when selected), hint/summary at the frame edge, error in the
    danger tone. **Edit dialog**: already `FormDialog`, unchanged.
  - Grep proof: `grep -rnE "Color\(0x|colorScheme|AppTokens|fontSize|FontWeight|InfoChip|ChipTone|PopupMenu|
    CircleAvatar|\bCard\(|EmptyView|app/theme.dart|Colors\.|EdgeInsets\.[a-zA-Z]+\([^)]*[0-9]"
    lib/features/match/presentation` = 0 hits; kit uses there: HoopsSpace 62, HoopsTone 13, StatTile 8, SheetAction 7,
    ContentFrame 6, StatusChip 5, showActionSheet 3, SectionCard 3, ResponsiveGrid 3, ListRow 2, PageHeader 2,
    EmptyState 2, PageBody 1, NoticeBanner 1 (named consts for the few sizes: tile min widths, stat button height).
- Verified (2026-11-07):
  - Red first: `test(web)` commit `b0797f8` (7 new tests in `match_screens_test.dart` group "design system (WP74)"
    failed before the restyle; 1 kit test failed to compile before `SheetAction.key`).
  - `flutter analyze`: no issues. `just web-format-check`: 333 files, 0 changed (after the rebase).
  - `just web-test` (fresh, after the rebase onto `81a595a`): **897 passed**, 0 failed (before the rebase, on
    fd918c2: 885 = 865 + 1 kit + 8 design tests + 12 goldens - 1 old golden).
  - Rebase: `goldens/live_match_360x780.png` (modified by WP75, moved by WP74) resolved by deleting it (now
    `goldens/match/live_match_360x780.png`); `home_parent_360x780.png` and the fixture goldens of the match list,
    season stats and setup re-recorded once more for WP75's shell avatar (136 px each); the demo-mock goldens
    were unchanged. WP75's `IconTile` not needed (match rows lead with the opponent's `InitialsAvatar`).
  - Goldens (new folder `test/golden/goldens/match/`, `test/golden/live_match_golden_test.dart`): from the demo mock
    (whole app in mock mode, demo coach, like the landing capture) `live_match_360x780{,_dark}`,
    `live_match_1024x768{,_dark}`, `live_match_stat_sheet_360x780{,_dark}`, `box_score_360x780{,_dark}`; from the
    widget-test fixtures (the mock's dates move with today) `match_list_360x780{,_dark}`, `match_list_1024x768`,
    `season_stats_360x780{,_dark}`, `match_setup_360x780`. Removed `goldens/live_match_360x780.png` (moved).
    Re-recorded `goldens/home_parent_360x780.png` (the parent's home is the match list: now with its PageHeader).
    Reviewed in real fonts (Roboto, demo mock, light + dark, 360 and 1280 px: list, live, stat sheet, log, menu,
    box score, season stats, setup) with a throw-away copy of `landing_screens_capture.dart` writing to `build/`
    (not committed); the live match at 360 px matches the mock-up's layout (scoreboard, strip, tabs, 2-column court,
    bench), in the new tokens. `assets/landing/*.png` untouched.
  - `tool/web_smoke.sh` (mock, Chrome + chromedriver): All tests passed (before and after the rebase).
  - `tool/offline_cold_start.sh` (before and after the rebase): **fails at step 4 "academy picker", before any match screen**: the script waits
    for the text "Elige tu academia", which since WP72 (`080aab7`, tenant switcher on `PageHeader`) is not among
    the leaf semantics texts (seen: "Cambiar de academia" and the two academy rows). Not caused by WP74 (no file
    under `lib/app` or `lib/core/ui/page_layout.dart` changed). A local probe of the same script with
    "Cambiar de academia" as the picker marker passes all 4 steps: "ok: the live match screen renders offline",
    offline banner present, "OK: offline cold start".
- Decisions/ADRs: none new (ADR-0040 applied). Event entry stays the bottom sheet opened from a player tile (one hand,
  near the thumb) rather than a fixed bottom bar, to keep the mock-up's layout. Totals of the season come after the
  match list (like a table footer). The bench tap in the staff widget test now uses a local `scrollAndTap`: with the
  sync banner up, the bench sits below the fold of 360x780 in the test font, and the shared `tapKey` taps the
  pre-scroll position (it does not pump between `ensureVisible` and `tap`).
- Open points / follow-ups:
  - `tool/offline_cold_start.py` picker marker (above): owner of the tenant switcher / the script (WP75 or the
    orchestrator) should look at the `PageHeader` title's semantics or wait for the `tenant-list` rows instead.
  - Kit: `PageBody` / `ContentFrame` centre a narrower section (Align topCenter with loose constraints), so a bare
    `PageHeader` as `PageBody.header` is centred, not left-aligned; worked around here with
    `SizedBox(width: double.infinity)`. Worth fixing in the kit (stretch sections) for WP73/WP75.
  - `test/support/pump_helpers.dart` `tapKey`: add a `pump` after `ensureVisible`, so taps on scrolled widgets hit.
  - `TimezoneNote` (core) pads itself with 16 px, which does not line up inside a `ContentFrame`; the match list shows
    the zone as the `PageHeader` subtitle instead (same text). Training (WP73) still uses `TimezoneNote`.
  - Stat labels with a check / cross glyph ("2 PT ✓") render as tofu in the Roboto-only review captures; browsers
    fall back to a system font. Unchanged strings.
