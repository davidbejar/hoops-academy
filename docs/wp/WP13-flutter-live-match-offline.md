# WP13 — Flutter: live match scoring with offline queue + sync

Model: Opus. Depends on: WP11, WP7 (contract + vectors in libs/contracts/vectors). Lane WEB. Plan §1.5, §2 "Match
statistics". Skills: flutter-feature, test-driven-development, systematic-debugging.

## Scope (features/match)
- Drift database: `matches_cache`, `roster_cache`, `pending_events` (id UUIDv7, matchId, deviceId, clientSeq, type,
  playerId, period, clockSecondsRemaining, payload JSON, recordedAtClient, status PENDING|SENT|ACCEPTED|DUPLICATE|REJECTED,
  rejectReason), `synced_events` (server_seq cursor per match), `device` (deviceId generated once).
- Local projector (pure Dart) mirroring the server: must pass every vector in `libs/contracts/vectors/*.json`
  (test copies them to `test/fixtures/`).
- Sync worker: batches pending events in clientSeq order → `POST events:batch`; handles per-event results; exponential
  backoff; pull `GET events?after=` to merge other scorers; pauses on 401 and resumes after re-login; "N unsynced"
  indicator; never silently drops REJECTED (shows reason, allows VOID/undo).
- UI: match list (team/season), match setup (roster snapshot, starters), live view — game clock & period controls
  (staff only), court panel with players on court/bench, tap player → action sheet (2PT/3PT made/missed, FT, AST, REB
  O/D, STL, BLK, TOV, FOUL), substitutions, opponent score, undo (VOID), live box score; parent-restricted mode
  (only linked players enabled; no clock); finished match box score + share.
- Resilience: works with network off from the start of the match (roster cached beforehand); token refresh proactive.

## Acceptance
- [ ] Dart projector passes all server vectors; property test: shuffled arrival order → same projection
- [ ] offline scenario test: 50 events queued offline → reconnect → 50 ACCEPTED; replay → 50 DUPLICATE; projection equals server box score (mock server from contract)
- [ ] parent mode: other players disabled, clock hidden; 401 path preserves queue
- [ ] widget tests + golden of live view (360×780); `flutter analyze && flutter test` green
