# Authorization matrix (oracle for role-matrix tests)

Roles are per tenant and additive (a user may hold several). "team staff" = COACH or ASSISTANT_COACH with a
`team_staff` row for the team in question. "linked" = PARENT with a `guardian_link` to the player. Teams whose season
has ended (academy time zone) count neither as staffed nor as a player's team, even while the staff row or the
assignment is still open (`staffTeamIds` / `playerTeamIds`, core 2.8.0, WP58).
Non-members of a tenant receive **404** for every tenant resource.

| Capability | ADMIN | COACH (team staff) | ASSISTANT_COACH (team staff) | PARENT (linked) | PLAYER (self) |
|---|---|---|---|---|---|
| Tenant profile (name, logo, settings, categories, seasons) | write | read | read | read | read |
| Members, roles, guardian links | write | – | – | – | – |
| New temporary password for a PENDING member (`POST /api/core/members/{id}/temporary-password`, ADR-0024; not for a login also used in another academy) | yes | – | – | – | – |
| Add / withdraw player | direct | via approval request | – | – | – |
| Approve / reject requests | yes | – | – | – | – |
| Assign players to teams (eligibility-checked), resolve orphan cases | yes | own teams | – | – | – |
| Match create / start / finish, roster, clock & period events | yes | yes | yes | – | – |
| Enter player stat events | yes | all team | all team | linked players only | – |
| Void events | yes | any | any | own events only | – |
| View match stats | yes | yes | yes | linked | self |
| Read the match event feed (`GET /api/game/matches/{id}/events`, ADR-0030) | all events | all events | all events | team-level + linked players' events | team-level + own events |
| Training schedule / sessions / plans | write | write | write | read | read |
| Mark plan completion | yes | team | team | linked | self |
| Planned absence | yes | yes | yes | linked | self |
| Attendance (present / late / absent) | yes | yes | yes | – | – |
| Injuries | write | write | write | linked (write) | read (self) |
| Height / weight | write | write | write | linked (write) | read (self) |
| Physical test results | write | write | write | read | read (self) |
| Physical test types and norms (global ones read-only; tenant types: create, edit incl. `code`, delete while no result uses it) | write | read | read | read | read |
| Academy activity (audit trail, `GET /api/core/audit-events`, ADR-0029) — the super admin's actions show as "Platform administrator" (no subject, person or name; metadata such as a suspension `reason` intact; WP38) | read | – | – | – | – |
| Tenant lifecycle, usage statistics | `super_admin` (platform) only — cannot read tenant content | | | | |
| A tenant's administrators (list, add, edit names/e-mail, remove, new temporary password while PENDING) | `super_admin` (platform, `/platform/tenants/{id}/admins`) — identity of the admins only, ADR-0023, ADR-0024; tenant ADMINs manage them as members | | | | |
| Audit trail of every academy (`GET /platform/audit-events`, optionally one `tenantId`) | `super_admin` (platform) only — actions, ids and metadata; names of academies and of their active administrators only (ADR-0023, ADR-0029). A super_admin without membership calling `/api/core/audit-events` gets 404 like any non-member | | | | |
| Guardian logins: add a new guardian to a player (`POST /api/core/guardians`; with an e-mail a login, its temporary password shown once, or an existing login linked, ADR-0025) and give a guardian without a login a first one (`POST /api/core/members/{id}/temporary-password`, PARENT with an e-mail; WP58) | yes | – | – | – | – |
| Attach any academy plan or template to a session (no assignment needed, decision 53) and quick-add exercises to it (`POST /api/athlete/training-sessions/{id}/items`, ADR-0041: copies items of any readable plan or template into the session's own plan, created on first use) | yes | team | team | – | – |
| Quick-add exercises to a tenant plan (`POST /api/athlete/training-plans/{id}/items:copy`, ADR-0041; templates read-only) | yes | yes | yes | – | – |

Feed row (ADR-0030): team-level events are `PERIOD_START`, `PERIOD_END`, `OPPONENT_SCORE`, `TIMEOUT` and a `NOTE` without a
player; substitutions and notes about a player are player events; a `VOID` is visible when the event it voids is. Staff of
another team read the feed like any other member (linked / own players only), as for the box score.
