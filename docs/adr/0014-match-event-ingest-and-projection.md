# ADR-0014: match event ingest and projection semantics (offline-first statistics)

- Status: Accepted
- Date: 2026-11-02

## Context
WP7 implements `POST /matches/{id}/events:batch`, the box-score projection and the season statistics. Several
devices (staff tablet, assistant phone, parents' phones) record events offline and sync later, in any order and
possibly more than once. Plan §2 fixes the principle ("schema + authorization only, never domain consistency") but
leaves open what happens in edge cases, and the Flutter projector (WP13) must reproduce the server's projection
exactly.

## Decision
1. **Idempotency and order.** The client event `id` is the idempotency key (table-wide primary key);
   `(match, deviceId, clientSeq)` is unique. A known id → `DUPLICATE` with its original `serverSeq`; the same
   `(deviceId, clientSeq)` with another id, or an id already stored for another match → `REJECTED CLIENT_SEQ_CONFLICT`
   (the contract has no dedicated reason for the latter). Batches of one match are serialised by a row lock
   (`select … for update` on `game.match`); `server_seq` is a global `bigserial`, monotonic per match in commit order,
   which makes `GET /events?after=` a safe cursor.
2. **Per-event checks, in this order:** schema (`SCHEMA_INVALID`; an event without a usable id is reported under the
   nil UUID) → duplicate → `MATCH_CANCELLED` → authorization (`NOT_AUTHORIZED`) → sequence conflict → stored.
3. **Status policy.** Events are accepted for SCHEDULED, LIVE and FINISHED matches; only CANCELLED rejects. A
   rejection is final for the client ("retrying unchanged will fail again"), so rejecting SCHEDULED would lose events
   recorded offline while the start call travelled separately. After FINISHED, staff may still correct (any event);
   a PARENT's event counts only if its `recordedAtClient` is not after `match.finishedAt`.
4. **Authorization per event** (authz matrix): ADMIN / staff of the match's team: any type. PARENT: SHOT, ASSIST,
   REBOUND, TURNOVER, STEAL, BLOCK, FOUL for linked players, and VOID of an event they recorded (stored or earlier
   in the same batch). Anybody else: nothing.
5. **Projection = pure function of the event set.** Replay order: period ↑, clock ↓, `recordedAtClient` ↑,
   `serverSeq` ↑, id ↑ (total order). VOIDs are resolved before the replay (VOID of a VOID ignored with a warning).
   Starters are on court; the clock runs only between PERIOD_START and PERIOD_END; overtime periods
   (`period > periodCount`) last `hoops.game.overtime-minutes` (default 5). Impossible sequences are warnings, never
   rejections. The whole match is re-projected inside the ingest transaction (and after roster or period changes);
   `match_player_stats` / `match_summary` are caches of that function. The exact rules are documented with the shared
   vectors in `libs/contracts/vectors/README.md`.
6. **Shared test vectors** are generated and verified by game-service (`ProjectionVectorsTest`) and copied to
   `libs/contracts/vectors/`; the copy is checked byte for byte so the Flutter projector tests against the server.

## Consequences
- Re-projection costs O(events of the match) per batch: fine for youth basketball (a few hundred events); revisit
  (incremental projection) only if batches become frequent on very long matches.
- A misbehaving client cannot block its queue: every event gets a final answer.
- Contract follow-ups (WP2b owner) are listed in the WP7 handover: a reason for "id used by another match", the
  technical/unsportsmanlike counts in `StatLine`, and a MatchEvent schema the OpenAPI validator can check.
