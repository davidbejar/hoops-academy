# Game-service model

The game service owns live match statistics: matches and their rosters, the append-only event log recorded
offline-first by the scorer, and the projections computed from it (box score, scoreboard, season statistics). It
keeps read-only replicas of the roster (`*_ref` tables, fed by core's roster events) so a match can be played without
calling core. Match and projection rules are in [glossary.md](glossary.md).

The tables and classes below are generated, not drawn: do not edit between the markers. After changing a Flyway
migration or a `domain` / `application` type, run `just diagrams` and commit the page; `just diagrams-check` (and CI)
fails when a page is stale. A table with more than 24 columns is summarised; private members are left out and
long member lists are capped.

## Tables

<!-- BEGIN GENERATED: er -->
<details open>
<summary>match and 5 more</summary>

```mermaid
erDiagram
    match {
        uuid id PK
        uuid tenant_id "RLS, not null"
        uuid team_id "not null"
        uuid season_id "not null"
        varchar opponent_name "not null"
        varchar home_away "not null"
        timestamptz scheduled_at "not null"
        varchar venue
        varchar status "not null"
        integer period_count "not null"
        integer period_minutes "not null"
        timestamptz started_at
        timestamptz finished_at
        timestamptz cancelled_at
        varchar cancel_reason
        uuid created_by_person_id "not null"
        bigint version "not null"
        timestamptz created_at "not null"
        timestamptz updated_at "not null"
    }
    match_event {
        uuid id PK
        uuid tenant_id FK "RLS, not null"
        uuid match_id FK "not null"
        bigint server_seq UK "not null"
        varchar device_id "not null"
        bigint client_seq "not null"
        varchar type "not null"
        uuid player_id
        integer period "not null"
        integer clock_seconds_remaining "not null"
        jsonb payload "not null"
        uuid recorded_by_person_id "not null"
        varchar recorded_by_display_name "not null"
        timestamptz recorded_at_client "not null"
        timestamptz received_at "not null"
        uuid voided_by
    }
    match_player_stats {
        uuid match_id PK,FK
        uuid tenant_id FK "RLS, not null"
        uuid player_id PK
        integer pts "not null"
        integer fgm1 "not null"
        integer fga1 "not null"
        integer fgm2 "not null"
        integer fga2 "not null"
        integer fgm3 "not null"
        integer fga3 "not null"
        integer ast "not null"
        integer oreb "not null"
        integer dreb "not null"
        integer tov "not null"
        integer stl "not null"
        integer blk "not null"
        integer pf "not null"
        integer technical_fouls "not null"
        integer unsportsmanlike_fouls "not null"
        integer seconds_played "not null"
        boolean was_starter "not null"
        jsonb warnings "not null"
    }
    match_roster {
        uuid match_id PK,FK
        uuid tenant_id FK "RLS, not null"
        uuid player_id PK
        varchar display_name "not null"
        varchar jersey_number
        boolean is_starter "not null"
    }
    match_summary {
        uuid match_id PK,FK
        uuid tenant_id FK "RLS, not null"
        integer our_score "not null"
        integer opp_score "not null"
        jsonb period_scores "not null"
        jsonb warnings "not null"
        bigint last_server_seq "not null"
        timestamptz updated_at "not null"
    }
    sync_receipt {
        uuid match_id PK,FK
        uuid tenant_id FK "RLS, not null"
        varchar device_id PK
        bigint last_client_seq "not null"
        timestamptz updated_at "not null"
    }
    match ||--o{ match_event : "tenant_id, match_id"
    match ||--o{ match_player_stats : "tenant_id, match_id"
    match ||--o{ match_roster : "tenant_id, match_id"
    match ||--o{ match_summary : "tenant_id, match_id"
    match ||--o{ sync_receipt : "tenant_id, match_id"
```

</details>

<details open>
<summary>applied_event and 9 more</summary>

```mermaid
erDiagram
    applied_event {
        uuid tenant_id PK "RLS"
        uuid event_id PK
        text topic "not null"
        timestamptz applied_at "not null"
    }
    guardian_link_ref {
        uuid tenant_id PK "RLS"
        uuid id PK
        uuid guardian_person_id "not null"
        uuid player_id "not null"
        boolean removed "not null"
        timestamptz occurred_at "not null"
        uuid event_id "not null"
    }
    parked_event {
        bigint id PK
        text topic "not null"
        integer kafka_partition "not null"
        bigint kafka_offset "not null"
        text record_key
        uuid event_id
        text reason "not null"
        timestamptz parked_at "not null"
        timestamptz inspected_at
    }
    person_ref {
        uuid tenant_id PK "RLS"
        uuid id PK
        text display_name
        text subject
        text[] roles
        boolean active
        timestamptz occurred_at "not null"
        uuid event_id "not null"
        boolean removed "not null"
    }
    player_ref {
        uuid tenant_id PK "RLS"
        uuid id PK
        uuid person_id
        text display_name
        text status
        date birth_date
        text gender
        timestamptz occurred_at "not null"
        uuid event_id "not null"
        boolean removed "not null"
    }
    replica_tenant {
        uuid id PK
        timestamptz first_seen_at "not null"
    }
    team_player_ref {
        uuid tenant_id PK "RLS"
        uuid id PK
        uuid team_id
        uuid player_id
        text jersey_number
        date joined_on
        date left_on
        text invalid_reason
        timestamptz occurred_at "not null"
        uuid event_id "not null"
        boolean removed "not null"
    }
    team_ref {
        uuid tenant_id PK "RLS"
        uuid id PK
        uuid season_id
        date season_end_date
        text name
        timestamptz occurred_at "not null"
        uuid event_id "not null"
        boolean removed "not null"
    }
    team_staff_ref {
        uuid tenant_id PK "RLS"
        uuid id PK
        uuid team_id "not null"
        uuid person_id "not null"
        text role
        boolean removed "not null"
        timestamptz occurred_at "not null"
        uuid event_id "not null"
    }
    tenant_ref {
        uuid tenant_id PK "RLS"
        text status
        text timezone
        timestamptz occurred_at "not null"
        uuid event_id "not null"
        boolean removed "not null"
    }
```

</details>
<!-- END GENERATED: er -->

## Domain classes

<!-- BEGIN GENERATED: domain -->
<details open>
<summary>Match</summary>

```mermaid
classDiagram
    class HomeAway {
        <<enumeration>>
        HOME
        AWAY
    }
    class JerseyNumber {
        <<record>>
        +String value
    }
    class Match {
        +schedule(MatchId,TeamId,SeasonId,String,HomeAway,Instant,String,Integer,Integer,UUID) Match
        +restore(MatchId,TeamId,SeasonId,String,HomeAway,Instant,String,MatchStatus,int,int,Instant,Instant,Instant,String,UUID,long,MatchScore) Match
        +start(MatchRoster,Instant) void
        +finish(Instant) void
        +cancel(String,Instant) void
        +requireRosterEditable() void
        +update(String,HomeAway,Instant,boolean,String,Integer,Integer) void
        +id() MatchId
        +teamId() TeamId
        +seasonId() SeasonId
        and 14 more
    }
    class MatchRoster {
        <<record>>
        +MatchId matchId
        +List~RosterEntry~ entries
        +hasStarter() boolean
    }
    class MatchScore {
        <<record>>
        +int team
        +int opponent
        +long lastServerSeq
    }
    class MatchStatus {
        <<enumeration>>
        SCHEDULED
        LIVE
        FINISHED
        CANCELLED
    }
    class PlayerVisibility {
        <<record>>
        +boolean seesAll
        +Set~PlayerId~ players
        +sees(PlayerId) boolean
    }
    class RosterEntry {
        <<record>>
        +PlayerId playerId
        +String displayName
        +JerseyNumber jerseyNumber
        +boolean starter
    }
    class SeasonClose {
        <<record>>
        +Instant at
        +hasPassed(Instant) boolean
    }
    Match --> HomeAway : homeAway
    Match --> MatchScore : score
    Match --> MatchStatus : status
    MatchRoster --> "*" RosterEntry : entries
    RosterEntry --> JerseyNumber : jerseyNumber
```

</details>

<details open>
<summary>Identifiers</summary>

```mermaid
classDiagram
    class MatchId {
        <<record>>
        +UUID value
        +toString() String
    }
    class PlayerId {
        <<record>>
        +UUID value
        +toString() String
    }
    class SeasonId {
        <<record>>
        +UUID value
        +toString() String
    }
    class TeamId {
        <<record>>
        +UUID value
        +toString() String
    }
```

</details>

<details open>
<summary>Package events</summary>

```mermaid
classDiagram
    class EventId {
        <<record>>
        +UUID value
        +compareTo(EventId) int
        +toString() String
    }
    class EventMeta {
        <<record>>
        +EventId id
        +String deviceId
        +long clientSeq
        +int period
        +int clockSecondsRemaining
        +Instant recordedAtClient
    }
    class EventOrdering {
        +canonical(Collection~RecordedEvent~) List~RecordedEvent~
    }
    class EventVisibility {
        +of(Collection~MatchEvent~,PlayerVisibility) EventVisibility
        +visible(MatchEvent) boolean
    }
    class MatchEvent {
        <<interface>>
        +meta() EventMeta
        +type() MatchEventType
        +playerId() Optional~PlayerId~
        +id() EventId
    }
    class MatchEventType {
        <<enumeration>>
        PERIOD_START
        PERIOD_END
        SUB_IN
        SUB_OUT
        SHOT
        ASSIST
        REBOUND
        TURNOVER
        and 7 more
    }
    class RecordedEvent {
        <<record>>
        +MatchEvent event
        +long serverSeq
        +id() EventId
        +meta() EventMeta
    }
    EventMeta --> EventId : id
    EventVisibility --> EventId : byId
    EventVisibility --> MatchEvent : byId
    RecordedEvent --> MatchEvent : event
```

</details>

<details open>
<summary>Package projection</summary>

```mermaid
classDiagram
    class BoxScoreProjector {
        +project(MatchRules,List~RosterEntry~,Collection~RecordedEvent~) Projection
    }
    class MatchRules {
        <<record>>
        +int periodCount
        +int periodMinutes
        +int overtimeMinutes
        +periodSeconds(int) int
    }
    class MatchSummary {
        <<record>>
        +int teamScore
        +int opponentScore
        +List~PeriodScore~ periodScores
        +long lastServerSeq
    }
    class PeriodScore {
        <<record>>
        +int period
        +int team
        +int opponent
    }
    class PlayerLine {
        <<record>>
        +PlayerId playerId
        +boolean wasStarter
        +StatLine stats
        +List~ProjectionWarning~ warnings
    }
    class PlayerTally {
    }
    class Projection {
        <<record>>
        +List~PlayerLine~ playerStats
        +MatchSummary summary
        +List~ProjectionWarning~ warnings
        +Map~EventId,EventId~ voidedBy
        +teamTotals() StatLine
    }
    class ProjectionRun {
    }
    class ProjectionWarning {
        <<record>>
        +String code
        +EventId eventId
        +PlayerId playerId
        +String message
    }
    class Scoreboard {
    }
    class SeasonLine {
        <<record>>
        +MatchId matchId
        +Instant scheduledAt
        +String opponentName
        +MatchStatus status
        +boolean wasStarter
        +StatLine stats
        +played() boolean
    }
    class SeasonStats {
        <<record>>
        +PlayerId playerId
        +SeasonId seasonId
        +int gamesPlayed
        +int gamesStarted
        +StatLine totals
        +Averages averages
        +List~SeasonLine~ matches
    }
    class StatLine {
        <<record>>
        +int points
        +int fg1Made
        +int fg1Attempted
        +int fg2Made
        +int fg2Attempted
        +int fg3Made
        +int fg3Attempted
        +int assists
        +int offensiveRebounds
        +int defensiveRebounds
        and 10 more
    }
    class VoidResolution {
        <<record>>
        +Map~EventId,EventId~ voidedBy
        +List~ProjectionWarning~ warnings
    }
    class WarningCode {
        <<enumeration>>
        SUB_IN_PLAYER_ON_COURT
        SUB_OUT_PLAYER_NOT_ON_COURT
        PLAYER_NOT_ON_COURT
        PLAYER_NOT_IN_ROSTER
        TOO_MANY_PLAYERS_ON_COURT
        EVENT_OUTSIDE_PERIOD
        PERIOD_ALREADY_RUNNING
        PERIOD_ALREADY_PLAYED
        and 5 more
    }
    MatchSummary --> "*" PeriodScore : periodScores
    PlayerLine --> "*" ProjectionWarning : warnings
    PlayerLine --> StatLine : stats
    PlayerTally --> "*" ProjectionWarning : warnings
    Projection --> "*" PlayerLine : playerStats
    Projection --> "*" ProjectionWarning : warnings
    Projection --> MatchSummary : summary
    ProjectionRun --> "*" ProjectionWarning : matchWarnings
    ProjectionRun --> MatchRules : rules
    ProjectionRun --> PlayerTally : tallies
    ProjectionRun --> Scoreboard : scoreboard
    SeasonLine --> StatLine : stats
    SeasonStats --> "*" SeasonLine : matches
    SeasonStats --> StatLine : totals
    VoidResolution --> "*" ProjectionWarning : warnings
```

</details>
<!-- END GENERATED: domain -->

## Application ports

<!-- BEGIN GENERATED: ports -->
<details open>
<summary>application (root)</summary>

```mermaid
classDiagram
    class MatchEventRepository {
        <<interface>>
        +findByMatch(MatchId) List~StoredEvent~
        +after(MatchId,PlayerVisibility,long,int) List~StoredEvent~
        +lastServerSeq(MatchId) long
        +append(MatchId,MatchEvent,Recorder) OptionalLong
        +markVoided(MatchId,Map~EventId,EventId~) void
        +recordReceipt(MatchId,String,long) void
        +count() long
        +countReceivedSince(Instant) long
    }
    class MatchRepository {
        <<interface>>
        +save(Match) void
        +findById(MatchId) Optional~Match~
        +lockById(MatchId) Optional~Match~
        +list(MatchFilter,int,int) MatchPage
        +roster(MatchId) MatchRoster
        +replaceRoster(MatchRoster) void
    }
    class ProjectionRepository {
        <<interface>>
        +save(MatchId,Projection) void
        +find(MatchId) Optional~Projection~
        +seasonLines(PlayerId,SeasonId) List~SeasonLine~
    }
    class RosterPort {
        <<interface>>
        +teamRoster(TenantId,TeamId) TeamRoster
        +players(TenantId,Collection~PlayerId~) List~PlayerBrief~
    }
    class SubmittedEvent {
        <<interface>>
        +eventId() UUID
    }
    class UsageCounter {
        <<interface>>
        +usage() Usage
    }
```

</details>

<details open>
<summary>application replica</summary>

```mermaid
classDiagram
    class ParkedRecords {
        <<interface>>
        +park(ParkedRecord) void
    }
    class RosterEvent {
        <<interface>>
        +envelope() EventEnvelope
        +topic() String
    }
    class RosterReplica {
        <<interface>>
        +markApplied(EventEnvelope,String) boolean
        +save(RosterEvent) boolean
    }
    class RosterReplicaQueries {
        <<interface>>
        +tenant(TenantId) Optional~ReplicaTenant~
        +team(TeamId) Optional~ReplicaTeam~
        +roster(TeamId) List~RosterLine~
        +players(Collection~PlayerId~) List~ReplicaPlayer~
        +activePerson(String) Optional~ReplicaPerson~
        +playerOf(UUID) Optional~PlayerId~
        +linkedPlayers(UUID) Set~PlayerId~
        +staffTeams(UUID) Set~TeamId~
        +openValidTeamsOf(Collection~PlayerId~) Set~TeamId~
        +seasonEnds(Collection~TeamId~) Map~TeamId,LocalDate~
    }
```

</details>
<!-- END GENERATED: ports -->
