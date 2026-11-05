# ADR-0028: Match event feed filtered by player visibility

- Status: Accepted
- Date: 2026-11-05
- Related: ADR-0021 §3 (match visibility; F-01 open there until now), ADR-0014 (ingest and projection),
  `docs/security/review-2026-11.md` F-01, decision 5 of 2026-11-05, WP33

## Context
`GET /api/game/matches/{id}/events` returned every event of a match to any member, while the box score hid other
players' lines from PARENT and PLAYER. A parent could rebuild other children's stat lines from the feed (F-01,
CWE-639). Decision 5 of 2026-11-05: filter the feed server-side; team-level events for everyone, player events only for
the caller's own or linked players; staff keep the full feed. Several details were open.

## Decision
1. **One rule decides whose statistics a caller sees** (`StatVisibility` in game-service `application`, returning the
   domain value `PlayerVisibility`): ADMIN and staff (COACH / ASSISTANT_COACH with a `team_staff` row) **of the match's
   team** see every player; anybody else sees the players they are guardian of (PARENT role) and their own player
   (PLAYER role). The box score's lines (`GetBoxScore`) and the feed (`GetMatchEvents`) both use it. So a COACH of
   *another* team reads the feed filtered, exactly as their box score already showed no lines (authz matrix column
   "COACH (team staff)"); a COACH of another team who is also a parent sees their linked children.
2. **Which events are player events** (`EventVisibility`, domain): every event with a `playerId` — the seven stat
   types, **`SUB_IN` / `SUB_OUT`** and a `NOTE` about a player. Substitutions are player data: they give each player's
   minutes, a column of the hidden box-score line. Team-level, visible to every member: `PERIOD_START`, `PERIOD_END`,
   `OPPONENT_SCORE`, `TIMEOUT` and a `NOTE` without a player (free text written by staff).
3. **A `VOID` follows its target**, through VOID-of-VOID chains: visible exactly when the event it finally voids is.
   A VOID whose target the server does not know, or that ends in a cycle of VOIDs, names no player and is visible
   (it has no effect on any projection). A parent's own events are always about linked players, so they and their
   VOIDs stay visible to that parent.
4. **Paging walks the visible events** (`after`, `limit`, `hasMore` refer to what the caller may read). For a filtered
   caller the use case reads the whole match (VOID targets may lie before `after`) and filters in memory; staff keep
   the indexed `after` query. `lastServerSeq` stays the match's highest sequence number for every caller (it is on the
   match resource for every member already and says nothing about who scored).
5. **Clients of filtered callers take team figures from the server.** The feed no longer lets them rebuild the score.
   The web app (live match, not staff) shows `GET box-score`'s score, period scores and team totals, refreshed when the
   feed changes and every 15 s while the screen is open, plus the effect of the caller's events the snapshot does not
   contain yet (own unsynced events, visible events after its `lastServerSeq`), so a parent's own entry still counts at
   once offline. Offline before any box score, the cached match score is shown and period scores and totals are hidden.
   The court shows one player list (other players' substitutions are unknown) and numbers only for own/linked players.
   The offline sync protocol is unchanged: the client's cursor is the highest `serverSeq` it holds, it never assumed
   consecutive numbers, and only staff and parents post events (parents' events are about linked players, so they come
   back in their feed).

## Consequences
- F-01 is fixed. `MatchEventFeedRoleMatrixTest` (12 callers × feed and paging), `EventVisibilityTest`,
  `StatVisibilityTest`, `PlayerVisibilityTest`; web `team_figures_test`, `feed_visibility_test`, controller and widget
  tests for PARENT / PLAYER / staff.
- Game contract 2.1.0 documents the filtering (wire format unchanged); the authz matrix gains the feed row.
- A filtered caller's feed request costs a full read of the match's events (a few hundred rows). If that ever matters,
  push the player filter into SQL and resolve VOIDs with a join; the rule stays in `EventVisibility`.
- Events of hidden players that arrive after the last box-score snapshot reach a parent's score with the next refresh
  (≤ 15 s online). A VOID that arrives before its target (not produced by the app) may stay visible after the target
  turns out hidden; it carries no player.
- The dev mock API (`MockGameApi`) and the web test fakes mirror the rule (`feed_visibility.dart`).
