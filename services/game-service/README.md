# game-service

Matches and match rosters of Hoops Academy (WP6). WP7 adds offline-synced match events, box scores and season
statistics on top of the same packages. Port 8082, schema `game`, contract `libs/contracts/openapi/game.yaml`.

## Implemented (WP6)
| Operation | Path | Who |
|---|---|---|
| listMatches, getMatch, getMatchRoster | `GET /api/game/matches[...]` | any tenant member |
| createMatch, updateMatch, startMatch, finishMatch, cancelMatch, replaceMatchRoster | `POST/PATCH/PUT /api/game/matches[...]` | ADMIN, or COACH / ASSISTANT_COACH who is staff of the match's team (otherwise 403) |
| getGameUsage | `GET /internal/usage/{tenantId}` | realm role `service` |

Not yet implemented (WP7): `submitMatchEvents`, event feed, box score, season statistics.

State machine: `SCHEDULED -> LIVE -> FINISHED`; `CANCELLED` from `SCHEDULED` or `LIVE`. Illegal transitions are 409
(`INVALID_STATE`); starting needs a roster with a starter (422 `NO_STARTERS`), starting a LIVE match is idempotent.

## Layout (`com.hoopsacademy.game`)
```
domain/                  Match (state machine), MatchRoster, RosterEntry, value objects (MatchId, TeamId, PlayerId, SeasonId, JerseyNumber)
application/             use cases (CreateMatch, StartMatch, ReplaceMatchRoster, ...), ports MatchRepository, RosterPort, UsageCounter
adapters/in/rest/        MatchResource, MatchRosterResource, DTOs, 503 mapper
adapters/in/internal/    UsageResource (/internal/usage/{tenantId})
adapters/out/persistence JPA entities (@TenantId), JpaMatchRepository, JpaUsageCounter
adapters/out/client/     RestRosterPort (core /internal/**, Caffeine 30 s, 2 s timeout), RosterAuthzResolver
```
WP7 adds `domain/event`, `application/` event use cases, `adapters/in/rest/MatchEventResource`,
`adapters/out/persistence/*Event*` and a Flyway `V2__match_event.sql`; `sync_receipt` already exists.

## Talking to core-service (ADR-0008)
`RestRosterPort` implements `RosterPort{teamRoster, players, authzContext}` against core `/internal/**` with a
client-credentials token (`ServiceTokenClientFilter`, `quarkus.oidc-client.*`). Answers are cached for
`hoops.roster.cache-ttl` (30 s) per distinct call; failures are not cached. 404 -> `NotFoundException`;
timeout (2 s, `quarkus.rest-client.core.*-timeout`), connection errors, 5xx, 401/403 -> `UpstreamUnavailableException`
-> `503` Problem with `code: UPSTREAM_UNAVAILABLE`. `RosterAuthzResolver` feeds the common tenant filter; a
SUSPENDED / WITHDRAWN tenant yields no membership (404).

## Configuration
| Key / env | Default | |
|---|---|---|
| `GAME_DB_URL` | `jdbc:postgresql://localhost:5432/hoops` | |
| `GAME_APP_PASSWORD`, `GAME_MIGRATOR_PASSWORD` | `change-me` | roles `game_app` (runtime), `game_migrator` (Flyway) |
| `KEYCLOAK_URL` | `http://localhost:8180` | realm `academy` |
| `GAME_SERVICE_CLIENT_SECRET` | `change-me` | OIDC client `game-service` (also used for service tokens) |
| `hoops.core.url` | `http://localhost:8081` | core-service base URL |

## Tests
```
source scripts/env.sh && ./mvnw -pl services/game-service verify
```
Needs Podman for the Postgres Testcontainer; core-service and Keycloak's token endpoint are WireMock
(`support/CoreWireMockResource`, wiremock-standalone). REST tests use `@TenantUser` (the common test-jar resolver) and
validate every response against `/openapi/game.yaml`. `RealAuthzResolverTest` runs the production resolver by excluding
`TestAuthzContextResolver` through a `QuarkusTestProfile` (`quarkus.arc.exclude-types`).
