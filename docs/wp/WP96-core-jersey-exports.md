# WP96 — Core: preferred jersey number with carry-over; server-side CSV exports

Model: Opus · effort high. Wave 2 (2026-11-10, sixth round): starts after WP91 is merged; runs alongside WP97 (web
browser-built exports), WP98 (game, athlete, `libs/common-quarkus`, `e2e`), WP99 (web hub, core Dart package 3.4.0).
You own `services/core-service`, `libs/contracts/openapi/core.yaml` and its contract tests, Flyway core `V19`
(reserved; use `V18` if WP91 left it free), ADR-0048 (reserved). Shared files: `docs/adr/README.md`,
`docs/domain/authz-matrix.md`, `UpdateRequestClearListContractTest` (append at the end, one entry per line). You do
NOT regenerate the Dart package or touch `apps/web` (WP101 does, wave 3) and you do not touch `deploy/helm` (WP100).
Depends on: decisions 67, 68, 70; ADR-0032 (clear lists), ADR-0029 (audit, actor masking), ADR-0033 (rate limits).
Skills: quarkus-hexagonal-service, tenant-isolation-testing, owasp-security, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp96-core-jersey-exports`, branch
`wp96-core-jersey-exports`.

Decision 70 of 2026-11-10: ADMIN and COACH set a player's preferred jersey number; PARENT and PLAYER may set it as a
wish for their own or linked player; staff still decide the real number on assignment. Decisions 67–68: exports are
CSV; the team roster with guardians and the audit log are produced by the server and audited.

## Scope
1. **Contract core → 3.5.0**, two commits (jersey, exports).
2. **Preferred number** (`core.player.preferred_jersey_number`, nullable, pattern `^[0-9]{1,2}$`, "0" ≠ "00"): on
   `Player` and `UpdatePlayerRequest` with `clear` (ADR-0032). Who writes it: ADMIN, COACH (per the matrix rule for
   editing players), PARENT for a linked player, PLAYER for the own player; everyone who reads the player reads it.
   Role-matrix tests from the authz matrix (add the rows).
3. **Carry-over on assignment** (`POST /api/core/teams/{teamId}/players` without an explicit number): the preferred
   number when free among the team's open assignments, else the number of the player's most recent assignment when
   free, else none. The response says which rule applied: `jerseySource` = `REQUESTED` | `PREFERRED` | `PREVIOUS` |
   `NONE`. Never take a number from another open assignment; an explicit number that clashes stays a 409. The rule
   is pure domain code (unit tests first, in PIT scope).
4. **Free numbers**: `GET /api/core/teams/{teamId}/jersey-numbers`: the taken numbers with their player, so a
   dialog can show what is free. Same readers as the team roster.
5. **Season rollover** keeps the numbers of the copied assignments: prove it with a test, fix it if it does not.
6. **Roster event**: `core.team_player.changed` already carries the number; `core.player.changed` gains nothing
   unless a consumer needs the preference (it does not): leave the event schemas alone.
7. **Roster export**: `GET /api/core/teams/{teamId}/roster` as `text/csv` (pick one of content negotiation or a
   `:export` operation, as the contract's conventions prefer, and use the same for the audit export): one row per
   player with person data, age category, eligibility state, jersey number, and each guardian with contact data; the
   team's staff with role as a second block or a second file (decide, write it in ADR-0048). ADMIN and the team's
   COACH only; ASSISTANT_COACH, PARENT and PLAYER are refused as the matrix says for members without the right;
   non-members 404. Every export writes an audit row `team.roster_exported` (who, team, row count; no personal data
   in the row). Never log the content.
8. **Audit log export**: the tenant's `GET /api/core/audit-events` and the platform's `/platform/audit-events` as
   CSV with the current filters and the same actor masking as the JSON read (ADR-0029); audit row `audit.exported`.
9. **Docs**: ADR-0048 (the export spec below, where each export is built, limits, the audit rows, alternatives);
   `docs/domain/audit-events.md`; authz matrix rows. Put in your handover the gateway rate-limit entries the export
   paths need (WP100 adds them to the chart) and the two new audit actions (WP101 labels them).

### Export spec (decisions 67–69; the same text is in WP96, WP97 and WP101; ADR-0048 is written by WP96)
- **CSV**: UTF-8 with BOM, `,` separator, RFC 4180 quoting (quote a field that holds `,`, `"`, CR or LF; double the
  quote), CRLF line ends, one header row. Media type `text/csv; charset=utf-8`.
