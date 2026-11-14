# Authorization matrix (oracle for role-matrix tests)

Roles are per tenant and additive (a user may hold several). "team staff" = COACH or ASSISTANT_COACH with a
`team_staff` row for the team in question. "linked" = PARENT with a `guardian_link` to the player. Teams whose season
has ended (academy time zone) count neither as staffed nor as a player's team, even while the staff row or the
assignment is still open (`staffTeamIds` / `playerTeamIds`, core 2.8.0, WP58). Such a team is **history** (ADR-0042,
WP80): "former staff" = COACH or ASSISTANT_COACH whose `team_staff` row for it remains (`historicStaffTeamIds`, core
3.2.0); they and ADMIN read it, nobody writes it (409 `SEASON_ENDED`); see the history rows at the end.
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
| Roster events backfill (`POST /platform/events/backfill`, WP81): one `.changed` per aggregate without an event, in every academy | `super_admin` (platform) only — writes the outbox, returns counts, never tenant content | | | | |
| Guardian logins: add a new guardian to a player (`POST /api/core/guardians`; with an e-mail a login, its temporary password shown once, or an existing login linked, ADR-0025) and give a guardian without a login a first one (`POST /api/core/members/{id}/temporary-password`, PARENT with an e-mail; WP58) | yes | – | – | – | – |
| Attach any academy plan or template to a session (no assignment needed, decision 53) and quick-add exercises to it (`POST /api/athlete/training-sessions/{id}/items`, ADR-0041: copies items of any readable plan or template into the session's own plan, created on first use) | yes | team | team | – | – |
| Quick-add exercises to a tenant plan (`POST /api/athlete/training-plans/{id}/items:copy`, ADR-0041; templates read-only) | yes | yes | yes | – | – |
| History: a team of an ended season, its roster and staff (`GET /api/core/teams?staffedByMe=true&includeEnded=true`, `Team.seasonEnded`; ADR-0042) | read | read (former staff; any member reads teams) | read (former staff) | read | read |
| History: write a team of an ended season or its matches, schedules, sessions, attendance, team plan assignments and their completions (team PATCH, staff, assignments; match create / update / start / finish / cancel / roster; athlete writes) | 409 `SEASON_ENDED` | 409 `SEASON_ENDED` (former staff; 403 if never staff) | 409 `SEASON_ENDED` (former staff) | 409 on completions of a team assignment | 409 on completions of a team assignment |
| History: match events of an ended season (`events:batch`): recorded on the device up to the season's last day still sync; later ones REJECTED `SEASON_ENDED` | as staff | as staff (former staff too) | as staff (former staff too) | linked players, same cut-off | – |
| History: statistics of a past match (box score, event feed) | all players | all players (former staff) | all players (former staff) | linked | self |
| History: attendance sheet of a past session | whole sheet | whole sheet (former staff; other coaches 403) | whole sheet (former staff) | linked | self |
| History: health records (injuries, height / weight, test results) of the players on a past team's roster, dated on or before the season's last day (also `teamId` = that team on the lists) | write (today's rule) | read (former staff; never staffed: 404); writes 409 `SEASON_ENDED` when the past team is the only relation | read (former staff), same | today's rule | today's rule |
| Request a new academy (`POST /platform/academy-requests`, the landing form; WP90, ADR-0044) | anonymous — anyone, no sign-in (players are not offered the role); 202 whatever happened, rate-limited per IP at the gateway | | | | |
| Academy requests: list, accept (creates the academy, the requester its first ADMIN, temporary password once), reject with a reason (e-mailed) (`/platform/academy-requests`, `…/{id}:accept`, `…/{id}:reject`) | `super_admin` (platform) only; anyone else 401 / 403 | | | | |
| Exercise catalogue: list, search and read exercises (`GET /api/athlete/exercises`, `…/{id}`; global ones in the caller's language, archived ones by id or with `includeArchived`; WP92, ADR-0047) | yes | yes | yes | yes | yes |
| Exercise catalogue: create, edit, archive and unarchive the academy's own exercises (`POST /api/athlete/exercises`, `PATCH …/{id}`, `…:archive`, `…:unarchive`; global exercises read-only for everyone, 403 `EXERCISE_IS_GLOBAL`; another academy's 404; ADR-0047) | yes | yes | yes | – | – |
| Add catalogue exercises to a tenant plan or a session (the `exerciseId` source of `…/items:copy` and `POST /api/athlete/training-sessions/{id}/items`; the item copies the text and keeps the reference; archived 422 `EXERCISE_ARCHIVED`; ADR-0047) | yes | plan: yes; session: team | plan: yes; session: team | – | – |
| Users of the application (`GET /platform/users`, WP91, decision 71): every login with its person in each academy (name, roles, active flag, academy name / slug / status), read-only | `super_admin` (platform) only, through core_platform (V18, ADR-0029 amendment); every tenant role 403, anonymous 401 | | | | |
| Own first and last name in one academy (`PATCH /api/core/me` with `givenName` / `familyName` and `tenantId`, WP91, decision 73): the caller's own person only, never the e-mail (400); no active membership of an ACTIVE academy there: 404 | self | self | self | self | self |
| Preferred jersey number of a player (`PATCH /api/core/players/{id}`, `preferredJerseyNumber`, clearable; WP96, decision 70, ADR-0048): a wish, staff decide the number of each assignment; read by everyone who reads the player | write | write (any player they read) | – (403) | write (linked; a wish) | write (self; a wish) |
| Jersey numbers taken on a team (`GET /api/core/teams/{id}/jersey-numbers`, WP96); an assignment without a number carries the preferred or the previous number over when free (`jerseySource`, under "Assign players") | read | read | read | read | read |
| Export the team roster with guardians and staff as CSV (`GET /api/core/teams/{id}/roster:export`, WP96, ADR-0048; audited `team.roster_exported`, rate-limited; current staff only since WP106, decision 83) | yes (teams of ended seasons too) | own teams as current staff only (a former coach of an ended season: 403, a fine-grained security event; another team: 403) | – (403) | – (403) | – (403) |
| Export the academy's audit trail as CSV (`GET /api/core/audit-events:export`, WP96, ADR-0048): the list's filters and masking; audited `audit.exported`, rate-limited | yes | – | – | – | – |
| Export the audit trail of every academy, or of one, as CSV (`GET /platform/audit-events:export`, WP96, ADR-0048) | `super_admin` (platform) only; recorded as `audit.exported` in each exported academy's trail; tenant roles 403, anonymous 401 | | | | |

Feed row (ADR-0030): team-level events are `PERIOD_START`, `PERIOD_END`, `OPPONENT_SCORE`, `TIMEOUT` and a `NOTE` without a
player; substitutions and notes about a player are player events; a `VOID` is visible when the event it voids is. Staff of
another team read the feed like any other member (linked / own players only), as for the box score.
