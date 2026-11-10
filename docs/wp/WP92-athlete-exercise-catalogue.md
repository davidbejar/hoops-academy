# WP92 — Athlete + web: exercise catalogue

Model: Opus · effort high. Wave 1 (2026-11-10, sixth round): runs alongside WP91 (core-service, core contract),
WP93 (workflows, hooks, doctor), WP94 (model diagrams), WP95 (web kit, `features/audit`, `features/landing`). You
own `services/athlete-service`, `libs/contracts/openapi/athlete.yaml` and its contract tests,
`apps/web/packages/athlete` (regenerate with `scripts/gen-api.sh athlete` only), `apps/web/lib/features/training/**`
with its tests and goldens, the athlete part of `apps/web/lib/core/mock`, Flyway athlete `V10` (reserved), ADR-0047
(reserved). Shared files: `apps/web/lib/l10n/*.arb` (keys next to the training keys, never at the end),
`docs/adr/README.md` and `docs/domain/authz-matrix.md` (append at the end), `UpdateRequestClearListContractTest`
(append at the end). Do not change the shared web kit (`apps/web/lib/core/design`, `core/ui`): WP95 owns it this
wave; say in the handover what you would need. Depends on: decisions 54 and 72, ADR-0041 (WP78: sessions reference
plans, item search, quick-add), ADR-0032 (clear lists). Skills: quarkus-hexagonal-service, tenant-isolation-testing,
flutter-feature, test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp92-athlete-exercise-catalogue`, branch `wp92-athlete-exercise-catalogue`.

Decision 72 of 2026-11-10: exercises become their own entity (global localised ones plus tenant-defined). The
migration turns each distinct item of the seeded global templates into a catalogue exercise in es / en / id and adds
the Cooper test; templates reference exercises; tenant plan items and session items keep their own text and gain an
optional exercise reference, so nothing a coach wrote changes. Athlete 3.0.0.

## Scope
1. **Contract athlete → 3.0.0** (breaking; list every breaking point in ADR-0047): `Exercise` with list and search
   (`q`, scope global or tenant, paging), read, and create / update / archive for tenant-defined ones (global ones
   are read-only and localised by `Accept-Language`, as templates are today); template items carry the `exerciseId`
   they reference; plan items and session items gain an optional `exerciseId`; adding an exercise to a plan or a
   session copies its text into the item and keeps the reference. Decide what happens to WP78's search inside
   templates (keep, or replace by the exercise search) and write it down.
2. **Data** (`V10`): the exercise table(s) following exactly the pattern the global templates use for rows without
   an academy, tenant-defined rows as a tenant table through `app.enable_tenant_rls`; both covered by
   `RlsSchemaMetaTest` and `GenericRlsIsolationTest`. Data migration as decided: distinct seeded template items →
   global exercises (three languages), the Cooper test added, template items pointed at them; tenant rows only gain a
   nullable reference. The migration must be safe on a database with tenant data (the compose database has it).
3. **Service**: use cases and authorisation per `docs/domain/authz-matrix.md` (who manages plans manages
   tenant exercises; everyone who reads plans reads exercises); non-members 404; role-matrix tests; an archived
   exercise stays readable where it is referenced.
4. **Web** (`features/training`): an exercise catalogue with search; quick-add from the catalogue on the session
   screen, in the "new session" dialog and in the plan editor (`copyItemsToPlan` is in the contract and not wired
   yet); create and edit tenant exercises; es / en / id; mock parity; goldens for the new screens. Offline rules of
   the `flutter-feature` skill.
5. **Docs**: ADR-0047 (model, migration, breaking points, alternatives); authz matrix rows.

## Acceptance
- [ ] Contract 3.0.0 validated; Dart athlete package regenerated and committed (only yours); `pubspec.lock` only
      with the package version bump
- [ ] Red tests committed before each change; RLS suites green for the new tables
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `flutter analyze` clean;
      `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] `just mutation athlete-service` at or above the baseline (record the score)
- [ ] The migration proven on a copy of seeded data (a test that migrates a V9 database with templates, plans and
      session items and checks nothing a tenant wrote changed)
