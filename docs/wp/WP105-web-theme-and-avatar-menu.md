# WP105 — Web: light / dark / system theme; language and theme in the avatar menu

Model: Sonnet · effort high. Wave 1 (2026-11-14, seventh round): runs alongside WP104 (OpenTofu, chart values),
WP106 (core and the generated `apps/web/packages/core`) and WP107 (seed script). You own `apps/web/lib/app/**`,
`apps/web/lib/core/l10n/**`, a new theme controller next to the locale controller, the language part of
`apps/web/lib/features/profile/presentation/profile_screen.dart`, the pickers in
`apps/web/lib/features/landing/presentation/sections/header_footer.dart`, and their tests and goldens. Nobody else
touches `apps/web` on `main` in this wave except the generated `packages/core` (WP106). `apps/web/lib/l10n/*.arb`: add
keys next to the related feature's keys, never at the end of the file. Depends on: decision 79, ADR-0040 (design
system), ADR-0049 (contexts and the shell). Skills: flutter-feature, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp105-web-theme`, branch `wp105-web-theme`.

Decision 79 of 2026-11-14 (owner): the user chooses **light, dark or system** (default: system), remembered in the
browser like the language. **Language and theme move together** from the profile screen to the menu behind the
avatar in the top bar, reachable from every screen; the landing header keeps its own pickers (language, and now
theme too, so the choice exists before sign-in).

Why: the app only follows the operating system today (`MaterialApp` has no `themeMode`), so on a Mac in dark mode
the owner never saw the light look of the landing screenshots.

## Scope
1. **Theme mode** (`lib/app`, `lib/core`): a controller like `locale_controller.dart` (shared preferences, key of its
   own); `MaterialApp.themeMode` follows it; an unknown or missing stored value means system. Unit tests first.
2. **Avatar menu** (`lib/app/shell.dart` and what it uses): language and theme are chosen in the menu the avatar
   opens, on phone and on the wide layout, in every context (academy and application admin). Find out what the avatar
   opens today and extend it with the design system's kit widgets, no new ad-hoc dialog. The profile screen loses its
   language section; nothing else on that screen changes (WP108 works on its name form in the next wave).
3. **Landing header**: a theme choice next to the language picker, with the same controller.
4. **Texts** in es, en and id. **Goldens**: the menu in light and dark, phone and wide; re-record only goldens whose
   picture really changed and say which in the handover.
5. Flutter 3.50 note: Material comes from `package:material_ui/material_ui.dart` (51f2dd0c); do not import
   `package:flutter/material.dart`.

## Acceptance
- [ ] Red tests committed before each change
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] A chosen theme survives a reload (test); system follows the platform brightness (test)
- [ ] Language and theme reachable from the avatar on every shell layout; gone from the profile screen
- [ ] Handover appended: the goldens re-recorded and why; what the user guides (es / en / id) must say now (the docs
      pass edits them); anything the mock or the journey tests needed

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with a
  `Co-Authored-By:` line that names the model you are.
- `apps/web/pubspec.lock`: do not commit drift.
- The owner may have the app running on port 5173 and the services on 8081–8083: never stop them.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
