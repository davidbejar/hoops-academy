# WP108 — Web: exercise catalogue for PARENT and PLAYER; own-name form on given / family name; export button rule

Model: Sonnet · effort medium. Wave 2 (2026-11-14, seventh round): starts after WP105 (avatar menu, profile screen)
and WP106 (core 3.6.0 and its Dart package) are merged; runs alongside WP109 (JDK 25 on its own branch, no file in
common on `main`). You own `apps/web/lib/features/training/**` (the catalogue screens),
`apps/web/lib/features/profile/**`, the roster export button in `apps/web/lib/features/roster/**`, the `/me` part of
`apps/web/lib/core/mock/**`, the routes and capabilities these need, and their tests and goldens.
`apps/web/lib/l10n/*.arb`: add keys next to the related feature's keys, never at the end of the file. You change no
service code and no contract. Depends on: decisions 82, 83 and 84, the WP106 handover (the status a former coach
gets, the shape of the `/me` names), the WP105 handover (what moved out of the profile screen), ADR-0047 (exercise
catalogue), ADR-0049 (own data), `docs/domain/authz-matrix.md`. Skills: flutter-feature, test-driven-development,
clean-code, verification-before-completion. Worktree: `~/code/hoops-wt/wp108-web-families-name`, branch
`wp108-web-families-name`.

Decision 82 of 2026-11-14 (owner): PARENT and PLAYER can browse the exercise catalogue in the web app; the API
already lets every role read it, the web shows it only inside the staff-only plan library.

Decision 83: the roster export is for the team's current staff and ADMIN; the web must not offer it to a former
coach looking at an ended season.

Decision 84: the "Your name" form uses the given and family name that `/me` now returns per membership.

## Scope
1. **Catalogue for families**: a read-only way into the exercise catalogue for PARENT and PLAYER from the training
   area (global and the academy's own exercises, the texts in the chosen language); no create, edit or delete for
   them. Staff keep what they have. Widget tests per role first; one golden.
2. **Own name**: the form reads `givenName` and `familyName` of the current membership and sends what changed; the
   split at the first space goes away, with its tests. The demo mock returns the two fields.
3. **Export button**: shown only where the server allows the export (current staff of the team, ADMIN); an ended
   season viewed by a former coach shows the roster without the button. Test with the roles of the matrix.
4. **Texts** in es, en and id.

## Acceptance
- [ ] Red tests committed before each change
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] The split-at-first-space code and its tests are gone
- [ ] Handover appended: the goldens added or re-recorded; what the user guides (es / en / id) must say now (the docs
      pass edits them)

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Material comes from `package:material_ui/material_ui.dart` (Flutter 3.50, 51f2dd0c); do not import
  `package:flutter/material.dart`.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with a
  `Co-Authored-By:` line that names the model you are.
- `apps/web/pubspec.lock`: do not commit drift. Never hand-edit `apps/web/packages/*` (generated).
- The owner may have the app running on port 5173 and the services on 8081–8083: never stop them.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
