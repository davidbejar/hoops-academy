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
