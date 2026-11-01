# WP4 — core-service: seasons, categories, teams, eligibility engine, orphan job, rollover

Model: Opus. Depends on: WP3. Lane CORE. ADR: 0010. Plan §2 "Roster & eligibility". Skills: test-driven-development,
quarkus-hexagonal-service, tenant-isolation-testing; property tests with jqwik.

## Scope
- Flyway V5+: `season` (exclusion constraint on daterange per tenant; reference_year), `age_category` (code, name,
  max_age nullable, sort_rank; unique per tenant), `team` (season, name, alias, age_category, gender_policy, status),
  `team_player` (jersey_number, joined_at, left_at, play_up_levels, invalidated_at, invalid_reason; partial unique
  (team_id, player_id) where left_at is null), `team_staff` (team, person, role COACH|ASSISTANT_COACH),
  `eligibility_case` (player, team_player, reason, status OPEN|RESOLVED, resolved_by, resolution, created_at).
- Default categories seeded on tenant creation: U8(7), U10(9), U12(11), U14(13), U16(15), U18(17), SENIOR(null).
- Pure package `com.hoopsacademy.core.domain.eligibility`: `AgeFunction` (BIRTH_YEAR: reference_year − birth year;
  BIRTHDAY: full years at asOf in tenant tz), `CategoryLadder`, `EligibilityEvaluator.evaluate(player, team, asOf,
  settings) → Eligible | PlayUp(levels) | Ineligible(reason)`, `PlayerStatusDerivation`.
- Use cases: seasons CRUD + `RolloverSeason` (creates next season, clones teams (status ACTIVE) without players,
  re-evaluates every open assignment of the previous season's teams against the cloned teams? NO — clones teams and
  returns, for every player, their natural category in the new season and whether their previous team's category is
  still eligible; marks players with no eligible cloned team as ORPHAN and opens cases), categories CRUD (admin),
  teams CRUD (admin), team staff (admin), `AssignPlayerToTeam` (eligibility-checked; staff for own teams, admin any),
  `UnassignPlayer`, `CheckEligibility` query (UI uses it to list eligible teams), eligibility cases list/resolve,
  `NightlyEligibilityJob` (Quarkus Scheduler, iterates tenants via platform datasource, `TenantScope.runAs`, tenant tz).
- `/internal/authz` now fills `staffTeamIds`; `/internal/teams/{id}/roster` and `/internal/players:batch` implemented.

## Acceptance
- [x] jqwik properties: never assign to lower category; gender policy respected; play-up limit enforced when set; status derivation idempotent
- [x] examples: Dec-31/Jan-1 boundaries for both rules; Feb-29 birthdays; MIXED teams; coach-only vs admin permissions
- [x] nightly job over two tenants proves isolation (cases only in the right tenant); BIRTHDAY tenant flags the day after birthday
- [x] rollover returns the orphan list and opens cases; assignment UI query lists only eligible teams
- [x] RLS suites + role-matrix + cross-tenant 404 for all new resources; verify green, coverage ≥ 80 % (domain ≥ 90 %)

(Evidence per item in the Handover table below.)

## Handover

### Built
All in `services/core-service` (plus ADR-0015). Decisions: see "Decisions" below and ADR-0015.
- **Flyway `V5__roster.sql`** (as `core_migrator`, every table via `app.enable_tenant_rls`): `season` (+ trigger
  `season_no_overlap`, see decisions), `age_category` (unique code and rank per tenant), `team` (unique
  `(tenant, season, name)`, composite FKs to season/category), `team_staff` (pk team+person, role
  COACH|ASSISTANT_COACH, `since`), `team_player` (`joined_on`/`left_on` dates, `play_up_levels`, `invalidated_at` +
  `invalid_reason` both-or-neither; partial unique `(team_id, player_id) where left_on is null` and
  `(team_id, jersey_number) where left_on is null`), `eligibility_case` (OPEN|RESOLVED, resolution, note,
  `resolved_by_person_id` FK; partial unique one OPEN case per assignment). `core.player` needed no change (status
  already allows ORPHAN; birth date/gender live on `person`).
- **Domain** (pure, 100 % lines): `domain.eligibility` — `AgeFunction` (BIRTH_YEAR, BIRTHDAY), `CategoryLadder`
  (rank order, natural category, ladder steps, order invariant → 422 `AGE_CATEGORY_ORDER`), `EligibilityEvaluator`
  → `Evaluation(Eligibility, age, naturalCategory)` with sealed `Eligibility` = `Eligible | PlayUp(levels) |
  Ineligible(reasons)` (contract enum names, all failing reasons reported, first = primary), `EligibilityCandidate`,
  `PlayerStatusDerivation`, `EligibilityCase` (+ `CaseStatus`, `CaseResolution`); `domain.roster` — `Season`,
  `AgeCategory`, `DefaultAgeCategories`, `Team`, `GenderPolicy`, `StaffRole`, `TeamStaffMember`, `TeamPlayer`,
  `JerseyNumber`, ids and `*Changes`; `domain.shared.TenantCalendar` (today in the tenant zone).
