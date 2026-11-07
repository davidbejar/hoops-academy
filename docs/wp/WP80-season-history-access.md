# WP80 — Season history: read-only access to past seasons for former staff and admins (core, game, athlete)

Model: Opus. Wave 2 (2026-11-06, fifth round): starts after wave 1 is merged; runs alongside WP73/74/75 (web
redesign), WP86 (chart), WP89 (CI). You own `libs/contracts/openapi/{core,game,athlete}.yaml` and the three Dart
packages, `services/core-service`, `services/game-service`, `services/athlete-service` (authz rules, queries,
replica authz resolvers of WP68/69), `libs/common-quarkus` authz context if the rule lives there, Flyway core `V16`,
game `V5`, athlete `V8` (reserved, if needed), `docs/domain/authz-matrix.md` (the "ended season" rule rows). NOT the
web (the "past seasons" selector in the lists is WP76's in wave 3: write in your handover exactly what the web must
send). Depends on: WP58 (decision 40: ended seasons drop access), ADR-0037 (replica authz mirrors core's
`/internal` rules: change both sides in step), WP2c/WP22 membership cache. ADR-0042 reserved for you. Skills:
quarkus-hexagonal-service, tenant-isolation-testing, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp80-season-history`, branch `wp80-season-history`.

Decision 62 of 2026-11-06: past seasons' teams, matches, attendance and health records are readable (never editable)
by the coaches who were staff of the team then and by admins; players and parents keep today's rules.

## Scope
1. **Rule** (ADR-0042): a team whose season has ended is "historic": readable by ADMIN and by the persons who were
   staff of that team (the staff row stays, WP58 only excluded it from "current" teams); every write on a historic team
   (and its matches, sessions, attendance, plans assignments, health records bound to it) is refused with 409
   `SEASON_ENDED` (or 403? pick one Problem type and document it); today's "current" views are unchanged by default.
2. **Contracts** (core 3.1.0 → 3.2.0, game 2.2.0 → 2.3.0, athlete 2.3.0 → 2.4.0, each only if a parameter or field is added; WP81 took core 3.1.0): list endpoints gain
   `seasonId` / `includeEnded` (pick one; the same name in the three APIs), `/me`'s team lists expose historic teams
   separately (e.g. `historicTeams`), responses carry `seasonEnded: true` where useful. Document the rule in each
   description. `UpdateRequestClearListContractTest` pins updated.
3. **Services**: red tests per rule (former staff reads, cannot write; admin reads; a coach never staffed cannot
   read: 404; the game and athlete replica resolvers give the same answers as core's `/internal`: contract tests
   on both sources, WP68/69 style); the authz-matrix rows.
4. **Docs**: ADR-0042; authz matrix; handover with the exact web contract for WP76.

## Acceptance
- [ ] Contracts validated; the three Dart packages regenerated and committed (only those); `pubspec.lock` updated
- [ ] Red tests first; `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just mutation core-service`, `game-service`, `athlete-service` at or above baseline (record); `just e2e`
      23/23 on compose (tell the orchestrator before you start it; WP86 does not use compose)
- [ ] ADR-0042 indexed (append at the end of `docs/adr/README.md`); handover appended

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
