# WP73 — Web redesign: training, plans, sessions, health, fitness and roster screens

Model: Opus. Wave 2 (2026-11-06, fifth round): starts after wave 1 is merged (WP72 design system, WP78 training
changes); runs alongside WP74 (match), WP75 (admin/platform/auth), WP80, WP86, WP89. You own
`apps/web/lib/features/{training,health,my_players,roster}/**`, their tests, and the goldens
`test/golden/training_health_golden_test.dart`, `roster_golden_test.dart` (+ files under `test/golden/goldens/` for
those). Shared: `lib/core/ui` only as the rule below says; `lib/l10n/*.arb` keys next to the feature's keys, never at
the end. Depends on: WP72 (ADR-0040), WP78 (the session plan picker and search you restyle, do not change their
behaviour). Skills: flutter-feature, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp73-web-redesign-training`, branch `wp73-web-redesign-training`.

Decision 52 of 2026-11-06: every screen takes the design system of WP72 (ADR-0040; tokens in `lib/core/design`,
kit in `lib/core/ui`, the wave 2 checklist in the WP72 handover). Rules for every redesign WP: no behaviour change
(the existing widget tests stay green unless they assert on looks); replace ad-hoc styling with the kit widgets and
tokens (no colours, sizes or paddings inline); every screen in light and dark; responsive (phone width 360 to desktop);
goldens of your features re-recorded and reviewed (describe what changed); the demo mock is the data source for
goldens; `apps/web/assets/landing/*.png` are the reference and must not be modified (decision 57). If the kit lacks a
widget you need, add it to `lib/core/ui` in a SEPARATE commit named `feat(web): kit: <widget>` so the other redesign WPs
can cherry-pick it, and tell the orchestrator.

## Scope
1. **Training**: training week / schedule, sessions list and session screen, attendance, planned absences, plans
   list, plan detail with items, templates, plan assignments and progress, the WP78 picker and search; the "training
   week" screen must match the landing mock-up `training_week.png` closely (it is one of the four showcased screens).
2. **Health and fitness**: injuries, availability, body measurements, physical test types / results / norms; the
   "player health" screen must match `player_health.png` closely.
3. **Roster**: teams, players, approvals, eligibility cases, guardian dialog; `my_players` (parent view).
4. Widget tests kept green; goldens re-recorded; `apps/web/README.md` not yours (WP72 wrote the design section).

## Acceptance
- [ ] Every screen of your features uses the kit and tokens (no inline colour/size literals: grep proof in the handover)
- [ ] Training week and player health screens visually match their mock-ups (golden images attached to the handover
      as paths)
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals); goldens listed
- [ ] `tool/web_smoke.sh` green; handover appended

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
