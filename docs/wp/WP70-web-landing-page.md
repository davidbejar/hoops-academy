# WP70 — Web: public landing page (teaser, features, roadmap, invitation request)

Model: Opus. Wave 2 (2026-11-06, fourth round): starts after WP52 is merged; runs alongside WP53 (`apps/web/lib/
core/mock` + the profile-menu reset entry), WP57, WP59, WP61, WP65. You own `apps/web/lib/features/landing/**`,
`apps/web/lib/app/router.dart` (the anonymous routes only), the login screen's link back to the landing,
`apps/web/web/` (landing assets, manifest `start_url` untouched), `apps/web/assets/landing/**`. Shared file
`apps/web/lib/l10n/*.arb`: put every `landing*` key in one block right after the login keys (WP53 adds keys next to
the profile keys). Depends on: `docs/marketing/landing-copy.md` (the copy; decision 50), WP41/WP47 (the demo mock,
for screenshots), WP49 (format policy). Skills: flutter-feature, test-driven-development,
verification-before-completion. Worktree: `~/code/hoops-wt/wp70-landing`, branch `wp70-landing`.

Decision 50 of 2026-11-06: the anonymous root of the web app is a marketing landing page: a teaser of what the
product does, basketball-only positioning, the six feature areas, who it is for, why it costs less, what is coming,
and two calls to action: request an invitation (placeholder form, nothing sent yet) and sign in. Copy is fixed in
`docs/marketing/landing-copy.md` (es/en/id): use it verbatim; if a string must change for layout reasons, change
it in the copy file in the same commit and say so in the handover.

## Scope
1. **Routes**: `/` for an anonymous session renders the landing (`/welcome` alias); a signed-in session keeps the
   current redirect to the app; "Sign in" goes to the existing login flow; the login screen gets a small "Back"
   link to the landing. The splash stays for the signed-in path. `redirectFor` tests updated first (red).
2. **Design** (this is the one page that must look like a product site): large type, generous spacing, the app's
   accent `#E8590C` on near-black and off-white, light and dark variants following the system theme, responsive from
   360 px to wide desktop (phone: single column; desktop: hero with a device mock-up beside the text, feature cards
   in a 3×2 grid, roles in a row). Device mock-ups: real screenshots of the demo mock (training week, live match,
   player health, platform usage) captured with the golden toolchain at phone size, embedded as assets (PNG, sized
   for retina, total under 1.5 MB); subtle entrance motion only (fade/slide, respects reduced-motion). No external
   fonts beyond what the app bundles; no network calls on the landing.
