# WP122 — Web: PDF buttons for the match sheet and the team roster

Model: Sonnet · effort medium. Wave 3 (2026-11-15, eighth round): starts after WP116 (core 3.7.0) and WP117 (game
2.4.0) are merged; runs alongside WP121 (web `features/finance`, shell navigation) and WP119 / WP120 (no web). You
own the export buttons and their providers in `apps/web/lib/features/roster/**` and `apps/web/lib/features/match/**`
with their tests, and the PDF keys in `apps/web/lib/l10n/*.arb` (next to the existing export keys). You do not touch
the shell or `features/finance`. Depends on: the WP116 and WP117 handovers, the WP97 / WP101 / WP108 handovers (how
the export buttons and the browser download work), ADR-0048. Skills: flutter-feature, test-driven-development,
clean-code, verification-before-completion. Worktree: `~/code/hoops-wt/wp122-web-pdf-buttons`, branch
`wp122-web-pdf-buttons`.

Decision 90 of 2026-11-15 (owner): PDF buttons next to the existing export buttons.

## Scope
1. **Team roster PDF**: next to the roster CSV button, with the same visibility rule (ADMIN and the team's current
   coach, WP108); downloads the PDF from core with the user's language.
2. **Match sheet PDF**: next to the match's export button, for whoever the WP117 handover says may read it.
3. **Behaviour**: online only (a clear message offline, as the server-side exports); the 503-style Problem when
   `pdf-service` is down shows a message, not a crash; file name from the response; the demo mock answers a small
   fixed PDF.
4. **l10n** es / en / id.

## Acceptance
- [ ] Red tests committed before each change
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean
- [ ] Handover appended: where the buttons are, what nobody checked in a real browser

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first (JDK 25). Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace in generated files: re-add
  and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit
  (it resyncs the Podman VM clock itself); under load it can time out: retry when a build has finished, never bypass
  it. End every commit message with a `Co-Authored-By:` line that names the model you are.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Gate rules: constant SQL with bound parameters (CodeQL), no nil-tenant bind without a dated acceptance (Semgrep), no
  environment-derived program names in scripts and tests (Semgrep taint). Since WP113 the PMD / CPD gate runs in
  `verify`: stay inside its thresholds, add no exclusion without a reason.
- An OpenAPI generator run can leave whitespace-only diffs in the Dart packages: discard them. Regenerate only your
  package (`scripts/gen-api.sh <svc>`). `apps/web/pubspec.lock`: commit it only with a generated package's version
  bump; revert other drift. `apps/web/lib/l10n/*.arb`: keys next to the feature's existing keys, never at the end.
- Shared index files (`docs/adr/README.md`, `docs/domain/authz-matrix.md`): append at the end, one entry per line.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
