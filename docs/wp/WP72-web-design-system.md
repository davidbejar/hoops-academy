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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
