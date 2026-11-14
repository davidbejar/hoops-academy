# ADR-0048: Exports: one CSV spec for server and browser, the roster and the audit trails built by core; preferred jersey numbers

- Status: Accepted (WP96, core 3.5.0); amended 2026-11-14 (decision 83, WP106, core 3.6.0: the roster export is for
  the team's current staff only)
- Date: 2026-11-10
- Records: decisions 67, 68 and 69 of 2026-11-10 (`docs/wp/FOLLOW-UPS.md`, sixth round); decision 70 for the jersey
  numbers of the same contract version
- Related: ADR-0017 / ADR-0029 (audit trail, actor masking), ADR-0033 (gateway rate limits), ADR-0042 (season
  history), ADR-0032 (`clear` lists), WP97 and WP101 (browser-built exports and the buttons),
  `libs/contracts/openapi/core.yaml`, `services/core-service/src/main/java/com/hoopsacademy/core/adapters/in/export`

## Context
Nothing could be exported. The owner asked for the audit log, the team roster with its coach and parents, player
statistics, a match box score and the team calendar (decision 67: CSV for everything, ICS for the calendar, a real
`.xlsx` for the browser-built ones, PDF later). Decision 68 splits them: the roster with guardians and the audit log
hold personal data or the record of who did what, so core builds, limits and audits them; statistics, box score and
calendar are built by the web from the JSON it already has (WP97). Both sides must produce the same kind of file, so
the format is specified once, here.

## Decision
### The export spec (shared by WP96, WP97 and WP101)
- **CSV**: UTF-8 with BOM, `,` separator, RFC 4180 quoting (a field holding `,`, `"`, CR or LF is quoted, a quote is
  doubled), CRLF line ends, one header row. Media type `text/csv; charset=utf-8`.
- **Formula-injection guard** (CSV and XLSX text cells): a text value starting with `=`, `+`, `-`, `@`, TAB or CR gets
  a leading `'`. Numbers written as numbers are exempt (a negative score stays `-3` only in a numeric column). The
  guard runs before quoting, so a guarded value that holds a separator is quoted with its `'`.
- **Language**: header labels in the user's language (es / en / id). Server: `Accept-Language`, negotiated like the
  athlete templates (quality order, header order on ties, `q=0` refused, `in` read as Indonesian, else English). Web:
  the app locale. Values are not translated, except enum labels (role, gender, eligibility, audit action, actor kind,
  target type), whose texts follow the web's ARB labels.
- **Dates and times**: ISO `yyyy-MM-dd` and `HH:mm` in the academy's time zone, in separate columns; the zone id in its
  own column wherever a time is present. XLSX uses typed date cells.
- **File name**: `hoops-<academy-slug>-<what>-<yyyyMMdd>.<ext>`, ASCII only. Each part is reduced to lower-case ASCII
  words joined by `-` (accents dropped, anything else a separator, at most 40 characters, an empty part left out). The
  day is today in the academy's time zone (UTC for an export of every academy, slug `platform`). Server:
  `Content-Disposition: attachment; filename="…"`; web: the download attribute.
- **ICS** (team calendar, WP97): RFC 5545 as the brief specifies (stable `UID` `<kind>-<id>@hoops-academy`, `TZID` plus
  `VTIMEZONE` or UTC times, escaped text, lines folded at 75 octets). WP97 records which time form it chose in its
  handover.
- **XLSX**: browser-built exports only, the library behind a deferred import, never in the main bundle or the service
  worker precache; when it cannot be fetched the user is told and CSV still works.
- **Limits**: one file, no paging. The server refuses more than **10,000 rows** with 422 `EXPORT_TOO_LARGE` and a detail
  that asks for a narrower filter. Responses carry `Cache-Control: no-store`.

### The server-built exports (core 3.5.0)
- **One `:export` operation per export**, not content negotiation on the JSON reads:
  `GET /api/core/teams/{teamId}/roster:export`, `GET /api/core/audit-events:export`,
  `GET /platform/audit-events:export`. Each declares only `text/csv` (`CsvFile`: `string`, `binary`), so the generated
  Dart client returns `Response<Uint8List>` with `ResponseType.bytes` (checked with a scratch generation: the BOM
  survives), and the JSON operations keep their typed models. Colon paths follow the contract's custom-method
  convention (`:batch`, `:copy`, `:accept`).
- **Roster** (`exportTeamRoster`): one file, one header row. One row per player of the team's open assignments (valid
  or invalidated): role, given and family name, birth date, gender, the natural age category in the team's season, the
  eligibility of the assignment as stored (ELIGIBLE, PLAY_UP when it plays up, INELIGIBLE once invalidated) and its
  play-up levels (a number), jersey number, joining day, e-mail, phone, then each **active** guardian (given name,
  family name, e-mail, phone) in repeated column groups `Guardian 1 …`, `Guardian 2 …`: as many groups as the player
  with the most guardians, at least one, so the header is stable for a team without guardians. Players are ordered by
  family then given name. **The staff is a second block of the same file**, not a second file: rows of the same
  columns with the role COACH / ASSISTANT_COACH, the names, e-mail, phone and the staff entry's `since` in the joining
  column; the player columns stay empty. One download keeps the button simple and the spec's "one header row" holds; a
  spreadsheet filter on the role column separates the blocks. Authz: ADMIN, or a COACH who is staff of the team, or
  was staff of a team of an ended season (its history, ADR-0042); ASSISTANT_COACH, PARENT and PLAYER 403; non-members
  404. *Amended 2026-11-14 (decision 83, WP106): a former coach no longer exports; see the amendment below.*
