# WP44 — Core adopts the `clear` list (ADR-0032)

Model: Opus. Wave 2 (2026-11-06, third round): starts after wave 1 is merged; runs alongside WP45 (game). You own
`libs/contracts/openapi/core.yaml`, `apps/web/packages/core`, `services/core-service`, the web features that edit core
objects and `apps/web/lib/core/mock/mock_core_api.dart`; you also own the shared contracts test
`UpdateRequestClearListContractTest` (WP45 adds one game line to it at the end; keep core's block above it).
`apps/web/lib/l10n/*.arb`: add keys next to the related feature's keys, never at the end of the file. Depends on:
WP39 (ADR-0032, the athlete implementation to mirror). Skills: quarkus-hexagonal-service, tenant-isolation-testing,
flutter-feature, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp44-core-clear`, branch `wp44-core-clear`.

Decision 26 of 2026-11-06: every service follows ADR-0032. Today core clears a field on an explicit JSON null, which
the generated Dart client cannot send; after this WP null means unchanged and `clear` names the fields to empty.

## Scope
1. **Contract** (`core.yaml`, minor bump 2.6.0 → 2.7.0): `clear` (unique list, enum of the request's optional
   nullable-in-storage properties, as WP39 did) on `UpdateTenantAdminRequest`, `UpdateTenantRequest`,
   `UpdateMeRequest`, `UpdateTenantProfileRequest`, `UpdateMemberRequest`, `UpdateSeasonRequest`,
   `UpdateAgeCategoryRequest`, `UpdateTeamRequest`, `UpdateTeamPlayerRequest`. A request with no clearable property
   gets no `clear` (say which in the handover). Extend `UpdateRequestClearListContractTest` to core. `./mvnw -pl
   libs/contracts verify`, `just gen-api`, commit only `apps/web/packages/core`.
2. **Service**: mirror WP39 (`PatchBody` or the equivalent core helper; 400 `CLEAR_CONFLICT` when a field is both
   given and cleared; null = unchanged). Test first per request type; find every existing test that relied on
   null-clears and switch it to `clear`. The shared-login e-mail rule (ADR-0026) and the audit rows are unaffected,
   but say so with the test that proves it.
3. **Web**: every core edit dialog (tenant profile, member, season, age category, team, team player, me, platform
   tenant and admin) names emptied optional fields in `clear`; `mock_core_api.dart` honours `clear` the same way.
   Widget tests first; goldens only where a screen changed (list them).
4. **Docs**: ADR-0032 gains an "Adoption" line for core; `docs/domain/authz-matrix.md` unchanged unless a rule moved.

## Acceptance
- [ ] Contract 2.7.0 validated; Dart core package regenerated and committed
- [ ] Red tests committed before each change (contracts, use cases/resources, widgets)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `flutter analyze` clean;
      `just web-test` green (fresh; totals)
- [ ] `just mutation core-service` at or above baseline (record the score)
- [ ] Handover appended with the request types that gained `clear` and the tests that changed from null to `clear`

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - Contract core **2.7.0**: `clear` (array, `uniqueItems`, enum of exactly the optional nullable properties) on
    `UpdateTenantProfileRequest` (contactEmail, websiteUrl), `UpdateMemberRequest` (email, phone, birthDate, gender),
    `UpdateAgeCategoryRequest` (maxAge), `UpdateTeamRequest` (alias), `UpdateTeamPlayerRequest` (jerseyNumber; no
    longer `required`, now `minProperties: 1`, so `{clear: [jerseyNumber]}` is the body that removes a jersey).
    **No `clear`** (nothing nullable): `UpdateTenantAdminRequest`, `UpdateTenantRequest`, `UpdateMeRequest`,
    `UpdateSeasonRequest`. `UpdateRequestClearListContractTest`: `ADOPTED = athlete, core` plus a core block
    (exact enums, the four without `clear`, 2.7.0, strict-validator cases); the core block sits above the athlete
    test-type tests, the file is otherwise unchanged. `AuditTrailContractTest` now checks "core ≥ 2.6.0" instead of
    pinning 2.6.0. Dart `apps/web/packages/core` regenerated (athlete/game regeneration noise not committed).
  - core-service: `MergePatch` → `PatchBody` (`adapters/in/shared`). A member is nullable exactly when the resource
    declares it clearable (`UPDATE_CLEARABLE` / `PROFILE_CLEARABLE` next to each resource = the contract enum);
    absent or `null` = unchanged; `null` on a non-clearable member = 400; named in `clear` = set to null; value +
    `clear` = 400 violation code `CLEAR_CONFLICT`; unknown, non-clearable, duplicate or malformed `clear` = 400 on
    `clear` (code `INVALID_VALUE`); `{}` or `{clear: []}` alone = 400. Violations are still collected into one 400.
    `Patch.map` (domain); `TeamPlayerService.renumber` takes a `Patch<JerseyNumber>`, so `{jerseyNumber: null}` is a
    no-op (was 400 "is required").
  - Web: team edit (alias), age-category edit (maxAge) and jersey change (null jersey) send `clear` via `clearList`;
    `mock_core_api.dart` applies profile / category / team / team-player PATCHes through `mockApplyUpdate` (clear
    honoured, value + clear = 400). The academy profile dialog edits no clearable field, there is no member edit
    dialog, and season / me / platform tenant / admin have nothing to clear: unchanged.
  - ADR-0032 "Adoption" gained the core line. `docs/domain/authz-matrix.md` unchanged (no rule moved).
- Tests switched from `null` to `clear` (each now also asserts `null` = unchanged): `AgeCategoryResourceTest`
  (`maxAge`), `TeamResourceTest` (`alias`), `TenantResourceTest.adminEditsTheProfileAndClearsTheNamedFields`
  (`contactEmail`, renamed), `MemberResourceTest.patchClearsOnlyTheNamedFieldsAndKeepsInvariants` (`phone`,
  `birthDate`, `gender` → 422; renamed), `MemberResourceTest.aMemberWithALoginKeepsAnEmail` (`email` → 422
  `LOGIN_REQUIRES_EMAIL`), `TeamPlayerResourceTest.adminAssignsListsRenumbersAndUnassigns` (`jerseyNumber`),
  `MergePatchTest` → `PatchBodyTest`. New 400 cases in `SeasonResourceTest` and `PlatformAdminResourceTest`.
- Unaffected, proven by unchanged green tests: the shared-login e-mail rule (ADR-0026) —
  `MemberResourceTest.emailChangeMovesTheLoginInKeycloakAndCore`, the `LOGIN_SHARED` test,
  `aDeactivatedMembershipElsewhereDoesNotShareTheLogin`, `PlatformAdminResourceTest`; audit rows — the
  `member.updated` and `tenant.profile_changed` assertions now also run on a `clear` (field listed, value not).
- Verified (fresh, 2026-11-06): `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0` BUILD SUCCESS,
  2,034 JVM tests (contracts 155, common-quarkus 186, core 784, game 256, athlete 653; e2e 25 with 21 skipped),
  all coverage checks met; `./mvnw -pl libs/contracts verify` green; `just mutation core-service` 498/499 killed
  (99.8 %, baseline 99.6 %, threshold 95); `flutter analyze` no issues; `just web-test` (flutter test) 656 passed.
  Goldens: none changed (no screen layout changed).
- Open points: the jersey dialog still requires a value (`noteDialog(required: true)`), so the app cannot remove a
  jersey yet although the repository and API can; no web dialog edits a member's personal data or the academy's
  contact e-mail / website, so `UpdateMemberRequest.clear` and `UpdateTenantProfileRequest.clear` are unused by the
  app; `docs/roadmap.md` still lists core under "`clear` list in core and game" (left for the orchestrator, WP45
  edits the same line); a no-op PATCH (`{"phone": null}`) still writes a `member.updated` row with no fields
  (pre-existing behaviour for unchanged values).
