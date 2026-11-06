# WP54 — Web: PWA installability, airplane-mode cold start, F-07 cache keys

Model: Sonnet. Wave 3 (2026-11-06, fourth round): starts after WP53 is merged; runs alongside WP62 (athlete norms)
and WP66 (Redpanda infra). You own `apps/web` (lib, test, tool, web/) this wave; nobody else edits it.
Depends on: WP14b (F-07 partial fix), `docs/security/review-2026-11.md` F-07. Skills: flutter-feature,
test-driven-development, owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp54-web-pwa`, branch `wp54-web-pwa`.

Decision 36 of 2026-11-06: the PWA passes an installability audit, the offline cold start is proven by a scripted
check, and cached match reads are scoped by tenant and person (F-07 residual).

## Scope
1. **Lighthouse**: no Node on the host (project rule). Run Lighthouse from a container
   (`podman run --rm --network host <lighthouse image pinned by tag>` against the built app served by the compose
   nginx or `tool/serve_build.sh` if present) in PWA/installability mode; record the score and fix every
   installability failure (manifest, icons, service worker scope, start_url, theme colour). Add
   `apps/web/tool/lighthouse.sh` (pinned image, prints the installability checks) and document it in
   `docs/runbooks/` (the web runbook or e2e.md).
2. **Airplane-mode cold start**: `apps/web/tool/offline_cold_start.sh` (or a Flutter `integration_test` with
   chromedriver): load the app once online, go offline (chromedriver network conditions or a proxy kill), reload,
   assert the shell renders and the last match opens from the local DB. README "Offline cold start" section updated
   with the command.
3. **F-07 cache keys**: `MatchStore` reads (`roster`, `matchJson`, `ownEvents`) keyed by tenant + matchId, and a wipe
   when a different `sub` signs in after an expired session (the review's open points). Red tests first in
   `match_store_*_test.dart`.
4. `docs/security/review-2026-11.md` F-07 row: status updated (you own only that row this wave).

## Acceptance
- [ ] Lighthouse installability: all checks pass (output in the handover); `tool/lighthouse.sh` committed
- [ ] Offline cold-start check green and documented; `tool/web_smoke.sh` still green
- [ ] Red tests for the cache keys and the sub-change wipe committed first; `flutter analyze` clean;
      `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- No Node, npm or npx on the host; containers only.
- Do not edit README.md beyond the "Offline cold start" section, nor docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built: (1) `apps/web/tool/lighthouse.sh`: Lighthouse 11.7.1 (pinned `femtopixel/google-lighthouse`; v12 dropped the PWA
  category) in a Podman pod with `nginx:1.27-alpine` serving `build/web` on localhost; prints score and checks, exit 1 on a
  failure; documented in `docs/runbooks/e2e.md`. (2) `tool/offline_cold_start.sh` + `.py` (stdlib WebDriver): online load until
  `sw.js` controls the page (185 files cached), static server stopped + offline emulation, reload, shell renders, mock
  sign-in, live match opens with the offline banner; README "Offline cold start" updated. (3) F-07: `MatchStore.roster`,
  `saveRoster`, `matchJson`, `ownEvents`, `watchOwnEvents` now require tenant (+ person); drift schema v2 (roster cache keyed
  by tenant, `device.owner_sub`); `MatchStore.bindOwner(sub)` wipes when another `sub` owns the DB, driven by
  `matchOwnerProvider` (token `sub`, awaited by the live match and match list notifiers). (4) Added the missing platform
  counter labels (`trainingSchedules`, `finishedMatches`, `membersAdmin`, `membersCoach`) in es/en/id. F-07 row updated.
- Verified: Lighthouse PWA score 1; installable-manifest, splash-screen, themed-omnibox, viewport, maskable-icon pass,
  content-width n/a, three manual audits; no manifest/icon/SW change was needed. `tool/offline_cold_start.sh` green.
  Red tests first (commit a367884: `match_store_scope_test.dart`, 8 tests), then `match_owner_test.dart`,
  `usage_counter_label_test.dart`. Fresh: `flutter analyze` no issues; `dart format ... lib test integration_test tool`
  0 changed; `flutter test` 777 passed; `tool/web_smoke.sh` All tests passed.
- Decisions/ADRs: none. A DB without an owner (fresh or pre-WP54) adopts the first `sub` instead of wiping; mock mode
  (non-JWT token) binds nothing. The wipe on a `sub` change discards that device's unsynced events of the previous user.
- Open points / follow-ups: Lighthouse does not test colour contrast and the Flutter canvas has no DOM text, so the
  white-on-#E8590C (about 3.6:1) note from WP70 is unverified and unchanged. The offline check runs against the mock API
  (in-process), so the cached-read fallback is covered by unit tests, not the browser script. `synced_events` reads are
  still keyed by matchId only (covered by the wipe on sub change). Not wired into CI.
