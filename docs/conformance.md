# Spec conformance checklist (WP20 review, 2026-11-02; reconciled 2026-11-05, WP26, and 2026-11-06, after WP37 and after WP42)

This page walks the original requirements — [`SPEC.md`](SPEC.md) sentence by sentence, the two additions the user made
when the plan was locked (trilingual UI, admin-uploaded logo), and the domain rules of [`PLAN.md`](PLAN.md) §2 — and
states for each what was built, where, and what proves it. It was written from the work-package handovers
([`wp/`](wp/)), the ADRs, the security review and a read of the code; nothing here was taken on trust from a single
source when the code could be checked. WP26 (2026-11-05) updated the evidence and gaps after WP21–WP25, the first green
CI runs and the product decisions of 2026-11-05 (`wp/FOLLOW-UPS.md` "Plan (2026-11-05)"); no status changed. The
reconciliation of 2026-11-06 follows WP26–WP37 (all merged): S-36, S-46 and R-11 moved from Partial to Implemented
(WP35, WP28, WP33), the e2e journey is green on kind (WP36) and the edge is Gateway API with Envoy Gateway (ADR-0031). The evening
reconciliation follows WP38–WP42 (all merged): S-08 moved from Partial to Implemented (`tilt ci` green with every
service, WP42); update requests can clear a field (ADR-0032, WP39); the gateway's rate limits are global (ADR-0033,
WP40); the journey's mail checks run on kind too (WP42); the demo mock reaches every screen (WP41).

**Status legend**
- **Implemented** — built as asked and covered by automated tests.
- **Partial** — built, but part of the statement is missing, or the evidence stops short of the statement (e.g. not run
  in a real browser).
- **Deviated** — built differently from the literal statement, on purpose, with the reason recorded (ADR or handover).
- **Not implemented** — asked for, not built, not planned.
- **Deferred-v2** — explicitly out of v1 by the spec or a locked decision; seams may exist.

