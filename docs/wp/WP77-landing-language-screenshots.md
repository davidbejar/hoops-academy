# WP77 — Landing: language switch in the header, screenshots per locale re-captured from the redesigned app

Model: Sonnet. Wave 4 (2026-11-06, fifth round): starts after wave 3 is merged (every screen redesigned, the form
wired by WP90); runs alongside WP88 (backend mutation round + `apps/web/tool/mutation*` only). You own
`apps/web/lib/features/landing/**`, `apps/web/assets/landing/**`, `apps/web/test/golden/landing_*.dart` +
`landing_screens_capture.dart`, `apps/web/pubspec.yaml` assets list, `docs/marketing/landing-copy.md` (only if a
string changes). `lib/l10n/*.arb`: keys next to the landing keys. Depends on: WP70, WP72–WP75 (the look the
screenshots must show), decision 57. Skills: flutter-feature, test-driven-development, verification-before-completion.
Worktree: `~/code/hoops-wt/wp77-landing-i18n`, branch `wp77-landing-i18n`.

Decision 57 of 2026-11-06: the language switch moves to the header; screenshots stay PNGs, captured per locale
(es/en/id) from the redesigned app at the end of the round; the old PNGs are replaced only now.

## Scope
1. **Header language switch**: next to Sign in (and still reachable in the footer if the design keeps it); persisted
   as today (`localePreferenceProvider`); widget test.
2. **Screenshots per locale**: `landing_screens_capture.dart` captures the four screens (training week, live match,
   player health, platform usage) from the demo mock in es, en and id at the same size as today (360×780 @2x), light
   theme (and dark if the landing has a dark mode: then both); assets `assets/landing/<screen>_<locale>.png`; the
   landing picks the set of the current locale (fallback en); the parity test checks the twelve files exist and are
   fresh (a hash of the screens' golden vs the asset, or a date in a manifest); `pubspec.yaml` assets updated.
3. **Goldens**: `landing_golden_test.dart` re-recorded per locale.
4. Keep the size budget: report the total asset bytes before and after (PNG quantised if needed, no Node).

## Acceptance
- [ ] Header switch with a widget test; `flutter analyze` clean; `just web-format-check` clean; `just web-test`
      green (fresh; totals)
- [ ] Twelve screenshots committed, taken from the redesigned app; `tool/web_smoke.sh` and `tool/lighthouse.sh`
      green (score unchanged)
- [ ] Handover appended (asset bytes before/after)

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
  - Header language switch (`landing-header-lang`, a popup menu showing the current code ES/EN/ID with the three
    language names, items `landing-header-lang-<code>`), left of Sign in, on every width; it sets
    `localePreferenceProvider` (stored as before). The footer switch stays (`landing-lang-<code>`), untouched.
    Tooltip reuses the existing `language` key: no new ARB key, no copy change.
  - `LandingShot.assetFor(languageCode)` picks `assets/landing/<screen>_<es|en|id>.png`, fallback en; `DeviceFrame`
    reads the locale from the context (no call site changed).
  - Twelve screenshots (training week, live match, player health, platform usage x es/en/id), captured from the
    redesigned app (WP72-76) on the demo mock, 720x1560 (360x780 @2x), light theme (the app has no dark capture; the
    landing's own dark mode only changes the page, not the screens). The four old unsuffixed PNGs are deleted.
  - `landing_screens_capture.dart` loops the three languages (seeds `hoops.locale`) and writes
    `assets/landing/manifest.json` (SHA-256 per PNG, size). `landing_assets_test.dart` (parity): twelve files exist,
    each matches the manifest hash and is 720x1560, no stray PNG. Freshness is "hash of the capture", re-run the
    capture after a screen changes and commit the PNGs + manifest together.
  - Goldens: the four existing landing goldens re-recorded (header + new shots); new `landing_360x780_en/_id`.
  - `sw_manifest_test` updated for the twelve assets. `pubspec.yaml` unchanged (`assets/landing/` is a directory entry).
- Verified:
  - Red first: header and locale-asset tests failed before the code (no key / no `assetFor`).
  - `flutter analyze`: no issues. `just web-format-check`: 361 files, 0 changed.
  - `just web-test` (fresh): **1005 passed**, 0 failed.
  - `tool/web_smoke.sh` (mock journey in Chrome): All tests passed. `tool/lighthouse.sh`: PWA score 1 (unchanged).
  - Asset bytes: before 499,102 (4 PNGs); after 1,403,241 (12 PNGs: es 483,239, en 461,477, id 458,525). A visitor
    downloads one set (~460-480 KB, equal to before). No PNG quantiser on the host (pngquant/oxipng absent), none used.
- Decisions/ADRs: none. Popup menu rather than three inline links so it fits 360 px next to the brand and Sign in.
- Open points:
  - The service worker precaches every file of the build, so the install now fetches all twelve PNGs (+~900 KB over
    before). If that matters, exclude the other languages from `collectPrecache` or quantise the PNGs (tool needed).
  - First capture run on a clean tree fails once (the landing at `/` asks for assets not yet written); run it twice.
  - Indonesian bottom nav wraps "Pertandingan" over two lines at 360 px (visible in `live_match_id.png`): an app
    layout issue outside this WP.
