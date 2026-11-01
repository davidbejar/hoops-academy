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
- [x] Dart projector passes all server vectors; property test: shuffled arrival order → same projection
- [x] offline scenario test: 50 events queued offline → reconnect → 50 ACCEPTED; replay → 50 DUPLICATE; projection equals server box score (mock server from contract)
- [x] parent mode: other players disabled, clock hidden; 401 path preserves queue
- [x] widget tests + golden of live view (360×780); `flutter analyze && flutter test` green

Evidence for each item: see `## Handover` → "Acceptance evidence".

## Handover

### Built (`apps/web` only; nothing committed, no git commands)
- **Domain (pure Dart, `lib/features/match/domain/`)**: `match_event.dart` (sealed `MatchEvent`, one class per contract
  type, contract-JSON codec, `RecordedEvent`), `pending_event.dart` (`EventStatus` PENDING/SENT/ACCEPTED/DUPLICATE/
  REJECTED, `EventResult`, `StoredEvent`, `CachedRosterEntry`), `projector/` (mirror of game-service
  `BoxScoreProjector`: `event_ordering.dart` = period ↑, clock ↓, recordedAtClient ↑, serverSeq ↑ (local unsynced
  events after synced ones), id ↑ with **Java `UUID.compareTo` signed semantics** done on hex digits (exact on web);
  `projector.dart` = VOID resolution before replay, starters on court, clock only between PERIOD_START/END, clamping,
  overtime (`MatchRules`, default 5 min), all 13 warning codes, period scores; `projection.dart` also exposes
  `LiveState` (on court, period, running, last clock) for the live screen; `merge.dart` = synced feed ∪ own non-REJECTED
  events, one per id), `scoring_rights.dart` (staff / parent-restricted / read-only), `stat_action.dart` (15 buttons).
- **Drift store (`data/local/`)**: tables `matches_cache`, `roster_cache`, `pending_events` (id UUIDv7, tenant, match,
  person, device, clientSeq, type, player, period, clock, payload JSON, recordedAtClient ISO text, status, rejectReason,
  serverSeq; unique (match, device, clientSeq)), `synced_events` (contract JSON + serverSeq; max = cursor), `device`
  (id generated once), `client_sequences` (monotonic per match, survives discards). `MatchStore` API (record in one
  transaction, outbox, results, revert, discard, feed merge, caches, watch streams). Web connection without
  SharedWorker / COOP/COEP (`opfsLocks` if isolated, else `unsafeIndexedDb`, else in-memory); native = drift_flutter.
  Assets `web/sqlite3.wasm` (sqlite3.dart release 3.8.0, sha256 efd308be…2d37) and `web/drift_worker.js` (dart2js of
  `tool/drift_worker.dart`) via `tool/fetch_web_db_assets.sh` (no Node). `match_database.g.dart` committed.
- **Remote (`data/`)**: `EventCodec` bridges domain ↔ generated `MatchEvent` oneOf through the package's
  `standardSerializers`; `ApiEventsRemote` (`submitMatchEvents`, `listMatchEvents`) and `ApiMatchesRepository`
  (list/get/create/start/finish/roster/replaceRoster/boxScore/seasonStats) on `hoops_game_api` (not regenerated).
- **Sync (`application/sync/`)**: `SyncWorker` (one pass at a time; per match PENDING/SENT of the signed-in person in
  clientSeq order, ≤ 500 per batch; SENT = in flight, reverted to PENDING on any failure; per-event results applied;
  feed pulled for watched/pushed matches with `after = max(serverSeq)`; `Backoff` 1 s → 60 s cap, uniform jitter in
  [nominal/2, nominal]; 401 → `pausedForAuth`, no retry loop, queue intact, `onAuthenticated` resumes; triggers:
  connectivity regained, app resume (`AppLifecycleListener`), sign-in, 15 s periodic while a match screen is open),
  `SyncStatus` (pendingCount, rejectedCount, syncing, lastError, pausedForAuth, nextRetryAt). Token refresh stays
  proactive in the existing OIDC/Dio layer (`refreshBefore` 60 s + 401 refresh-once backstop).
- **Application**: `LiveMatchController` (family; match + roster network-first with Drift cache fallback, live
  projection recomputed on every store change, log entries with sync state / voided / canVoid, commands: stat,
  period start/end, substitution, opponent score, timeout, undo = VOID of the last own event in effect, void, discard,
  start/finish match), `GameClock` (local countdown, staff only, ±10 s, never an event), list provider with offline cache.
