# WP124 — Web: finance expenses, balance, exports; coach status view; family dues

Model: Sonnet · effort high. Wave 4 (2026-11-15, eighth round): starts after WP121 and WP122 are merged and `ci` is
green on them; runs alongside WP123 (Go service, e2e). You are the only web WP of the wave: you own `apps/web/**`
except the generated packages. Depends on: the WP121, WP119 and WP118 handovers, ADR-0056, decisions 96, 99. Skills:
flutter-feature, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp124-web-finance-rest`, branch `wp124-web-finance-rest`.

Decision 96 of 2026-11-15 (owner): PARENT reads the dues and payments of linked players, PLAYER their own; a team's
current COACH reads who of the team is up to date (status only); ASSISTANT_COACH nothing. Decision 99: fixed expense
categories, localised in the web.

## Scope
1. **ADMIN**: expenses (list, create, edit, delete; category labels es / en / id), season balance (figures and one
   chart from the kit's chart card), export buttons for dues and expenses with the existing export button pattern.
2. **COACH**: on the team's screen, who is up to date (a marker per player, no amounts); only for the team's
   current coach.
3. **PARENT / PLAYER**: the dues of each linked player (or their own) with state and payment date, where the
   family's player screens live (`features/my_players`, `features/me`).
4. **Capabilities**: the visibility rules in one place, tested per role; the demo mock extended.
5. If WP123 bumped the contract, use the regenerated package after the orchestrator says it is on `main`.

## Acceptance
- [ ] Red tests committed before each change; goldens for the new screens in light and dark
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean; `just mutation`
      for the web tool unchanged if you touched files in its manifest
- [ ] Handover appended: the routes per role, what nobody checked in a real browser

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
