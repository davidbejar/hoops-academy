# WP9 — athlete-service: training plans, templates, assignments, completion

Model: Sonnet. Depends on: WP8. Lane ATHLETE. Plan §2 "Training". Skills: as WP8.

## Scope
- Flyway: `training_plan` (tenant_id NULL for global templates, name, description, author_person_id, is_template,
  archived), `plan_item` (plan, position, title, description, duration_min, category), `plan_assignment` (plan,
  team_id xor player_id, due_on, assigned_by, note), `plan_completion` (assignment, player, status, note, marked_at,
  marked_by; pk assignment+player). RLS: templates readable by all tenants (policy `tenant_id is null or tenant_id =
  app.current_tenant()`, writes only own tenant) — allow-list the nullable case in the meta-test subclass with reason.
- Seed ~10 global templates (warm-up, ball handling, shooting form, conditioning, …) in a repeatable migration with
  items in es/en/id names? No — item text is coach content; seed in English with a `locale` column; UI translates
  template names via keys (document).
- Use cases: list/create/patch/archive plans (staff), copy template (copy-on-use), items CRUD, assignments (team or
  player), fan-out read model (team assignment → current roster via RosterPort), completion marking (player self,
  parent linked, staff team), progress summary per assignment.

## Acceptance
- [x] global templates visible read-only to every tenant; tenant cannot modify templates (RLS test on nullable owner column): `TemplateRlsIsolationTest` (7), `TrainingPlanApiTest.everyMemberSeesTheSeededTemplates...`, `templatesAreReadOnly`
- [x] copy-on-use creates an independent tenant plan; assignment XOR constraint; completion permissions matrix: `copyingATemplateCreatesAnIndependentTenantPlan`, `PlanDomainTest`, DB `check ((team_id is null) <> (player_id is null))`, `PlanAssignmentApiTest.exactlyOneTarget...`, `PlanRoleMatrixTest.markCompletion*`
- [x] RLS suites; contract validation; verify green, coverage >= 80 %: see Handover (341 tests, 96.3 % lines)

## Handover

### Built
Everything in `services/athlete-service` (plus this file); no other module touched, no git commands.
- **Flyway `V2__plans.sql`** (only version taken; WP10 may use V3): `training_plan`, `plan_item`, `plan_assignment`, `plan_completion`,
  and a (not valid) FK `training_session.plan_id -> training_plan` with `on delete set null`. **`R__plan_templates.sql`**: ten global
  templates (warm-up & mobility, ball handling basics, form shooting, free-throw routine, finishing at the rim, defensive footwork,
  conditioning (intervals), passing & decision making, rebounding & box-out, cool-down & stretching), 5-6 timed items each,
  `locale='en'`, uuid5 ids, upserts + delete/insert of the template's items.
- **domain**: `TrainingPlan` (items numbered from 0, `copiedBy`, `reordered`, `requireEditable` -> 403 `PLAN_IS_TEMPLATE`), `PlanItem`,
  `PlanAssignment` (XOR -> 422 `ASSIGNMENT_TARGET_REQUIRED` / `ASSIGNMENT_TARGET_AMBIGUOUS`), `PlanCompletion`, `PlanProgress`,
  `CompletionStatus`, `PlanId`, `PlanItemId`, `AssignmentId`.
- **application**: `ManagePlans` (list/get/create/patch/archive/delete/copy, items add/patch/delete/reorder), `ManageAssignments`
  (create/get/list/delete, read-time fan-out), `ManageCompletions` (record/list/progress), `PlanAccess` (the plan authz rules),
  ports `PlanRepository`, `AssignmentRepository`; `ManageSessions` validates `planId` (404 when unknown) and `ReportUsage` reports
  `trainingPlans` and `planAssignments`.
- **adapters**: `TrainingPlanResource`, `PlanAssignmentResource` (incl. `PUT .../completions/{playerId}`), `PlanCompletionResource`,
  `PlanDtos`, `AssignmentDtos`; persistence `PlanJpaRepository`, `AssignmentJpaRepository`, entities.
- Contract operations implemented: all of `TrainingPlans` (list, create, get, update, delete, copy, addItem, reorder, updateItem,
  deleteItem), `PlanAssignments` (list, create, get, delete), `PlanCompletions` (record, list). Not in the contract and not exposed:
  archive/unarchive and progress (use cases exist and are tested, see open points).