- **UI (`presentation/`)**: match list (team filter for staff, status chips, score, cached-offline chip, create dialog),
  setup (roster from core team roster: include, starter, jersey; inline "mark a starter" validation; caches roster),
  live view (header: score / period / clock / period start-end / opponent +1+2+3 / timeouts / undo; parent-mode chip;
  tabs Court / Plays / Box score; court 5 + bench, tap → action sheet, bench tap (staff) → "comes in for" sheet;
  log with Pending / Sending / Synced / "by <name>" / Rejected: <reason>, Void and Discard with confirmation;
  "N unsynced" banner with Retry and the 401 explanation), box score (period scores, DataTable, totals, warning count
  for staff, copy result to clipboard), season stats screen. 123 new l10n keys in es/en/id.
- **Routes**: Matches module `subPages` `stats/:playerId`, `:matchId/setup`, `:matchId`, each its own deferred
  library; placeholder `features/matches/` removed (deleted, not via git). Player detail (WP12) got a
  "Season statistics" button → `/matches/stats/<playerId>`.
- **Shared touches (minimal)**: `TenantMembership.linkedPlayerIds` + mapping from `/me.authz.linkedPlayerIds`;
  `Capabilities.linkedPlayerIds`, `canRunMatch(teamId)`, `isLinkedTo`, `canCreateMatches`; mock adapter routes
  `/api/game/*` to `MockGameApi` and gives PARENT in "Academia Demo" the link to `p-ana`; test `Harness`/`pumpAs` take
  a `FakeGame` (default empty) so any screen opening the match module works in tests.
- **Dependencies** (`pubspec.yaml`): drift 2.35.3, drift_flutter 0.3.1, sqlite3 3.8.0, uuid 4.6.0; dev: drift_dev,
  build_runner, fake_async. Tools: `tool/sync_vectors.sh`, `tool/fetch_web_db_assets.sh`, `tool/drift_worker.dart`.
- **Mock mode**: `MockGameApi` (LIVE vs Tigres with 7-player roster, SCHEDULED vs Águilas without roster, FINISHED vs
  Lobos), batch semantics in ADR-0014 order incl. parent rule and CLIENT_SEQ_CONFLICT, feed with voidedBy, box score
  (parent: linked lines only), season stats. README section "Live match & offline queue (WP13)".

### Verified (fresh, 2026-11-02)
- `flutter analyze` → `No issues found!`
- `flutter test` → `+285: All tests passed!` (WP12: 195; +90). New by file: projector_vectors 17 (byte-identity of the
  7 copies, 7 vectors, 7 × 25 seeded shuffles with re-deliveries, pending-vs-synced ordering), match_event_json 2,
  scoring_rights 4, match_store 6 (restart across a file DB, UUIDv7, discard keeps seq, outbox, feed merge, caches),
  game_api 5 (every vector event through the generated oneOf, batch/feed mapping, 401/network → AppError,
  repository), mock_game_api 2, sync_worker 19 (incl. 7 vector feed merges), live_match_controller 9, game_clock 2,
  match_screens 23 (widgets), live golden 1.
- `flutter build web --pwa-strategy=offline-first` → `✓ Built build/web` (sqlite3.wasm + drift_worker.js copied);
  `flutter build web --dart-define=HOOPS_MOCK_API=true` (scratch output dir) also builds.
- **TDD red log** (each unit's test run red before its code): 1 domain/projector: suites failed to load (`RecordedEvent`,
  `Projection`, `StatLine`, `ProjectionWarning` undefined); 2 store: `match_database.dart`/`match_store.dart`/
  `pending_event.dart` missing; 3 sync: `backoff`/`sync_status`/`sync_worker`/`merge` missing; 4 API bridge:
  `api_events_remote`/`event_codec`/`matches_repository` missing; 5 rights: `scoring_rights.dart` missing and
  `Capabilities` had no `linkedPlayerIds`; 6 controller: `live_match_controller`/`match_providers`/`stat_action`
  missing; 7 clock: `game_clock.dart` missing. Negative controls (reverted): no sort in `canonicalOrder` → property tests
  fail; clamping disabled → `impossible-sequences-warnings` fails; no revert-to-PENDING on 401 → the 401 test fails.
  Honest exceptions: the dev-only `MockGameApi` and the presentation widgets were written before their tests (tests
  then found: snack bar covering the bench/save button → inline setup error; non-UTC `DateTime` in a fake; SENT
  wording when offline → SENT now strictly "in flight").