- **Application `application.roster`**: `SeasonService`, `RolloverSeason`, `AgeCategoryService`, `TeamService`,
  `TeamStaffService`, `AssignPlayerToTeam` (the checked command), `TeamPlayerService` (list, jersey, unassign),
  `EligibilityQueries` (check, eligible teams), `EligibilityCaseService` (list/get/resolve), `EligibilityEngine`
  (re-evaluation, invalidation + case), `PlayerStatusSync`, `EligibilitySweep`, `InternalRoster`, `RosterAuthz`,
  `TenantToday`, `TeamViews`. WP3 hooks filled: `StaffTeams` (StaffTeamsQuery; WP3's `NoStaffTeamsYet` default
  removed), `DefaultCategoriesOnOnboarding` (TenantProvisioningHook: U8=7 … U18=17, SENIOR=null),
  `ReevaluateOnRuleChange` (TenantSettingsListener), `RosterUsageCounter` (`seasons`, `teams`). New ports:
  `SeasonRepository`, `AgeCategoryRepository`, `TeamRepository`, `TeamStaffRepository`, `TeamPlayerRepository`,
  `EligibilityCaseRepository`; `PlayerRepository` gained `summary/summaries` (name, status, birth date, gender) and
  `updateStatus`.
- **Adapters**: REST `SeasonResource` (+ `POST /seasons/{id}/rollover`), `AgeCategoryResource`, `TeamResource`
  (teams + staff), `TeamPlayerResource` (assign / PATCH jersey / DELETE / `…/eligibility`), `EligibleTeamsResource`
  (`GET /players/{id}/eligible-teams` only — the rest of `/players` is WP5), `EligibilityCaseResource`;
  `in/internal/InternalRosterResource` (`/internal/teams/{teamId}/roster?tenantId=`, `/internal/players:batch?tenantId=`,
  role `service`); `in/scheduler/NightlyEligibilityJob` (`@Scheduled(cron = "{hoops.core.eligibility-cron}")`);
  JPA entities/repositories in `out/persistence` (JPQL only; unique/exclusion violations flushed into 409 by
  `ConstraintConflicts`). `MergePatch` gained `matching(...)` and `integer(...)`; `Params.date` for query dates.
- Config: `hoops.core.eligibility-cron=${CORE_ELIGIBILITY_CRON:0 15 * * * ?}` (`%test`: `off`); module pom adds
  `quarkus-scheduler` and test-scoped `jqwik` (version from the parent). README updated.
- Tests (red first; domain and REST suites were seen failing — compile errors / 404s — before the code existed):
  domain `AgeFunctionTest`, `CategoryLadderTest`, `EligibilityEvaluatorTest`, `EligibilityPropertiesTest` (jqwik, 4
  properties × 1000 tries), `PlayerStatusDerivationTest`, `EligibilityCaseTest`, `SeasonTest`, `AgeCategoryTest`,
  `TeamTest`, `TeamPlayerTest`, `TeamStaffMemberTest`, `TenantCalendarTest`; DB `RosterSchemaTest`,
  `CoreRlsIsolationTest` fixtures for the 6 new tables; REST `SeasonResourceTest`, `AgeCategoryResourceTest`,
  `TeamResourceTest`, `TeamPlayerResourceTest`, `EligibilityCaseResourceTest`, `RolloverResourceTest`,
  `ReevaluationTriggersTest`, `InternalRosterResourceTest`; job `NightlyEligibilityJobTest`; additions to
  `PlatformTenantResourceTest` (seeded ladder) and `MeResourceTest` (staffTeamIds). Test support: `RosterDb`,
  `Members.signInAs/callerPersonId`, `Contract` now flattens `allOf` (`withResolveCombinators(true)`).

### How verified (fresh, 2026-11-02)
`source scripts/env.sh && ./mvnw -pl services/core-service clean verify` → exit 0, **BUILD SUCCESS, Tests run: 329,
Failures: 0, Errors: 0, Skipped: 0** (WP3: 168), **"All coverage checks have been met"**: lines **98.8 %**
(2600/2632), branches 91.3 %, domain 99.3 % (`domain.eligibility` 100 %, `domain.roster` 100 %),
`application.roster` 100 %. No compiler warnings (only the pre-existing "artifact relocated" notice for the
validator). Keycloak-tagged tests stay excluded as WP3 configured.

