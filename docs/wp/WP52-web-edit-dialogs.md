# WP52 — Web: match edit, jersey removal, member data and academy contact edits

Model: Sonnet. Wave 1 (2026-11-06, fourth round): runs alongside WP56 (realm), WP58 (core), WP60 (game), WP63
(kind), WP64 (workflows). You own `apps/web/lib/features/{match,roster,admin,tenant}` and their tests; you are the
only agent in `apps/web` this wave. `apps/web/lib/l10n/*.arb`: add keys next to the related feature's keys, never
at the end of the file. Depends on: WP44, WP45 (the `clear` lists and `MatchesRepository.update`). Skills:
flutter-feature, test-driven-development, verification-before-completion. Worktree:
`~/code/hoops-wt/wp52-web-edit-dialogs`, branch `wp52-web-edit-dialogs`.

Decision 34 of 2026-11-06: the app exposes every edit the contracts already allow.

## Scope
1. **Match edit dialog** (`features/match`): opponent, date/time (academy zone), home/away, venue (clearable),
   periods; wired to `MatchesRepository.update` (sends `clear` for an emptied venue); roles per
   `docs/domain/authz-matrix.md`; not offered once the match has events unless the contract allows it (check and
   say so in the handover).
2. **Jersey removal** (`features/roster`): the jersey dialog accepts an empty value and sends `clear: [jerseyNumber]`
   (WP44 handover: `noteDialog(required: true)` is the blocker).
3. **Member personal data** (`features/admin` or wherever members are listed): edit dialog for the fields of
   `UpdateMemberRequest` (email, phone, birthDate, gender clearable; mind the 422 `LOGIN_REQUIRES_EMAIL` rule: a
   member with a login cannot clear the e-mail, show the server message).
4. **Academy contact** (`features/tenant` profile): contactEmail and websiteUrl editable and clearable.
5. The demo mock already honours `clear` for these PATCHes (WP44/WP45); extend its data only if a dialog needs it.

## Acceptance
- [ ] Red widget test committed before each dialog (opens with current values, sends the right request incl.
      `clear`, server error keeps the dialog open, role gating)
- [ ] l10n parity green (es/en/id); goldens regenerated only where a screen changed (list them)
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] Handover appended with anything the contracts lack

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Format only the files you change (`dart format <file>`); the CI check runs on the whole app.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
