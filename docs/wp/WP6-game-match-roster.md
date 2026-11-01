# WP6 — game-service: match & roster CRUD, RosterPort REST adapter

Model: Sonnet. Depends on: WP2a, WP2b (contracts); runtime depends on core `/internal` (mock with WireMock in tests).
Lane GAME. Contract: `libs/contracts/openapi/game.yaml`. Skills: test-driven-development, quarkus-hexagonal-service,
tenant-isolation-testing.

## Scope
- Module `services/game-service`, package `com.hoopsacademy.game`, datasource `game_app`, Flyway as `game_migrator`.
- Flyway V1: `match` (team_id, season_id, opponent_name, home_away, scheduled_at, venue, status, period_count,
  period_minutes, started_at, finished_at, created_by, version), `match_roster` (match, player_id, display_name,
  jersey_number, is_starter), `sync_receipt` placeholder (WP7). RLS on all.
- `RosterPort` (application port): `teamRoster(teamId)`, `players(ids)`, `authzContext(sub, tenantId)`; adapter =
  Quarkus REST client to core `/internal/**` with `ServiceTokenClientFilter`, Caffeine cache 30 s, 2 s timeout → 503
  Problem; `AuthzContextResolver` for the common tenant filter delegates to it (also honours tenant status).
- Use cases: create match (staff of team or admin), get/list (by team/season/status), patch, start/finish/cancel
  (state machine), put roster (snapshot names/jerseys from RosterPort; validate players belong to the team or are
  explicitly allowed play-up guests), get roster; `/internal/usage/{tenantId}` (match counts).

## Acceptance
- [ ] state machine tests (SCHEDULED→LIVE→FINISHED, CANCELLED from SCHEDULED/LIVE; invalid → 409)
- [ ] role matrix: parent/player cannot create/start; staff of another team → 403; cross-tenant → 404
- [ ] RosterPort adapter: WireMock happy path, 404 mapping, timeout → 503 Problem, cache hit avoids second call
- [ ] RLS suites for schema `game`; contract validation on responses; verify green, coverage ≥ 80 %
