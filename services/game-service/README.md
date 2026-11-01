# game-service

Matches and match rosters of Hoops Academy (WP6). WP7 adds offline-synced match events, box scores and season
statistics on top of the same packages. Port 8082, schema `game`, contract `libs/contracts/openapi/game.yaml`.

## Implemented (WP6)
| Operation | Path | Who |
|---|---|---|
| listMatches, getMatch, getMatchRoster | `GET /api/game/matches[...]` | any tenant member |
| createMatch, updateMatch, startMatch, finishMatch, cancelMatch, replaceMatchRoster | `POST/PATCH/PUT /api/game/matches[...]` | ADMIN, or COACH / ASSISTANT_COACH who is staff of the match's team (otherwise 403) |
| getGameUsage | `GET /internal/usage/{tenantId}` | realm role `service` |


## Implemented (WP7)
| Operation | Path | Who |
|---|---|---|
| submitMatchEvents | `POST /api/game/matches/{id}/events:batch` | per event: ADMIN / team staff any type; PARENT stat events of linked players + VOID of own events; others `NOT_AUTHORIZED` |
| listMatchEvents | `GET /api/game/matches/{id}/events?after=&limit=` | any tenant member |
| getBoxScore | `GET /api/game/matches/{id}/box-score` | any member; player lines: ADMIN/team staff all, PARENT linked, PLAYER self |
| getPlayerSeasonStats | `GET /api/game/players/{id}/season-stats?seasonId=` | ADMIN, COACH, ASSISTANT_COACH, linked PARENT, PLAYER self; others 404 |

Ingest and projection semantics: ADR-0014. The projector is pure domain code (`domain/events`, `domain/projection`);
shared test vectors live in `src/test/resources/vectors` and are copied to `libs/contracts/vectors`
(`-Dvectors.write=true` on `ProjectionVectorsTest` regenerates both).

State machine: `SCHEDULED -> LIVE -> FINISHED`; `CANCELLED` from `SCHEDULED` or `LIVE`. Illegal transitions are 409
(`INVALID_STATE`); starting needs a roster with a starter (422 `NO_STARTERS`), starting a LIVE match is idempotent.

## Layout (`com.hoopsacademy.game`)
```
domain/                  Match (state machine), MatchRoster, RosterEntry, value objects (MatchId, TeamId, PlayerId, SeasonId, JerseyNumber)
application/             use cases (CreateMatch, StartMatch, ReplaceMatchRoster, ...), ports MatchRepository, RosterPort, UsageCounter
adapters/in/rest/        MatchResource, MatchRosterResource, DTOs (401/409/503 Problems come from common-quarkus)
adapters/in/internal/    UsageResource (/internal/usage/{tenantId})
adapters/out/persistence JPA entities (@TenantId), JpaMatchRepository, JpaUsageCounter
adapters/out/client/     RestRosterPort (thin mapping over common-quarkus' CoreRosterClient)
```
WP7: `domain/events` (MatchEvent sealed hierarchy, EventOrdering), `domain/projection` (BoxScoreProjector, SeasonStats),
`application/` (IngestEventBatch, EventAuthorization, MatchReprojection, GetMatchEvents, GetBoxScore,
GetPlayerSeasonStats; ports MatchEventRepository, ProjectionRepository), `adapters/json` (MatchEventJson codec),
`adapters/in/rest` (MatchEventResource, BoxScoreResource, SeasonStatsResource, MatchEventDecoder = JSON Schema
validation), `adapters/out/persistence` (JDBC repositories on the transaction's
connection) and Flyway `V2__events.sql` (`match_event`, `match_player_stats`, `match_summary`).

## Talking to core-service (ADR-0008)
Since WP2c the client lives in common-quarkus (`com.hoopsacademy.common.client`): `CoreInternalClient` (REST client,
configKey `core`, base URL `hoops.core.url`, 2 s timeouts, client-credentials token via `ServiceTokenClientFilter`),
`CoreRosterClient` (Caffeine cache `hoops.core.cache-ttl` = 30 s per distinct call; failures, unknown teams and "not a
member" are not cached; 404 -> `NotFoundException`, timeout / connection error / 5xx / 401 / 403 ->
`UpstreamUnavailableException` -> `503` Problem `UPSTREAM_UNAVAILABLE`, declared in the contract) and
`RosterAuthzResolver` (`@DefaultBean` for the common tenant filter; SUSPENDED / WITHDRAWN tenant -> no membership, 404).
`RestRosterPort` implements game's `RosterPort{teamRoster, players}` by mapping the shared client's DTOs.

## Configuration
| Key / env | Default | |
|---|---|---|
| `GAME_DB_URL` | `jdbc:postgresql://localhost:5432/hoops` | |
| `GAME_APP_PASSWORD`, `GAME_MIGRATOR_PASSWORD` | `change-me` | roles `game_app` (runtime), `game_migrator` (Flyway) |
| `KEYCLOAK_URL` | `http://localhost:8180` | realm `academy` |
| `GAME_SERVICE_CLIENT_SECRET` | `change-me` | OIDC client `game-service` (also used for service tokens) |
| `hoops.core.url` | `http://localhost:8081` | core-service base URL |
| `hoops.game.overtime-minutes` | `5` | length of overtime periods (period > periodCount) |

## Tests
```
source scripts/env.sh && ./mvnw -pl services/game-service verify
```
Needs Podman for the Postgres Testcontainer; core-service and Keycloak's token endpoint are WireMock
(`support/CoreWireMockResource`, wiremock-standalone). REST tests use `@TenantUser` (the common test-jar resolver) and
validate every response against `/openapi/game.yaml` (event payloads: see `support/Contract.BATCH/FEED` and
`support/EventSchema`). Tests use a random HTTP port (`%test.quarkus.http.test-port=0`). `RealAuthzResolverTest` runs the production resolver by excluding
`TestAuthzContextResolver` through a `QuarkusTestProfile` (`quarkus.arc.exclude-types`).
