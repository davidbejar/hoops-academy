# WP81 — Core: producer recovery, `.removed` on deletion, backfill and shadow period

Model: Opus. Wave 1 (2026-11-06, fifth round): runs alongside WP72 (web), WP78 (athlete), WP83 (workflows), WP87
(chart + kind). You own `services/core-service`, Flyway `V15` (reserved), `libs/contracts/events/**` (schemas: only
additive changes, new `.removed` types), `docs/runbooks/events.md` section "Core publisher" and a new section
"Backfill and shadow period", `docs/adr/0008-*.md` amendment. You do not edit `deploy/**` (WP87 owns the chart and
`deploy/kind/up.sh`, which carries the restart workaround: tell WP87 through the orchestrator when the fix lands so
it drops the workaround, or leave the note for the docs pass). Depends on: WP67 (publisher: `PublishOutbox`,
`OutboxPublisherStatus`, `KafkaEventBroker`), WP71 handover (the failure: broker users created after core started,
idempotent producer keeps expiring records, `DEGRADED` with backlog until restart), ADR-0036, ADR-0037. Skills:
quarkus-hexagonal-service, tenant-isolation-testing, test-driven-development, systematic-debugging,
verification-before-completion. Worktree: `~/code/hoops-wt/wp81-core-events`, branch `wp81-core-events`.

Decision 59 of 2026-11-06: the core producer recovers by itself after a failed first SASL login; deletions publish
`.removed` events for every aggregate; a backfill appends one `.changed` per aggregate older than WP67; a shadow
period is documented; the default stays `rest`.

## Scope
1. **Producer recovery**: reproduce with Dev Services Redpanda (start core before the SCRAM user exists, create the
   user, expect publishing to resume without restart). Fix in the adapter (recreate the emitter/producer after N
   consecutive send failures or when the backlog is older than X and nothing was sent since start; or make the
   liveness check fail so Kubernetes restarts the pod: prefer in-process recovery, keep liveness as the last resort
   and say why in the ADR-0008 amendment). Metrics: `hoops_outbox_producer_resets_total`.
2. **`.removed` for every aggregate**: `deleteUnprovisioned` (tenant), persons, players, teams, team-player,
   assignments: every delete path appends a `.removed` event (schema additive: the new type per topic with examples;
   contracts test updated); tombstone after it as for the existing removals. Red tests per path.
3. **Backfill**: an admin-triggered platform operation (`POST /platform/events:backfill`, super admin, idempotent,
   audit row; or a one-shot job `just events-backfill`): appends one `.changed` per live aggregate older than the
   first outbox row (or all, with `force`), ordered per aggregate, through the same outbox; progress metric and log.
   Proven on compose: run it, consume the topics, counts match the tables.
4. **Shadow period**: `docs/runbooks/events.md` "Backfill and shadow period": run the backfill, keep `rest`, watch
   `hoops_roster_replica_parked_total` = 0 and lag over a period, run `just e2e` with `replica` for both services
   at once (do it on compose now: `GAME_ROSTER_SOURCE=replica ATHLETE_ROSTER_SOURCE=replica just e2e`), and what
   the flip decision needs (ADR-0037 "When rest flips" updated with the evidence you gather).
5. **Docs**: ADR-0008 amendment (recovery design), ADR-0037 evidence line, runbook sections.

## Acceptance
- [ ] Red tests first; the recovery scenario is an automated test on Dev Services Redpanda
- [ ] `./mvnw -B -ntp -pl services/core-service -am verify -Dquarkus.http.test-port=0` green (totals) and
      `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals); `./mvnw -pl libs/contracts
      verify` green with the new examples
- [ ] `just mutation core-service` at or above baseline (record); `just e2e` 23/23 on compose with both replicas on,
      after a backfill (coordinate the compose stack with WP78 and WP83 through the orchestrator)
- [ ] Handover appended: the config keys, the backfill command, the shadow-period evidence

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
