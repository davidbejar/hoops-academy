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
