# WP121 — Web: Finance area for ADMIN (settings, fee plans, dues, payments)

Model: Sonnet · effort high. Wave 3 (2026-11-15, eighth round): starts after WP118 is merged (contract `finance.yaml`
1.0.0 and `apps/web/packages/finance`); runs alongside WP119 (the Go service behind the same contract), WP120
(observability) and WP122 (web PDF buttons: `features/roster` and `features/match` export buttons only). You own
`apps/web/lib/features/finance/**` with its tests and goldens, the shell's navigation entry and route for Finance,
the finance part of the demo mock, and the finance keys in `apps/web/lib/l10n/*.arb` (a new block next to the admin
feature's keys, never at the end). You do not regenerate any package. Depends on: the WP118 handover, ADR-0056,
decisions 93–99, the design-system kit (WP95). Skills: flutter-feature, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp121-web-finance-admin`, branch `wp121-web-finance-admin`.

Decision 92 of 2026-11-15 (owner): the finance web screens land this round. This WP: what ADMIN does with settings,
fee plans, dues and payments. WP124 adds expenses, balance, exports, the coach's and the family's views.

## Scope
1. **Finance area** for ADMIN only (other roles do not see the entry; WP124 adds theirs): settings (currency, locked
   with an explanation once dues exist), fee plans (list, create, edit, archive; cadence; team or category),
   dues (list with filters by team, period and state; generate with the preview count; change amount and waive with
   a reason; record a payment; void a payment with a reason).
2. **Money**: amounts shown from minor units with the academy's currency and the user's locale (IDR has no decimals);
   input parsed the same way; unit tests first.
3. **Offline**: read-only when offline (no queued finance writes); say so in the UI as the other admin screens do.
4. **Demo mock**: finance endpoints in the mock with a small seed so the demo and the widget tests have data.
5. **l10n** es / en / id; kit components (`SectionCard`, `ListRow`, `PickerDialog`, `runAction`), no new dialog kinds.

## Acceptance
- [ ] Red tests committed before each change; goldens for the main screens in light and dark, phone and wide
- [ ] `flutter analyze` clean; `just web-test` green (fresh; totals); `just web-format-check` clean
- [ ] Endpoints the service still answers 501 for (WP118 handover) degrade to a clear message, not a crash
- [ ] Handover appended: the routes, what WP124 builds on (providers, money formatting), what was only tested against
      the mock

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
