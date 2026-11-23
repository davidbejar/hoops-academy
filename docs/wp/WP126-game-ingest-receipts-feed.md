# WP126 — Game: ingest reads the match once, `sync_receipt` dropped, feed cursor race, parked events unique

Model: Opus · high. Wave 1 (2026-11-23, ninth round): runs alongside WP127 (athlete), WP128 (core), WP129 (web). You
own `services/game-service/**`; nobody else touches it. You do not touch `libs/**`, the other services or the root
`pom.xml`. Depends on: ADR-0037, ADR-0053, WP98. Skills: work-package, quarkus-hexagonal-service,
tenant-isolation-testing, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp126-game-ingest-receipts-feed`, branch `wp126-game-ingest-receipts-feed`.

Decisions 104, 106 and 109 of 2026-11-23: everything confirmed in game-service is fixed; `game.sync_receipt` is
dropped; `parked_event` gets its unique key now, the move of the replica pipeline to the library is WP130. ADR-0058 is
reserved for you if a decision is needed.

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `game-service.md`
(GAME-01..15), verification `verify-game-athlete.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Ingest (GAME-01)**: the match is loaded and JSON-decoded twice per batch (`IngestEventBatch`, then
   `MatchReprojection`), `markVoided` rewrites every voided row, the lock lookup runs a score query ingest never uses.
   Read once and pass the list on; keep the stored event list (the ledger keeps only ids and sequence numbers).
   `ProjectionVectorsTest` and `ConcurrentIngestTest` must stay green.
2. **`sync_receipt` (GAME-02, GAME-13)**: remove the port, adapter and call, and drop the table in a new migration
   together with the GAME-13 clean-up; RLS fixtures and the generated model diagram follow.
3. **Roster reads (GAME-03)**: `PastSeasons` and `GetMatchSheetPdf` load a whole team roster for a season end date or
   a team name: one narrow port method, parity in `RosterPortContractTest`.
4. **Feed cursor (GAME-04, bug)**: the feed reads the page before `lastServerSeq`, so a client can skip events
   committed in between: failing test first, then take the value from the summary.
5. **Parked events (X-01, part; bug)**: `parked_event` has no unique key and a plain insert, so a topic replay parks a
   record twice: migration with the unique coordinates and `on conflict do nothing`, as athlete has. Read X-01 in
   `cross-cutting.md` and its verification.
6. **The rest**: every other GAME finding of your scope, and the game README that contradicts itself.

