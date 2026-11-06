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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
