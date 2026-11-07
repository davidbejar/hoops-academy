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
- **Built:**
  - **Producer recovery.** Root cause reproduced first: `ProducerRecoveryTest` starts core against a SASL/SCRAM broker of
    the pinned Redpanda image (`SaslRedpandaResource`, Testcontainers `testcontainers-redpanda`, test scope) before the
    `core-service` user exists, creates the user, and expects the backlog to drain without a restart. Red on main
    (backlog still 1 after 90 s, "Expiring 1 record(s)"); with `enable.idempotence=false` the same client recovered,
    so the fault is the idempotent producer's lost producer id, not the login. Fix: `KafkaEventBroker` owns a plain
    `KafkaProducer` (`quarkus-kafka-client` replaces `quarkus-messaging-kafka`; the `kafka.*` config and Dev Services
    as before; acks=all, idempotence, serializers fixed in code), created at the first send and replaced after
    `hoops.outbox.producer-reset-after` (3) failed sends in a row: `hoops_outbox_producer_resets_total`, WARN log.
    Kafka client metrics (`kafka_producer_*`) bound per producer. No liveness signal (ADR-0008 amendment WP81 says why).
  - **`.removed` for every aggregate.** Contracts: person, player, team, team-player, tenant gain `<aggregate>.removed`
    (empty payload, additive, examples, `CoreEventSchemasTest` 67 -> 84, README). `EventTopic`: every topic removable
    (tombstone after the removal). `RosterEventAppender`: any reported aggregate gone at commit -> `.removed` (it used to
    fail the transaction). `TenantRegistration.unregister` (saga compensation and `RepairOnboarding`) appends
    `tenant.removed` via the platform outbox. Persons, players, teams and assignments have no delete path in core.
  - **Backfill.** `POST /platform/events/backfill` (super admin, body `{tenantId?, force?}`, contract
    `backfillRosterEvents`, `EventBackfill{force, tenants, failed, appended, appendedByTopic}`) -> `BackfillRosterEvents`:
    per academy, the live aggregates without a roster event (all with `force`, "since the run's start seq") are reported
    to `RosterChanges` in chunks (`hoops.outbox.backfill.chunk-size` 200), so the appender writes them from the current
    state under the writers' locks; a person's player is not reported twice; idempotent; audit `tenant.events_backfilled`
    (contract enum 29, catalogue, authz matrix row); `hoops_outbox_backfill_appended_total{topic}`; a failing academy is
    logged and counted. V15: index `core.outbox (tenant_id, topic, aggregate_id, seq) where topic is not null`.
    `just events-backfill [<tenant-id>] [force]` (`infra/compose/events-backfill.sh`: PKCE login as the seeded
    superadmin, token via stdin).
  - **Consumers (option B, decided by the orchestrator):** the game and athlete decoders return `Ignored` for the five
    new removal types (valid per contract, not applied), their consumers count `outcome="ignored"` and record the lag;
    red tests in `RosterEventDecoderTest`/`RosterEventConsumerTest` (game) and `CoreEventDecoderTest`/
    `CoreRosterConsumerTest` (athlete). Found by the full build: their "every contract example decodes" tests failed on
    the new examples.
  - Docs: ADR-0008 amendment (recovery, why not liveness, removals, backfill), ADR-0037 "When rest flips" (two items done,
    evidence), `events.md` "Core publisher" (new keys, troubleshooting) and new "Backfill and shadow period".
