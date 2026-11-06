# WP39 — Athlete: `clear` list on update requests, test-type code edit and delete

Model: Opus. Wave 1 (2026-11-06): runs alongside WP38 (core) and WP40 (gateway); disjoint files except
`apps/web/lib/l10n/*.arb` (add your keys next to the existing training/health keys, not at the end of the file).
Depends on: WP35 (its handover lists the limits), WP29 (ADR-0027: no `allOf`, strict validator). Skills:
quarkus-hexagonal-service, tenant-isolation-testing, flutter-feature, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp39-athlete-clear`, branch `wp39-athlete-clear`.

Decision 17 of 2026-11-06: update requests get a `clear` list. A field absent or `null` in the body is unchanged (as
today); a field named in `clear` is set to null / detached. This is the repository convention for every
`Update*Request` from now on (ADR-0032, number reserved for you); only the athlete contract adopts it in this WP.
Decision 20: a custom physical test type can have its `code` changed and can be deleted.

## Scope
1. **ADR-0032** `docs/adr/0032-update-requests-clear-list.md`: the convention (`clear: [string]`, an enum of the
   clearable property names per request so the strict validator rejects typos; `clear` wins over a value for the
   same field → 400; required fields are never clearable), why not explicit-null tri-state (generated Dart clients
   cannot distinguish absent from null), how core and game adopt it later. Add the row to `docs/adr/README.md` and a
   paragraph to `libs/contracts/README.md` (conventions section).
2. **Contract** (`libs/contracts/openapi/athlete.yaml`, minor bump 2.0.1 → 2.1.0): `clear` on
   `UpdateTrainingSessionRequest` (planId, location, notes), `UpdatePlannedAbsenceRequest` (reason, …),
   `UpdateBodyMeasurementRequest`, `UpdatePhysicalTestResultRequest` (notes, …), `UpdateInjuryRequest`,
   `UpdateTrainingPlanRequest`, `UpdatePlanItemRequest`, `UpdateTrainingScheduleRequest`,
   `UpdatePhysicalTestTypeRequest`: every optional, nullable-in-storage property of each, nothing else. Add `code`
   to `UpdatePhysicalTestTypeRequest` (same pattern as on create; 409 when another type of the tenant has it; global
   types are read-only as today) and `deletePhysicalTestType` (`DELETE /physical-test-types/{id}`: 204; 404 for a
   global type or another tenant's; 409 `problem` when results reference it, so data is never orphaned). Keep the
   conventions test and the strict validator green: `./mvnw -pl libs/contracts verify`, then `just gen-api` and
   commit the regenerated `apps/web/packages/athlete`.
3. **Service**: use cases honour `clear` (test first, per request type: cleared field is null afterwards, a field in
   both `clear` and the body is a 400 problem, an unknown name is rejected by validation); test-type rename and delete
   with the 409 rule; role matrix tests for the new operation (`docs/domain/authz-matrix.md` row: same roles as
   `updatePhysicalTestType`). RLS suites need no new table.
4. **Web** (`apps/web/lib/features/training`, `features/health`): the edit dialogs from WP35 send `clear` when the
   user empties a field or detaches the plan; test types: code editable for custom types, delete with confirmation
   and the 409 shown as "This test type has results and cannot be deleted". Widget tests first; goldens only where a
   screen changed (list them).
5. **Demo mock** (`apps/web/lib/core/mock`): do not touch; WP41 adds athlete mock support after you merge.

## Acceptance
- [ ] ADR-0032 written and indexed; contract 2.1.0 validated; Dart package regenerated and committed
- [ ] Red test committed before each change (contract conventions test if needed, use cases, resources, widgets)
- [ ] `./mvnw -B -ntp -T 1C verify` green (fresh; totals); `cd apps/web && flutter analyze` clean; `just web-test`
      green (fresh; totals)
- [ ] Authz matrix updated; handover appended with the list of request types that gained `clear`

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: if a Testcontainers run fails with "localhost:2375 failed to respond" or a
  port clash, re-run that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - ADR-0032 (`docs/adr/0032-update-requests-clear-list.md`, indexed; convention paragraph in `libs/contracts/README.md`).
  - Contract athlete **2.1.0**: `clear` (array, `uniqueItems`, `enum` of exactly the optional nullable properties) on the
    nine update requests: `UpdateTrainingSessionRequest` (location, planId, notes), `UpdatePlannedAbsenceRequest`
    (reason), `UpdateBodyMeasurementRequest` (heightCm, weightKg), `UpdatePhysicalTestResultRequest` (notes),
    `UpdateInjuryRequest` (description, expectedReturnOn, actualReturnOn), `UpdateTrainingPlanRequest` (description),
    `UpdatePlanItemRequest` (description, durationMinutes, sets, repetitions, videoUrl), `UpdateTrainingScheduleRequest`
    (location, validUntil), `UpdatePhysicalTestTypeRequest` (description). `code` on `UpdatePhysicalTestTypeRequest`
    (409 `TEST_TYPE_CODE_EXISTS`), new `deletePhysicalTestType` (204; 404 global / other tenant; 409
    `TEST_TYPE_HAS_RESULTS`; the tenant's norms of the type go with it, FK cascade). Enforced by
    `UpdateRequestClearListContractTest` (adopted specs: athlete only). Dart package `apps/web/packages/athlete`
    regenerated (generator whitespace normalised like earlier commits; core/game regenerations were noise and not committed).
  - athlete-service: `PatchBody` takes each request's clearable set; absent or `null` = unchanged, `clear` = null, value +
    `clear` = 400 `CLEAR_CONFLICT`, unknown/duplicate/non-clearable name = 400 on `clear`. Test types: code change (domain
    `changedTo(code, …)`, entity code updatable), `ManageTestTypes.delete`, `TestResultRepository.existsForType`.
    Authz matrix row "Physical test types and norms" (ADMIN write, others read).
  - Web: `core/api/clear_list.dart` (`clearList`); the session, schedule, absence, plan-item, measurement, result and
    test-type edit forms (and `PlanDetailNotifier.rename`) name every optional field left empty; the session dialog now
    always offers "no plan" (detaches). Test types: code editable, delete with confirmation, 409 shown as
    `testTypeHasResults`; the type chip moved into the subtitle so edit + delete fit at 360 px. New l10n keys
    `testTypeDeleteConfirm`, `testTypeDeleted`, `testTypeHasResults` (es/en/id). Demo mock untouched.
- Verified (fresh, 2026-11-06): `./mvnw -B -ntp -T 1C clean verify` BUILD SUCCESS, 2,015 JVM tests (contracts 151,
  common-quarkus 186, core 770, game 255, athlete 653), all coverage checks met; `./mvnw -pl libs/contracts verify` green
  incl. openapi-generator validate; `just mutation athlete-service` 430/430 killed (100 %); `flutter analyze` no issues;
  `just web-test` 623 passed. Goldens: none changed (the test-types screen has no golden).
- Decisions/ADRs: ADR-0032. An explicit `null` in an athlete PATCH body used to clear (merge patch, never documented in
  the contract, never sent by the Dart client); it is now "unchanged" per decision 17 — the service tests that relied on
  it were rewritten to `clear`. Delete of a global type is 404 (brief), while PATCH of a global type stays 403.
- Open points / follow-ups: core (still merge patch: `null` clears) and game adopt ADR-0032 in their own WPs (add the spec
  to `ADOPTED` in the contract test); no web dialog edits an injury's description / dates, so `UpdateInjuryRequest.clear`
  is unused by the app so far; WP41 adds athlete mock support (including `deleteType`).