Red checks (mutant applied, the named tests failed, file restored): evaluator `levels < 0` → `< -1`
(`neverAssignsToACategoryBelowTheNaturalOne`); `GenderPolicy.admits` → `true` (gender property); removed
`requireCoachOf` in `AssignPlayerToTeam` (`TeamPlayerResourceTest` role matrix, 2 failures) and in
`EligibilityCaseService.resolve` (case role matrix); sweep listing all tenants instead of ACTIVE (suspended tenant
flagged); `StaffTeams` returning empty (`InternalRosterResourceTest`, `MeResourceTest`); status derivation ignoring the
season scope (`RolloverResourceTest`, 2 failures); sweep catching only `IllegalStateException` (broken tenant stops
the sweep, 3 errors).

| Acceptance item | Evidence |
|---|---|
| jqwik: never lower category; gender policy; play-up limit when set / unlimited when null; status derivation idempotent | `EligibilityPropertiesTest` (4 properties, 1000 tries each; two mutants caught) |
| examples: Dec-31/Jan-1 both rules; Feb-29; MIXED; coach vs admin | `AgeFunctionTest` (Dec-31/Jan-1 both rules, Feb-29 at 28 Feb/1 Mar non-leap and leap year), `EligibilityEvaluatorTest` (same at team level, MIXED/MALE/FEMALE, play-up limit 0/1/null, missing data, PLAYER_NOT_ACTIVE, older than every category), `TenantCalendarTest` + `NightlyEligibilityJobTest.localMidnightDecidesTheBirthday` (Asia/Jakarta vs Europe/Madrid at one instant), `TeamPlayerResourceTest.birthdayRuleUsesTheEvaluationDate`; coach vs admin: `TeamPlayerResourceTest.roleMatrix` (9 caller variants incl. coach of another team, assistant of the team), `aCoachMayOnlyAssignToTheirOwnTeams`, `TeamResourceTest.staffOfATeamStillCannotManageIt` |
| job over two tenants proves isolation; BIRTHDAY flags the day after the birthday | `NightlyEligibilityJobTest.theDayAfterTheTwelfthBirthday…`: BIRTHDAY tenant → invalidated (CATEGORY_TOO_LOW) + 1 OPEN case + ORPHAN, player whose birthday is tomorrow untouched; BIRTH_YEAR tenant with the same birthday and a SUSPENDED tenant untouched; second run + `job.run()` → still 1 case (idempotent); `underBirthYearNothingChangesBetweenRollovers`; `aBrokenTenantIsSkippedWithoutStoppingTheSweep` |
| rollover returns orphans and opens cases; assignment query lists only eligible teams | `RolloverResourceTest` (orphans Ann/Cat with previous team + reasons, 2 case ids, clones staff/players, eligible player stays valid, withdrawn player not carried, source season untouched, 409 second rollover, `clonePlayers=false`, 404/422/400, admin-only matrix, cross-tenant 404); `TeamPlayerResourceTest.eligibleTeamsListsOnlyEligibleTeamsInRankOrder` (rank order, PLAY_UP levels, gender/too-low/limit filtered, other season) |
| RLS + role matrix + cross-tenant 404; verify green; coverage | `CoreRlsSchemaMetaTest` + `CoreRlsIsolationTest` (16 tables incl. the 6 new) + `RosterSchemaTest` (overlap trigger 23P01 as `core_app`, partial uniques); role matrices (`Members.roleSetsWithAdminFlag` or per-class caller tables) and `anotherTenants…NotFound` tests in every new resource test; internal endpoints: 403 for non-`service`, 404 for unknown/suspended tenant and foreign team; verify green, 98.8 % / domain 99.3 % |

