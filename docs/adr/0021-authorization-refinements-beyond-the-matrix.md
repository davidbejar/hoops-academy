# ADR-0021: Authorization refinements beyond the authz matrix

- Status: Accepted (records decisions taken in WP4, WP6, WP7, WP8, WP9, WP10; F-01 decided on 2026-11-05: filtered feed, built in WP33)
- Date: 2026-11-02
- Related: `docs/domain/authz-matrix.md` (the oracle), ADR-0005, ADR-0014 §3–4

## Context
The matrix states capabilities per role but not every qualifier ("team staff" vs any staff, reads vs writes, what
happens after a match ends). The lanes had to decide these; the decisions are scattered over the handovers. This ADR
collects them so the matrix, the guides and the role-matrix tests can be read together.

## Decision
1. **Assistant coach is a separate tenant role** (`ASSISTANT_COACH`, SPEC left it open). Assistants of a team: run
   matches (create/start/finish, roster, clock, periods), enter stats for every player, void any event, training
   schedule/sessions/plans, attendance, planned absences, injuries, height/weight, physical tests. They may **not**
   request player add/withdraw, assign players or resolve eligibility cases (COACH of the team or ADMIN only), and they
   read eligibility checks/cases of their team. The web UI shows roster screens read-only for them.
2. **"Coach of the team"** = COACH role + a `team_staff` row for the team (any staff role on the row).
3. **Match visibility**: any tenant member may list and read matches, rosters and the event feed (WP6/WP7). Box scores
   and season stats are line-filtered: ADMIN/team staff all lines, PARENT linked players, PLAYER self. **Open (F-01):**
   the event feed is not filtered, so a parent or player can rebuild other players' lines; product decision pending.
4. **Event ingest by status** (ADR-0014 §3): SCHEDULED, LIVE and FINISHED accept events, CANCELLED rejects. After
   FINISHED staff may still correct anything; a PARENT event counts only if recorded before `finishedAt`. Parents may
   record SHOT, ASSIST, REBOUND, TURNOVER, STEAL, BLOCK, FOUL for linked players and VOID their own events; never clock,
   period, opponent, substitutions or roster. A parent who also holds COACH/ASSISTANT_COACH on the team has staff rights.
5. **Training data is tenant-readable for all staff**, writable by ADMIN or staff of the team (WP8/WP9); plans may be
   written by any COACH/ASSISTANT_COACH (plans are not team-bound). PARENT/PLAYER read only data of their players' teams.
6. **Health data is team-scoped** (WP10): staff read and write health data only of players on teams they staff; PARENT
   writes injuries and measurements of linked players and may delete measurements (not injuries); PLAYER reads self.
7. **Error shape**: not a member → 404; a member without the relation reading a single resource → 404; readable but not
   writable → 403; naming an unreadable player in a body or filter → 403.
8. **super_admin** manages tenants and reads usage counters only; without a membership it gets 404 on `/api/**` and
   cannot read tenant content (by design, PLAN §1.3). A super_admin who is also a member uses the tenant normally.
   Narrow exception (ADR-0023, WP22): through `/platform/tenants/{tenantId}/admins` the super admin lists, adds, edits
   and removes the tenant's administrators and sees their identity only (names, e-mail, invitation status, other role
   names) — never other members or academy data.

## Consequences
- Role-matrix tests encode these rules: `TeamPlayerResourceTest`, `EligibilityCaseResourceTest`, `MatchResourceTest`,
  `EventAuthorizationTest`, `MatchEventResourceTest`, `RoleMatrixTest`, `PlanRoleMatrixTest`, `HealthRoleMatrixTest`.
- The matrix document gains these qualifiers with WP33 (F-01 decided on 2026-11-05: team-level events for everyone, player events only for own or linked players).
- Training reads for all staff and health reads limited to own teams are intentionally different (health data of minors
  is more sensitive).