- **Audit trails** (`exportAuditEvents`, ADMIN; `exportPlatformAuditEvents`, super_admin): the rows the JSON list
  returns for the same `from`, `to`, `action` (and `tenantId`), with the same names and the same actor masking
  (ADR-0029: on the academy path a PLATFORM actor has no login, person or name). Columns: date, time and zone, action
  label and code (the code is the stable identifier used by the filter and `docs/domain/audit-events.md`), actor kind,
  name, person id and login, target type, id and name, and the metadata as sorted `key=value` pairs (easier to read in
  a spreadsheet than JSON; metadata never holds personal data). The platform file starts with the academy's name and
  id, and each row's date and time are in its own academy's zone.
- **Where it is built**: the use cases (`application.export`) gather the rows and write the audit row; the CSV is
  rendered in the inbound adapter (`adapters.in.export`: `CsvDocument`, `ExportLabels` with
  `i18n/export_<lang>.properties`, `ExportLanguage`, `ExportFileName`, `RosterCsv`, `AuditCsv`), all pure and in the
  mutation scope. The audit lists are read page by page through the existing read use cases (`ExportPages`): the
  first page's total is checked against the limit before anything else is read; pages follow until a short one; a
  row read twice because a newer row pushed it onto the next page is kept once. No new SQL.
- **Audit rows**: `team.roster_exported` (new target type `team`, metadata `rows`) and `audit.exported` (target the
  academy, metadata `rows` and the filter as given: `from`, `to`, `actions`). Never names, e-mails or the file. The
  academy export writes its row after reading, so a file never contains its own export. The platform export records
  `audit.exported` in the trail of the academy given as `tenantId`, or of each academy with rows in the file (its own
  row count), with the super admin as actor (masked for the academy, as every platform action). A refused export
  (403, 404, 422) writes nothing.
- **Never logged**: the services log no request or response bodies; the file content and the guardians' contact data
  appear in no log line (`TeamRosterExportTest.theContentIsNeverLogged`).
- **Rate limits** at the gateway (ADR-0033), added by WP100: each export path per client IP, see the WP96 handover.

