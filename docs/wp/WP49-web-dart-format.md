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

## Handover
- Built: format commit `style(web): dart format (80 columns)` = 192 files changed, 17751 insertions(+), 6603 deletions(-) (lib, test, integration_test, tool only). Tooling commit: `just web-format`, `just web-format-check`, ci.yml flutter job runs the check before `flutter analyze`, CLAUDE.md line, flutter-feature sentence, analysis_options.
- Excluded: `packages/*` (owned by `just gen-api`), `build/`, `web/`. Generated `lib/l10n/gen/*` and `match_database.g.dart` are inside the formatted dirs but were already formatted, so they came out unchanged (the check covers them and is green).
- Lint alignment: after formatting, `flutter analyze` reported 87 `curly_braces_in_flow_control_structures` infos (the formatter puts `if (x) return y;` on two lines). The rule is disabled in `apps/web/analysis_options.yaml` rather than adding braces (not a formatting-only change). So the format commit alone is not analyze-clean; the tooling commit that follows is.
- Verified: before: analyze clean, `flutter test` +668 all passed. After both commits: `just web-format-check` 256 files, 0 changed; `flutter analyze` no issues; `flutter test` +668 all passed (goldens unchanged); `actionlint` clean on ci.yml.
- Open points: none.
