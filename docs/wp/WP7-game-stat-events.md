# WP7 — game-service: event ingest, idempotency, projections, parent rule

Model: Opus. Depends on: WP6. Lane GAME. Plan §2 "Match statistics". Skills: test-driven-development,
quarkus-hexagonal-service, tenant-isolation-testing, property-based tests (jqwik).

## Scope
- Flyway: `match_event` (id uuid pk client-generated, tenant_id, match_id, server_seq bigserial, device_id, client_seq,
  type, player_id, period, clock_seconds_remaining, payload jsonb, recorded_by_person_id, recorded_at_client,
  received_at, voided_by uuid null; unique (match_id, device_id, client_seq)), `match_player_stats`, `match_summary`.
- Ingest `POST /matches/{id}/events:batch`: JSON-Schema validation per event (libs/contracts/events), authz per event
  (staff: all; PARENT: player-attributed stat events for linked players only, VOID only own events; PLAYER: none),
  `select … for update` on match, insert ignoring duplicates (by id) → per-event ACCEPTED/DUPLICATE/REJECTED{reason},
  re-project within the transaction.
- Projector (pure domain): ordering (period, clock desc, recorded_at_client, server_seq); minutes from starters +
  PERIOD_START/END + SUB_IN/OUT; points/fg/ast/reb/tov/stl/blk/pf; warnings for impossible sequences (never reject);
  VOID handling; period scores & totals incl. OPPONENT_SCORE.
- `GET /events?after=serverSeq&limit`, `GET /box-score`, `GET /players/{id}/season-stats`.
- Export deterministic JSON test vectors (`src/test/resources/vectors/*.json`: events + expected projection) and copy
  them to `libs/contracts/vectors/` for the Flutter projector (WP13).

