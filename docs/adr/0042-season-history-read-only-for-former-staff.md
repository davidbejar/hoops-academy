# ADR-0042: Past seasons are history: read-only for the team's former staff and admins, 409 `SEASON_ENDED` on writes

- Status: Accepted (WP80, core 3.2.0, game 2.3.0, athlete 2.4.0)
- Date: 2026-11-07
- Related: decision 62 of 2026-11-06, decision 40 / WP58 (ended seasons drop today's access), ADR-0037 (replica
  authz resolvers reproduce core's `/internal` rules), ADR-0021 (authorization refinements), ADR-0030 (event feed
  visibility), `docs/domain/authz-matrix.md`

## Context
Since WP58 a team whose season has ended (academy time zone) is neither a staffed team nor a player's team, even while
the `team_staff` row or the assignment stays open: coaches lose access to last season's team the day after it ends.
The owner wants that history back, read-only (decision 62): past seasons' teams, matches, attendance and health
records are readable by the coaches who were staff of the team then and by admins, never editable; players and
parents keep today's rules. Today's views must not change by default.

## Decision
1. **Historic team.** A team whose season's last day is before today in the academy's time zone (`Season.hasEnded`,
   the WP58 rule). A season whose dates an admin changes changes the answer at once; seasons stay editable (the admin's
   way to reopen one).
2. **Former staff = historic staff.** The persons with a `team_staff` row for a historic team (core keeps the row;
   WP58 only left it out of `staffTeamIds`) who still hold a team-staff role (COACH or ASSISTANT_COACH, the same role
   condition as `isStaffOf`). The authorization context carries them as a separate set, `historicStaffTeamIds`
   (core's `/internal/authz` `AuthzContext`, `/me`'s `AuthzSummary`, the Java `AuthzContext` with
   `wasStaffOf(teamId)`); `staffTeamIds` keeps its meaning, so every check that grants today's access is unchanged.
   Access to a past team's history ends with the staff role or the membership (a staff row of a historic team cannot
   be removed: rule 4).
3. **What history grants (read only).**
   - core: teams and rosters were already readable by every member; `GET /api/core/teams?staffedByMe=true&includeEnded=true`
     adds the caller's historic teams to the staffed list; `Team.seasonEnded` tells the UI which teams are history.
   - game: ADMIN and former staff see every player's statistics of the historic team's matches (box score, event
     feed), like the current staff; matches are readable by every member as before.
   - athlete: former staff see the whole attendance sheet of the historic team's sessions (other staff keep 403);
     they read the health records (injuries, height/weight, test results) of the players on the historic team's
     roster dated on or before the season's last day (the view they had when the season ended; anything later stays
     hidden, 404 as for any unrelated player). Sessions, schedules and plan assignments were already readable by every
     staff role.
   - A coach who was never staff of the team gets today's answers (health 404, attendance sheet 403).
4. **Writes on a historic team are refused with 409 `SEASON_ENDED`** (one Problem type, `code` = `SEASON_ENDED`,
   `common.problem.SeasonEndedException`) for everybody who could write it otherwise: ADMIN, the former staff (instead
   of 403) and, for match events, parents. 409 rather than 403: the caller is authorized, the state of the season is
   what forbids it, and the UI can say so. A caller with no write right at all keeps 403.
   - core: team PATCH, staff PUT and DELETE, assignment, renumbering and unassignment of a historic team; an
     eligibility case may still be resolved (DISMISSED / REMOVED_FROM_TEAM close an alert; REASSIGNED into a
     historic team is refused by the assignment). Seasons, rollover from a past season and the nightly jobs are not
     team writes.
   - game: creating a match for a historic team and every write on its matches (update, start, finish, cancel, roster).
     Match events are an offline-first sync: an event recorded on the device after the season's last day (academy
     zone) is rejected per event with `SEASON_ENDED` (new `MatchEventRejectionReason`); events recorded during the
     season still sync after it ended, so no device loses a match.
   - athlete: schedules, sessions (create, update, cancel, quick-add items), attendance, team plan assignments (create,
     withdraw) and completions of a team assignment; a health write by a coach whose only relation to the player is a
     historic team. Planned absences and player assignments are not bound to a team and keep their rules.
5. **How game and athlete know.** Current staff need no lookup (`staffTeamIds` holds only teams of seasons not
   ended) and former staff none either (`historicStaffTeamIds` holds only ended ones). For an ADMIN, a parent's event
   or anything else the season end comes from `RosterPort.teamRoster` (`TeamRoster.seasonEndDate`, a new field of
   core's internal `TeamRoster`; the replicas already store `season_end_date`). A team core does not know (404) or an
   answer without the field (an older core) counts as not ended: the other rules decide, as before.
6. **Replicas in step (ADR-0037).** Both replica resolvers compute `historicStaffTeamIds` like core's
   `MembershipLookup` (staff teams known with a season end before today in the academy zone); the contract tests that
   run on both sources gained the historic cases (game `AuthzContextContractTest`, athlete `MembershipContract`), and
   the roster port contracts check `seasonEndDate`.
7. **Lists.** `includeEnded` (boolean, default false) is the one list parameter, on core's `listTeams`; game's and
   athlete's lists already return past seasons' matches, sessions and assignments to every staff role, and the health
   lists reach a past season through `teamId` (records of that team's roster up to the season's end for its former
   staff). Default answers are unchanged everywhere.

## Consequences
- The web can offer a "past seasons" selector: core's teams with `includeEnded=true`, then the existing lists filtered
  by `teamId`; edit actions hide when `Team.seasonEnded` (or a 409 `SEASON_ENDED` arrives).
- An admin can no longer fix a typo in a past team's name or its roster; reopening the season (its end date) is the
  escape hatch, on purpose visible in the audit trail.
- One more cached core call for an ADMIN's (or a parent's event) write in `rest` mode; none in `replica` mode.

## Alternatives considered
- **403 for writes**: hides the reason; the brief allowed either; 409 says "authorized but closed".
- **Putting historic teams into `staffTeamIds`**: every existing write check would have needed a season test, and
  the WP58 meaning (today's access) would be lost.
- **A `seasonId` parameter on every list**: game and athlete do not know which teams belong to a season in `rest`
  mode without a new core endpoint; `teamId` already narrows every list.
- **Former staff read all health records of the player**: would show a coach who left the team the player's
  current injuries forever; the season's last day bounds it.
