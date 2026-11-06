# WP78 — Athlete: session references any plan directly; exercise search inside templates; quick-add

Model: Opus. Wave 1 (2026-11-06, fifth round): runs alongside WP72 (web design system: `lib/app`, `lib/core/ui`,
`lib/core/design`), WP81 (core), WP83 (workflows), WP87 (chart). You own `libs/contracts/openapi/athlete.yaml`,
`apps/web/packages/athlete`, `services/athlete-service` and Flyway `V7` (reserved), and under the web only
`apps/web/lib/features/training/**` (session dialog/screen, plan picker, search) and its tests; `lib/core/mock`
(the demo mock's athlete part: keep parity). `apps/web/lib/l10n/*.arb`: keys next to the training keys, never at the
end. `apps/web/pubspec.lock`: commit only with the generated-package bump. Shared test list
`libs/contracts/src/test/java/com/hoopsacademy/contracts/UpdateRequestClearListContractTest.java`: update the athlete
version pin (one line). Depends on: WP9 (plans/templates), WP61 (template i18n, ADR-0039), WP29/ADR-0027. ADR-0041
reserved for you. Skills: quarkus-hexagonal-service, tenant-isolation-testing, flutter-feature,
test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp78-athlete-session-plans`, branch `wp78-athlete-session-plans`.

Decisions 53 and 54 of 2026-11-06: a session item references any plan directly (tenant plan or global template) by
id, no assignment needed; assignment stays as an optional shortcut; templates stay read-only. The plan/session search
finds an exercise inside a template ("cooper" finds the Cooper test item) and one or several template items can be
quick-added to a session or a plan without going through the template. The exercise catalogue entity is next round.

## Scope
1. **Contract athlete 2.2.0 → 2.3.0**: `CreateTrainingSessionRequest.planId` / update accept any readable plan
   (tenant plan, or template) with no assignment prerequisite (find and remove the rule in `ManageSessions`, keep
   the 404 for plans of other tenants); document in the description which plans a COACH may pick (own teams' tenant
   plans + templates). `GET /api/athlete/training-plans?q=` already searches names: extend `q` to match item titles
   (localised, ADR-0039) and return `matchedItems` (id, title, planId) in the summary so the UI can show "found in
   template X: Cooper 12 min". New `POST /api/athlete/training-sessions/{sessionId}/items` (or a plan-level
   `POST /training-plans/{planId}/items:copy`): copies one or several items (by `planId` + `itemId`) into the target
   session's plan (sessions carry a plan: decide whether a session without a plan gets an ad-hoc tenant plan created
   on first quick-add, and say so in ADR-0041). Items keep their localised text at copy time.
2. **Data** (`V7`): whatever the ad-hoc session plan needs (e.g. `training_plan.ad_hoc_for_session`), tenant
   tables with RLS via the helper, covered by the generic suites; a trigram or `ILIKE` index for the item search.
3. **Service**: red tests per rule (direct template reference allowed; assignment not required; search by item title in
   es/en/id; copy items; COACH scope; 404 for foreign tenant; templates still read-only).
4. **Web** (`features/training`): session dialog plan picker lists tenant plans and templates (grouped), with the
   search box; search results show item matches with the template name; quick-add from a result into the session
   (multi-select); the demo mock serves the same. Widget tests first. Keep the current look (WP73 restyles in wave 2).
5. **Docs**: ADR-0041 (sessions reference plans directly; search semantics; quick-add copies; the catalogue entity
   deferred); `docs/domain/authz-matrix.md` rows for the new endpoint (append at the end).

## Acceptance
- [ ] Contract 2.3.0 validated; Dart athlete package regenerated and committed (only yours); `pubspec.lock` updated
- [ ] Red tests committed before each change; RLS suites green for new tables;
      `./mvnw -B -ntp -pl services/athlete-service -am verify -Dquarkus.http.test-port=0` green (totals) and
      `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] `just mutation athlete-service` at or above baseline (record the score); `just e2e` 23/23 on compose
      (coordinate the compose stack with WP83 through the orchestrator: say when you start and finish)
