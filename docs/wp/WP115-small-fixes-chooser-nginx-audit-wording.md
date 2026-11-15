# WP115 — Small fixes: language and theme on the academy chooser, compose nginx limits, audit wording

Model: Sonnet · effort medium. Wave 1 (2026-11-15, eighth round): runs alongside WP111 (compose.yaml, chart, CI),
WP112, WP113 (poms) and WP114 (Containerfile). You own `apps/web/lib/features/tenant/**` with its tests and goldens,
`infra/compose/nginx.conf` (and `infra/compose/nginx/**`), `docs/domain/audit-events.md`. No other WP touches
`apps/web` in this wave. Depends on: the WP105 handover (avatar menu, pickers), ADR-0033 (the gateway's limits),
ADR-0044, ADR-0048. Skills: flutter-feature, test-driven-development, clean-code, verification-before-completion.
Worktree: `~/code/hoops-wt/wp115-small-fixes`, branch `wp115-small-fixes`.

Decision 100 of 2026-11-15 (owner): the small fixes bundle.

## Scope
1. **Academy chooser**: someone with several academies who has not chosen one can change language and theme there
   (reuse WP105's pickers; the chooser sits outside the shell). Widget tests first; goldens in light and dark.
2. **Compose nginx**: `limit_req` for the CSV export paths and the public `POST /platform/academy-requests`, with
   the gateway's numbers (10/min + 2/s per IP, ADR-0033 and its amendments); a 429 answers as the existing zones do.
   Prove with a loop of requests against `just up` (record the first 429).
3. **Audit wording**: `docs/domain/audit-events.md`, `team.roster_exported`: ADMIN or the team's *current* coach
   (decision 83).

## Acceptance
- [ ] Red tests committed before the web change
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean
- [ ] nginx: `nginx -t` passes in the container; the 429 observed for both paths
- [ ] Handover appended: the new goldens, the limits as configured

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