**Evidence sources.** JVM tests run by `./mvnw verify` (counts in [§ Verification baseline](#verification-baseline));
Flutter tests run by `flutter test` in `apps/web`; e2e steps are methods of `e2e/src/test/java/com/hoopsacademy/e2e/JourneyTest.java`
(21 ordered steps since WP24; green on compose in WP18b and in every CI `e2e` run on `main` since 2026-11-02; green on
kind through the Envoy Gateway in WP36, with its mail checks since WP42). "WPn" refers to `docs/wp/WPn-*.md` `## Handover`.

## Summary

| Status | Count |
|---|---|
| Implemented | 53 |
| Partial | 8 |
| Deviated | 5 |
| Not implemented | 0 |
| Deferred-v2 | 3 |
| **Total statements** | **69** |

(Spec statements S-01…S-50, user additions U-01…U-02, plan §2 rules R-01…R-15, v2 items V-01…V-02; one row each.
Partial: S-03, S-04, S-09, S-16, S-43, S-44, R-13, R-15. Deviated: S-25, S-41, R-01, R-04, R-09.
Deferred-v2: S-15, V-01, V-02.)

### Top gaps a user should know
1. **Browser-level checks ran only partly, and only locally.** The `flutter drive` smoke (`tool/web_smoke.sh`) ran green
   in mock and `--real` modes on 2026-11-02 and `tool/browser_login_check.py` covers the login round trip (WP21, WP25),
   both with a hand-installed chromedriver, not in CI. The Lighthouse installability check and the airplane-mode reload
   of the offline shell never ran; the offline cold start is proven by unit tests, a mocked service-worker run and a
   headless boot only (S-03, R-09).
2. **Kubernetes is proven on kind only.** kind + Helm + Tilt deployed game, athlete and web (WP16), all three services
   passed the smoke script (WP18), since WP36 the 21-step journey is green on kind through the Envoy Gateway
   (Gateway API, ADR-0031), and since WP42 with its mail checks (Mailpit) and after a green `tilt ci` with all three
   services (5 min 55 s on a fresh cluster). The rate limits are global across Envoy replicas (Redis, ADR-0033, WP40).
   No cluster beyond kind exists (S-04).
3. **Event feed visibility (F-01) — resolved in WP33.** The feed now follows the box score's rule (ADR-0030): ADMIN and
   team staff read every event, anybody else team-level events plus their own or linked players' (S-30, R-11).
4. **Fitness norms are partly placeholders.** Since WP27 (2026-11-05), 370 of 630 norm rows are sourced (beep test
   8–18 FitBack 2023; sit-and-reach 9–17 Catley & Tomkinson 2013; 20 m sprint 8–17 Cossio-Bolaños 2026; T-test and
   vertical jump 14–15 Mascherini 2022; Cooper 12-min 13–19). The remaining 260 (Cooper 8–12, T-test and vertical jump
   outside 14–15, a few edge ages) stay flagged "reference pending" in the UI; the Cooper figures are not verified
   against the 1968 paper (S-44). Sources, mapping rules and open leads: `docs/domain/norms.md`.
5. **Birthday → orphan works differently from the literal spec** under the default `BIRTH_YEAR` rule: a birthday changes
   nothing; orphans arise at season rollover, and the player's status only flips to ORPHAN when the old season ends
   (the rollover report lists them at once). `BIRTHDAY` mode behaves literally (S-24, R-05).
6. **Clearing a field — resolved in WP39 for athlete.** Update requests name the fields to clear in a `clear` list
   (ADR-0032, athlete 2.1.0) and the web edit forms send it, so a session's plan, a location or a note can be removed;
   core and game adopt the convention when they need it (S-36).
7. **Players see their own line in the live box score** since WP28 (S-46); no longer a gap.
8. **Billing is seams only** and the outbox is written but never published (WP19 not built) (S-15, S-16).
9. **CI** is green on GitHub since 2026-11-02 (`ci` incl. OWASP dependency-check with a valid NVD key, `e2e` journey
   on the runner, `images` built, scanned and pushed to ghcr.io), apart from one `trivy-fs` failure on 3b59360 fixed on
   2026-11-06; `ci`, `e2e` and `images` green on bb68194 (WP39) and 33441be (WP41). Dependabot opens weekly grouped update PRs (Maven,
   pub, GitHub Actions). Mutation testing runs on demand (`just mutation`, WP37: scores 99.1–100 %, baselines kept;
   athlete 430/430 after WP39).
10. **Withdrawn/suspended tenants**: members are blocked at once in core but up to 30 s later in game/athlete (membership
    cache); Keycloak logins themselves stay enabled; both accepted by design on 2026-11-05 (decision 6, ADR-0025: a
    login may belong to other academies); no purge job (R-15).

## A. SPEC.md, sentence by sentence

| ID | Statement (SPEC.md) | Status | Where | Evidence |
|---|---|---|---|---|
| S-01 | Application in Java using a microservices architecture | Implemented | Java 21 / Quarkus 3.40.1; `services/core-service`, `game-service`, `athlete-service` (ADR-0003, ADR-0007); hexagonal per service | `ArchitectureTest` / `AthleteArchitectureTest` / `HoopsArchitectureRules` (ArchUnit); root `./mvnw verify` |
| S-02 | Frontend web, mobile first | Implemented | Flutter Web in `apps/web` (ADR-0004), 360 px layout, bottom bar < 720 px / rail ≥ 720 px | goldens at 360×780 (`test/golden/goldens/*`), `navigation_roles_test.dart` |
| S-03 | "Progressive loading application kind of thing" (PWA) | Partial | manifest + icons, deferred libraries per feature (160 `*.part.js`), own caching `web/sw.js` (ADR-0018), update banner | `sw_manifest_test.dart`, `service_worker_test.dart`, `csp_hashes_test.dart`, headless-Chrome boot (WP14b); `tool/web_smoke.sh` in Chrome, mock and `--real`, 2026-11-02. **Not run**: install / airplane-mode reload / Lighthouse in a real browser |
| S-04 | Backend eventually deployed in Kubernetes | Partial | `deploy/helm/hoops` (umbrella, CNPG, Keycloak, 3 service subcharts, web), `deploy/kind/*` | `deploy/helm/tests/run.sh` (lint, snapshots, kubeconform 85/85, assertions); WP18 `smoke.sh core game athlete` SMOKE PASSED. WP36: chart 0.2.0 on Gateway API (Envoy Gateway v1.9.3, ADR-0031), journey on kind 21/21 green, `ratelimit-check.sh` PASSED. WP40: chart 0.3.0, global rate limits (Envoy rate limit service + Redis, ADR-0033), `ratelimit-check.sh` PASSED with 1 and 2 replicas and Redis down. WP42: journey 21/21 on kind with the mail checks. Gap: kind only, no other cluster |
| S-05 | Use Podman instead of Docker | Implemented | `scripts/env.sh` (Podman socket for Testcontainers), `podman compose`, `KIND_EXPERIMENTAL_PROVIDER=podman`, images via `podman build` | WP0/WP1/WP16 handovers; every `verify` runs Testcontainers on Podman |
| S-06 | Frontend: avoid Node, use something different | Implemented | Flutter/Dart only; sqlite3.wasm fetched + `dart compile js` for the drift worker (`tool/fetch_web_db_assets.sh`) | no `package.json` in the repo; WP11/WP13. (A one-off `deno` run checked `sw.js` in WP14; not part of the toolchain) |
| S-07 | Backend with docker compose, but with Podman | Implemented | `infra/compose/compose.yaml` (Postgres 17, Keycloak 26.8.1, MailHog, nginx) + `e2e/bin/services-up.sh` | WP1 checks; **e2e journey 20/20 green on compose, three consecutive runs** (WP18b) |
| S-08 | Then, when the app works, kind + Helm + Tilt | Implemented | `deploy/kind/{up,down,secrets,seed-users,smoke}.sh`, `Tiltfile`, `just kind-up` / `just tilt` | WP16: `tilt ci` green for game + athlete + web; WP18: core/game/athlete via Helm + smoke. WP30: the Tiltfile runs `scripts/sync-chart-files.sh` before rendering; WP36: Gateway API routes and rate limits checked on kind; WP40: global rate limits (Redis) checked with 1 and 2 Envoy replicas; WP42: `just tilt ci -- --from-host` "All workloads are healthy" with core, game, athlete and web on a fresh cluster (5 min 55 s) |
| S-09 | Write tests for everything | Partial | JUnit 5/AssertJ/jqwik/REST Assured/WireMock/ArchUnit/Testcontainers as non-owner roles; `flutter test`; e2e module | 2,019 JVM tests (fresh `verify` after WP39 on WP38) plus 4 e2e unit tests, 646 Flutter tests (WP41), 21 e2e steps on compose and on kind (mail checks included); JaCoCo gates (≥ 80 %, domain ≥ 90 %) met; all three CI workflows green since 2026-11-02; mutation testing on demand (PIT, WP37: common 99.1 %, core 99.6 %, game 99.5 %, athlete 100 %; athlete 430/430 after WP39). Gaps: browser smoke executed only locally (mock + real), several WPs admit code written before its tests |
| S-10 | One big git project or several: your choice | Implemented | single monorepo (ADR-0002) | repo layout |
| S-11 | A lightweight database that works well in k8s | Implemented | PostgreSQL 17, one database, schema per service, CloudNativePG on kind (`charts/databases`) | WP16 CNPG clusters healthy, managed roles reconciled; RLS suites. (Postgres rather than an embedded DB: chosen for RLS and CNPG) |
| S-12 | Make sure secrets are not pushed to git | Implemented | `.env` ignored, `.env.example` placeholders, gitleaks pre-commit + CI, realm export without credentials, Secrets from `.env` (ADR-0012) | WP0 (fake AWS key blocked), WP16/WP17 `helm template … \| gitleaks detect --pipe` clean, `gitleaks detect --no-git` hits only in ignored `.env`; `NoBuiltInCredentialsTest` (game, athlete) |
| S-13 | Find skills on clean code, security, TDD on the internet and add them | Implemented | `.claude/skills/{clean-code,owasp-security,test-driven-development,verification-before-completion,systematic-debugging}` (vendored, provenance in `THIRD_PARTY_SKILLS.md`) + 5 project skills | WP0 handover |
| S-14 | A basketball application for basketball academies | Implemented | domain: roster/eligibility, matches/box score, training, health & fitness | whole suite; user guides `docs/guides/*` |
| S-15 | No billing module for the moment | Deferred-v2 | — | roadmap (`docs/roadmap.md`) |
| S-16 | … but prepare for billing as a possible expansion | Partial | `billing.plan` (seeded FREE), `billing.tenant_subscription` (created at onboarding), `EntitlementService` port + `NoopEntitlementService` called from team creation, member invite and player registration; `core.outbox` rows written | `CoreRlsIsolationTest` covers `billing.tenant_subscription`; `PlatformTenantResourceTest` (FREE subscription). Gaps: no test of an entitlement denial path; outbox never published (WP19 not built) |
| S-17 | Multitenant: academies must not see each other's contents | Implemented | `tenant_id` + ENABLE/FORCE RLS on every tenant table, non-owner NOBYPASSRLS roles, `app.current_tenant()` raising when unset, `TenantHeaderFilter` 404 for non-members (ADR-0006, ADR-0011) | `CoreRlsSchemaMetaTest`/`CoreRlsIsolationTest`, `GameRlsIsolationTest`, `AthleteGenericRlsIsolationTest`, `TenantRegistryRlsTest`, per-resource `anotherTenants…NotFound`; e2e `secondTenantCannotSeeTheFirstTenantsData` |
| S-18 | Each tenant has four roles: administrator, coach, parent, player | Implemented | `core.membership_role`: ADMIN, COACH, ASSISTANT_COACH, PARENT, PLAYER (additive) — tenant roles live in the DB, not Keycloak (ADR-0005) | `Members.roleSetsWithAdminFlag` matrices in `MemberResourceTest` & co |
| S-19 | Players belong to categories | Implemented | `age_category` (U8…U18, SENIOR seeded, editable), natural category derived per season; players belong to teams of a category | `CategoryLadderTest`, `AgeCategoryResourceTest`, `PlatformTenantResourceTest` (seeded ladder) |
| S-20 | They cannot be in categories for lower ages | Implemented | `EligibilityEvaluator` → `INELIGIBLE(CATEGORY_TOO_LOW)`; assignment command checks it | `EligibilityPropertiesTest` (jqwik "never lower category"), `EligibilityEvaluatorTest`, `TeamPlayerResourceTest` |
| S-21 | … but some players may play in higher categories | Implemented | `PLAY_UP(n)` with per-tenant `max_play_up_levels` (null = unlimited), `team_player.play_up_levels` | `EligibilityPropertiesTest` (play-up limit), `eligibleTeamsListsOnlyEligibleTeamsInRankOrder`; web play-up badge (`teams_test.dart`) |
| S-22 | A coach trains n age categories | Implemented | derived from `team_staff` rows (any number of teams/categories) → `staffTeamIds` in `/me` and `/internal/authz` | `MeResourceTest` (staffTeamIds), `InternalRosterResourceTest` |
| S-23 | An administrator can also be a coach or a parent or both | Implemented | roles are a union per person | role-set matrices incl. ADMIN+COACH, COACH+PARENT, ADMIN+PLAYER (`MemberResourceTest`, `RoleMatrixTest`, `HealthRoleMatrixTest`, `EventAuthorizationTest`) |
| S-24 | Different teams in a particular age group | Implemented | `team(season, name, alias, age_category, gender_policy)`, unique name per season only | `TeamResourceTest`; e2e `adminCreatesSeasonCategoriesAndTeam` |
| S-25 | On a birthday a player who no longer fits becomes orphan; coach and/or admin fix it by assigning a new group | Deviated | default `age_rule = BIRTH_YEAR` (ADR-0010): birthdays never change the category; the rollover re-evaluates and lists orphans; `BIRTHDAY` rule: hourly sweep after local midnight invalidates + opens a case. Status ORPHAN ⇔ no valid open assignment in a season that has not ended (ADR-0015), so after a rollover the status flips when the old season ends. Fix: `EligibilityCaseService.resolve` / reassign by ADMIN or COACH of the team | `NightlyEligibilityJobTest` (BIRTHDAY day-after, BIRTH_YEAR untouched, idempotent), `RolloverResourceTest` (orphan list + cases), `EligibilityCaseResourceTest`; e2e `rolloverIntoTheNextSeasonProducesAnOrphanWhichIsResolved` (asserts via the report, not `status=ORPHAN`, WP18b fix 5) |
| S-26 | Groups have names or alias, and age category | Implemented | `team.name`, `team.alias`, `team.age_category_id` | `TeamResourceTest`; web team form (`teams_test.dart`) |
| S-27 | Also gender: a male cannot play in girls' groups and vice versa | Implemented | `GenderPolicy.admits` (MALE / FEMALE / MIXED), reason `GENDER_POLICY`; PLAYER requires gender + birth date | `EligibilityPropertiesTest` (gender property), `EligibilityEvaluatorTest` (MALE/FEMALE) |
| S-28 | There may be mixed groups that allow both genders | Implemented | `gender_policy = MIXED` | `EligibilityEvaluatorTest` (MIXED) |
| S-29 | Coach can have an assistant coach; separate role? | Implemented | separate tenant role `ASSISTANT_COACH` with a defined capability set (ADR-0021 §1): match ops, all stats, training, attendance, health; **no** add/withdraw requests, assignments or case resolution | `TeamPlayerResourceTest.roleMatrix` (assistant of the team), `ApprovalPolicyTest`, `EventAuthorizationTest`, `RoleMatrixTest` |
| S-30 | Coach, assistant and parent have access to the match view | Implemented | web Matches destination for every role; server: any member may read matches/roster/feed (ADR-0021 §3). the feed is filtered for everybody but ADMIN / team staff (F-01, WP33, ADR-0030) | `MatchResourceTest`, `match_screens_test.dart` (role variants), `MatchEventFeedRoleMatrixTest` |
| S-31 | In the match view they enter game data and player stats as the game goes (assists, points, turnovers, …) | Implemented | 15 event types (SHOT 1/2/3 made/missed, ASSIST, REBOUND, TURNOVER, STEAL, BLOCK, FOUL kinds, SUB_IN/OUT, PERIOD_START/END, OPPONENT_SCORE, TIMEOUT, VOID, NOTE); offline-first queue with idempotent batch sync (ADR-0014) | `MatchEventResourceTest`, `BoxScoreProjectorTest`, `ProjectionVectorsTest` + Dart `projector_vectors_test.dart`, `sync_worker_test.dart` (50 queued → 50 ACCEPTED → replay 50 DUPLICATE); e2e `coachAndParentEnterEventsAndTheParentIsRestricted`, `replayingTheCoachBatchIsIdempotent` |
| S-32 | A parent can only enter stats of their linked child unless also assistant coach or coach | Implemented | `EventAuthorization`: PARENT → 7 player-stat types for linked players + VOID of own events; staff union wins. Deviation in detail: parents never record clock/period/opponent/subs, and after FINISHED only events recorded before `finishedAt` count | `EventAuthorizationTest` (roles, unions, FINISHED rule), `parentMayRecordStatsOfTheLinkedPlayerAndVoidOwnEventsOnly`; web parent mode (`match_screens_test.dart`, `scoring_rights_test.dart`); e2e step above |
| S-33 | Assistant coach and coach can enter stats for everybody in the team | Implemented | staff of the match's team: any event type for any player | `EventAuthorizationTest`, `MatchEventResourceTest` |
| S-34 | Starting team, minutes played, when they came to the court | Implemented | `match_roster.is_starter`; SUB_IN/SUB_OUT with period + clock; `seconds_played`, `was_starter` projected; event log shows each substitution | `MinutesTest` (re-entry, period boundaries, overtime), vector `substitutions-and-minutes`; `startWithoutStarterIs422` |
| S-35 | Coach, assistant coach and parent can enter injuries and expected return date | Implemented | `injury(occurred_on, body_part, severity, expected_return_on ≥ occurred_on, actual_return_on, OPEN/RECOVERED)`; PARENT for linked players (create/update, not delete); availability derived | `InjuryApiTest`, `HealthRoleMatrixTest`, `HealthDomainTest`; web `health_test.dart`; e2e `injuryMakesPlayerUnavailableThenMeasurementAndPhysicalTestWithBand` |
| S-36 | Coach and assistant enter the training calendar: location, schedule and training plan | Implemented | schedules (weekday, time, duration, location, validity) materialised 8 weeks ahead in the tenant zone; ad-hoc sessions; `training_session.plan_id` in the API. **Web**: plan picker on ad-hoc sessions and a session edit dialog (WP35); emptied fields are cleared and a plan can be detached (`clear` list, ADR-0032, WP39); plans also reach players through assignments (team/player, due date) | `ScheduleApiTest`, `SessionMaterialiserTest` (DST Madrid, Jakarta), `SessionPlanApiTest`; web `calendar_test.dart`, `schedules_absences_test.dart`, `session_edit_test.dart`; e2e `scheduleMaterialisesSessionsAndAttendanceHonoursPlannedAbsence` |
| S-37 | Predefined training plans, and the coach can also enter their own | Implemented | 10 global templates (`R__plan_templates.sql`, English names), copy-on-use into the tenant; own plans with items, reorder, archive | `TemplateSeedTest`, `TemplateRlsIsolationTest` (templates read-only), `TrainingPlanApiTest`; web `plans_test.dart`; e2e `planCopyOnUseAssignmentAndCompletion` |
| S-38 | Overall admin manages tenants: sign up and withdraw tenants | Implemented | `/platform/tenants` create (tenant + FREE subscription + seeded categories + first ADMIN login, saga ADR-0013), suspend, reactivate, withdraw (retention `P365D`); `super_admin` realm role. Sign-up is done by the super admin (no self-service sign-up); the super admin also lists, adds, edits and removes each academy's administrators (`/platform/tenants/{id}/admins`, ADR-0023). A new login's temporary password is returned once and Keycloak forces a new password at the first sign-in; no setup e-mail (ADR-0024, re-issue while PENDING) | `PlatformTenantResourceTest` (saga compensation cases), `PlatformAdminResourceTest`, `OnboardingRepairTest`, `KeycloakTemporaryPasswordKeycloakTest` (`-Pkeycloak-it`); web `platform_test.dart`; e2e `superAdminCreatesTenantWithFirstAdmin`, `firstAdminSignsInWithTheTemporaryPasswordAndMustChooseTheirOwn`, `suspendedTenantAnswersNotFound…` |
| S-39 | … can see how many teams, players, games and other usage statistics | Implemented | `GET /platform/tenants/{id}/usage` aggregating core + game + athlete `/internal/usage` (`unavailableServices` on failure), daily snapshots + `/usage/history` | `TenantUsageResourceTest`, `TenantUsageHistoryResourceTest`, `UsageSnapshotJobTest`, `UsageAndInternalApiTest`; web usage dashboard and trend chart (`platform_test.dart`, WP35); e2e `platformUsageShowsTheCounts` |
| S-40 | Admin and coach can add or withdraw players; by a coach it needs admin approval | Implemented | `approval_request` ADD_PLAYER / WITHDRAW_PLAYER; ADMIN direct (auto-approved audit row), COACH → PENDING, approval runs the eligibility-checked assignment (ADR-0020) | `ApprovalPolicyTest`, `ApprovalRequestResourceTest` (422 keeps PENDING, double decide 409, concurrent decisions), `PlayerResourceTest`; web `approvals_cases_test.dart`; e2e `adminAddsPlayerAndCoachRequestsOneWhichTheAdminApproves` |
| S-41 | (Approval outcome: rejected requests) | Deviated | a rejected ADD leaves the player `REJECTED` (a fifth status, contracts 2.0, ADR-0016/0020), hidden from non-admins; web labels it "Rejected" (es/en/id, WP28) | `rejectingAnAddLeavesThePlayerRejected…` (core); web `labels_test.dart` |
| S-42 | Coach can enter other physical-education stats, e.g. Cooper test results with date | Implemented | `physical_test_type` (6 global: COOPER_12MIN, SPRINT_20M, VERTICAL_JUMP, AGILITY_T_TEST, SIT_AND_REACH, BEEP_TEST + tenant types), `physical_test_result(player, date, value)` | `PhysicalTestApiTest`, `HealthRoleMatrixTest`; web `health_test.dart` |
| S-43 | For each, an indication of the expected level for the age | Partial | `BandResolver`: band POOR…EXCELLENT by gender + age at test date + value, tenant norms override global; `bandStatus` MATCHED / NO_NORM / MISSING_PLAYER_DATA; "reference pending" flag in the UI | `BandResolverTest`, `NormSeedTest`; web `charts_test.dart`. **Data gap**: 370 of 630 norm rows sourced (WP27; see S-44) |
| S-44 | (Expected levels must be real reference values) | Partial | sourced (370 of 630 rows, WP27): BEEP_TEST 8–18 (FitBack 2023), SIT_AND_REACH 9–17 (Catley & Tomkinson 2013), SPRINT_20M 8–17 (Cossio-Bolaños 2026), AGILITY_T_TEST and VERTICAL_JUMP 14–15 (Mascherini 2022), COOPER_12MIN 13–19 (Cooper 1968 as reproduced, primary not obtained); the other 260 rows are placeholders flagged `reference_pending` (`docs/domain/norms.md`) | `NormSeedTest` (placeholders ⇔ flagged pending, band edges per source, placeholder count per test); WP10b and WP27 handovers |
| S-45 | Each player has weight and height, modifiable by parents, coach and assistant coach | Implemented | `body_measurement(player, measured_on, height_cm, weight_kg)` unique per day (409 on a same-day race); PARENT linked write; PLAYER read; growth charts | `BodyMeasurementApiTest`, `MeasurementSameDayRaceTest`, `HealthRoleMatrixTest`; web `charts_test.dart` |
| S-46 | Players can see their own stats | Implemented | server: box score returns the PLAYER's own line, season stats for self (`GetPlayerSeasonStats`); web Me → season statistics. web live box score shows the PLAYER's own line and no other (`ScoringRights.ownPlayerId`, WP28) | `StatisticsResourceTest` (self line, season stats visibility); web `profile_test.dart`, `scoring_rights_test.dart`, `match_screens_test.dart` |
| S-47 | … and the training program given by the coach, and mark it done / not done / partially | Implemented | `plan_assignment` fan-out at read time, `plan_completion` DONE / PARTIAL / NOT_DONE by self, linked parent or team staff; progress view | `PlanCompletionApiTest`, `PlanRoleMatrixTest` (102 cases), `PlanProgressTest`; web `plans_test.dart`, `profile_test.dart`; e2e `planCopyOnUseAssignmentAndCompletion` |
| S-48 | Parents and players can record a planned absence | Implemented | `planned_absence(player, from, to, reason)`: PARENT linked, PLAYER self, staff any; shown as `expectedAbsent` on the attendance sheet | `PlannedAbsenceApiTest`, `RoleMatrixTest`; web `schedules_absences_test.dart`; e2e step above |
| S-49 | Coach and assistant record a player late or missing a training | Implemented | `attendance(session, player, PRESENT/LATE/ABSENT/EXCUSED, minutes_late)` by ADMIN / staff of the team | `AttendanceApiTest`, `RoleMatrixTest` (73 cases); web `session_test.dart` |
| S-50 | Plan run by different agents, the adequate model per task (Sonnet/Opus), no Fable except for the plan design | Implemented | PLAN §5 model table; every WP brief names its model; orchestrated per the user's 2026-11-01 update | WP briefs `Model:` lines |

> S-41 and S-44 split a consequence out of the preceding sentence (approval outcome, quality of the reference values) so
> each can carry its own status; S-50 is the process requirement at the end of the spec.

## B. User additions (locked 2026-11-01)

| ID | Statement | Status | Where | Evidence |
|---|---|---|---|---|
| U-01 | UI trilingual from the start: Spanish, English, Indonesian; locale per user with tenant default | Implemented | `apps/web/lib/l10n/app_{es,en,id}.arb` (es template, real Indonesian), Profile language picker → local + `PATCH /api/core/me`; effective locale: user choice > academy `defaultLocale` > es; user guides in es/en/id (`docs/guides/`) | `l10n_keys_test.dart` (key + placeholder parity, not-a-copy), `locale_test.dart` (es/en/id switch, persisted, tenant default); `sign_out_test.dart` (es/en/id strings). Backend Problem `detail` texts are English only (the UI never shows server text) |
| U-02 | Academy logo uploaded by an ADMIN (PNG/JPEG/WebP, SVG sanitised or rejected, ≤ 512 KB, in Postgres, ETag caching) | Implemented | `PUT/GET/DELETE /api/core/tenant/logo`, `core.tenant_logo` bytea, magic-byte detection, SVG and GIF rejected (415), 512 KB (413), ETag/304 + Cache-Control + nosniff (ADR-0009); web upload with client-side checks and app-bar refresh | `TenantLogoResourceTest` (16), `LogoImageTest`; web `logo_validation_test.dart`, `academy_profile_test.dart`, `api_repositories_test.dart` (exact bytes) |

## C. PLAN.md §2 domain rules

PLAN §2 is prose; it is split here into 15 checkable rules (roster & eligibility R-01…R-05, approvals R-06,
match statistics R-07…R-11, training R-12, health & fitness R-13, authorization matrix R-14, tenant withdrawal R-15).

| ID | Rule (PLAN §2) | Status | Where | Evidence |
|---|---|---|---|---|
| R-01 | Person / membership model: PLAYER requires birth date + gender; `player.status` PENDING_APPROVAL / ACTIVE / ORPHAN / WITHDRAWN; guardian links | Deviated | as planned plus status `REJECTED` (ADR-0016) | `PersonTest`, `PlayerStatusDerivationTest`, `GuardianLinkResourceTest`, `V8__player_rejected.sql` check |
| R-02 | Seasons non-overlapping with a reference year; categories seeded U8…U18, SENIOR, editable; teams with gender policy; a player may be on several teams; `team_staff` is the single source of "coach trains N" | Implemented | `V5__roster.sql`; non-overlap by trigger + advisory lock (no `btree_gist`, ADR-0015) → 409 `SEASON_OVERLAP` | `SeasonTest`, `RosterSchemaTest` (23P01 as `core_app`), `SeasonResourceTest`, `TeamResourceTest`, `CategoryLadderTest` |
| R-03 | Eligibility engine: `AgeFunction` BIRTH_YEAR (default) / BIRTHDAY; `eligibility(player, team, asOf)` → ELIGIBLE / PLAY_UP(n) / INELIGIBLE(reasons: CATEGORY_TOO_LOW, PLAY_UP_LIMIT_EXCEEDED, GENDER_POLICY, MISSING_BIRTH_DATE, MISSING_GENDER, PLAYER_NOT_ACTIVE); invariants | Implemented | `domain.eligibility` (pure, 100 % lines) | `AgeFunctionTest` (Dec-31/Jan-1, Feb-29), `EligibilityEvaluatorTest`, `EligibilityPropertiesTest` (4 jqwik properties × 1000) |
| R-04 | ORPHAN ⇔ ACTIVE player with no valid open assignment | Deviated | scope narrowed to assignments of seasons that have not ended in the tenant zone (ADR-0015 "orphan scope"); consequence under BIRTH_YEAR described in S-25 | `PlayerStatusDerivationTest`, `RolloverResourceTest` (status derivation season scope mutant caught) |
| R-05 | Evaluator never deletes: sets `invalidated_at` + reason and opens an `eligibility_case` (OPEN → RESOLVED by ADMIN or the team's staff); nightly per tenant + synchronous rollover; assignment UI offers eligible teams only | Implemented | `EligibilityEngine`, `NightlyEligibilityJob` (hourly, each tenant after its local midnight, `runExclusive`), `RolloverSeason`, `GET /players/{id}/eligible-teams`. Resolution by ADMIN or COACH of the team (assistants read only) | `NightlyEligibilityJobTest`, `ReevaluationTriggersTest`, `RolloverResourceTest`, `EligibilityCaseResourceTest`, `eligibleTeamsListsOnlyEligibleTeamsInRankOrder`; web `teams_test.dart` (assign verdicts), `approvals_cases_test.dart` |
| R-06 | Approvals: ADMIN executes immediately (audit row), COACH → PENDING, assistants cannot request; ADD creates player PENDING_APPROVAL visible to admins + requester; approval applies the team via the checked command (may 422 and stay PENDING); WITHDRAW keeps ACTIVE until approval; only PENDING decidable; one PENDING per (action, player) | Implemented | `domain.approvals`, `application.approvals` (ADR-0020); plus player login provisioning (WP17) and audit events (ADR-0017) | `ApprovalPolicyTest`, `ApprovalRequestTest`, `ApprovalRequestResourceTest` (`anIneligibleAssignmentFailsWith422AndTheRequestStaysPending`, `twoConcurrentDecisionsHaveExactlyOneWinner`), `PlayerResourceTest` |
| R-07 | Match: SCHEDULED → LIVE → FINISHED / CANCELLED, period count/minutes, roster with display name, jersey, starter | Implemented | `Match` aggregate, `MatchRoster` (denormalised display name/jersey, ADR-0008) | `MatchTest`, `MatchRosterTest`, `MatchResourceTest`, `MatchRosterResourceTest` |
| R-08 | Event = client UUIDv7 id, server_seq, (device, client_seq) unique, 15 types each with a JSON Schema; server validates schema + authz only, never domain consistency (impossible sequences → projection warnings, fixed by VOID) | Implemented | `V2__events.sql`, `libs/contracts/events/match-event.schema.json`, `MatchEventDecoder`, projection warnings (13 codes) | `MatchEventJsonSchemaTest`, `MatchEventDecoderTest`, vector `impossible-sequences-warnings`, `ProjectionPropertiesTest` |
| R-09 | `events:batch` → per-event ACCEPTED / DUPLICATE / REJECTED; row lock; re-projection of player stats + summary; total ordering; `GET /events?after=seq`; minutes from starters + period/sub events | Deviated | as planned, **plus** events are accepted for SCHEDULED and FINISHED matches, only CANCELLED rejects (ADR-0014 §3; `MATCH_NOT_STARTED` reserved, unused); id reused for another match → `EVENT_ID_REUSED` (ADR-0016) | `ConcurrentIngestTest` (overlapping concurrent batches = sequential replay), `repostingABatchIsAllDuplicate…`, `MinutesTest`, `ProjectionVectorsTest`; Dart `sync_worker_test.dart` |
| R-10 | Event authz: staff → any event + transitions; PARENT → player-attributed stat events of linked players, VOID own only, never clock/period/opponent/roster; PLAYER read-only | Implemented | `EventAuthorization` (pure), ADR-0014 §4, ADR-0021 §4 | `EventAuthorizationTest`, `MatchEventResourceTest`; e2e `coachAndParentEnterEventsAndTheParentIsRestricted` |
| R-11 | View match stats: staff all, PARENT linked, PLAYER self | Implemented | box score and season stats are line-filtered on the server, and the event feed by the same rule since WP33 (F-01, ADR-0030); the web live box score shows the PLAYER's own line (S-46, WP28) | `StatisticsResourceTest`, `MatchEventFeedRoleMatrixTest`; security review F-01 |
| R-12 | Training: schedules materialised 8 weeks ahead (idempotent, DST), ad-hoc sessions, plans + items (global templates, copy-on-use), assignment to exactly one of team/player fanned out at read time, completion by self / linked parent / team staff, planned absence, attendance by staff, absence overlay | Implemented | `athlete` V1/V2 + `R__plan_templates.sql`; templates via `owner_tenant_id` (NULL = global) instead of `tenant_id NULL` (WP9, `nullableTenantTables()` hook, ADR-0016 §6); training reads open to all staff (ADR-0021 §5) | `SessionMaterialiserTest`, `ScheduleApiTest`, `NightlyMaterialisationTest`, `PlanDomainTest`, `PlanAssignmentApiTest`, `PlanCompletionApiTest`, `AttendanceApiTest`, `PlannedAbsenceApiTest`, `TemplateRlsIsolationTest` |
| R-13 | Health & fitness: injury → player unavailable; measurements unique per day editable by parent + staff; test types; results; norms (tenant rows override global); expected level = band for (gender, age at measurement, value); seeds cite sources, uncited flagged "reference pending" | Partial | all built (`V3__health.sql`, `BandResolver`, availability endpoint); staff access team-scoped (ADR-0021 §6); availability badge shown in the health view, attendance sheet, team roster and match setup (WP35); 260 of 630 norm rows are still placeholders (S-44) | `HealthDomainTest`, `InjuryApiTest`, `BodyMeasurementApiTest`, `PhysicalTestApiTest`, `BandResolverTest`, `NormSeedTest`, `HealthRlsIsolationTest` |
| R-14 | Authorization matrix (oracle for role-matrix tests); non-members 404; super_admin only for tenant lifecycle and usage, cannot read tenant content | Implemented | `docs/domain/authz-matrix.md` + refinements ADR-0021; `TenantHeaderFilter`, `@RequiresTenantRole`, `Authz`; super_admin without membership → 404 on `/api/**` (by design) | role-matrix suites in every service (`Members.roleSetsWithAdminFlag`, `RoleMatrixTest`, `PlanRoleMatrixTest`, `HealthRoleMatrixTest`, `TeamPlayerResourceTest.roleMatrix`), `RealAuthzResolverTest.superAdminWithoutMembershipGetsNotFound`, `TenantRegistryRlsTest` (platform cannot read tenant tables) |
| R-15 | Tenant withdrawal: logins blocked immediately, data retained for a configurable period, purge job v2 | Partial | `TenantLifecycle` (retention `hoops.tenant.withdrawn-retention=P365D`); memberships of SUSPENDED/WITHDRAWN tenants disappear from `/me` and the resolvers. Core blocks at once (cache invalidated); game/athlete after up to 30 s (`hoops.core.cache-ttl`); Keycloak accounts stay enabled (a member of another tenant keeps working there); the 30 s delay and enabled logins are accepted by design (decision 6, ADR-0025). Purge job: Deferred-v2 | `RealAuthzResolverTest.suspendedAndWithdrawnTenantsAnswerNotFound`, `PlatformTenantResourceTest`; e2e `suspendedTenantAnswersNotFoundForItsMembersAndReactivationRestoresIt` (waits for the 30 s caches) |

## D. Explicit v2 / out-of-scope items

| ID | Item | Status | Notes |
|---|---|---|---|
| V-01 | Events v2: transactional outbox publisher + Redpanda + local replicas (WP19, optional) | Deferred-v2 | `core.outbox` is written by onboarding/invites/approvals but nothing publishes it; `RosterPort` stays REST (ADR-0008) |
| V-02 | Purge job for withdrawn tenants, push notifications, native images, Pact broker | Deferred-v2 | PLAN §8; roadmap |

## Deviations, stated plainly
These are the places where the system knowingly differs from a literal reading of the spec or plan. Each has a recorded
reason; none is a silent gap.

| Topic | What the system does | Recorded in |
|---|---|---|
| Event ingest for SCHEDULED / FINISHED matches | accepted (only CANCELLED rejects); a final rejection would lose events recorded offline before the start call arrived. After FINISHED staff may correct; parent events only if recorded before `finishedAt` | ADR-0014 §3, ADR-0016 |
| Orphans under `BIRTH_YEAR` | birthdays change nothing; orphans arise at rollover; status ORPHAN only once the old season has ended (the rollover report and cases show them immediately) | ADR-0010, ADR-0015, WP18b fix 5 |
| Rejected players | fifth status `REJECTED` (rows kept for audit, hidden from non-admins, e-mail stays reserved) | ADR-0016, ADR-0020 |
| Assistant coach permissions | separate role; match + stats + training + health, but no player add/withdraw requests, assignments or case resolution | ADR-0021 §1 |
| Parents entering stats | linked players only, 7 stat types + VOID of own events; never clock, periods, opponent score, substitutions | ADR-0014 §4, ADR-0021 §4 |
| Coach add / withdraw | always through an approval request unless the coach is also ADMIN; withdraw only for players on own teams | ADR-0020 |
| Cooper / fitness norms | 370 of 630 rows cited (WP27); the other 260 are placeholders flagged "reference pending"; Cooper 13–19 from reproductions, not the primary paper | `docs/domain/norms.md`, WP10b, WP27 |
| Offline cold start | Flutter's worker caches nothing; own `sw.js` instead; never exercised in a real browser | ADR-0018 |
| super_admin and tenant content | cannot read tenant content without a membership (404), sees counters only | PLAN §1.3, ADR-0021 §8 |
| Billing | extension points only (tables, noop `EntitlementService`, outbox rows), no module, no publisher | PLAN locked decisions, V-01 |
| Kubernetes | deployed and smoke-tested on kind (game/athlete/web via Tilt; core/game/athlete via Helm); edge is Gateway API with Envoy Gateway with global rate limits (Redis); the e2e journey is green on kind with its mail checks and `tilt ci` is green (WP42); no other cluster | WP16, WP18, WP36, WP40, WP42, ADR-0031, ADR-0033 |
| Browser tests | `integration_test` + `tool/web_smoke.sh` run locally with a hand-installed chromedriver (green in mock and `--real` modes, 2026-11-02; mock mode again in WP41, through training and the platform console); not in CI | WP11, WP18 |
| Health vs training visibility | health data team-scoped for staff, training data tenant-wide for staff | ADR-0021 §5–6 |
| Session sign-out | no `offline_access`; sign-out wipes the offline DB after warning about unsynced events | ADR-0019 |
| First sign-in / e-mail verification | no setup or verification e-mail; a server-generated temporary password is shown once to the creator, Keycloak forces a new password at the first sign-in; e-mail ownership is never verified (pre-account hijacking F-22, accepted by design) | ADR-0024, ADR-0025 |
| One login, several academies | an invite of an e-mail that already signs in links that login without asking its owner and reveals that it exists (F-11, accepted by design); logins stay enabled when an academy is suspended or withdrawn | ADR-0025 |

## Verification baseline
- **Backend**: fresh local `./mvnw -B -ntp -T 1C clean verify` after WP39 was rebased on WP38 (2026-11-06): contracts
  152, common-quarkus 186, core-service 773, game-service 255, athlete-service 653 = **2,019 tests**, 0 failures /
  errors / skipped, every coverage gate met. Since WP42 the `e2e` module also runs in `verify`: 4 `MailSinkTest` tests,
  and the 21 `JourneyTest` steps reported as skipped (no `e2e.baseUrl`). CI `ci` green on bb68194, ba4e948, 625a5f9 and 33441be.
  (CI on 3b59360 after WP37: 1,970; CI on ebdd49f after WP35: 1,902; WP26 baseline on ec3360e: 1,760; WP20 review: 1,467.)
- **Flutter**: `just web-test` after WP41: **646 tests passed**, `flutter analyze` clean (608 after WP37, 612 after
  WP38, 623 after WP39). No golden changed in WP39–WP41; WP38 re-recorded `audit_activity_1024x768`.
- **e2e**: CI `e2e` green on every push to `main` (compose stack on the runner; requests and responses validated,
  ADR-0027). WP42 locally: compose 25 run (4 unit + 21 journey), 0 skipped; kind through the Envoy Gateway on :8090,
  21/21, 0 skipped, 72 s, mail checks against Mailpit's `/api/v1`. `just tilt ci -- --from-host` on a fresh kind cluster:
  "All workloads are healthy" in 5 min 55 s.
- **Mutation**: WP37 local `just mutation`: common-quarkus 99.1 %, core 99.6 %, game 99.5 %, athlete 100 %; baselines
  95 / 95 / 95 / 100. After WP39 athlete 430/430 killed; the other modules were not re-run after WP38–WP42.
- **Charts**: chart 0.3.0; WP40 local `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED (79 checks, kubeconform 147/147,
  5 snapshots); `ratelimit-check.sh` passed on kind with 1 and 2 Envoy replicas and in `redis-down` mode (fail open).
