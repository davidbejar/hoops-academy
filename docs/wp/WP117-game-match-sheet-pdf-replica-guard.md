# WP117 — Game: match sheet PDF through pdf-service; start guard for `replica` without its consumer

Model: Opus · effort high. Wave 2 (2026-11-15, eighth round): starts after WP111 (pdf-service) and WP113 (PMD gate)
are merged; runs alongside WP116 (core), WP118 (finance-service in Go: chart, compose, realm, CI, kind). You own
`services/game-service/**`, `libs/contracts/openapi/game.yaml` (2.3.0 → 2.4.0), the generated
`apps/web/packages/game` and your amendment in `docs/adr/0048-*.md` (WP116 adds its own: keep both). You change no
chart, compose or realm file: WP111 wired `PDF_SERVICE_URL` and the audience (read its handover first). Depends on:
decisions 89, 90, 100, ADR-0048, ADR-0034, ADR-0037, ADR-0042 (season history), the WP111 and WP98 handovers.
Skills: quarkus-hexagonal-service, tenant-isolation-testing, owasp-security, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp117-game-match-pdf`, branch `wp117-game-match-pdf`.

Decision 89 of 2026-11-15 (owner): game loads the match and its box score, calls `pdf-service` and returns the PDF.

Orchestrator note (2026-11-16): the `pdf-service` audience mappers on the clients `core-service` and `game-service`
are on `main` (realm file, chart copy, snapshots, `RealmTokenPolicyTest`), so the step "WP116 must first add the
mappers" in the WP111 handover is done; an existing compose realm gets them with `just seed-users`. Start
`pdf-service` locally with `just pdf-up` (port 8084). The ADR-0034 audience table still lacks the `pdf-service`
column: WP116 adds that amendment line.

## Scope
1. **Match sheet PDF**: a new endpoint under `/api/game/matches/{id}/...` answering `application/pdf` (match header,
   score, per-player box score as the web's export shows it; ADR-0048). Readers: decide from
   `docs/domain/authz-matrix.md` who may read the box score today and keep exactly that rule (role-matrix test first;
   non-member 404); if the sheet shows more than those readers see today, stop and report. An audit record like the
   other exports if the matrix asks for one; file name by the ADR-0048 pattern; labels in the caller's language.
2. **Client adapter** (`adapters/out/client`): a port in `application`, game's client-credentials token, time-outs,
   a Problem (503-style) when `pdf-service` is down or `PDF_SERVICE_URL` is unset; the request validated against
   `pdf.yaml` in a test; the service stubbed as the WP111 handover says.
3. **Start guard**: game refuses to start with the roster source `replica` and `GAME_ROSTER_CONSUMER_ENABLED=false`,
   as athlete does (FOLLOW-UPS "game on `replica` without its consumer"); `ReplicaRosterSourceTest` gets a consumer.
4. **Dart package**: `scripts/gen-api.sh game`, commit `apps/web/packages/game` only.
5. **Docs**: the authz-matrix row, the ADR-0048 amendment, the events runbook line for the guard.

## Acceptance
- [ ] Game contract 2.4.0 validated; Dart package regenerated and committed (only `packages/game`)
- [ ] Red tests committed before each change
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `flutter analyze` clean;
      `just web-test` green (fresh; totals)
- [ ] `just mutation game-service` at or above baseline (record the score); `just diagrams` committed if types changed
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