### How verified (fresh `source scripts/env.sh && ./mvnw -pl services/athlete-service clean verify`, 2026-11-02)
**BUILD SUCCESS, 341 tests (was 181), 0 failures/errors/skipped, no compiler warnings, coverage gate met. JaCoCo lines 96.3 %
(1566/1626), branches 86.3 % (442/512); `domain` 95.8 % lines, `application` 97.8 %.**
New tests (160): `TemplateRlsIsolationTest` (7), `TemplateSeedTest` (2), generic RLS suite now 6 tables + meta-test, `PlanDomainTest` (13),
`TrainingPlanApiTest` (9), `SessionPlanApiTest` (4), `PlanAssignmentApiTest` (9), `PlanCompletionApiTest` (5), `PlanRoleMatrixTest`
(102 parameterised cases), `PlanProgressTest` (3), `PlanArchiveTest` (2) and an extended `UsageAndInternalApiTest`. All REST calls go
through `ApiSupport` (request + response validated against `athlete.yaml`).

### TDD log (first failing test per feature, red seen before the code)
| Feature | First failing test and why |
|---|---|
| RLS on plans | `TemplateRlsIsolationTest`, `AthleteRlsSchemaMetaTest`: relation `athlete.training_plan` does not exist. Then green except `aTenantCannotUpdateOrDeleteATemplate`: **a single `FOR ALL` policy let a tenant DELETE a template** (DELETE only evaluates USING) -> split into select/insert/update/delete policies |
| Generic RLS for assignment/completion | `AthleteGenericRlsIsolationTest` fixtures written first (tables missing) |
| Domain | `PlanDomainTest`: compilation failure (no classes), then green |
| Plans / items / copy / templates | `TrainingPlanApiTest`: 8 of 9 failed (404), 1 error; then the `:copy` path (see decisions) and a missing `@TestSecurity` were test-side fixes |
| Session plan attach | `SessionPlanApiTest.anUnknownPlanIsRejected` (500 FK violation instead of 404), `SessionApiTest.patchChanges...` had to use a real plan |
| Assignments, completions, role matrix | all 116 cases red (404), 7 later failed on test-data accumulation (fixed in the tests: own teams per test, containment asserts) |
| Usage counters | `UsageAndInternalApiTest.usageCountsTheTenantsDataOnly` red on `counters.trainingPlans` |
| Honest deviations | `ManageCompletions.progress`, `ManagePlans.setArchived` and the repositories were written in the same pass as the use cases they belong to; `PlanProgressTest`, `PlanArchiveTest`, `TemplateSeedTest` were written after the code and passed on first run (not seen red) |

### Decisions
- **Column `owner_tenant_id`, not `tenant_id`** (brief said `tenant_id null`). The common `RlsSchemaInspector` fails every table that has a
  `tenant_id` column which is not `uuid not null`, and `GenericRlsIsolationTest` asserts "A sees exactly its own row" (templates would
  break it); neither can be extended from a service (no hook, `libs/` is off limits). With a differently named column both tables are
  "global" for the meta-test and are allow-listed in `AthleteRlsSchemaMetaTest.globalTables()` with the reason; `TemplateRlsIsolationTest`
  additionally asserts RLS enabled + forced + a policy on `app.current_tenant()` for exactly these two tables. Candidate for common: a
  `nullableTenantTables()` hook.
- **Policies per command**: select `owner is null or owner = current`; insert/update/delete `owner = current`. Tenants cannot update, delete,
  insert templates, nor turn a plan into a template or hand it to another tenant. `plan_item` has a composite FK `(plan_id, owner_tenant_id)`
  so an item cannot point at another tenant's plan (RI checks bypass RLS).
- **Seeding under FORCE RLS**: the migrator is subject to the forced policies too, so `R__plan_templates.sql` does `NO FORCE`, upserts, `FORCE`
  inside the Flyway transaction (DDL is transactional; `TemplateSeedTest` checks FORCE is back and a double run changes nothing).