- Goldens: new `test/golden/goldens/live_match_360x780.png`; regenerated (intended UI change) `home_parent_360x780.png`
  (PARENT home is now the match list) and `player_detail_360x780.png` (new stats button). `--update-goldens` ran over
  the whole golden folder; the other goldens passed unchanged before the update.

### Acceptance evidence
| Item | Evidence |
|---|---|
| projector passes all vectors; shuffle property | `projector_vectors_test.dart` (7 vectors: playerStats, summary, teamTotals, warnings compared numerically + voidedBy; 25 seeded shuffles/vector with duplicates); fixtures byte-checked against `libs/contracts/vectors` |
| 50 offline → 50 ACCEPTED; replay → 50 DUPLICATE; projection = server box score | `sync_worker_test.dart` "50 events queued offline…" (FakeGameServer = contract semantics; box score = projector over the server's stored set) + 7 vector tests (feed of other scorers → local projection equals the golden and the fake server's box score) |
| parent mode; 401 preserves queue | `match_screens_test.dart` parent group (other / bench players' `onTap == null`, no clock / period / opponent / timeout / menu; coach event has no Void), `live_match_controller_test.dart` parent tests, `sync_worker_test.dart` "401 pauses … re-login resumes" |
| widget tests + golden 360×780; analyze + test green | `match_screens_test.dart` (list / setup / live / box score / season stats: loading, empty, error, populated, roles), `live_match_360x780.png`; analyze clean, 285 green |

### Decisions
- Domain events are plain Dart with contract JSON as the single codec; generated built_value types are only used at
  the HTTP edge (`EventCodec`), keeping the projector testable against the vector JSON and the web build simple.
- A local event without serverSeq sorts after any synced event at the same game instant (serverSeq = +∞ then id);
  once synced, the server order applies. REJECTED own events are excluded from the projection (the server never
  stored them) but stay in the log until discarded. Discard requires confirmation and never frees the clientSeq.
- SENT = in flight only; on any failure the batch returns to PENDING (a stored-but-unanswered event is re-sent and
  answered DUPLICATE, so nothing is lost or double counted).
- Sync scope = (active tenant, signed-in personId): events recorded by a previous user on the same device are never
  sent with another person's token (they would be REJECTED NOT_AUTHORIZED, a final answer).
- Parents have no clock: their events take the period / clock of the latest known event (feed or own).
- Undo VOIDs the last own event still in effect; the VOID gets the target's period/clock so it sits next to it.
- The game clock is local UI state (not persisted, not an event); it is initialised from the last event clock.
- Box score lines from the local projection follow `GET box-score` visibility: staff all, PARENT linked only, others
  team totals only.
- Season stats live under the Matches module (`/matches/stats/:playerId`) because every role has that destination.

### How WP14 links to season stats
`context.go('/matches/stats/<playerId>')` from Me (PLAYER: needs its own playerId, see gaps) and My players (PARENT:
`Capabilities.linkedPlayerIds`). The screen picks the current season (`activeSeasonProvider`) with a season dropdown
and uses `GET /players/{id}/season-stats?seasonId=`; back arrow goes to `/matches`.

### Open points / contract gaps
- **PWA offline reload (important for "network off from the start")**: Flutter 3.47 now emits a self-unregistering
  `flutter_service_worker.js` (no asset caching) even with `--pwa-strategy=offline-first`. Scoring works offline as
  long as the tab stays open (all data is in IndexedDB); reopening the app with no network needs a caching service
  worker (custom `web/sw.js` registered from `index.html`, or nginx/Workbox) — a shell/PWA decision for WP11/WP18.
- Not verified in a real browser: the wasm/IndexedDB path, the mock-mode click-through and real game-service
  (widget/unit tests use the native in-memory executor; both web builds compile). Multi-tab on one device:
  `unsafeIndexedDb` has no cross-tab lock, two tabs could allocate the same clientSeq (→ CLIENT_SEQ_CONFLICT, visible).
- Contract: `/me` has no player id for a PLAYER member → the client cannot show the "self" box-score line nor link
  Me → season stats without an extra lookup (WP14/WP3). No "match not started" / "id used by another match" reasons
  (WP7 gaps 2), no technical/unsportsmanlike in `StatLine` (shown only from the local projection), `opponentFouls`
  always null. The feed's `voidedByEventId` is stored but the local projection recomputes voids itself.
- The match list reads one page (size 100); create-match dialog uses the period defaults (4 × 10 min).
- `setup` replaces the roster online only (by design of the contract: 409 after FINISHED); offline the cached roster
  is used read-only.
- Stale files in `test/golden/failures/` (home_admin_*) predate this WP.
