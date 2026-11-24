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
| listMatchEvents | `GET /api/game/matches/{id}/events?after=&limit=` | any tenant member; filtered (WP33, ADR-0030): ADMIN/team staff every event, others team-level events + own/linked players' events (`StatVisibility` + `EventVisibility`, the box score's rule) |
| getBoxScore | `GET /api/game/matches/{id}/box-score` | any member; player lines: ADMIN/team staff all, PARENT linked, PLAYER self |
| getMatchSheetPdf | `GET /api/game/matches/{id}/box-score:pdf` | as getBoxScore (the same lines); rendered by pdf-service (WP117) |
| getPlayerSeasonStats | `GET /api/game/players/{id}/season-stats?seasonId=` | ADMIN, COACH, ASSISTANT_COACH, linked PARENT, PLAYER self; others 404 |

Ingest and projection semantics: ADR-0014. A batch locks the match row, reads its events once and re-projects from
them plus the accepted ones, writing only the `voided_by` marks that changed (WP126). The feed's `lastServerSeq` is
read with the match (its projected summary), before the page, so it never passes an event the page did not hold. The projector is pure domain code (`domain/events`, `domain/projection`);
shared test vectors live once in `libs/contracts/vectors`, which the web app's projector test reads too
(`-Dvectors.write=true` on `ProjectionVectorsTest` regenerates them).

State machine: `SCHEDULED -> LIVE -> FINISHED`; `CANCELLED` from `SCHEDULED` or `LIVE`. Illegal transitions are 409
(`INVALID_STATE`); starting needs a roster with a starter (422 `NO_STARTERS`), starting a LIVE match is idempotent.

## Layout (`com.hoopsacademy.game`)
```
domain/                  Match (state machine), MatchRoster, RosterEntry, value objects (MatchId, TeamId, PlayerId, SeasonId, JerseyNumber)
application/             use cases (CreateMatch, ChangeMatchStatus, ReplaceMatchRoster, ...), ports MatchRepository, RosterPort, UsageCounter
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
`RestRosterPort` implements game's `RosterPort{teamRoster, team, players}` by mapping the shared client's DTOs.

## Roster replica (WP68, WP82, WP98; ADR-0037)
`hoops.roster.source` (`GAME_ROSTER_SOURCE`) picks where `RosterPort` and the tenant filter's authorisation context
read core's roster: `replica` (the default since WP98) reads the local `*_ref` tables, `rest` (the fallback) core's
`/internal` API above. The consumer (`adapters/in/messaging`, channel `core-roster` over core's seven roster topics,
`GAME_ROSTER_CONSUMER_ENABLED`, default on) feeds the replica in both modes: schema-validated, applied in the event's
tenant (known `eventId` skipped, older `occurredAt` never wins, removals soft), invalid records parked in
`game.parked_event` (once per topic position, WP126). A daily job prunes old applied event ids and inspected parked
records (`hoops.roster.replica.retention.*`). The envelope checks, the consumer loop (a database failure is retried
`hoops.roster.replica.max-attempts` = 5 times, backoff from 0.5 s doubling, for apply and park), the meters and the
bookkeeping stores are common-quarkus' (`com.hoopsacademy.common.replica`, WP130, ADR-0062), the same as athlete's; game
keeps `RosterEventMapper` (payload to `RosterEvent`) and its replica tables. The tenant filter's context in `replica`
mode is common's `MembershipRule` (the rule of core's `/internal/authz`, WP134, ADR-0066) over `JdbcMembershipReads`.
Operations: `docs/runbooks/events.md`.

## Match sheet PDF (WP117; ADR-0051, ADR-0052)
`GetMatchSheetPdf` reads the caller's box score, the team's name (`RosterPort.team`) and the academy's name, and asks
the internal Rust pdf-service to render it (`adapters/out/client/PdfServiceMatchSheetRenderer`, game's service token;
the answer must start with `%PDF-`). Without `PDF_SERVICE_URL` the endpoint answers 503 `UPSTREAM_UNAVAILABLE` and
everything else works.

## Operations (WP17)
- `/q/health/live`, `/q/health/ready` (datasource check + `core-service` indicator), `/q/health/started`
  (`quarkus-smallrye-health`). The core indicator (`com.hoopsacademy.common.client.CoreReachabilityCheck`, shared from common-quarkus) is always UP and only
  reports `data.core = reachable|unreachable` from core's `/q/health/live` (timeout `hoops.core.health-timeout`, 1 s;
  cached `hoops.core.health-cache-ttl`, 10 s): a core outage must not take this service out of rotation, requests
  answer 503 Problems on their own. Helm probes use the http paths.
- `/q/metrics` (Prometheus), OpenTelemetry (SDK off unless `QUARKUS_OTEL_SDK_DISABLED=false`), JSON logs in prod with
  `tenantId`/`traceId` MDC, security headers, CORS allow-list and the 2 MB body limit come from common-quarkus defaults.
- Credentials have no fallback values: `*_PASSWORD` / `*_CLIENT_SECRET` must be set in the environment (a missing
  variable fails the start; `NoBuiltInCredentialsTest`).

## Configuration
| Key / env | Default | |
|---|---|---|
| `GAME_DB_URL` | `jdbc:postgresql://localhost:5432/hoops` | |
| `GAME_APP_PASSWORD`, `GAME_MIGRATOR_PASSWORD` | none (required) | roles `game_app` (runtime), `game_migrator` (Flyway) |
| `KEYCLOAK_URL` | `http://localhost:8180` | realm `academy` |
| `GAME_SERVICE_CLIENT_SECRET` | none (required) | OIDC client `game-service` (also used for service tokens) |
| `hoops.core.url` | `http://localhost:8081` | core-service base URL |
| `GAME_ROSTER_SOURCE` (`hoops.roster.source`) | `replica` | `rest` reads core's `/internal` API instead |
| `GAME_ROSTER_CONSUMER_ENABLED` | `true` | the roster consumer; `KAFKA_*` for the broker |
| `PDF_SERVICE_URL` (`hoops.pdf.url`) | unset | pdf-service base URL; `hoops.pdf.connect-timeout` 2 s, `hoops.pdf.read-timeout` 10 s |
| `hoops.game.overtime-minutes` | `5` | length of overtime periods (period > periodCount) |

## Tests
```
source scripts/env.sh && ./mvnw -pl services/game-service verify
```
Needs Podman for the Postgres Testcontainer; core-service and Keycloak's token endpoint are WireMock
(`support/CoreWireMockResource`, wiremock-standalone). REST tests use `@TenantUser` (the common test-jar resolver) and
validate every request and response against `/openapi/game.yaml`, match events included (`support/Contract.FILTER`,
default strict configuration, ADR-0027; the feed is also checked per event by `support/EventSchema`). Tests use a random HTTP port (`%test.quarkus.http.test-port=0`). `RealAuthzResolverTest` runs the production resolver by excluding
`TestAuthzContextResolver` through a `QuarkusTestProfile` (`quarkus.arc.exclude-types`).
