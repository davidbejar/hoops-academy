# WP82 — Game + athlete: replica housekeeping (applied/parked retention) and `.removed` for every aggregate

Model: Opus. Wave 3 (2026-11-06, fifth round): starts after wave 2 is merged (WP80 touched the three services);
runs alongside WP76 (web), WP85 (`libs/common-quarkus`, realm, `images.yml`), WP90 (core). You own
`services/game-service` and `services/athlete-service` (consumers, replica apply rules, jobs), Flyway game `V6`,
athlete `V9` (reserved), `docs/runbooks/events.md` game and athlete sections, `docs/adr/0037-*.md` amendment.
Depends on: WP68/WP69 (replicas), WP81 (the new `.removed` types for every aggregate in `libs/contracts/events`;
read its handover), ADR-0037. Skills: quarkus-hexagonal-service, tenant-isolation-testing, test-driven-development,
verification-before-completion. Worktree: `~/code/hoops-wt/wp82-replica-housekeeping`, branch
`wp82-replica-housekeeping`.

Decision 59 of 2026-11-06 (continued): the replica `applied_event` and `parked_event` tables get retention jobs; the
replicas apply the `.removed` events WP81 added for persons, players, teams, team-player and tenants.

## Scope
1. **`.removed` handling**: red tests per aggregate (soft removal in the `*_ref` row, tombstone skipped, tenant
   removal cascades its refs or marks the tenant removed: decide, same in both services; authz resolvers treat
   removed rows as absent).
2. **Retention**: a scheduled job per service (Quarkus scheduler, `runExclusive`-style guard or `SKIP LOCKED`)
   deletes `applied_event` rows older than the tombstone retention (7 days, configurable; never below it: a replay
   relies on them) and `parked_event` rows older than N days after they were inspected (metric + log of what was
   deleted); config keys `hoops.roster.replica.retention.*`; tests with a clock.
3. **Docs**: runbook sections (what is pruned, how to inspect parked rows before they go), ADR-0037 amendment.

## Acceptance
- [ ] Red tests first; `./mvnw -B -ntp -pl services/game-service,services/athlete-service -am verify
      -Dquarkus.http.test-port=0` green (totals); `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green
      (fresh; totals)
- [ ] `just mutation game-service` and `athlete-service` at or above baseline (record)
- [ ] `GAME_ROSTER_SOURCE=replica ATHLETE_ROSTER_SOURCE=replica just e2e` 23/23 on compose (tell the orchestrator
      before: WP90 also needs the stack)
- [ ] Handover appended with the config keys

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
