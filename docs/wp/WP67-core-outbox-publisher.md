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
- **Built:**
  - Contracts: `libs/contracts/events/core.{person,player,team,team-player,team-staff,guardian-link,tenant}.schema.json`
    (Draft 2020-12, identical closed envelope `eventId/type/version/tenantId/aggregateId/occurredAt/payload`, types
    `<aggregate>.changed` and `.removed` for team-staff and guardian-link, every payload field required, null =
    absent), examples `events/examples/core.<aggregate>.valid.json`, `CoreEventSchemasTest` (meta-schema, one schema
    per `redpanda-topics.sh` topic, naming, envelope identity, examples per type, negative cases), README "Events"
    (state transfer, at least once, additive = same topic, breaking = `<topic>.v2`). Team-staff aggregate id = UUID v3
    of `team-staff:<teamId>:<personId>`.
  - `V14__outbox_publisher.sql`: `topic` (null = internal v1 notification, never published), `seq` identity,
    `occurred_at` default `clock_timestamp()`, pending index `(tenant_id, seq)`, `core_platform` SELECT policy + column
    grant on `tenant_id, topic, occurred_at, published_at` only (no payload, no update/delete).
  - Writing: the repositories (only writers of the roster tables) report changes to `application.events.RosterChanges`;
    a JTA synchronization before commit appends one row per aggregate via `RosterEventAppender` from `RosterStates`
    (`JpaRosterStateRepository`: native SQL after flush, writer row locks). Person -> its player, season -> its teams.
    Platform lifecycle/master data append `tenant.changed` (`TenantEvents`). v1 notification rows unchanged.
  - Publisher: `PublishOutbox` + `OutboxPublisherJob` (`@Scheduled`), `JpaOutboxQueueRepository` (`FOR UPDATE SKIP
    LOCKED` + head-of-line rule), backlog through the platform datasource, `KafkaEventBroker` (`MutinyEmitter<Record>`,
    channel `core-events`, topic per record, tombstone after `.removed`), `OutboxPublisherHealthCheck` (readiness,
    always UP, `state` OK/DEGRADED), gauges/counter on /q/metrics. Dev Services Redpanda pin active in common-quarkus
    (`run.sh` reads it commented or not), topics pre-created by Dev Services.
  - Docs: ADR-0008 amendment (why no cluster lock), index row, `docs/runbooks/events.md` "Core publisher".
- **Verified:**
  - `./mvnw -B -ntp -T 1C clean verify -Dquarkus.http.test-port=0`: BUILD SUCCESS, 4:05 min; contracts 223, common
    186, core 871, game 324, athlete 679, e2e 27 (23 skipped offline), 0 failures; all coverage gates met.
  - `./mvnw -pl libs/contracts verify`: 223 tests (67 in `CoreEventSchemasTest`); a mutated schema fails 3 of them.
  - Per use case (red first): `TeamEventsTest`, `MemberEventsTest`, `PlayerEventsTest`, platform/admin/rollover/
    eligibility assertions, every event schema-validated (`RosterEvents`); `OutboxRlsTest` (V14 grants/order).
  - `OutboxPublisherJobTest` (Dev Services Redpanda v26.2.6): order per aggregate + key + eventId + tenant id + tombstone,
    no resend after mark, crash between send and mark resends the same eventId, a row locked by another publisher
    holds back its aggregate only (mutating the head-of-line clause fails it), broker paused: API 201, health UP/
    DEGRADED, `hoops_outbox_pending` >= 1, `broker_available` 0, then drain.
  - `just e2e` on compose with the publisher on: JourneyTest 23/23 (27 with MailSinkTest); afterwards 34 roster rows,
    0 pending; `rpk topic describe` high watermarks equal the rows per topic (person 14, player 4, team 2,
    team-player 7, team-staff 2, guardian-link 1, tenant 4); `rpk topic consume core.team` shows the envelope.
  - `just mutation core-service`: 558/560 killed (99.6 %, baseline 95); scope now includes `EventTopic`,
    `RosterPayloads`, `RosterEventAppender`, `EventEnvelopes`, `TenantEvents` (their 66 mutants all killed; unit tests
    written after the code, as PIT scope).
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED (Redpanda pin check reads the active line).
- **Decisions/ADRs:** ADR-0008 amendment (collector in the application layer fed by the repositories; state read
  under the writers' lock; platform sees queue columns only; no `runExclusive`: row locks + head-of-line rule).
- **Open points / follow-ups:**
  - Config keys: `hoops.outbox.poll-interval` (`CORE_OUTBOX_POLL_INTERVAL`, `1s`, `off`), `hoops.outbox.batch-size`
    (`CORE_OUTBOX_BATCH_SIZE`, 100), `hoops.outbox.send-timeout` (`CORE_OUTBOX_SEND_TIMEOUT`, `PT10S`),
    `%prod.kafka.bootstrap.servers` (`KAFKA_BOOTSTRAP_SERVERS`, `localhost:19092`), `KAFKA_SECURITY_PROTOCOL`
    (`PLAINTEXT`), `KAFKA_SASL_USERNAME` (`core-service`), `KAFKA_SASL_PASSWORD`; `mp.messaging.outgoing.core-events.*`.
  - Chart not wired (outside this WP's files): core's Deployment needs `KAFKA_BOOTSTRAP_SERVERS=redpanda.<ns>.svc...:9092`,
    `KAFKA_SECURITY_PROTOCOL=SASL_PLAINTEXT` and `KAFKA_SASL_PASSWORD` from `hoops-redpanda-core-service` behind
    `events.enabled`; until then the publisher on kind is DEGRADED (pods stay ready). kind not run.
  - game/athlete builds log "Unrecognized configuration key quarkus.kafka.devservices.*" until WP68/WP69 add the extension.
  - `docs/quality/mutation.md` core row (classes, 560 mutants) is the docs pass's.
  - Tenant deletion (`deleteUnprovisioned`) publishes nothing (no event was ever written for it). Persons, players,
    teams, assignments and tenants have no `.removed` type (never deleted).
