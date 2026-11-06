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
- [ ] Contract 2.2.0 validated; Dart athlete package regenerated and committed (only yours); `pubspec.lock` updated
- [ ] Red tests first; `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals);
      `flutter analyze` clean; `just web-format-check` clean; `just web-test` green (fresh; totals)
- [ ] `just mutation athlete-service` at or above baseline (record the score); handover appended

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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
