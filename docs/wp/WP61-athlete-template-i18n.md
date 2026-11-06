# WP61 — Athlete: training-plan templates in es/en/id

Model: Opus. Wave 2 (2026-11-06, fourth round): starts after wave 1 is merged; runs alongside WP53 (web mock),
WP55, WP57, WP59 (core contract), WP65. You own `libs/contracts/openapi/athlete.yaml`, `apps/web/packages/athlete`,
`services/athlete-service` and Flyway `V4` (reserved for you; `R__plan_templates.sql` is yours), the web training
plan screens' name rendering (`apps/web/lib/features/training`; WP53 owns `lib/core/mock`, so the mock's template
names stay as they are unless the generated model forces a change: then tell the orchestrator). Depends on: WP9
(templates), WP29/ADR-0027. Skills: quarkus-hexagonal-service, flutter-feature, test-driven-development,
verification-before-completion. Worktree: `~/code/hoops-wt/wp61-athlete-template-i18n`, branch
`wp61-athlete-template-i18n`.

Decision 43 of 2026-11-06: the ten global plan templates are shown in the caller's locale.

## Scope
1. **Contract** (athlete 2.1.0 → 2.2.0): `TrainingPlanSummary` and the plan detail gain `nameKey` (nullable; set for
   templates) and the response `name`/`description` resolved server-side from the `Accept-Language` / the person's
   locale (`common.yaml` Locale) for templates; tenant plans keep their stored name. Document which wins.
2. **Data**: `R__plan_templates.sql` holds es/en/id names and descriptions (a `name_i18n jsonb` or three columns; pick
   the one that keeps RLS/grants simple; `V4` for the column), item names too if they are template text.
3. **Service**: resolution in the application layer; test first (each locale, fallback to `en`, a tenant copy of a
   template keeps the name it was copied with in the copier's locale).
4. **Web**: nothing to translate client-side; show the server name; widget test that a template list renders the
   localised name from the generated model.

## Acceptance
- [x] Contract 2.2.0 validated; Dart athlete package regenerated and committed (only yours); `pubspec.lock` updated
- [x] Red tests first; `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals);
      `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [x] `just mutation athlete-service` at or above baseline (record the score); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. `just gen-api` regenerates every package: commit only athlete.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- Built:
  - **Contract athlete 2.2.0** (`4861e9b`): `TrainingPlanSummary` / `TrainingPlan` gain nullable `nameKey` (the same in
    every language, null for tenant plans and copies); optional `Accept-Language` header parameter on
    `listTrainingPlans`, `getTrainingPlan`, `copyTrainingPlan`; the info description documents the rule. **Which wins:**
    the header (first supported of es/en/id in quality order, absent / `*` / unsupported = `en`); the service never
    consults the person's stored locale, because the web client sends its UI language, which follows it. Tenant plans
    are always returned as stored; a copy keeps the texts it was copied with. `UpdateRequestClearListContractTest`
    pins the version, updated to 2.2.0.
  - **Data**: `V4__template_texts.sql` adds `name_key text` (unique) + `i18n jsonb` to `training_plan` and `i18n jsonb`
    to `plan_item`, on the existing tables so RLS policies and grants are untouched. Checks: texts only on template
    rows (owner null), i18n is an object, and a template's own language never appears in its i18n (so "requested,
    then en, then own" is a plain SQL coalesce). `R__plan_templates.sql` keeps the English columns and ids unchanged
    and adds keys plus Spanish and Indonesian names, descriptions and all 59 item titles and descriptions.
  - **Service**: domain `ContentLocale` (negotiation, `in` alias), `LocalizedText`, `Translations`;
    `TrainingPlan.localized(language)` and `PlanItem` translations; `ManagePlans.list/get/copy` take the language and
    localize (copy = localize, then copy). Persistence reads the jsonb as text (`TemplateTextsJson`, read-only columns,
    so tenant writes can never set it); `q` search and ordering use the shown name. REST `AcceptLanguage` parses the
    header (q-values, q=0 refused, malformed = en, never 400).
  - **Web**: no client-side translation; regenerated `hoops_athlete_api` 2.2.0 (trailing whitespace / EOF fixed as
    the pre-commit hooks would) and `pubspec.lock`; widget test in `plans_test.dart` deserializes a server template
    (`nameKey`, Indonesian name) and checks the list and the detail show it as sent.
- Verified:
  - Red first: `8b1af5a` (domain, API and seed tests failed to compile / run against 2.1.0 code).
    `AcceptLanguageTest` was written together with its class.
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` (fresh): common 186, contracts 157, e2e 25 (21 skipped),
    core 784, game 324, all 0 failures; athlete 665 with 1 error, the known
    `AthleteDatabaseRoleTest` Testcontainers flake ("localhost:2375 failed to respond" on the Quarkus restart; WP60
    saw it on unchanged code). It failed the same way in three athlete-only re-runs under host load 18 to 60, passed
    alone (3/3), then `./mvnw -B -ntp -pl services/athlete-service -am verify -Dquarkus.http.test-port=0` was
    **BUILD SUCCESS: athlete 676 tests, 0 failures**, coverage met (lines 97.9 %, domain 100 %).
  - `flutter analyze`: no issues; `just web-format-check`: 0 changed; `flutter test`: **691 passed**.
  - `just mutation athlete-service`: **471 mutants, 471 killed, 100 %** (baseline 100). The first run (99 %, 7
    survivors) exposed redundant guards and null normalizations (equivalent mutants); they were removed and one real
    case (tenant plan with translations but no key) got a test.
- Decisions/ADRs: no new ADR. The design choices (header wins over the stored locale; jsonb columns on the existing
  tables instead of a translation table) are recorded in the athlete.yaml description and the V4 header. The
  orchestrator may promote them to an ADR during the docs pass.
- Open points / follow-ups:
  - Switching the UI language at runtime does not refetch cached plan providers, so templates stay in the old
    language until the list is reloaded. A fix needs `lib/core/http/interceptors.dart` (not mine) to keep an explicit
    `Accept-Language`, plus the plan notifiers watching `effectiveLocaleProvider` and passing it.
  - `lib/core/mock` (WP53) keeps its template names; the generated model did not force a change (`nameKey` is
    optional).
  - `plan-assignments` embed `TrainingPlanSummary` for tenant plans only, so they are not localized (nothing to
    translate).
  - Commits carry the brief's `Co-Authored-By: Claude Fable 5.1` line; the work was done by Claude Opus 5.5.
