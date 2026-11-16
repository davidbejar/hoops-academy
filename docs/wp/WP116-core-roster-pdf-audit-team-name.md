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
- [x] Core contract 3.7.0 validated; Dart package regenerated and committed (only `packages/core`)
- [x] Red tests committed before each change
- [x] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `flutter analyze` clean;
      `just web-test` green (fresh; totals)
- [x] `just mutation core-service` at or above baseline (record the score); `just diagrams` committed if types changed
- [x] Handover appended: how the web asks for the PDF (WP122), the statuses it can get, what the e2e journey (WP123)
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

- Built:
  - **Printed roster** (decision 89): `GET /api/core/teams/{id}/roster:export` with `Accept: application/pdf`.
    `PrintTeamRoster` takes the roster from `ExportTeamRoster.gather` (same authz: ADMIN, the team's current COACH;
    other members 403, non-members 404; the 10,000-row limit), checks the sheet's limits
    (`ExportLimit.requirePrintable`: 60 players, 20 staff, 4 active guardians per player, = `pdf.yaml` `maxItems`;
    else 422 `EXPORT_TOO_LARGE`, nothing sent), adds the heading (academy name and zone, season, team category),
    has the port `RosterPrinter` render it and then audits `team.roster_exported` with `rows` and `format` (`pdf`;
    the CSV now writes `format` `csv`). File name `hoops-<slug>-roster-<team>-<yyyyMMdd>.pdf` by core
    (`ExportFileName.pdf`), `Cache-Control: no-store`, labels in the `Accept-Language` language (`locale`).
    `AcceptedFormat` picks the form; `CsvResponse` became `ExportResponse`; `PlayerLine.standing()` is shared by
    CSV and PDF.
  - **Client adapter** `adapters/out/client`: `PdfServiceClient` (REST client built with `QuarkusRestClientBuilder`,
    `ServiceTokenClientFilter` = core's client-credentials token), `TeamRosterRequestDto` (`pdf.yaml`
    `TeamRosterRequest`), `PdfServiceRosterPrinter`. Config `hoops.pdf-service.url=${PDF_SERVICE_URL:}`, connect 1 s,
    read 5 s (2 s in `%test`). Unset, unreachable, slow, any error status or an empty body:
    `UpstreamUnavailableException` = 503 `UPSTREAM_UNAVAILABLE`; the logged message names cause and status only.
  - **Audit `team` target**: `AuditNames.teams` (RLS, `core.team`), resolved by `ReadAuditTrail`, so the list and
    its CSV export name the team. The platform trail keeps team targets by id (ADR-0029: no tenant content there).
  - Contract core 3.7.0 (`application/pdf` on the 200, a 503, `PdfFile`, `AuditTarget.displayName`); Dart package
    `apps/web/packages/core` regenerated (3.7.0, plus the `pubspec.lock` bump); model diagrams regenerated.
- How the web asks (WP122): `TeamsApi.exportTeamRoster(xTenantId, teamId, acceptLanguage: <app locale>,
  headers: {'Accept': 'application/pdf'})` returns `Response<Uint8List>` (the generated method has no Accept
  parameter: OpenAPI ignores an `Accept` header parameter). Statuses: 200 `application/pdf` (name in
  `Content-Disposition`); 403 (not ADMIN / current coach); 404 (non-member, unknown team); 422 `EXPORT_TOO_LARGE`
  (team too large for a sheet: offer the CSV); 503 `UPSTREAM_UNAVAILABLE` (pdf-service down: retry later or CSV);
  401. Without that header the CSV is unchanged.
- For the e2e journey (WP123): `just pdf-up` (or the chart's pdf-service) and `PDF_SERVICE_URL`; as an ADMIN call
  `GET /api/core/teams/{id}/roster:export` with `Accept: application/pdf`, expect 200, `application/pdf`, a body
  starting `%PDF-`, the `.pdf` file name, and an audit row `team.roster_exported` with `format` `pdf`; as a PARENT 403.
- Verified (2026-11-16):
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`, fresh: BUILD SUCCESS, 9:58 min; 3,453 tests (3,392 + 61
    new), 0 failures, 0 errors, 26 skipped (surefire reports: common 403, contracts 323, core 1,225, game 467,
    athlete 1,003, e2e 32 / 26 skipped). PMD / CPD, SpotBugs, JaCoCo gates passed.
  - `TeamRosterPdfTest` (31): WireMock stands in for pdf-service; the received body validates against
    `classpath:openapi/pdf.yaml` (strict validator), bearer = the service token; role matrix of the CSV; failures
    500, 503, 401, 400, connection reset and a 3 s delay (> 2 s read time-out) each give 503 with no audit row and
    neither guardian names / e-mail nor the team name in the logs. Unit: `TeamRosterRequestDtoTest`,
    `PdfServiceRosterPrinterTest`, `AcceptedFormatTest`, `ExportLimitTest`, `ExportFileNameTest`. Audit:
    `AuditEventResourceTest` and `AuditEventExportTest` (own team named; deleted or another academy's team null).
  - `flutter analyze`: no issues; `just web-test`: 1,507 tests, all passed.
  - `just mutation core-service`: 932/933 (99 %), baseline 99 unchanged (was 925/926). `just diagrams-check`: up to date.
  - Not run: a real call to pdf-service (copying the main checkout's `.env` into the worktree was refused, so
    `just pdf-up` could not run here; the stubbed tests stand in), `just isolation-check` separately (the commit
    hook ran it), kind, CI.
- Decisions/ADRs: ADR-0048 amendment (Accept negotiation on the same path rather than a sibling path: one authz rule,
  one audit action, the existing gateway rate limit, the Dart method stays `Uint8List`; limits; 503; file name by
  core); ADR-0034 amendment (`pdf-service` in the audience table for `core-service` and `game-service`).
  `docs/domain/authz-matrix.md` row, `docs/domain/audit-events.md` (`format`, team names).
- Open points / follow-ups:
  - The remote call happens inside the export's transaction (holds a DB connection up to the 5 s read time-out);
    acceptable for a rate-limited ADMIN / COACH action, revisit if pdf-service gets slow.
  - pdf-service's own `Content-Disposition` is ignored (it derives the academy part from the name, core uses the
    slug).
  - The web button and its l10n texts are WP122's; a team over the sheet's limits has no paged PDF (CSV only).