- **Formula-injection guard** (CSV and XLSX text cells): a text value that starts with `=`, `+`, `-`, `@`, TAB or CR
  gets a leading `'`. Numbers written as numbers are exempt (a negative score stays `-3` only in a numeric column).
- **Language**: header labels in the user's language (es / en / id; server: `Accept-Language` as the rest of the
  API; web: the app locale). Values are not translated except enum labels (role, status).
- **Dates and times**: ISO `yyyy-MM-dd` and `HH:mm` in the academy's time zone, in separate columns; the zone id in
  its own column where a time is present. XLSX uses typed date cells.
- **File name**: `hoops-<academy-slug>-<what>-<yyyyMMdd>.<ext>`, ASCII only (`Content-Disposition: attachment` on
  the server; the download attribute in the web).
- **ICS** (team calendar): RFC 5545; `PRODID:-//Hoops Academy//EN`; one `VEVENT` per match and per training session
  with a stable `UID` (`<kind>-<id>@hoops-academy`), `DTSTAMP`, `DTSTART`/`DTEND` with `TZID` of the academy zone
  plus the matching `VTIMEZONE` (or UTC `Z` times when the zone data is not at hand: say which in the ADR),
  `SUMMARY`, `LOCATION` (venue), `STATUS:CANCELLED` for cancelled ones; text escaped (`\\`, `\;`, `\,`, `\n`) and
  lines folded at 75 octets.
- **XLSX**: only for the browser-built exports; the library is reached only through `import ... deferred as` and
  `loadLibrary()` at the moment the user picks Excel; it is not part of the main bundle and is left out of the
  service worker precache; when it cannot be fetched (offline, first use) the user gets a message and CSV still works.
- **Limits**: one file, no paging; the server refuses more than 10,000 rows with a Problem that asks for a narrower
  filter. Responses carry `Cache-Control: no-store`.

