# WP49 — Web: `dart format` policy (80 columns) and CI check

Model: Sonnet. Wave 4 (2026-11-06, third round): runs ALONE, after every other web change of the round (WP47) is
merged; nobody else edits `apps/web` while it runs. Depends on: nothing else. Skills: flutter-feature,
verification-before-completion. Worktree: `~/code/hoops-wt/wp49-web-format`, branch `wp49-web-format`.

Decision 30 of 2026-11-06: `apps/web` follows the default `dart format` (80 columns); CI fails on unformatted files.

## Scope
1. `cd apps/web && dart format lib test integration_test tool` (not `packages/*`, which `just gen-api` owns; not
   generated `*.g.dart` / l10n output if they are checked in: list what you excluded and why). One commit
   `style(web): dart format (80 columns)` with no other change. Before and after: `flutter analyze` clean,
   `just web-test` green (same totals; goldens unchanged since formatting is not rendering).
2. `justfile`: `web-format` (formats) and the check (`dart format --output=none --set-exit-if-changed <same dirs>`)
   added to `web-test` or as `web-format-check`; `.github/workflows/ci.yml` flutter job runs the check before
   `flutter analyze`; `actionlint` clean. CLAUDE.md command list gains the recipe (one line). `.claude/skills/
   flutter-feature/SKILL.md`: one sentence on the policy.
3. If the `analysis_options.yaml` has a `line_length` or a lint that conflicts with the formatter, align it.

## Acceptance
- [ ] Format commit separate from the tooling commit; `git diff --stat` of the format commit in the handover
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals unchanged); format check green; `actionlint` clean
- [ ] Handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`; for
  the format commit stage the four directories by path). Conventional Commits. A Claude Code hook runs a ~40 s
  tenant-isolation test before every commit (it resyncs the Podman VM clock itself); it is expected, do not try to
  bypass it. End every commit message with the line `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.
