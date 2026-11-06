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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