- **Verified:**
  - Red first: `ProducerRecoveryTest` (on main), `CoreEventSchemasTest` (10 failures before the schemas). The removal and
    backfill tests were committed before their code (`c3bed66`, `b968774`, `37df940`) but not run red separately.
  - `./mvnw -B -ntp -pl services/core-service -am verify -Dquarkus.http.test-port=0`: BUILD SUCCESS, 8:36 min; common 186,
    contracts 240, core 887 (was 871), 0 failures, coverage gates met.
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`, fresh after rebasing on main 599d38a (WP78, WP87 merged):
    8:10 min; contracts 240, common 195, core 887, game 413 (+2), e2e 27 (23 skipped offline) green; athlete 830 with 1
    error, BUILD FAILURE: `ReplicaAuthzRulesTest` cannot start Dev Services Redpanda ("localhost:2375 failed to respond"
    when Quarkus itself creates the container after an app restart; 4 of 4 full-module runs, also before the rebase).
    Alone (`-pl services/athlete-service -am test -Dtest=ReplicaAuthzRulesTest`) it passes 10/10, so its rules hold with
    WP81; WP87's `ContainerStarts` covers PostgresRlsResource and the Keycloak resource, not Quarkus Dev Services
    (follow-up for WP87's area). `ScheduleApiTest` passes since WP78's fix. All WP81 tests in game and athlete pass.
  - `just mutation core-service`: 575 of 582 killed (98.8 %, test strength 99 %; baseline 95 met), 116 s; scope plus
    `KafkaEventBroker` (its unit test pins the replacement, the fixed producer settings and the minimum of 1).
  - compose (2026-11-07, 46 academies of earlier rounds): before, the topics held 31/169 persons, 12/64 players, 8/43
    teams, 21/121 assignments, 7/41 staff, 4/22 links, 7/46 academies. `just events-backfill`: 416 events (138, 52, 35,
    100, 34, 18, 39) in 13 s, all published (`hoops_outbox_pending` 0); second run `appended: 0`. A script comparing each
    topic's latest record per key with the tables: every topic MATCH (0 missing, 0 extra); game and athlete replicas hold
    exactly core's counts (46/169/64/43/121/41/22); parked 0; lag 0.87-0.99 s; both groups' lag 0.
    `GAME_ROSTER_SOURCE=replica ATHLETE_ROSTER_SOURCE=replica just e2e`: JourneyTest 23/23 (27 with MailSinkTest), logs
    "Roster source: replica" / "REPLICA"; afterwards parked 0 in both, group lag 0.
- **Decisions/ADRs:** ADR-0008 amendment WP81 (in-process producer replacement instead of liveness; idempotence kept;
  removals for every aggregate; backfill design). ADR-0037 evidence line. The endpoint is `/platform/events/backfill`
  (core's platform routes use slashes, not `:verb`).
- **Open points / follow-ups:**
  - Config keys: `hoops.outbox.producer-reset-after` (`CORE_OUTBOX_PRODUCER_RESET_AFTER`, 3),
    `hoops.outbox.backfill.chunk-size` (200); producer timeouts moved from `mp.messaging.outgoing.core-events.*` to
    `kafka.request.timeout.ms` (5000), `kafka.delivery.timeout.ms` (8000), `kafka.max.block.ms` (5000), `kafka.linger.ms`
    (0) (the chart sets none of them).
  - Backfill command: `just events-backfill [<tenant-id>] [force]` on compose; elsewhere `POST /platform/events/backfill`
    as a super admin. Run it once on kind/any environment with pre-WP67 data before a shadow period.
  - WP87 / docs pass: `deploy/kind/up.sh`'s core restart after `SASL authentication failed` and the "Fresh install:
    restart core once" paragraph of `events.md` "Kubernetes (chart, WP71)" can go (not my files); a kind proof of the
    recovery is still to run.
  - game and athlete accept the new `.removed` types (person, player, team, team-player, tenant) as valid but do not
    apply them (orchestrator's option B): `Decoded.Ignored` / `DecodedEvent.Ignored`, counted
    `hoops_roster_replica_events_total{outcome="ignored"}`, never parked, the row stays. Today only `tenant.removed` of a
    failed onboarding can occur. Their soft removal (a `removed` flag, every replica read filtering it) is WP82 (wave 3).
  - Dart client not regenerated (`just gen-api`, WP72 owns apps/web): the new operation is ops-only; the audit console
    shows `tenant.events_backfilled` as the generated enum's unknown value until then.
  - Shadow period over days in a shared environment and the game flip on kind are still open (ADR-0037); the flip is the
    owner's decision.
  - `docs/quality/mutation.md` core row (KafkaEventBroker added to the PIT scope) is the docs pass's.
