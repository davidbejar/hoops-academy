# Authorization matrix (oracle for role-matrix tests)

Roles are per tenant and additive (a user may hold several). "team staff" = COACH or ASSISTANT_COACH with a
`team_staff` row for the team in question. "linked" = PARENT with a `guardian_link` to the player.
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
| Read the match event feed (`GET /api/game/matches/{id}/events`, ADR-0028) | all events | all events | all events | team-level + linked players' events | team-level + own events |
| Training schedule / sessions / plans | write | write | write | read | read |
| Mark plan completion | yes | team | team | linked | self |
| Planned absence | yes | yes | yes | linked | self |
| Attendance (present / late / absent) | yes | yes | yes | – | – |
| Injuries | write | write | write | linked (write) | read (self) |
| Height / weight | write | write | write | linked (write) | read (self) |
| Physical test results | write | write | write | read | read (self) |
| Tenant lifecycle, usage statistics | `super_admin` (platform) only — cannot read tenant content | | | | |
| A tenant's administrators (list, add, edit names/e-mail, remove, new temporary password while PENDING) | `super_admin` (platform, `/platform/tenants/{id}/admins`) — identity of the admins only, ADR-0023, ADR-0024; tenant ADMINs manage them as members | | | | |

Feed row (ADR-0028): team-level events are `PERIOD_START`, `PERIOD_END`, `OPPONENT_SCORE`, `TIMEOUT` and a `NOTE` without a
player; substitutions and notes about a player are player events; a `VOID` is visible when the event it voids is. Staff of
another team read the feed like any other member (linked / own players only), as for the box score.
