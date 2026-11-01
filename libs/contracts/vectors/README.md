# Match projection test vectors

**Generated — do not edit by hand.** These files are produced and verified by game-service
(`services/game-service/src/test/java/.../domain/projection/ProjectionVectorsTest.java`, source copies in
`services/game-service/src/test/resources/vectors/`). That test fails if a copy here differs from the source.
They are consumed by the Flutter offline projector (WP13), which must reproduce `expected` exactly.

Regenerate after a deliberate projection change (then review the diff):

```
source scripts/env.sh
./mvnw -pl services/game-service test -Dtest=ProjectionVectorsTest -Dvectors.write=true
```

## File format

```jsonc
{
  "name": "simple-game",
  "description": "what the scenario exercises",
  "match":  { "periodCount": 4, "periodMinutes": 10, "overtimeMinutes": 5 },   // period > periodCount = overtime
  "roster": [ { "playerId": "…", "displayName": "Ana", "jerseyNumber": "4", "isStarter": true } ],  // line order
  "events": [ { "serverSeq": 1, "recordedByPersonId": "…", "event": { /* contract MatchEvent JSON */ } } ],
  "expected": {
    "playerStats": [ { "playerId": "…", "wasStarter": true,
                       "stats": { /* StatLine + technicalFouls + unsportsmanlikeFouls */ },
                       "warnings": [ { "code": "…", "eventId": "…", "playerId": "…|null" } ] } ],
    "summary":   { "teamScore": 0, "opponentScore": 0, "periodScores": [ { "period": 1, "team": 0, "opponent": 0 } ],
                   "lastServerSeq": 0 },
    "teamTotals": { /* sum of the player lines */ },
    "warnings":  [ /* match-level warnings, same shape */ ],
    "voidedBy":  { "<voided event id>": "<VOID event id>" }
  }
}
```

`events` are listed in creation order; `serverSeq` is the arrival order at the server and may differ (see
`out-of-order-arrival`). `recordedByPersonId` only matters for authorization; the projection ignores it. Warning
`message` texts are informative and not part of the vectors.

## Projection rules (summary)

- Replay order: period ascending, clock (seconds remaining) descending, `recordedAtClient` ascending, `serverSeq`
  ascending, event id ascending. Repeated ids count once. The result depends only on the set of events.
- VOID removes its target everywhere; the earliest VOID (replay order) is the recorded `voidedBy`. VOID of a VOID →
  `VOID_OF_VOID` (ignored); unknown target → `VOID_TARGET_NOT_FOUND`.
- Starters are on court before the first period. The clock runs only between PERIOD_START and PERIOD_END;
  substitutions while it is stopped change the lineup without adding time. A clock above the period length is
  clamped (`CLOCK_OUT_OF_RANGE`); a PERIOD_START of a later period while one is running closes it at 0:00
  (`MISSING_PERIOD_END`). While a period is still running, time counts up to the latest event's clock.
- Points: made SHOTs (1/2/3); every made shot counts for the team score, also for a player not on the roster.
  `personalFouls` counts every foul; TECHNICAL and UNSPORTSMANLIKE are also counted separately.
- Warnings never drop an event: `SUB_IN_PLAYER_ON_COURT`, `SUB_OUT_PLAYER_NOT_ON_COURT`, `PLAYER_NOT_ON_COURT`
  (not for technical/unsportsmanlike fouls), `PLAYER_NOT_IN_ROSTER` (match level, no player line),
  `TOO_MANY_PLAYERS_ON_COURT`, `EVENT_OUTSIDE_PERIOD` (incl. after the final PERIOD_END), `PERIOD_ALREADY_RUNNING`,
  `PERIOD_ALREADY_PLAYED`, `PERIOD_NOT_RUNNING`, `MISSING_PERIOD_END`, `CLOCK_OUT_OF_RANGE`.
- `periodScores` has one entry per period from 1 to max(periodCount, highest period of a counted event).
