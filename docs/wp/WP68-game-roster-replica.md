# WP68 — Game: roster replica from core events behind `RosterPort`

Model: Opus. Wave 5 (2026-11-06, fourth round): starts after WP67 is merged; runs alongside WP69 (athlete, same
design, disjoint files). You own `services/game-service` and Flyway `V4` (reserved), `docs/adr/0037-*.md` (shared
with WP69: you write it, WP69 appends its "athlete" section at the end), the game part of `docs/runbooks/events.md`.
Depends on: WP67 (event contracts, publisher), WP19 brief, `RosterPort` (`services/game-service/.../application/
RosterPort.java`), the WP2c/WP22 membership cache. Skills: quarkus-hexagonal-service, tenant-isolation-testing,
test-driven-development, clean-code, verification-before-completion. Worktree: `~/code/hoops-wt/wp68-game-replica`,
branch `wp68-game-replica`.

Decision 48 of 2026-11-06 (continued): game keeps a local replica of the roster data it reads from core, fed by the
events, selectable with `hoops.roster.source=rest|replica` (default `rest` until proven; the ADR says when it
flips). ADR-0037 reserved (replica design, idempotency, replay, cutover).

## Scope
1. **Tables** `V4__roster_replica.sql`: `game.person_ref`, `player_ref`, `team_ref`, `team_player_ref`,
   `team_staff_ref`, `guardian_link_ref`, `tenant_ref` as needed by `RosterPort` and the authz context; every one a
   tenant table (`app.enable_tenant_rls`), covered by `RlsSchemaMetaTest` and `GenericRlsIsolationTest`; a
   `consumer_offset`/`applied_event` table for idempotency.
2. **Consumer**: `quarkus-messaging-kafka` incoming channels per topic, upsert by `aggregateId` with `occurredAt`
   ordering (older event never overwrites newer), duplicate `eventId` ignored, tenant binding per event
   (`TenantScope` with the event's tenant, never the request's), dead-letter or park on schema violation (validate
   against `libs/contracts/events`), metrics (lag, applied, parked).
3. **Adapter**: `RosterPort` replica implementation; the existing contract tests of the port run against both
   adapters (parameterised); `hoops.roster.source` switch; the REST adapter stays the default.
4. **Replay**: `just events-replay game` (or a documented `rpk` + offset reset) rebuilds the replica from the topic
   start; test: replica equals core after replay from empty (Dev Services Redpanda + a core fixture that publishes
   the fixture events through the WP67 contracts, not through core itself).
5. **Docs**: ADR-0037; `docs/runbooks/events.md` game section; `docs/architecture.md` is the docs pass's.

## Acceptance
- [ ] Red tests first; RLS suites green for the new tables; `./mvnw -B -ntp -pl services/game-service -am verify
      -Dquarkus.http.test-port=0` green (totals); `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green
      (fresh; totals)
- [ ] Port contract tests green on both adapters; replay test green; duplicate and out-of-order delivery tests green
- [ ] `just mutation game-service` at or above baseline; `just e2e` 21/21 on compose with `replica` for game
      (evidence); ADR-0037 written and indexed (append at the end of `docs/adr/README.md`); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. The compose stack: coordinate with WP69 by running `just e2e`
  only after your module verify is green (one at a time; tell the orchestrator before you start it).
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