3. **Sections** in the order of the copy file: hero, why basketball-only, six feature cards, four roles, why it
   costs less, coming next, invitation request, footer (AGPL line linking to the GitHub repo, language switch
   reusing the app's locale controller).
4. **Invitation request** (placeholder, decision 51): a form with name, e-mail, role (admin/coach/parent; no
   player), academy name; client validation with the copy's messages; on submit nothing is sent: show the
   confirmation text and clear the form; a `TODO`-free comment referencing the follow-up in FOLLOW-UPS. Do not add
   a backend call or a contract.
5. **Tests**: widget tests per section (renders the copy in each locale, CTA navigation, form validation and the
   confirmation), golden `landing_360x780` and `landing_1280x800` (light and dark), l10n parity, `redirectFor`.
   `tool/web_smoke.sh` gains a first step on the landing (anonymous → sign in button present).
6. **PWA**: the service worker precache includes the landing assets; the offline cold start of the app is not
   affected (the landing is online-first).

## Acceptance
- [ ] Copy rendered verbatim in es/en/id from the ARB keys (a test compares a sample of keys with the copy file
      is overkill; the parity test plus a per-locale widget test suffices)
- [ ] Red tests first; `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh;
      totals); goldens listed; `tool/web_smoke.sh` mock mode green
- [ ] Assets under 1.5 MB total; Lighthouse-style checks are WP54's (note anything you see)
- [ ] Handover appended: screenshots used, any copy change, what the placeholder form does

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Format only the files you change. `pubspec.yaml` assets section may change; no new heavy dependency.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - `apps/web/lib/features/landing/**`: `LandingScreen` (header, hero, why basketball-only, six feature cards,
    four roles, why it costs less on a contrasting band, coming next, invitation request, footer), own palette
    (`#E8590C` on off-white `#FAF7F2` / near-black `#0E0F11`, system light/dark), width classes compact < 720 ≤
    medium < 1024 ≤ wide (hero side by side from 960 px, features 3×2 / 2 / 1, roles 4 / 2 / 1, roadmap 4 / 2 / 1),
    `Reveal` entrance motion (fade + 24 px lift once in view, skipped with the platform's "disable animations"),
    phone `DeviceFrame`, faint court markings behind the hero. No network calls; the GitHub link goes through an
    `ExternalLinkOpener` port (`window.open`, `noopener`).
  - Routes: `/` and `/welcome` render the landing for anonymous sessions (`redirectFor` keeps them while auth
    initialises or is signed out; every other app route still goes to `/login`; signed-in sessions are redirected to
    the app as before). The router no longer forces `initialLocation: '/splash'` so a cold start at `/` can become
    the landing; the root shows a plain loading view while the auth status is unknown (no landing flash for a
    signed-in user; the splash stays for the profile load). Login screen: "Back" link (`login-back`) to `/`.
  - Screenshots used (demo mock, Academia Demo, Spanish, 360×780 @2x, real Roboto + Material icons):
    `assets/landing/live_match.png` (vs Tigres, hero front), `training_week.png` (hero back), `player_health.png`
    (Leo Gil's injury, next to "why basketball-only"), `platform_usage.png` (usage trend, on the cost band); 496 KiB
    total. Regenerate with `flutter test test/golden/landing_screens_capture.dart` (no `_test` suffix, never run by
    `flutter test`); `HOOPS_CAPTURE_LANDING=1` also writes full-page review pictures to `build/landing_review/`.
  - Invitation form (placeholder, decision 51): name (optional; the copy has no message for it), e-mail, role
    (admin / coach / parent, no player), academy name; client validation with the copy's three messages; on a valid
    send nothing leaves the page: the form is cleared and the confirmation text shown (hidden again on the next
    edit). Domain `InvitationRequest` documents the follow-up in FOLLOW-UPS ("Invitation-only sign-up").
  - Footer: AGPL line + "Source code on GitHub." link (the copy's sentence rendered as two keys, text unchanged),
    language switch reusing `localePreferenceProvider` (stored choice), sign-in link. No privacy link: no policy page
    exists.
- Verified (2026-11-06, worktree `wp70-landing`):
  - Red first: `test/core/redirect_test.dart` (2 new cases failed before `redirectFor` changed), landing widget and
    domain tests written before the screens.
  - `flutter analyze`: no issues. `just web-format-check`: 277 files, 0 changed.
  - `just web-test` (fresh): **724 passed**, 0 failed. New: 6 `invitation_request_test`, 19 `landing_screen_test`
    (copy of every section in es/en/id, default Spanish, sign-in / footer sign-in / Back, scroll to the form,
    `/welcome` for anonymous and signed-in users, validation messages, malformed e-mail, confirmation + cleared form,
    confirmation hides on edit, language switch persisted, GitHub link, no privacy link, splash while auth unknown,
    reduced motion, fade-in), 4 redirect cases, 1 auth-guard case, 1 service-worker precache case; l10n parity green.
  - Goldens added: `landing_360x780.png`, `landing_360x780_dark.png`, `landing_1280x800.png`,
    `landing_1280x800_dark.png` (test font, as the other goldens; screenshots decoded before capture).
  - `tool/web_smoke.sh` (mock mode, Chrome/chromedriver 156): All tests passed; the journey now starts with
    "landing shown → header sign-in → login".
  - `HOOPS_ALLOW_HTTP_ISSUER=1 tool/build_web.sh`: release build OK, `sw.js` precaches the four
    `assets/assets/landing/*.png` (184 files).
- Decisions/ADRs: none new (decisions 50/51 applied). Copy change: one string added to the copy file, section 9
  "Login screen": Back / Volver / Kembali (`landingBack`); no existing string changed.
- Open points / follow-ups:
  - Outside the owned files but required by the route change: `test/app/auth_guard_test.dart`,
    `test/app/mock_mode_test.dart`, `integration_test/*_smoke_test.dart`, `test/tool/sw_manifest_test.dart`,
    `lib/core/session/session.dart` and `tool/browser_login_check.py` (now taps sign-in on the landing, then on the
    login screen, until the Keycloak form appears). The real-Keycloak check (`ci_login_check.sh`) was not run
    locally (needs the stack); CI's browser job will exercise it.
  - For WP54 (Lighthouse): white on `#E8590C` buttons is about 3.6:1 (AA only for large text; labels are 17 px bold);
    small orange text uses `#C2410C` on light. The screenshots are light-theme captures also in dark mode.
  - Seen while capturing: the platform tenant detail shows the raw metric key `trainingSchedules` in its per-module
    counters (missing label); the capture is scrolled past it. Not fixed (not in scope).
  - The landing assets are precached like every build file, so the landing also opens offline; the app's offline
    cold start is unchanged.