- [ ] Handover appended: breaking points, what the user guides must say, kit wishes

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the line
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Never restart the Podman machine or its API service, never
  run `just down` or remove volumes: other agents use the same VM and compose stack.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/guides; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words: what was built, the
  fresh verification totals, versions and ADRs, open points, anything another WP must know.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
- Built:
  - **Contract athlete 3.0.0**: `/api/athlete/exercises` (list with `q`, `scope` GLOBAL|TENANT, `includeArchived`,
    paging, `Accept-Language`; get; create / update (`clear` list) / `:archive` / `:unarchive` for the academy's own);
    `PlanItem.exerciseId`, `PlanItemMatch.exerciseId`; `PlanItemRef` replaced by `PlanItemSource` (exactly one of
    `exerciseId` or `planId`+`itemId`); 422 `EXERCISE_ARCHIVED` on quick-add. `ExerciseCatalogueContractTest` (19),
    version pin and `UpdateExerciseRequest` in `UpdateRequestClearListContractTest`. Dart package regenerated (content
    changes only), `pubspec.lock` = version bump only; `PlanItemRef` renamed in the web code.
  - **Data**: V10 `athlete.exercise` (one nullable-owner table, per-command RLS like templates/test types, checks keep
    key/i18n on globals, globals never archived) + `plan_item.exercise_id` (FK `NOT VALID`, as V7).
    `R__exercise_catalogue.sql`: 59 distinct template items + `cooper-test` (60, en/es/id); `R__plan_templates.sql`
    builds template items from their exercise (same item ids, template's own duration). Tenant rows: nothing changes,
    reference null (no title backfill).
  - **Service**: domain `Exercise`, `ExerciseId`, shared `ItemContent` limits, `PlanItem` keeps its reference through
    copy/edit/localize; `ManageExercises`, `ExerciseRepository`/JPA, `ExerciseResource`; `QuickAddItems` takes
    `FromExercise` / `FromPlan` sources. Authz: plan managers write, every role reads, globals 403 `EXERCISE_IS_GLOBAL`,
    other academies 404.
  - **Web** (sub-agent, `features/training`, mock, l10n, goldens): red tests committed (`71e364e`); implementation was
    still in progress and uncommitted when this handover was written (see Open points).
- Verified:
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` (fresh, after the service commits): **BUILD SUCCESS**;
    athlete 1000, core 994, game 468, common-quarkus 392, contracts 298, e2e 32 (26 skipped off compose); jacoco checks
    met in every module.
  - `just mutation athlete-service`: **713 / 713 killed, 100 %** (baseline 100; was 687).
  - `ExerciseCatalogueMigrationTest` migrates a V9 database (template seed of V9 as a test fixture) holding an academy's
    plan, items (one a template copy), a session with its own plan and one on a template; every academy row is equal
    after V10 + seeds. Proven to fail when a seed touches tenant items.
  - Web: `flutter analyze` clean after the `PlanItemSource` rename (contract commit). Full `flutter test`,
    `web-format-check` and the goldens of the web part: **not verified by me**.
- Decisions/ADRs: **ADR-0047** (one table instead of the brief's "tenant table through `enable_tenant_rls`": the helper
  needs `tenant_id not null`, globals cannot have it, and one FK / one paged query beat two tables; breaking points;
  plan search of 2.3.0 kept); ADR index and three authz-matrix rows appended.
- Open points / follow-ups:
  - Web half: finish, commit and verify (`flutter test`, analyze, format, goldens); the sub-agent also touched
    `lib/core/http/mock_api_adapter.dart` and `lib/core/mock/mock_state_log.dart` (shared mock plumbing).
  - User guides must say: the catalogue (global exercises read-only, own exercises created/edited/archived by
    coaches), "add exercises" from the catalogue in session, new-session dialog and plan editor, items keep their own
    text, archived exercises stay on items, the Cooper test is in the catalogue (not in a template).
  - `just e2e` not run (compose DB shared; V10 would be applied there). `docs/quality/mutation.md` athlete row not
    updated (713 mutants).
  - Kit wishes: none recorded by me; see the web sub-agent's report.