### Decisions (ADR-0015 unless noted)
- **Exclusion constraint outcome:** `create extension btree_gist` as `core_migrator` fails ("Must have CREATE
  privilege on current database", checked in a throwaway Postgres 17 container with the production init SQL). Non-
  overlap is enforced by the use case (409 `SEASON_OVERLAP`) and a `BEFORE INSERT/UPDATE` trigger with a per-tenant
  advisory lock raising 23P01 (also mapped to 409). No unique `(tenant_id, reference_year)` — the trigger enforces
  the real invariant.
- **Rollover semantics = the contract** (the lane brief differed): target season exists and has no teams; teams
  (+ staff with `cloneStaff`) are cloned; with `clonePlayers` (default **true**) open assignments of ACTIVE/ORPHAN
  players are copied and evaluated with the target reference year; ineligible copies are invalidated with a case;
  orphans = previously assigned active players without a valid assignment in the target season. `clonePlayers=false`
  gives the brief's "no auto-assignment" behaviour (orphans listed with empty reasons, no cases). Source season is
  never modified. Errors: 409 `ROLLOVER_TARGET_NOT_EMPTY`, 422 `ROLLOVER_SAME_SEASON` / `ROLLOVER_BACKWARDS`, 404.
- **Sticky invalidation:** re-evaluation only touches open valid assignments of non-ended seasons; an invalidated
  assignment stays invalid until a person resolves its case (REASSIGNED also closes it; DISMISSED keeps it invalid).
  Triggers: sweep, rollover, settings listener (same tx), team category/policy, category max age/rank, season
  dates/reference year.
- **ORPHAN scope:** valid open assignment to a team of a season that has not ended (tenant time zone).
- **Sweep cadence:** hourly by default (each tenant shortly after its local midnight); ACTIVE tenants only, one
  `TenantScope.runAs` transaction per tenant, failures logged and skipped.
- Assignment evaluates as of `joinedOn` (default today); the rollover as of max(today, target start).
- "COACH of the team" = COACH tenant role + any `team_staff` row for the team; eligibility check and case read also
  allow ASSISTANT_COACH staff (contract); `eligible-teams` = ADMIN or COACH role (contract).
- No `status` column on `season`/`team` (the contract exposes none; `current` is derived from dates; all teams are
  cloned). Assignment dates are `joined_on`/`left_on` (`date`, matching the contract's `joinedOn`/`leftOn`).
- Closing an assignment before it started records `left_on = joined_on`. `GET` of another team's case by a staff
  member → 403 (member without the relation), cross-tenant → 404.
- Test infrastructure: `Contract` resolves `allOf` (otherwise every `Season`/`AgeCategory` response fails strict
  additionalProperties). Side effect: the validator then drops `nullable` from `allOf`-wrapped request fields, so
  `PATCH …/players/{id}` with `jerseyNumber: null` is validated response-only (commented in the test).

### How WP5 plugs in
- **Assignment after approval / admin create:** call `AssignPlayerToTeam.assign(new Assignment(teamId, playerId,
  Optional.ofNullable(jersey), Optional.empty()))` inside the approval transaction. It checks authz (ADMIN or COACH
  of the team — the approver is ADMIN), 404s, 409 `PLAYER_ALREADY_ON_TEAM` / `JERSEY_NUMBER_TAKEN`, 422
  `PLAYER_INELIGIBLE` with `violations[].code` = reasons (the request stays PENDING), and re-derives the status.
  The player must already be ACTIVE (PENDING_APPROVAL → `PLAYER_NOT_ACTIVE`): flip the status first, then assign.
- **Player creation without a team:** by definition the player is ORPHAN; call `PlayerStatusSync.rederive(List.of(player),
  tenantToday.today())` after creating it so the orphan dashboard (`GET /players?status=ORPHAN`) is immediate
  (otherwise the next sweep does it).
- **Withdraw:** close open assignments with `TeamPlayer.close(today)` via `TeamPlayerRepository.update`, set
  WITHDRAWN (`PlayerRepository.updateStatus`; derivation never touches WITHDRAWN); decide what happens to OPEN cases
  of those assignments (suggest: resolve as REMOVED_FROM_TEAM by the approver).
- `GET /players`, `GET /players/{id}` can use `PlayerRepository.summaries`, `TeamPlayerRepository.openOfPlayers` and
  `CategoryLadder.naturalFor` (natural category of the current season). Keep `/api/core/players/{id}/eligible-teams`
  out of the new `PlayerResource` (it is served by `EligibleTeamsResource`).

### Open points
- **Contract vs brief (rollover):** implemented per contract; if the product wants "create the season in the same
  call", that needs a contract change (WP2b owner).
- An unassign (`DELETE …/players/{id}`) of an invalidated assignment leaves its OPEN case open (resolve it via the
  case API); rollover does not run the TEAMS entitlement check for cloned teams (billing is a no-op in v1).
- `staffTeamIds` include teams of ended seasons (staff rows are history too); narrow if the UI needs only live teams.
- The sweep visits every ACTIVE tenant hourly; optimise to "tenants whose local midnight just passed" if it grows.
- `Contract`'s muted request key `validation.request.body.schema.additionalProperties` (WP3) may be unnecessary now
  that combinators are resolved — left as is (not my lane to loosen/tighten WP3's tests).
- ADR numbering: 0012 and 0014 were taken by other lanes; this WP uses **0015** — renumber on merge if needed.
- Process: no git commands were intended; one command accidentally included a no-op `git diff --no-index /dev/null
  /dev/null` (no repository effect).
