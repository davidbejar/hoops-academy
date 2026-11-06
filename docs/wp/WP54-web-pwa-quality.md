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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