Not yours: GAME-05 and GAME-06 (WP130), GAME-07 (WP137), GAME-09, GAME-10, GAME-11, GAME-12 (WP137).

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just mutation game-service` at or above the baseline (record the score)
- [ ] `just isolation-check` and `just db-role-check` run by hand in the worktree (results in the handover)
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points, ID table (work-package skill). -->
- **Built** (16 commits, `11f0841f`..`329d8fa5`, every behaviour change after its red test):
  - Feed cursor (bug): `GetMatchEvents` returns `match.score().lastServerSeq()` (the summary, read with the match before
    the page); `MatchEventRepository.lastServerSeq` is gone. A page is 3 statements. Red test `FeedCursorTest` (a
    batch committed while the page is read was skipped by a contract-following client); `ConcurrentIngestTest` now
    asserts the summary holds the highest sequence number.
  - Parked events (bug, X-01 part): `V8__parked_event_unique_position.sql` merges rows parked twice (oldest stays,
    inspected when any copy was; checked on a throwaway Postgres) and adds `unique (topic, kafka_partition,
    kafka_offset)`; `JdbcParkedRecordRepository` inserts `on conflict do nothing`. The identity `id` stays (runbook and
    retention use it). Red test `RosterReplicaSchemaTest.aReplayedRecordIsParkedOnce`.
  - Ingest: `IngestEventBatch` keeps the stored list it read; `MatchReprojection.reproject(match, stored, appended)`
    projects from it plus `EventLedger.accepted()`; new pure `VoidMarks` (PIT scope) writes only the `voided_by` marks
    that changed, in one batch (none when unchanged; a target arriving after its VOID is still marked); `lockById` maps
    with `MatchScore.NONE` (no score query). Pinned by `IngestBatchStatementsTest` (spies: one read, two queries for a
    one-event batch, no update, no batch when nothing changed).
  - `sync_receipt` and the `server_seq` unique key dropped (`V9__drop_sync_receipt.sql`); port method, adapter, call,
    RLS fixture removed; `docs/domain/game-model.md` regenerated (`just diagrams`).
  - `RosterPort.team(tenant, team)` → `TeamBrief`; replica: tenant check + `team_ref` by id; REST: mapped from the
    cached roster answer. Used by `PastSeasons` and `GetMatchSheetPdf`. Parity in `RosterPortContractTest`; rules in
    `ReplicaRosterPortTest`; new `PastSeasonsTest`.
  - `RosterConsumerSwitchedOffTest` without its profile; `ChangeMatchStatus` replaces Start/Finish/CancelMatch;
    `JdbcMatchEventRepository` / `JdbcProjectionRepository` (and the root `spotbugs-exclude.xml` entry for the SQL text
    block, renamed with the class); game README rewritten where wrong.
- **Verified**:
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` (fresh, 2026-11-23): common-quarkus 346 + 38 (32 skipped),
    contracts 403, **game-service 556 tests, 0 failures, coverage gates met, SpotBugs/PMD clean**; e2e green. The
    reactor is red only on two tests outside this WP, code unchanged from `main`: athlete
    `ScheduleApiTest.changingTheWeekdayMovesUntouchedSessionsButKeepsEditedOnes` (1003 tests, 1 failure; date-dependent:
    it fails when run on a Monday, the schedule's weekday, also alone) and core
    `TemporaryPasswordSweepTriggerTest.theRequestNeitherWaitsForTheSweepNorFailsBecauseOfIt` (1225 tests, 1 failure; a
    timing bound under load, green when re-run alone).
  - `just mutation game-service`: 572/574 (99.6 %), baseline 99, 117 s; recorded in `docs/quality/mutation.md`.
  - `just isolation-check` in the worktree: 6 core tests + 4 finance Go tests passed. `just db-role-check`: 13 Java tests + 2 finance Go tests passed.
  - `scripts/model-diagrams.sh` regenerated; only `game-model.md` changed.
- **Decisions/ADRs**: no new ADR (decisions 104, 106, 109 cover the scope; ADR-0058 unused). Amendments: ADR-0030
  (feed cursor read from the summary, three statements), ADR-0037 game section (`parked_event` unique position).
- **Open points / follow-ups**:
  - `game.yaml` (not mine): with the fix `lastServerSeq` may be lower than the page's last event when a batch commits
    between the match read and the page; a client then re-fetches events it already has (harmless, ids are stable).
    The contract text could say "at or below".
  - GAME-04's optional secondary (feed rows mapped straight to wire JSON instead of decode/re-encode): not done.
  - Docs outside this WP's write list that are now stale: `docs/PLAN.md:116` lists `sync_receipt` (historic plan).
  - The athlete date-dependent test above belongs to WP127's module.
  - Merge: `spotbugs-exclude.xml` (root) changed one class name; `docs/domain/game-model.md` regenerated; migrations
    V8 and V9 are new in game.

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| GAME-01 | Done | One read per batch, re-projection from it, only changed `voided_by` marks, no score query under the lock |
| GAME-02 | Done | `recordReceipt` port/adapter/call removed, table dropped (V9), RLS fixture and diagram updated |
| GAME-03 | Done | `RosterPort.team` → `TeamBrief`; `PastSeasons` and `GetMatchSheetPdf` use it; parity in `RosterPortContractTest` |
| GAME-04 | Done (bug) | `lastServerSeq` from the summary read before the page; closes the cursor race; 3 statements per page |
| GAME-08 | Done | Profile removed; the class shares the main group's Quarkus boot |
| GAME-13 | Done | `match_event_server_seq_key` dropped in V9 |
| GAME-14 | Done | `ChangeMatchStatus` (start, finish, cancel); REST resource and contract unchanged |
| GAME-15 | Done | `JdbcMatchEventRepository`, `JdbcProjectionRepository`; `JpaMatchRepository` keeps its name (it uses JPA) |
| X-01 (part) | Done (bug) | V8 unique `(topic, kafka_partition, kafka_offset)` after merging duplicates, `on conflict do nothing`; the pipeline move is WP130 |
| README | Done | No `change-me` defaults; replica, match sheet PDF, `hoops.pdf.*`, `ChangeMatchStatus`, WP126 behaviour |
| GAME-05, GAME-06 | Skipped | WP130 |
| GAME-07, GAME-09..12 | Skipped | WP137 (excluded by the brief) |