### Jersey numbers of the same version (decision 70)
- **Preferred number** `core.player.preferred_jersey_number` (V19; nullable; the pattern of the assignment's number,
  "0" ≠ "00"; not unique): `Player.preferredJerseyNumber`, written with `PATCH /api/core/players/{id}`
  (`UpdatePlayerRequest`, `clear: [preferredJerseyNumber]`). ADMIN and COACH write it for any player they read (staff
  read every player); a PARENT for a linked player and a PLAYER for themselves write it as a wish; an ASSISTANT_COACH
  gets 403; a caller who cannot read the player gets 404. Not audited (a wish, not an administrative change) and not
  published: `core.player.changed` does not carry it and no consumer needs it, so the event schemas stay as they are.
- **Carry-over** on `POST /api/core/teams/{teamId}/players` without a number (`JerseyCarryOver`, domain, in the
  mutation scope): the preferred number when no open assignment of the team holds it, else the number of the player's
  most recent assignment that had one (latest joining day; on the same day an open one, then the later leaving day),
  when free, else none. A number is never taken from another open assignment; an explicit number that clashes stays
  409 `JERSEY_NUMBER_TAKEN`. `AssignedTeamPlayer.jerseySource` (`REQUESTED` / `PREFERRED` / `PREVIOUS` / `NONE`) says
  which rule applied. The approval of a player with a team and the REASSIGNED case resolution use the same command, so
  a reassigned player keeps their number when it is free. Two concurrent assignments that pick the same free number
  meet the partial unique index: the second answers 409 `TEAM_PLAYER_CONFLICT` and can be retried.
- **Taken numbers**: `GET /api/core/teams/{teamId}/jersey-numbers` (any member, as the roster) lists the numbers of the
  open assignments with their player, by value and then length ("0", "00", "7", "07").
- **Season rollover** already copies each assignment with its number, an invalidated copy included
  (`RolloverResourceTest.theCopiedAssignmentsKeepTheirNumbersEligibleOrNot`).

## Alternatives rejected
- **Content negotiation** (`Accept: text/csv` on `listAuditEvents`): one operation with two response types makes the
  generated Dart method return a JSON model for a CSV body, and paging parameters that an export ignores.
- **Building the roster and the audit exports in the browser**: no audit row, no server-side limit, and the roster
  needs the guardians' contact data that no JSON read gives a coach.
- **A second file (or a ZIP) for the staff**: two downloads or an archive for a dozen rows; the second block keeps one
  header row.
- **One row per player and guardian** ("long" format): repeats the player's data and makes "one row per player" false.
- **Translating values** (category names, metadata): they are the academy's own texts or identifiers.

## Consequences
- Contract core 3.5.0 (minor): three operations, the `Accept-Language` parameter, `CsvFile`, two audit actions and the
  `team` target type (new values of response enums, minor by the precedent of ADR-0029: the web maps unknown actions to a
  fallback label until WP101 adds theirs).
- A spreadsheet that opens a jersey "07" may show 7 unless the column is imported as text; the CSV keeps the digits.
- A COACH with both staff roles on different teams is treated like the rest of the roster rules (the staff entry's
  role is not checked, only the tenant role and the staff row).

## Amendment 2026-11-14 (decision 83, WP106): the roster export is for the team's current staff only

The roster file carries the guardians' e-mail addresses and phone numbers, which no JSON read gives a coach. Since
core 3.6.0 `exportTeamRoster` is allowed to **ADMIN** (any team, a team of an ended season included) and to a **COACH
who is current staff of the team** (`staffTeamIds`, the team's season not ended). A former coach of an ended season
(`historicStaffTeamIds`, ADR-0042) keeps every read-only screen of that history but gets **403** from the export, as a
coach of another team does; the refusal is a fine-grained authorization denial and so a security event (ADR-0043,
`security.kind` = `fine_grained`) and writes no audit row. ASSISTANT_COACH, PARENT and PLAYER stay 403 (tenant role),
non-members 404. The authz matrix row and `TeamRosterExportTest.roleMatrix` say the same. The web hides the button
for a team the caller is not current staff of (WP108).

Rejected: keeping the history export (the contact data of families a coach no longer works with outlive the reason
to hold them), and answering 404 to the former coach (they are a member who reads the team; 404 is for non-members,
rule 3 of `CLAUDE.md`).
