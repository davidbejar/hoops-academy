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
- [ ] re-posting a batch → all DUPLICATE and identical projection; two threads posting overlapping batches == sequential replay
- [ ] table-driven minutes tests (starter out and back in, period boundaries, overtime, missing SUB_OUT → warning)
- [ ] parent: SHOT for linked player ACCEPTED; for other player REJECTED(FORBIDDEN); PERIOD_START REJECTED; VOID of coach event REJECTED
- [ ] jqwik: projection is a pure function of the event set (order of arrival irrelevant)
- [ ] RLS + cross-tenant + contract validation; verify green, coverage ≥ 80 % (domain ≥ 90 %); vectors committed