## Acceptance
- [ ] Contract 3.5.0 validated, including the `text/csv` responses in the contract tests
- [ ] Red tests committed before each change; RLS suites green; the CSV writer has unit tests for quoting, BOM,
      CRLF, the formula guard and the 10,000-row refusal
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just mutation core-service` at or above the baseline (record the score)
- [ ] After rebasing on `main`: `just diagrams` and commit the regenerated `docs/domain/core-model.md` (WP94)
- [ ] Handover appended: endpoint shapes for WP101's mock, rate-limit entries for WP100, the audit actions

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
- **Built** (red test commit before each change; rebased on `main` after WP99):
  - **Contract core 3.5.0** in two commits (jersey, exports); contract tests `JerseyNumbersContractTest`,
    `ExportsContractTest`, the clear-list entry for `UpdatePlayerRequest`, `AuditTrailContractTest` counts (32 actions,
    target `team`).
  - **Preferred number**: Flyway **V19** (`core.player.preferred_jersey_number`, nullable, `^[0-9]{1,2}$`, not
    unique). `PATCH /api/core/players/{id}` (`updatePlayer`): ADMIN, COACH (any player they read), PARENT linked,
    PLAYER self; ASSISTANT_COACH 403; unreadable player 404; unchanged value writes nothing; no audit row, no event.
    `Player.preferredJerseyNumber` for every reader.
  - **Carry-over** (`JerseyCarryOver`, domain, PIT): requested → preferred if free → most recent *numbered* assignment's
    number if free → none; `AssignedTeamPlayer.jerseySource`. Approval with a team and REASSIGNED case resolution use
    the same command. A race on the same free number answers 409 `TEAM_PLAYER_CONFLICT`.
  - **Taken numbers**: `GET /api/core/teams/{id}/jersey-numbers` (any member), ordered by value then length.
  - **Rollover** already kept numbers (invalidated copies too): proven by
    `RolloverResourceTest.theCopiedAssignmentsKeepTheirNumbersEligibleOrNot`, no fix needed. Event schemas untouched.
  - **Exports** as `:export` operations (ADR-0048 says why not content negotiation): roster (one file; staff as a second
    block of rows, same header), academy audit, platform audit. Writer, labels (`i18n/export_{en,es,id}.properties`),
    language, file name, renderers in `adapters.in.export` (pure, PIT); `ExportPages` reads the existing list use
    cases page by page (no new SQL, no `set_config`).
- **Shapes for WP101's mock** (core omits null members):
  - `PATCH /api/core/players/{id}` `{"preferredJerseyNumber":"7"}` or `{"clear":["preferredJerseyNumber"]}` → `Player`
    (+ `preferredJerseyNumber`); any other member 400.
  - `POST /api/core/teams/{id}/players` → 201 `AssignedTeamPlayer` = `TeamPlayer` + `"jerseySource":
    "REQUESTED|PREFERRED|PREVIOUS|NONE"`.
  - `GET /api/core/teams/{id}/jersey-numbers` → `[{"jerseyNumber":"7","player":{"id":uuid,"displayName":"Uma Test"}}]`.
  - `GET /api/core/teams/{id}/roster:export`, `GET /api/core/audit-events:export?from&to&action`,
    `GET /platform/audit-events:export?tenantId&from&to&action`: 200 `text/csv; charset=utf-8` bytes (Dart:
    `Response<Uint8List>`, parameter `acceptLanguage`), `Content-Disposition: attachment; filename="hoops-<slug>-roster-<team>-<yyyyMMdd>.csv"`
    / `…-audit-…` / `hoops-platform-audit-…`, `Cache-Control: no-store`; 422 Problem `code: EXPORT_TOO_LARGE` above
    10,000 rows; roster 403 for ASSISTANT_COACH / PARENT / PLAYER and for a coach of another team.
- **Audit actions for WP101's labels**: `team.roster_exported` (target type **`team`**, new) and `audit.exported`
  (target tenant); server labels en "Team roster exported" / "Audit trail exported", es "Plantilla del equipo
  exportada" / "Registro de auditoría exportado", id "Daftar tim diekspor" / "Jejak audit diekspor".
- **Rate limits for WP100** (`core.route.rateLimits`, RE2 on the raw path, per client IP):
  `{name: roster-export, path: "/api/core/teams/[^/]+/roster(:|%3[Aa])export", rpm: 10, rps: 2}`,
  `{name: audit-export, path: "/api/core/audit-events(:|%3[Aa])export", rpm: 10, rps: 2}`,
  `{name: platform-audit-export, path: "/platform/audit-events(:|%3[Aa])export", rpm: 10, rps: 2}`.
- **Verified** (fresh, after the rebase, `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`, BUILD SUCCESS,
  coverage and SpotBugs gates met): common-quarkus 392, contracts 315, core-service 1163, game-service 468,
  athlete-service 1000, e2e 32 (26 skipped); 0 failures. `just mutation core-service`: 925/926 killed (99.9 %, baseline
  99; the survivor is the older `Eligibility.reasons` one), 108 s. `just diagrams` committed (`core-model.md`). A scratch
  `scripts/gen-api.sh core` (outside the repo) generated the three exports as `Response<Uint8List>`.
- **Decisions**: ADR-0048 (export spec, `:export` operations, staff as a second block, `key=value` details, audit rows,
  jersey rules). "Previous number" = the most recent assignment *with* a number. The roster's eligibility is the
  stored assignment state; the age category is the natural one in the team's season; only active guardians. A former
  coach of an ended season may export that team (ADR-0042 history). The platform export records `audit.exported` in
  each academy with rows in the file.
- **Open points**: the commit hook once treated a Bash heredoc with unbalanced quotes as a commit and failed its
  isolation check on a Quarkus boot timeout after 607 s (host load), blocking that command; later commits passed.
  The audit `team` target shows no name (`displayName` null; resolving team names is a small follow-up). The compose
  nginx has no `limit_req` for the export paths (WP100 or infra). `docs/adr/README.md`: 0048 placed before WP99's 0049.
