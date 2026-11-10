# WP95 — Web leftovers: design-system kit, Indonesian bottom navigation, audit label, landing precache

Model: Sonnet · effort medium. Wave 1 (2026-11-10, sixth round): runs alongside WP92 (it owns
`apps/web/lib/features/training/**`, the athlete Dart package and the athlete mock), WP91 (core), WP93, WP94. You
own the shared kit (`apps/web/lib/core/design`, `apps/web/lib/core/ui`), `apps/web/lib/features/audit/**`,
`apps/web/lib/features/landing/**`, the bottom navigation labels in `apps/web/lib/app/shell.dart`, the PWA precache
script and their tests and goldens. `apps/web/lib/l10n/*.arb`: keys next to the related feature's keys, never at the
end. `apps/web/pubspec.lock`: revert any drift. Depends on: FOLLOW-UPS "Web app" (kit follow-ups WP72–WP75, WP77),
ADR-0040. Skills: flutter-feature, clean-code, test-driven-development, verification-before-completion. Worktree:
`~/code/hoops-wt/wp95-web-leftovers`, branch `wp95-web-leftovers`.

## Scope
1. **Kit follow-ups** (one commit each): `PageBody` / `ContentFrame` stretch a narrower section (remove the
   `SizedBox(width: double.infinity)` workarounds); `SectionCard` provides a transparent `Material` for a
   `CheckboxListTile`; `AsyncBody` renders `EmptyState` for empty lists; delete `AppTokens`, `InfoChip` and
   `ChipTone` once nothing uses them; `LandingPalette` reads `HoopsColors`; one fab-clearance constant in
   `HoopsSize` instead of the per-feature copies; a kit `PickerDialog` for the `AlertDialog` + `ListTile` pickers;
   `TimezoneNote` lines up inside a `ContentFrame`.
2. **Indonesian bottom navigation**: "Pertandingan" wraps over two lines at 360 px. Fix it in the layout (label
   scaling or ellipsis rules of the kit) or with a shorter label a native speaker would accept; a widget test at
   360 px for es / en / id.
3. **Audit label**: `tenant.request_accepted` shows its wire name; add `auditActionTenantRequestAccepted` in
   es / en / id next to the other audit keys, with a test that every action of the contract's enum has a label.
4. **Landing screenshots out of the precache**: an install fetches all twelve PNGs. Precache only what the offline
   cold start needs (the screenshots of the other languages are fetched on demand); keep
   `tool/offline_cold_start.sh` passing; fix the capture script failing once on a clean tree if it is quick.

## Acceptance
- [ ] Red tests committed before each change
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] Goldens: list every re-recorded file and why in the handover
- [ ] Handover appended; no JVM build is needed for this WP

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.
- A kit change must not alter the goldens under `features/training` (WP92 re-records there right now). If one
  would, leave that kit item undone and report it; replacing a workaround inside `features/training` is also left
  to a later pass.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
