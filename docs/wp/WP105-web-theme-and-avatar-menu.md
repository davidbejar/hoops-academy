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
- Built:
  - `lib/core/l10n/theme_mode_controller.dart`: `themeModePreferenceProvider` (shared preferences key `hoops.themeMode`,
    values `system|light|dark`, missing or unknown = system); `HoopsApp` passes it as `MaterialApp.themeMode`.
    `theme_mode_labels.dart`: label and icon of a `ThemeMode`.
  - `lib/app/avatar_menu.dart`: the avatar button (`profile-button`, unchanged key) now opens the menu: a bottom sheet on
    phones, a panel at the top right from tablets up (same pattern as the context switcher). Content with kit widgets
    only (`ListRow`, `SectionCard`, `IconTile`, `InitialsAvatar`): person row (`avatar-menu-profile`, opens `/profile`),
    language rows (`lang-es|en|id`, keys kept), theme rows (`theme-system|light|dark`). A choice applies at once and the
    menu stays open. The language choice still tells the server (`updateLocale`, errors swallowed), as the profile did.
    It works in every shell layout and context (academy and application admin).
  - Profile screen: language section removed, nothing else touched. Landing header: theme menu next to the language
    picker (`landing-header-theme`, `landing-header-theme-<mode>`); the brand shows the mark only when under 110 px
    (the extra button made the Row overflow in the 360 px tests).
  - ARB (es, en, id) `themeTitle|themeSystem|themeLight|themeDark` after `languageName_id`; `l10n/gen` regenerated.
- Verified (fresh, in the worktree): `flutter analyze` no issues; `just web-format-check` 0 changed of 451 files;
  `flutter test` (all of `apps/web`): 1454 passed, 0 failed. New tests: `test/app/theme_mode_test.dart` (default,
  unknown value, system follows platform brightness, explicit beats platform and is stored, survives a reload),
  `test/app/avatar_menu_test.dart` (phone, tablet, desktop, app admin, language and theme choice, check marks, profile
  link, profile without language), landing header theme switch in `landing_screen_test.dart`. Red tests were committed
  first (131e2251). Tests that opened the profile via the avatar now use `test/support/avatar_menu.dart`
  (`openAvatarMenu`, `openProfile`); the old language-picker test moved from `locale_test.dart` to the avatar menu test.
- Goldens: new `avatar_menu_{360x780,1024x768}_{light,dark}.png`; re-recorded `landing_360x780`, `landing_360x780_dark`,
  `landing_360x780_en`, `landing_360x780_id`, `landing_1280x800`, `landing_1280x800_dark` (the header gained the theme
  icon). No other golden changed. The goldens use the Ahem test font (blocks).
- Decisions/ADRs: none new (decision 79 applies). Commit note: `git commit --no-verify` was refused by the permission
  classifier, so both commits used a plain `git commit` (the repo's pre-commit hooks ran and passed, including the
  tenant-isolation hook).
- User guides (es/en/id) must say now: language and theme are chosen in the menu behind the round avatar with the
  initials (top right, every screen of the app), not on the profile screen; that menu also holds the link to the profile.
  Theme: Light, Dark or System (default, follows the device); remembered in this browser. On the landing page, before
  signing in, language and theme are in the header (globe code and sun/moon icon).
- Open points: (1) the academy chooser screen (`NeedsTenant`) and the profile screen sit outside the shell, so they have
  no avatar menu: someone with several academies who has not chosen one cannot change language or theme there (the
  landing header covers it before sign-in). A small follow-up could add the picker to the chooser. (2) The profile
  screen still shows its own back route only; WP108 owns its name form. (3) `pubspec.lock` untouched; no mock or journey
  test needed changes beyond the helper above.
