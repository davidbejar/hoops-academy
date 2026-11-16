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

- Built:
  - **Match sheet PDF**, game contract 2.4.0: `GET /api/game/matches/{matchId}/box-score:pdf` (`getMatchSheetPdf`, tag
    Statistics, only `application/pdf` = `PdfFile` binary, optional `Accept-Language`). `MatchSheetPdfResource` ->
    `application.sheet.GetMatchSheetPdf` (not transactional: no DB connection is held while pdf-service renders) ->
    `GetBoxScore` (the same readers and lines: the visible-lines logic moved into one `BoxScore.visibleLines()`, used by
    the JSON box score and the sheet) + `RosterPort.teamRoster(...).teamName()` + `AcademyNames` + the caller's zone ->
    `MatchSheets` (pure mapping) -> port `MatchSheetRenderer`. Projection warnings are not printed. Not audited (the
    matrix asks for no audit row; the audit trail is core's).
  - **Client adapter** `adapters.out.client.PdfServiceMatchSheetRenderer`: a programmatic REST client (`PdfServiceClient`,
    body `MatchSheetBody` = pdf.yaml `MatchSheetRequest`) on `hoops.pdf.url=${PDF_SERVICE_URL:}` with common's
    `ServiceTokenClientFilter` (game's client-credentials token), 2 s connect / 10 s read timeouts. No URL, unreachable,
    too slow, any Problem (400/401/403/413/415/422/500/503) or a 200 that is not `%PDF-`: `UpstreamUnavailableException`
    -> 503 `UPSTREAM_UNAVAILABLE`, the message holds the status at most, never the body. The file name is passed on
    only when it is a plain `[a-z0-9-]+.pdf` name, else `hoops-match-sheet.pdf`.
  - **Academy name**: game had none (pdf.yaml requires it). V7 adds `game.tenant_ref.name`; `tenant.changed` always
    carried it; `RosterEvent.TenantChanged`, the decoder and the repository keep it; `ReplicaAcademyNames` reads it in
    both roster sources (core's `/internal` has none). Unknown -> "Hoops Academy"; no zone -> UTC.
  - **Start guard**: `RosterSourceSelection` (`@Startup`) refuses `replica` with `GAME_ROSTER_CONSUMER_ENABLED=false`
    (`hoops.roster.source=replica needs hoops.roster.consumer.enabled=true ...`), as athlete does;
    `ReplicaRosterSourceTest` runs `RosterBrokerResource` (a consumer).
  - Dart `apps/web/packages/game` 2.4.0 regenerated (`getMatchSheetPdf` -> `Response<Uint8List>`, `ResponseType.bytes`)
    and `apps/web/pubspec.lock` (only its version line). Docs: authz-matrix row (appended), ADR-0048 amendment
    (appended), events runbook (guard, academy name and how to fill it), `just diagrams` (game-model.md).
  - Mutation scope (+`ReplicaAcademyNames`, `AcceptLanguage`, `MatchSheets` with their tests).
- **For WP122 (web)**: `StatisticsApi.getMatchSheetPdf(xTenantId:, matchId:, acceptLanguage: <app locale>)`; save the
  bytes under the file name of `Content-Disposition` (`hoops-<academy>-match-sheet-<team>-<opponent>-<yyyyMMdd>.pdf`).
  Who may press it: **every member who sees the box score** (no role check needed in the UI; the sheet holds the same
  lines the box score shows that user). Statuses: 200 PDF; 404 Problem (unknown match / not a member); 401; 503
  `UPSTREAM_UNAVAILABLE` (pdf-service down, not configured or failing: show a "try again later" message; offline: do
  not call). 400 only for a malformed id. Generated path: the colon is sent literally (`box-score:pdf`).
- **For WP123 (e2e)**: call `GET /api/game/matches/{id}/box-score:pdf` with `X-Tenant-Id` as a coach and as a parent
  with `just pdf-up` running; expect 200, `application/pdf`, body starting `%PDF-`, `Cache-Control: no-store`; stop
  pdf-service (or unset `PDF_SERVICE_URL`) and expect 503 `UPSTREAM_UNAVAILABLE`.
- Verified (2026-11-16):
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` fresh: BUILD SUCCESS, 9:58 min, all coverage checks met,
    PMD/CPD/SpotBugs green. Its log kept the summaries of common-quarkus 403, contracts 322, core 1,225, e2e 32 (26
    skipped) but lost game's and athlete's under `-T 1C` interleaving, so I re-ran `-pl libs/contracts,
    services/game-service,services/athlete-service verify` sequentially: BUILD SUCCESS, contracts 322, game 541, athlete
    1,003, 0 failures / errors. Total 3,526 tests, 0 failures, 0 errors, 26 skipped.
  - `flutter analyze`: no issues; `just web-test`: 1,507 tests, all passed.
  - `just mutation game-service`: 555/557 (99.6 %, baseline 99); the 2 survivors are the older `ProjectionRun:56` and
    `EventVisibility:34`; every new class in scope 100 %.
  - The start guard proved on boot: `RosterConsumerSwitchedOffTest` with `-D%test.hoops.roster.source=replica` fails at
    start with the guard's message (not committed, a one-off check).
  - The role matrix (`MatchSheetPdfResourceTest`, 10 callers: ADMIN, COACH / ASSISTANT_COACH of the team, former COACH,
    linked PARENT, PLAYER self, COACH of another team, unlinked PARENT, PLAYER not in the match, member without role)
    asserts the lines sent equal `getBoxScore`'s for that caller; non-member / other tenant / unknown match 404 without
    calling pdf-service; every body sent validated against `pdf.yaml` (strict); `LogCapture` finds no player name in
    any log line on success or failure.
  - Not run: a real call to pdf-service (`just pdf-up`): this worktree has no `.env` (game's client secret) and I did
    not take it from the main checkout; the stubbed tests follow the WP111 handover. CI, `just isolation-check` apart
    from the commit hook, kind.
- Decisions/ADRs: ADR-0048 amendment (operation shape, readers, academy name from the replica, not audited, failures).
  The path is a sibling `box-score:pdf`, not content negotiation, as ADR-0048 decided for the CSV exports.
- Open points / follow-ups:
  - Academy names of existing tenants stay unknown in game until core sends their next `tenant.changed` (an academy
    edit) or `just events-backfill force` / a replay runs; until then the sheet prints "Hoops Academy". The orchestrator
    may want a forced backfill after the merge on kind / cloud.
  - With `GAME_ROSTER_SOURCE=rest` and the consumer off, the sheet always prints the fallback name.
  - A match of a team core no longer knows answers 404 (the team name comes from core / the replica).
  - `scripts`' drift check does not compare the new `name` column (owned elsewhere this wave).
  - Under `-T 1C` the Maven console log can lose module summaries (seen for game and athlete); count from a sequential
    run when the totals matter.
