# WP116 — Core: team roster PDF through pdf-service; team name on the audit `team` target

Model: Opus · effort high. Wave 2 (2026-11-15, eighth round): starts after WP111 (pdf-service) and WP113 (PMD gate)
are merged; runs alongside WP117 (game), WP118 (finance-service in Go: chart, compose, realm, CI, kind). You own
`services/core-service/**`, `libs/contracts/openapi/core.yaml` (3.6.0 → 3.7.0), the generated `apps/web/packages/core`
and your amendment in `docs/adr/0048-*.md` (WP117 adds its own: keep both). You change no chart, compose or realm
file: WP111 wired `PDF_SERVICE_URL` and the audience (read its handover first). Depends on: decisions 83, 89, 90, 100,
ADR-0048, ADR-0017 / ADR-0029 (audit), ADR-0034, the WP111 handover, the WP106 handover. Skills:
quarkus-hexagonal-service, tenant-isolation-testing, owasp-security, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp116-core-roster-pdf`, branch `wp116-core-roster-pdf`.

Decision 89 of 2026-11-15 (owner): core loads the roster, calls `pdf-service` and returns the PDF.

Orchestrator note (2026-11-16): the `pdf-service` audience mappers on the clients `core-service` and `game-service`
are on `main` (realm file, chart copy, snapshots, `RealmTokenPolicyTest`), so the step "WP116 must first add the
mappers" in the WP111 handover is done; an existing compose realm gets them with `just seed-users`. Start
`pdf-service` locally with `just pdf-up` (port 8084). The ADR-0034 audience table still lacks the `pdf-service`
column: WP116 adds that amendment line.

## Scope
1. **Roster PDF**: `GET /api/core/teams/{id}/roster:export` gains a PDF form (decide with the contract's existing
   style: an `Accept: application/pdf` or a sibling path; record it in the ADR-0048 amendment). The same rule as the
   CSV (decision 83: ADMIN and the team's current coach; role-matrix test first, non-member 404), the same audit
   event with the format, the file name by the ADR-0048 pattern, labels in the caller's language.
2. **Client adapter** (`adapters/out/client`): a port in `application`, the call with core's client-credentials
   token (`ServiceTokenClientFilter`), time-outs, and a Problem (503-style, no stack trace) when `pdf-service` is
   down or `PDF_SERVICE_URL` is unset; the request validated against `pdf.yaml` in a test; the service stubbed as the
   WP111 handover says. Nothing of the roster is logged.
3. **Audit `team` target**: the audit read resolves the team's name for targets of type `team` (`displayName` is
   null today; FOLLOW-UPS "Export follow-ups").
4. **Dart package**: `scripts/gen-api.sh core`, commit `apps/web/packages/core` only; the web still analyses and
   passes unchanged.
5. **Docs**: the authz-matrix row, the ADR-0048 amendment, `docs/domain/audit-events.md` if the event's fields change.

## Acceptance
- [ ] Core contract 3.7.0 validated; Dart package regenerated and committed (only `packages/core`)
- [ ] Red tests committed before each change
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `flutter analyze` clean;
      `just web-test` green (fresh; totals)
- [ ] `just mutation core-service` at or above baseline (record the score); `just diagrams` committed if types changed
- [ ] Handover appended: how the web asks for the PDF (WP122), the statuses it can get, what the e2e journey (WP123)
      should call

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