## Acceptance
- [x] re-posting a batch → all DUPLICATE and identical projection; two threads posting overlapping batches == sequential replay
- [x] table-driven minutes tests (starter out and back in, period boundaries, overtime, missing SUB_OUT → warning)
- [x] parent: SHOT for linked player ACCEPTED; for other player REJECTED(FORBIDDEN); PERIOD_START REJECTED; VOID of coach event REJECTED
  (the contract's reason is `NOT_AUTHORIZED`; there is no `FORBIDDEN` value)
- [x] jqwik: projection is a pure function of the event set (order of arrival irrelevant)
- [x] RLS + cross-tenant + contract validation; verify green, coverage ≥ 80 % (domain ≥ 90 %); vectors committed
  (vectors written to the working tree; no git commands were run in this lane)

Evidence for each item: see `## Handover` → "Acceptance evidence".

## Handover

### Built
- **Flyway `V2__events.sql`** (all three through `app.enable_tenant_rls`, composite tenant FKs to `game.match`):
  `match_event` (id uuid pk = client UUIDv7, `server_seq bigserial unique`, device_id, client_seq bigint,
  type (check: 15 types), player_id, period 1..12, clock 0..3600, payload jsonb, recorded_by_person_id,
  **recorded_by_display_name** (contract `PersonRef` needs a name), recorded_at_client, received_at default now(),
  voided_by; unique (match_id, device_id, client_seq); indexes (match_id, server_seq) and (tenant_id, received_at)),
  `match_player_stats` (pk match+player; pts, fgm/fga 1/2/3, ast, oreb, dreb, tov, stl, blk, pf, **technical_fouls,
  unsportsmanlike_fouls**, seconds_played, was_starter, warnings jsonb), `match_summary` (match_id pk, our_score,
  opp_score, period_scores jsonb, **warnings jsonb** (match-level), last_server_seq, updated_at). The existing
  `sync_receipt` is now filled (max client_seq per match+device).
- **domain** (framework-free): `domain.events` — `MatchEvent` sealed interface with one record per type (+ sealed
  `PlayerStat` for the 7 parent-recordable types), `EventMeta`, `EventId`, `RecordedEvent`, `EventOrdering`
  (period ↑, clock ↓, recordedAtClient ↑, serverSeq ↑, id ↑; `canonical()` also drops repeated ids).
  `domain.projection` — `BoxScoreProjector.project(MatchRules, roster, events) → Projection{playerStats, summary,
  warnings, voidedBy}` (internals `VoidResolution`, `ProjectionRun`, `PlayerTally`, `Scoreboard`), `MatchRules`
  (overtime length), `StatLine`, `PlayerLine`, `MatchSummary`, `PeriodScore`, `ProjectionWarning`/`WarningCode`,
  `SeasonLine`/`SeasonStats` (totals, games played/started, averages rounded to 2 decimals). `Match` carries a
  read-only `MatchScore` snapshot (fills `MatchDto.score/lastServerSeq`).
- **application**: `IngestEventBatch` (row lock, `EventLedger`, per-event admission, re-projection in the same
  transaction), `EventAuthorization` (pure per-event rule), `MatchReprojection` (also called by `ReplaceMatchRoster`
  and by `UpdateMatch` when period settings change), `GetMatchEvents`, `GetBoxScore` (line visibility),
  `GetPlayerSeasonStats`; ports `MatchEventRepository`, `ProjectionRepository`, `MatchRepository.lockById`;
  `SubmittedEvent` (Valid | Invalid), `Recorder`, `StoredEvent`.
- **adapters**: `adapters.json.MatchEventJson` (contract JSON ↔ domain), `in.rest.MatchEventDecoder` (networknt
  json-schema-validator 2.0.8 against `/events/match-event.schema.json` from the contracts jar, now a compile
  dependency), `MatchEventResource` (`events:batch`, `events`), `BoxScoreResource`, `SeasonStatsResource`, DTOs,
  `OptimisticLockExceptionMapper` (409 Problem `CONCURRENT_MODIFICATION` for `OptimisticLockException` /
  `StaleStateException` — common-quarkus has no such mapper), `out.persistence.JpaMatchEventRepository`,
  `JpaProjectionRepository` (JDBC on the transaction's connection via a `JdbcRepository` base, `app.current_tenant()`
  for inserts), `JpaMatchRepository` (pessimistic lock + scores), `JpaUsageCounter` (`matchEvents`,
  `matchEventsLast30Days` now real).
- Config: `hoops.game.overtime-minutes=5`; `%test.quarkus.http.test-port=0` (parallel lanes' Quarkus tests were
  holding 8081). Module pom: `jqwik` (version from parent), `json-schema-validator 2.0.8`, contracts compile scope,
  JaCoCo PACKAGE rule ≥ 90 % lines for `com.hoopsacademy.game.domain*` (appended to the parent's BUNDLE ≥ 80 %).
  `src/test/resources/junit-platform.properties` repeats quarkus-junit's two settings (only the first file is read)
  and moves the jqwik database to `target/`.
- **ADR-0014** (ingest + projection semantics). Module README updated. **Vectors**:
  `services/game-service/src/test/resources/vectors/` and the identical copy + README in `libs/contracts/vectors/`.

### Verified (fresh `source scripts/env.sh && ./mvnw -pl services/game-service clean verify`, 2026-11-02, read in full)
BUILD SUCCESS, **188 tests, 0 failures, 0 errors, 0 skipped** (WP6 had 87), no compiler warnings, "All coverage
checks have been met": lines **98.7 %** (1330/1348), branches 91.1 %; `domain` 99.3 %, `domain.events` 97.9 %,
`domain.projection` 99.2 %, application 99.3 %, adapters ≥ 97 %. `./mvnw -pl libs/contracts verify` still green
(79 tests).
New test classes: `EventOrderingTest` 2, `BoxScoreProjectorTest` 10, `MinutesTest` 10 (table), `ProjectionPropertiesTest`
1 property × 300 tries, `ProjectionVectorsTest` 15, `SeasonStatsTest` 2, `EventAuthorizationTest` 6,
`MatchEventDecoderTest` 19, `MatchEventResourceTest` 13, `StatisticsResourceTest` 15, `ConcurrentIngestTest` 2,
`OptimisticLockExceptionMapperTest` 1; extended `GameRlsIsolationTest` (6 tables), `UsageResourceTest` (+1), `MatchTest` (+1).
Negative controls (each reverted): no sort in `EventOrdering.canonical` → the jqwik property fails at try 1;
plain `em.find` instead of the pessimistic lock → `ConcurrentIngestTest` fails ("one serverSeq per event");
concurrent PATCH rounds really produce 409s (observed 10× 200 / 10× 409, never 500); domain rule at 99.9 % →
`jacoco:check` reports exactly the three domain packages.

### Acceptance evidence
- Re-post → all DUPLICATE with the original serverSeqs, byte-identical box score:
  `MatchEventResourceTest.repostingABatchIsAllDuplicateWithTheOriginalSeqsAndAnIdenticalProjection`.
  Concurrency: `ConcurrentIngestTest.overlappingBatchesPostedConcurrentlyEqualTheSequentialReplay` — 5 rounds, two threads
  (barrier) post overlapping batches (2nd reversed) of a 60+-event game; both 200 within 30 s (no deadlock), each event
  ACCEPTED exactly once with one serverSeq, box score equals the one of a match fed sequentially.
  `concurrentEditsOfOneMatchAreConflictsNotServerErrors`: only 200/409.
- Minutes: `MinutesTest` (whole game, starter out and back in, sub between periods, sub before tip-off, overtime,
  missing SUB_OUT → `SUB_IN_PLAYER_ON_COURT`, missing PERIOD_END, running period, clamped clock, no period events) +
  vector `substitutions-and-minutes` (hand-computed: 2100/2100/2400/2400/2340/360/300 s).
- Parent: `MatchEventResourceTest.parentMayRecordStatsOfTheLinkedPlayerAndVoidOwnEventsOnly` (linked SHOT ACCEPTED, other
  player / PERIOD_START / VOID of the coach's event → REJECTED NOT_AUTHORIZED, VOID of own event in the same batch
  ACCEPTED) + `EventAuthorizationTest` (all types, roles, unions, FINISHED rule).
- jqwik: `ProjectionPropertiesTest` — random games (all 15 types, VOIDs incl. VOID of VOID and unknown targets,
  overtimes, out-of-range clocks, non-roster players), shuffled and partly re-delivered → equal projection.
- RLS: `GameRlsSchemaMetaTest`, `GameRlsIsolationTest` (match_event, match_player_stats, match_summary added).
  Cross-tenant 404 for batch, feed, box score; season stats of tenant B invisible in A. Contract: box score, season
  stats, batch result and usage fully validated; feed see contract gaps.

### Decisions (details in ADR-0014)
- **Statuses**: events accepted for SCHEDULED, LIVE, FINISHED; CANCELLED → `MATCH_CANCELLED`. No `MATCH_NOT_STARTED`
  (not in the contract, and a final rejection would lose offline events). After FINISHED: staff anything; PARENT only
  events with `recordedAtClient ≤ finishedAt`.
- Check order: schema → duplicate → cancelled → authz → (device, seq) conflict. Event without usable id → reported
  under the nil UUID. Id already used by another match → `CLIENT_SEQ_CONFLICT` (closest reason). Max 500 events
  (400 beyond, also for empty / non-batch bodies).
- **Projection**: rules in `libs/contracts/vectors/README.md`. Fouls: `pf` counts all kinds (contract), TECHNICAL and
  UNSPORTSMANLIKE additionally counted in their own columns (no warning; bench technicals are not "not on court").
  Made shots of non-roster players count for the team score only (match-level `PLAYER_NOT_IN_ROSTER`). "Stats after
  FINISHED" = after the final PERIOD_END → `EVENT_OUTSIDE_PERIOD`. Live box score counts minutes up to the latest event.
- **Season stats** over **LIVE and FINISHED** matches — the contract summary says so (the brief said FINISHED; the
  contract is the source of truth). Visible to ADMIN, COACH, ASSISTANT_COACH (any player), linked PARENT, PLAYER self;
  anybody else 404. Games played = started or any minutes/stat. Box score: ADMIN/team staff all lines, PARENT linked,
  PLAYER self, others no lines (totals/score always).
- Feed and events visible to any member (WP6 visibility decision). `recordedBy.displayName` = the token's `name`
  claim, else the principal name, stored at ingest.
- Persistence uses JDBC in `*Repository` classes (bulk rewrite of projections, `insert … on conflict do nothing
  returning server_seq`); RLS protects every statement.

### Test vectors (`src/test/resources/vectors` = `libs/contracts/vectors`)
`simple-game` (10-9, all stat types), `substitutions-and-minutes`, `overtime` (4×8 + 4-min OT, 7-6),
`void-and-corrections` (re-attributed shot, VOID of VOID, unknown target, double VOID), `out-of-order-arrival`
(second device synced late, reversed), `parent-mixed-scorers` (two parents + staff, parent voids own event),
`impossible-sequences-warnings` (every warning code but VOID_*). Format and regeneration in the README there.

### Contract gaps (for the contracts owner, WP2b) — nothing in `libs/contracts/openapi` or `events` was changed
1. **`MatchEvent` oneOf cannot be validated by swagger-request-validator 3.0.0**: it ignores the discriminator and
   reports every non-matching branch; `PeriodStartEvent`/`PeriodEndEvent` and `SubInEvent`/`SubOutEvent` are
   structurally identical, so strict oneOf can never pass. Tests therefore skip request-body validation of
   `submitMatchEvents` (`Contract.BATCH`) and response-body validation of `listMatchEvents` (`Contract.FEED`; the
   envelope is asserted and each event validated against the JSON Schema by `support/EventSchema`). Fix suggestion:
   `type: {type: string, enum: [<TYPE>]}` in each `<Type>Event` schema.
2. `MatchEventRejectionReason` has no value for "event id already stored for another match" (uses
   `CLIENT_SEQ_CONFLICT`) and none for "match not started" (not needed with the chosen policy).
3. `StatLine` has no technical / unsportsmanlike counts (stored server-side, in the vectors, not in the API).
4. `BoxScore.opponentFouls` is always null (opponent fouls are not an event type).
5. The acceptance text says `REJECTED(FORBIDDEN)`; the contract value is `NOT_AUTHORIZED` (implemented).

### Open points
- `UsageCounter.lastActivityAt` still uses `max(match.updated_at)`; event arrival does not touch it.
- `ConcurrentIngestTest` PATCH case cannot force a conflict deterministically; the mapper is unit-tested and
  conflicts were observed in every run here.
- Person display names are a snapshot from the token at ingest time (no core lookup); fine for audit display.
- The REST client generators send `:` unencoded; a percent-encoded `events%3Abatch` is 404 in Quarkus REST
  (tests use `urlEncodingEnabled(false)`). The nginx/ingress route must pass the path unchanged.
- Rate limiting of batch ingest (plan §3) is an infra/gateway concern, not done here.
- PIT (domain mutation testing) not run in this WP.