- [ ] ADR-0041 written and indexed (append at the end of `docs/adr/README.md`); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - **Contract athlete 2.3.0** (`athlete.yaml`): `planId` on session create/update documented as "any readable plan"
    (tenant plan or template, no assignment; foreign = 404; another session's own plan = 422
    `PLAN_OF_ANOTHER_SESSION`); `q` on `listTrainingPlans` also matches item titles and returns `matchedItems`
    (`PlanItemMatch`: id, planId, title); new `copyItemsToSession` (`POST /training-sessions/{id}/items`) and
    `copyItemsToPlan` (`POST /training-plans/{id}/items:copy`) with `CopyPlanItemsRequest` (1–50 `PlanItemRef`);
    `sessionId` on plans. `TrainingPlanSummary`/`TrainingPlan` now share the mixin `TrainingPlanFields` (only the summary
    has `matchedItems`). Version pin in `UpdateRequestClearListContractTest` updated.
  - **Service**: there was no assignment rule in `ManageSessions` to remove (it only checked existence); the check is
    now `requireAttachable` (exists under RLS + not another session's own plan). `QuickAddItems` (new use case): copies
    localized items (fresh ids) into a tenant plan, or into the session's own plan, created on first use (empty and
    named "Sesión/Session/Sesi <day>", or copy on write of the template/shared plan it referenced). Leaving the own
    plan deletes it; it is never listed or assignable (422 `PLAN_OF_A_SESSION`). Item search: correlated EXISTS on the
    shown title (same coalesce rule as names). Domain: `TrainingPlan.forSession/adHocCopyFor/withCopiesAppended/
    itemsMatching/requireAttachableTo`, `TrainingSession.withPlan/requireChangeable`. `PlanRepository.exists` removed
    (unused).
  - **V7** `training_plan.ad_hoc_for_session` (+ composite FK to `training_session (tenant_id, id)` on delete cascade,
    added NOT VALID because validation scans under forced RLS; unique partial index; check tenant rows only). No new
    table, so the generic suites are unchanged; `TemplateRlsIsolationTest` proves the FK keeps a plan on a session of its
    own tenant and one plan per session.
  - **Web** (`features/training`): `PlanPickerDialog` (academy plans and templates grouped, search box, "Encontrado: …"
    under plans found by an exercise) replaces the dropdown in `SessionDialog` (warns when leaving the session's own
    plan); session screen lists the plan's exercises, marks the own plan and has "Añadir ejercicios"
    (`ExerciseSearchDialog`: multi-select across searches; a plan found by name offers all its exercises). Repository
    `copyItemsToSession`, provider `planSearchResultsProvider`, 12 l10n keys after `sessionCancelled` (es/en/id). Demo
    mock: same rules, plus an "Acondicionamiento" template with "Test de Cooper 12 min" so "cooper" works in the demo.
    Athlete package regenerated (only files with content changes committed; whitespace-only regenerations dropped).
- Verified:
  - `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` (fresh, host load 10–48): common-quarkus 186,
    contracts 223, core 871, game 411, e2e module 27 (23 skipped off compose): **all green**; athlete 818: 1 failure +
    the flake below. The failure was real and pre-existing: `ScheduleApiTest.endingAScheduleRemovesFutureSessions…`
    used FRIDAY 19:00 Europe/Madrid and fails every Friday after 19:00 (today's session is no longer "future"); fixed
    (tomorrow's weekday, commit `385cc40`), 15/15 green at a time the old version failed.
  - `./mvnw -B -ntp -pl services/athlete-service -am verify -Dquarkus.http.test-port=0`: **not green in a single run**.
    5 of 5 runs (host load 10–48, 2-CPU Podman VM shared with 4 worktrees) hit the documented FOLLOW-UPS flake: Dev
    Services cannot create the Redpanda container for `ReplicaAuthzRulesTest` right after `RealResolverApiTest`'s
    profile shuts down ("localhost:2375 failed to respond", `[Error Occurred After Shutdown]`). 739 other tests green.
    The 12 classes it skips (96 tests, all RLS suites included) are green when run on their own, and so is the
    `RealResolverApiTest` → `ReplicaAuthzRulesTest` transition (4 classes, BUILD SUCCESS, 561 s under load).
    `jacoco:check` on that run's data passes: lines **97.4 %**, domain **100 %**, application 98.5 %;
    `QuickAddItems`, `TrainingPlan`, `ManagePlans`, `PlanJpaRepository` 100 %.
  - `just web-format-check` 0 changed; `flutter analyze` no issues; `flutter test` **791 passed** (training 73).
  - `just mutation athlete-service`: **495 mutants, 495 killed, 100 %** (baseline 100).
  - `just e2e` on compose: **JourneyTest 23/23** (+ MailSinkTest 4/4). The first attempt failed in core's Flyway
    validation because WP81's core V15 was applied on the shared DB; re-run with
    `QUARKUS_FLYWAY_IGNORE_MIGRATION_PATTERNS='*:future,*:missing'` in the environment (not committed).
- Decisions/ADRs: **ADR-0041** (direct reference, search semantics, quick-add copy on write into the session's own
  plan, its lifecycle, no trigram index, catalogue deferred), indexed at the end of `docs/adr/README.md`; two rows
  appended to `docs/domain/authz-matrix.md`.
- Open points / follow-ups:
  - Trigram index for the item search needs `pg_trgm` created in `infra/db/init` (and the chart's init); the migrator
    cannot create extensions.
  - The seeded templates have no Cooper item; the exercise catalogue (next round) should bring it.
  - Quick-add is only on the session screen (needs a session id), not in the "new session" dialog, and not wired in the
    plan editor although `copyItemsToPlan` exists (WP73 restyles these screens next wave).
  - Changing a q that used to match only names: "Warm-up" now also returns templates with a warm-up exercise
    (`TrainingPlanApiTest` adapted).
  - athlete V7 is applied on the compose DB used by the other worktrees (Flyway treats it as a future migration).
  - The athlete Testcontainers flake (above) now hits every full module run on a loaded host; it needs the fix noted in
    FOLLOW-UPS (stale docker-java connection to the Podman socket after a Dev Services shutdown).
