# ADR-0062: one roster replica pipeline in common-quarkus, with one retry, reason and meter policy

- Status: Accepted (amends ADR-0037)
- Date: 2026-11-24
- Related: ADR-0037 (roster replicas; its WP82 and WP98 amendments moved `ReplicaRetention` into common), ADR-0036
  (topics, keys), ADR-0053 (duplication gate), ADR-0045 (SAST acceptances), decision 106 of 2026-11-23,
  [WP130](../wp/WP130-replica-pipeline-in-common.md), audit 2026-11-23 X-01, LIB-01, GAME-05, GAME-06, ATH-02, ATH-05

## Context
ADR-0037 describes one replica design "shared by game and athlete", but WP68 and WP69 wrote it twice, in parallel, and
only the retention rule and the test broker moved into common-quarkus later (WP98). The two copies (about 1,100 lines
of main code) had drifted where operators notice:

| Point | game (before) | athlete (before) |
|---|---|---|
| Retries of a record's database work | `apply-attempts` 3, pauses 1 s, 2 s (linear) | `max-attempts` 5, pauses from `first-backoff` 0.5 s doubling |
| A failed park | not retried: one database blip failed the channel | retried like an apply |
| Parked reason | up to 1000 characters, all schema errors, the record key and the unknown time zone quoted | up to 500 characters, at most 5 schema errors, no value of the record |
| Meters `parked_total` / `lag_seconds` | registered for all seven topics at start | registered on first use (a panel saw "no data", not 0) |
| `parked_event` | identity `id`, column `kafka_partition`, unique position (WP126) | primary key on the position, column `partition` |
| Retention job | scheduler identity `game-replica-retention` | `athlete.replica-retention` |

The characterisation tests of WP130 (`RosterEventConsumerPolicyTest`, `CoreRosterConsumerPolicyTest`, removed with the
two loops) pinned these differences before the move.

## Decision
1. **One pipeline in `com.hoopsacademy.common.replica`**, plain classes (core depends on the library and keeps no
   replica, so nothing there is a CDI bean):
   - `CoreEventDecoder<E>`: the envelope half of the decoders: the seven topics (`RosterTopic`), each topic's JSON Schema
     from the contracts jar (read once, at construction; a missing jar fails the start), the key
     `<tenantId>:<aggregateId>`, a tenant event about its own tenant, the event id. It hands an `EventEnvelope` and the
     payload to the service's `EventMapper<E>`, which only says what the event means for that service's replica.
     A mapper that throws `IllegalArgumentException` or `DateTimeException` (a value the schema allows but the service
     cannot read, such as an unknown time zone) gets the record parked; any other exception is a bug and stops the
     consumer.
   - `ReplicaConsumer<E>`: the loop each service's `@Incoming("core-roster")` method hands its records to: tombstone
     counted and skipped, valid event applied by the service's `ReplicaApplier` (its use case, in the event's tenant)
     and counted by `ReplicaOutcome`, invalid record parked through `ParkedEvents` and acknowledged.
   - `ReplicaMetrics`, `ReplicaHousekeeping` (the retention run under the service's advisory lock, counted),
     `JdbcReplicaHistory` and `JdbcParkedEvents` on a `ReplicaSchema` (a plain lower-case identifier, so the SQL text is
     built once from constants and that name; every value is a bound parameter).
   Each service keeps its mapper, its use case and replica tables (what an event means for it), a producer that wires
   the pipeline, and its `@Scheduled` retention method: the scheduler is still not a dependency of the library (WP98),
   so `ReplicaRetentionJob` stays a five-line shim per service around `ReplicaHousekeeping`.
2. **One policy where the copies differed**, athlete's except for the meters:
   - **Retries**: `hoops.roster.replica.max-attempts` (default 5; env `GAME_ROSTER_REPLICA_MAX_ATTEMPTS` /
     `ATHLETE_ROSTER_REPLICA_MAX_ATTEMPTS`) tries of a record's database work, with a pause from
     `hoops.roster.replica.first-backoff` (0.5 s) doubling after each failed try (7.5 s in all), for the apply **and the
     park**; then the failure is rethrown and fails the channel (ADR-0037 §5). Why: a park is the same database work as
     an apply, and 7.5 s rides out a short failover that game's 3 s did not. `apply-attempts` is gone.
   - **Parked reason**: at most five schema errors and 500 characters, and never a value of the record (not the key,
     which has its own column, not a time zone, not a parser message that quotes the input); ADR-0037 §4 already said
     "not the value". A record the mapper cannot read is parked as `value outside the contract: <exception type>`.
   - **Meters**: game's: `hoops_roster_replica_parked_total{topic}` and `hoops_roster_replica_lag_seconds{topic}`
     exist for all seven topics from the start, so "parked = 0" is visible to an alert or a panel in both services.
   - **`parked_event`**: athlete's shape in both schemas (game V10): primary key `(topic, partition, kafka_offset)`, no
     surrogate id; one runbook procedure marks a row inspected by its position. The insert is `on conflict do nothing`
     without a conflict target, as athlete's always was, so a replayed record is parked once.
   - **Retention scheduler identity**: the lock name, `<service>.replica-retention`.

## Consequences
- About 800 lines of main code leave the two services (the figures are in WP130's handover); the library gains about
  500 with its own unit tests (in PIT scope) and a database test on the shared table shape (common's test migration V3).
- game behaves differently in three ways an operator can see: it retries five times over 7.5 s instead of three over
  3 s, it retries a failed park, and its parked reasons no longer quote the key or the unknown zone. The runbook
  (`docs/runbooks/events.md`, "Roster replicas: game and athlete") describes one procedure.
- A change to the envelope (a `v2` topic, a key rule), the retry policy or the meters is made once.
- finance's Go consumer (ADR-0055) is a language decision and keeps its own copy; its `parked_event` already uses
  `partition` and `"offset"`.

## Alternatives considered
- **Keep two copies and only align the settings**: the cheapest change, but the next fix would drift again; decision
  106 chose the move.
- **The retention job itself in common, enabled by a property**: would add `quarkus-scheduler` to the library core
  depends on (WP98); a five-line shim per service costs less.
- **game's `parked_event` shape for both** (identity id, `kafka_partition`): keeps game's runbook query, but the
  surrogate key adds nothing once the position is unique, and athlete and finance already name the column `partition`.
