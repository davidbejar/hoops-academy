# WP67 — Core: outbox publisher and the event contracts

Model: Opus. Wave 4 (2026-11-06, fourth round): starts after WP66 is merged; runs alone (the only agent). You own
`services/core-service`, Flyway `V14` (reserved), `libs/contracts/events/**` (new: JSON Schemas of the seven event
types, one file per topic, versioned), `libs/contracts` tests for them, `apps/web` nothing. Depends on: ADR-0008,
ADR-0036 (WP66: broker, topics, keys), the WP19 brief, `core.outbox` (V4 grants). Skills:
quarkus-hexagonal-service, tenant-isolation-testing, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp67-outbox-publisher`, branch
`wp67-outbox-publisher`.

Decision 48 of 2026-11-06 (continued): core publishes its roster changes through the transactional outbox to
Redpanda; game and athlete consume them in WP68/WP69.

## Scope
1. **Event contracts** (`libs/contracts/events/<topic>.schema.json`, Draft 2020-12 like the match-event schema):
   envelope (`eventId`, `type`, `version`, `tenantId`, `aggregateId`, `occurredAt`, `payload`), one payload per
   topic from the WP19 brief; a contracts test validates the examples and enforces the naming conventions;
   `libs/contracts/README.md` section "Events" (versioning: additive = same major; breaking = new topic suffix).
2. **Writing the outbox**: every use case that changes person, player, team, team-player, team-staff, guardian-link
   or tenant appends a row in the same transaction (test first per use case: the row exists with the schema-valid
   payload; the RLS/grants of `core.outbox` unchanged or extended in `V14`). Find the single place to do it (a
   domain-event collector in the application layer, not in resources).
3. **Publisher**: `FOR UPDATE SKIP LOCKED` polling (interval configurable, default 1 s; `runExclusive`-style single
   publisher across replicas is NOT required because of the row locks, say why), `quarkus-messaging-kafka` producer
   keyed per ADR-0036, at-least-once with `published_at`; metrics (published, lag) on `/q/metrics`; health check
   when the broker is down (degraded, not down; the HTTP API keeps working). Dev Services Redpanda in tests
   (pinned image from WP66).
4. **Tests**: publish order per aggregate, duplicate-safe (`eventId`), crash between send and mark (the row is
   re-sent), broker down then up (backlog drains), tenant id in every event; `RlsSchemaMetaTest` /
   `GenericRlsIsolationTest` cover `core.outbox` if it is a tenant table.
5. `docs/adr/0008-*.md` amendment "implemented in WP67"; `docs/runbooks/events.md` section "core publisher".

## Acceptance
- [ ] Event schemas + examples validated in `./mvnw -pl libs/contracts verify`
- [ ] Red tests committed before each change; `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green
      (fresh; totals); `just e2e` 21/21 on compose with the publisher on (events visible with `rpk topic consume`)
- [ ] `just mutation core-service` at or above baseline (record the score); handover appended with the config keys

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
