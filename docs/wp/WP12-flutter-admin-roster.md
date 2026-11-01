# WP12 — Flutter: admin & roster, academy profile + logo, approvals inbox, orphan cases, invitations

Model: Sonnet. Depends on: WP11, WP3–WP5 contracts. Lane WEB. Skills: flutter-feature, test-driven-development.

## Scope (features/admin, features/roster)
- Academy profile: name, timezone, age rule, max play-up, default locale, **logo upload** (image picker, client-side
  size/type check, preview, PUT, cache-busting via ETag), logo shown in app bar/tenant switcher.
- Members: list/search, invite (email, roles), edit roles, deactivate; guardian links editor.
- Seasons (create, rollover wizard showing orphan list), age categories editor, teams (CRUD, gender policy, category),
  team staff, team roster (assign with eligibility check showing eligible teams only; play-up badge), players
  (list/filter by team/category/status, create → admin direct or coach request), approvals inbox (admin: approve/reject
  with note; coach: my requests + cancel), eligibility cases dashboard (open cases → reassign flow).
- Role-aware: coach sees own teams' actions only; assistant read-only here; parent/player do not see this module.

## Acceptance
- [x] widget tests per screen (loading/empty/error/populated/role variants); golden for teams list & player detail (360 px)
- [x] logo upload rejects > 512 KB / wrong type client-side with localized message; success updates header
- [x] all strings localized (es/en/id key parity test still green); `flutter analyze && flutter test` green

## Handover

### Built (`apps/web`, nothing committed)
- **Admin (`features/admin`)**: hub `/admin`; academy profile (name, timezone, age rule BIRTH_YEAR/BIRTHDAY, max play-up, default locale) with
  **logo section** (`file_selector` behind the `logoPickerProvider` seam; client checks by extension + magic bytes + <= 512 KB in
  `domain/logo_validation.dart`; preview; PUT of the raw bytes through the generated `putTenantLogo`; delete with confirmation; after any
  change `logoRevisionProvider` is bumped, `tenantLogoProvider` re-fetches with `Cache-Control: no-cache` (ETag revalidation) and
  `/me` + profile are invalidated, so the app-bar logo/name update); members (list + search, invite with roles multi-select, edit roles,
  deactivate, guardian links editor on a PARENT member: add player / remove link); seasons (list, create/edit with date pickers, rollover
  wizard: confirm with clone-staff/players flags -> result with cloned teams, orphans + reasons, opened cases, "go to eligibility cases");
  age categories editor (code, name, max age or no limit, order, delete).
- **Roster (`features/roster`)**: teams of the selected season (create/edit: name, alias, category, gender policy); team detail with staff
  (add coach/assistant from members, remove) and roster (jersey change, unassign, play-up badge, "no longer eligible" marker); **assign flow**
  = pick player -> `checkPlayerEligibility` verdict (eligible / play-up +n / ineligible with localized reasons, button disabled) -> assign
  with jersey; players list with filters (status incl. ORPHAN/PENDING_APPROVAL, team, category, search); player detail (basics, natural
  category, teams with play-up/invalid markers, guardians for ADMIN, assign via `eligible-teams`, withdraw); create player (ADMIN direct,
  COACH -> approval request with note + initial own team; message depends on `approvalRequest.status`); approvals inbox (admin: pending/all,
  approve with optional note, reject with required note; coach: "my requests" + cancel own pending); eligibility cases dashboard
  (reason, player, invalidated team; reassign from eligible teams, remove from team, dismiss).
- **Role-awareness**: `core/session/capabilities.dart` (mirror of the authz matrix; `staffTeamIds`/`personId` now come from `/me`
  memberships) drives buttons; `redirectFor` now accepts sub-routes of an allowed destination (`/teams/:id`, `/admin/members`...) and
  still bounces other roles; `Guarded` shows the localized "not allowed" state for per-route checks (assistant on `/players/requests` or
  `/players/new`). ADMIN full; COACH only own teams' roster actions + player request + my requests; ASSISTANT read-only; PARENT/PLAYER
  cannot reach any of it (destination guard).
- **Layering**: `data/` repositories (interface + `Api*` over the generated clients, tenant id injected), `application/` Riverpod
  `AsyncNotifier`s (family notifiers for team detail, player detail, guardian links), `presentation/`. Mutations throw, screens call
  `runAction` which shows a localized snackbar (never server text). Repositories return the generated built_value models directly
  (see Decisions).
- **Routing/deferred loading**: `FeatureModule.subPages` (`ModulePage`) lets every sub-screen keep its own `deferred as` import; the router
  builds nested `GoRoute`s from it. Old placeholders in `features/teams` and `features/players` were removed.
- **i18n**: 205 new keys in es/en/id (real Indonesian), `flutter gen-l10n` output committed; parity test green.
- **Mock mode** (`--dart-define=HOOPS_MOCK_API=true`): `lib/core/mock/mock_core_api.dart` serves the whole admin/roster surface in memory
  (eligibility with play-up and gender policy, approvals, rollover with orphans + cases, logo upload/delete with ETag, role switch via
  `HOOPS_MOCK_ROLES`). README updated (routes, shared widgets, mock roles).

