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
- [ ] jqwik properties: never assign to lower category; gender policy respected; play-up limit enforced when set; status derivation idempotent
- [ ] examples: Dec-31/Jan-1 boundaries for both rules; Feb-29 birthdays; MIXED teams; coach-only vs admin permissions
- [ ] nightly job over two tenants proves isolation (cases only in the right tenant); BIRTHDAY tenant flags the day after birthday
- [ ] rollover returns the orphan list and opens cases; assignment UI query lists only eligible teams
- [ ] RLS suites + role-matrix + cross-tenant 404 for all new resources; verify green, coverage ≥ 80 % (domain ≥ 90 %)
