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