### Verified (fresh, 2026-11-02)
- `flutter analyze` -> `No issues found!`
- `flutter test` -> `+195: All tests passed!` (was 64 in WP11; +131). New by file: logo_validation 5, academy_profile 9 (loading, error+retry,
  populated, validation, logo happy path incl. app-bar re-fetch with revalidation, > 512 KB, wrong type, English message, remove),
  api_repositories 5 (**PUT carries the exact bytes**, tenant header, assign/reject/season JSON), members 12, seasons+rollover+categories
  12, teams 20 (list loading/error/empty/no-season/populated/role variants, create, detail per role, staff, unassign/jersey, assignment
  verdicts eligible/play-up/ineligible-disabled), players 23 (list states, filters, role variants, detail, withdraw, create admin/coach,
  422), approvals+cases 17 (approve/reject-needs-note/cancel, coach vs admin, guards, reassign/remove/dismiss, coach own teams only),
  notifiers 12, capabilities 4, redirect sub-routes 3, mock_core_api 7 (real repositories + generated deserialisers against the mock),
  mock-mode whole-stack test extended (teams from the mock), goldens +2.
- Goldens committed: `test/golden/goldens/teams_list_360x780.png`, `player_detail_360x780.png` (home goldens regenerated because ADMIN home is now the
  hub instead of the placeholder).
- `flutter build web --pwa-strategy=offline-first` -> `Built build/web` (54 `*.part.js` deferred chunks).
- TDD: logo validation and the redirect/capabilities units were written red first; the remaining screens were written together with their
  tests in the same step (tests found real bugs: dropdown overflow at 360 px, invite-role validation never shown, deferred sub-libraries
  not preloaded in the harness).

### Acceptance checklist
| Item | Evidence |
|---|---|
| widget tests per screen (loading/empty/error/populated/role variants); golden teams list & player detail (360 px) | the files above; goldens `teams_list_360x780.png`, `player_detail_360x780.png` |
| logo upload rejects > 512 KB / wrong type client-side, localized; success updates header | `academy_profile_test.dart` (es + en message, no API call on rejection, upload happy path, `tenant.logoFetches.last == true` = revalidated re-fetch), `logo_validation_test.dart`, `api_repositories_test.dart` (PUT body bytes) |
| all strings localized, parity green; analyze && test green | `l10n_keys_test.dart` +3; analyze clean; test +195 |

### Decisions
- **Repositories expose the generated built_value models** (no second domain model layer) to keep WP12's ~30 operations small; the
  generated types are the contract and immutable. Creation of `SeasonInput`/`AgeCategoryInput` (non-instantiable interfaces) is hidden
  behind primitive-argument repository methods (`$SeasonInput` internally). `core/api/api.dart` re-exports the package (hiding its `Locale`,
  alias `ApiLocale`) plus `Date`, which the package does not export.
- Sub-routes are flat `go` navigation with an explicit back arrow (`SubPage(parentPath)`), not a push stack (shell bottom nav stays valid).
- Coach "own team" = `/me` `authz.staffTeamIds`; "own request" = `requestedBy.personId == membership.personId`. Server remains the authority.
- The assign dialog fetches players with the plain players list and filters ACTIVE/ORPHAN not on the roster client-side; eligibility is
  asked per selected player (`GET /teams/{t}/players/{p}/eligibility`), not for the whole list.
- Dropdown/forms are dialogs (`FormDialog`) except player creation (full page). `FormDialog.validateExtra` carries non-field validation.
- Cache busting = revision counter + `Cache-Control: no-cache` on the next GET, not a changing URL (the generated client has no query param).

### How WP13 / WP14 coexist
- Add their screens as `ModulePage`s of the Matches / Training modules; reuse `Capabilities` (add `canScoreMatch`, ... there, one place),
  `AsyncBody` (loading/error/empty/data), `runAction` + `confirmDialog` + `noteDialog`, `FormDialog`, `SubPage`/`InfoChip`/`Guarded`,
  `labels.dart` enum labels, `EligibilityBadge`/`PlayUpBadge` (roster chips for match rosters), and `activeSeasonProvider`/`teamsProvider`
  for team pickers.
- Test support to reuse: `Harness(core: FakeCore(...))`, `pumpAs(...)` (role + location), `tapKey`/`enter`, `core_fixtures.dart` builders,
  `Faulty` fakes (`hang`, `failWith`). Add their repositories to `Harness` the same way (overrides in `harness.dart`).
- Mock mode: extend `MockCoreApi` pattern with a game/athlete mock the same way; adapter routes `/api/core/*` only.
- `harness.dart` preloads `subPages` libraries too; new `ModulePage`s are picked up automatically.

### Open points / contract gaps
- **Contract: `putTenantLogo`** generated method always sends `Content-Type: image/png`; JPEG/WebP bytes are sent with that header (the server
  detects the real type from magic bytes per ADR-0009, so it works, but the contract should list `contentType` per body or the generator
  template should honour it). Characterised in `api_repositories_test.dart`.
- **Contract: `GET /players` has no category filter** (client-side filter on the fetched page); **no pagination UI**: every list reads the first
  page (size 100). `EligibilityCase.team` carries no season, so the reassign dialog uses the season currently selected on the Teams screen.
- No contract operation for deleting/archiving a team, re-activating a member, or editing a member's personal data (`updateMember` exists,
  no UI: roles + deactivate only); guardian links are only editable from the parent's member page (player detail lists them for ADMIN).
- Assistant coach can open `/players/:id` and team pages (read-only) but the server decides what data they get (guardians are not requested).
- Not verified in a real browser: the actual `file_selector` web dialog (covered through the picker seam), the mock-mode click-through in
  Chrome (build compiles; whole-stack widget test uses the mock), and the real backend (core-service absent).
- **Incident**: I ran `git rm --cached` on the two removed placeholder files (`features/teams/.../teams_screen.dart`,
  `features/players/.../players_screen.dart`) before noticing "no git commands"; I immediately restored the index with `git reset -- <those
  two paths>`, so the index is as before and the files are simply deleted in the working tree (unstaged).
- `dart format` was applied to `lib/core` and `lib/features/roster` (some WP11 core files may show whitespace-only diffs).