- **Entities without `@TenantId`** for plan/item (Hibernate's discriminator filter would hide templates); RLS is the only filter, and the
  repository sets `owner_tenant_id` from `CurrentTenant`. Assignment/completion entities use `@TenantId` as in WP8.
- **Contract wins over the brief**: items have `durationMinutes/sets/repetitions/videoUrl` (no `category`), assignment has `notes`
  (not `note`), completion has `comment` and an `id` (extra column `plan_completion.id`, unique), plans expose `sourceTemplateId`;
  template deletion/edit is **403** (contract) with code `PLAN_IS_TEMPLATE`; assigning a template is **422** `PLAN_IS_TEMPLATE`.
  `name_key` column skipped: the contract has nowhere to expose it; the UI maps template names by their stable ids.
- Problem codes: `PLAN_IS_TEMPLATE`, `PLAN_HAS_ASSIGNMENTS` (409), `PLAN_ARCHIVED` (422), `ITEM_ORDER_MISMATCH`, `INVALID_ITEM`/`INVALID_PLAN`,
  `ASSIGNMENT_TARGET_REQUIRED/AMBIGUOUS`, `PLAYER_NOT_IN_TEAM` (team assignment), `PLAYER_NOT_TARGETED` (player assignment).
- **Authz**: write plans = ADMIN or any COACH/ASSISTANT_COACH (matrix has no team qualifier); assign to a team = ADMIN or staff of it; to a
  player = ADMIN (player must exist in core) or staff of a team whose roster has the player (via `RosterPort.teamRoster`, stale teams skipped);
  withdraw = same as assign; mark completion = ADMIN, staff of the team (player assignment: of a team the player is in), guardian, the player
  himself; reads: staff roles see all assignments of the tenant (consistent with WP8; the brief said "their teams"), PARENT/PLAYER only
  assignments that target their players, else 404; naming another player in a filter is 403. Order of checks: role (403) -> visibility (404) ->
  relation (403) -> target (422).
- **Fan-out**: no tenant-wide "teams of a player" exists, so list-by-player takes the teams that currently have a team assignment and keeps those
  whose (cached) roster contains the player. PARENT/PLAYER lists without `teamId` therefore work (the WP8 gap does not apply here).
- **`:copy` in tests**: swagger-request-validator only matches `{planId}:copy` when the colon is not percent-encoded, so tests call it with
  `urlEncodingEnabled(false)` (`TrainingPlanApiTest.copy`).
- Sessions: `planId` must exist (a plan or a template is fine) else 404; `TrainingSession.edited` already sets `manually_edited`, so a
  materialised session with a plan survives a re-plan (`SessionPlanApiTest`); deleting a plan detaches it (FK `set null`).
- Plan deletion with assignments is 409; archived plans are excluded from lists and cannot be assigned (422).
- Roles in lists: plan list `template=false` returns only the tenant's non-archived plans, `template=true` only templates, `q` is a
  case-insensitive substring of the name.

### How WP10 should extend it
Add `V3__health.sql` (do not touch V2/R__); fixtures for new tenant tables in `AthleteGenericRlsIsolationTest.fixtureOverrides()`. Reuse
`TrainingAccess`, `PlanAccess.teamsOf/isStaffOfPlayer` (package-visible helpers for "staff of a team of this player"), `CallerActor`,
`PatchBody` (now with `nonBlankText`), `Requests` (now with `bool`), `PageDto`, `ApiSupport`, `RoleMatrixTest.Caller` constants for matrix tests
(`PlanRoleMatrixTest` shows the pattern, including unique ids per test to avoid data accumulation). Extend `ReportUsage` the same way as here.

### Open points
- Contract additions wanted (libs/contracts owner): an archive operation for plans (`archived` exists in DB and use case `ManagePlans.setArchived`,
  list excludes archived), a progress operation (`GET /plan-assignments/{id}/progress`; use case `ManageCompletions.progress` is ready), an
  optional `nameKey`/`locale` on `TrainingPlanSummary`, and `validation` note about `:copy` encoding for the validator.
- `training_session_plan_fk` is `NOT VALID` (V1 never checked old values); validate it after cleaning data.
- Fan-out cost grows with the number of distinct teams having assignments (one cached roster call each, 30 s TTL); fine for an academy, revisit
  with a local replica of rosters (ADR-0008 v2).
- Common-quarkus candidate: hook for tables with a nullable tenant column (see decisions).
