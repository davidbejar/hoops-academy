# WP60 — Game: match feed visibility filter in SQL

Model: Opus. Wave 1 (2026-11-06, fourth round): runs alongside WP52 (web), WP56 (realm + OIDC properties), WP58
(core), WP63 (kind), WP64 (workflows). You own `services/game-service` Java and Flyway `V3` (reserved for you),
except the OIDC properties and auth classes (WP56). No contract change expected. Depends on: WP33 / ADR-0030
(`EventVisibility`, feed rules), WP37 (mutation baseline). Skills: quarkus-hexagonal-service,
tenant-isolation-testing, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp60-game-feed-sql`, branch `wp60-game-feed-sql`.

Decision 42 of 2026-11-06: for non-staff callers the feed is filtered in the query, not by walking every event of
the match in memory.

## Scope
1. Read ADR-0030 and the current filter (`EventVisibility`, the feed use case and its repository port). Keep the
   domain rule as the single source of truth: the SQL predicate must be derived from or verified against it (a
   property-style test that compares the SQL result with the in-memory rule on random event sets, jqwik is in the
   build).
2. Repository: a query that takes the caller's visible player ids / team scope and returns only visible events,
   paged as today; `V3__feed_visibility_index.sql` only if an index is needed (RLS policy untouched;
   `RlsSchemaMetaTest` green). The `%3A` batch path and `events:batch` are unaffected.
3. Tests first: the existing feed tests for PARENT/PLAYER/COACH stay green unchanged; the new property test; a
   bound on queries per feed page (no N+1).
4. `docs/adr/0030-*.md` amendment line "filter moved to SQL (WP60)"; `docs/architecture.md` is the docs pass's.

## Acceptance
- [ ] Red tests first; `./mvnw -B -ntp -pl services/game-service -am verify -Dquarkus.http.test-port=0` green
      (totals) and `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just mutation game-service` at or above baseline (record the score)
- [ ] Handover appended with the predicate and the measured query count per page

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - Port `MatchEventRepository.after(match, viewer, after, limit)` (was `after(match, after, limit)`): the events the
    viewer may read, per `EventVisibility`. `GetMatchEvents` makes one page call for every caller; the in-memory
    whole-match read and filter are gone. `JpaMatchEventRepository`: staff (`seesAll`) keep the plain
    `(match_id, server_seq)` query; a filtered viewer gets one statement, `VISIBLE_AFTER`:
    - **Predicate**: `e.server_seq > :after and case when e.type = 'VOID' then not exists (hidden_void for e)
      else e.player_id is null or e.player_id = any(:players) end`, ordered by `server_seq`, `limit :limit+1`.
    - `chain` (recursive CTE): every VOID of the page range, followed target by target through VOIDs of **this match**
      (`t.match_id = :match`), stopping on a VOID already passed (`t.id <> all(passed)`, so cycles and self-VOIDs end).
      `hidden_void`: a chain that ends in a non-VOID event of this match with a player not in `:players`. Unknown
      targets, targets in another match and cycles therefore leave the VOID visible, exactly as `EventVisibility`.
  - `EventVisibility` unchanged (javadoc: it is the definition the SQL is checked against). No contract change, no
    `V3` migration: the anchor and final scan use `match_event_match_seq_idx`, VOID targets the primary key; RLS policy
    untouched.
  - Tests: `FeedVisibilityQueryPropertyTest` (persistence, `@QuarkusTest`): 60 seeded random matches (0–40 events,
    every type, notes with/without player, VOIDs of earlier/later events, VOIDs, itself, unknown ids, another match's
    event) × 6 viewers/cursors/limits each, SQL result `==` `EventVisibility` over `findByMatch` then cursor/limit
    (whole `StoredEvent`s compared), plus a named case with a 3-chain, a 2-cycle, a self-VOID and a foreign target.
    Seeded `java.util.Random` rather than a jqwik `@Property`: jqwik's engine does not run the Quarkus extension (no
    boot, no injection); the seed is in the test name. `FeedPageStatementCountTest`: PARENT and COACH, matches of 1 and
    20 rounds (25 / 481 events with 3-deep VOID chains).
- Measured query count per page: **4 statements, for every caller and any match size** (counted on the
  `JdbcRepository.query/update/batch` funnel via `@InjectSpy`: the match `em.find` (entity without associations) +
  its `match_summary` score, the page, `lastServerSeq`; no `findByMatch`, no update/batch). Before: the same 4 for a
  filtered caller, but the page statement read the whole match.
- Verified (2026-11-06):
  - Red first (commit 8248feb): property test 61/61 errors (stubbed filtered branch), statement count 2/4 failed
    (filtered callers called `findByMatch`); `MatchEventFeedRoleMatrixTest` 26/26 green before and after, unchanged.
  - Negative controls (SQL broken on purpose, random seeds only): no chain following 10/60 seeds fail, foreign-match
    target resolved 15/60, cycles hidden 5/60, team notes hidden 54/60, cursor off by one 48/60.
  - `./mvnw -B -ntp -pl services/game-service -am verify -Dquarkus.http.test-port=0`: BUILD SUCCESS; common 186,
    contracts 157, game **324**, 0 failures; coverage met.
  - `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` (fresh): common 186, contracts 157, e2e 25 (21
    skipped), core 784, game 324 (lines 98.9 %, domain 99.8 %), athlete 644 with **1 error**:
    `AthleteDatabaseRoleTest.shippedConfigurationConnectsAsTheAppRoleAndMigratesAsTheOwner`, Testcontainers
    "localhost:2375 failed to respond" when Quarkus restarts for that class (4 ms after "Creating container"). Same
    in two athlete-only re-runs under load, green alone (3/3), then the third athlete-only re-run
    (`./mvnw -B -ntp -pl services/athlete-service verify -Dquarkus.http.test-port=0`) BUILD SUCCESS: **653 tests, 0
    failures**, coverage met. No athlete or libs file differs from main on this branch.
  - `just mutation game-service`: 401 mutants, 399 killed, **99 %** (baseline 95; same mutant count as WP37).
- Decisions/ADRs: ADR-0030 amended (§4 "filter moved to SQL (WP60)", consequence struck through).
- Open points / follow-ups:
  - Flake seen 3× in a row under the round's load (kind cluster + five builds on a 2-CPU Podman VM):
    `AthleteDatabaseRoleTest` container start on the Quarkus restart ("localhost:2375 failed to respond"), green once
    the load dropped. Looks like a stale docker-java connection to the Podman socket, not code; worth a FOLLOW-UPS
    line if it recurs.
  - `docs/architecture.md` mention is the docs pass's (brief).
  - Commits carry the brief's `Co-Authored-By: Claude Fable 5.1` line; the work was done by Claude Opus 5.5.
