# WP130 — Library, game, athlete: roster replica pipeline once in `common-quarkus`

Model: Opus · high. Wave 2 (2026-11-23, ninth round): starts after wave 1 is merged; runs alongside WP131 (finance),
WP132 (pdf), WP133 (CI, scripts). You own `libs/common-quarkus/**`, `services/game-service/**`,
`services/athlete-service/**`; nobody else touches them in this wave. Not the root `pom.xml`, not core. Depends on:
WP126, WP127; ADR-0037, ADR-0053, WP98. Skills: work-package, quarkus-hexagonal-service, tenant-isolation-testing,
test-driven-development, clean-code, verification-before-completion. Worktree:
`~/code/hoops-wt/wp130-replica-pipeline-in-common`, branch `wp130-replica-pipeline-in-common`.

Decision 106 of 2026-11-23: decoder envelope, consumer loop (one retry and metric policy, one reason limit) and
history store move into `common-quarkus`; the retention job stays per service (WP98), at most a small shared helper
behind each service's own `@Scheduled`. ADR-0062 is reserved for you (write it; it amends ADR-0037).

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `cross-cutting.md`
(X-01), `libs.md` (LIB-01), `game-service.md` (GAME-05, GAME-06), `athlete-service.md` (ATH-02, ATH-05); verifications
`verify-cross-cutting-libs.md` and `verify-game-athlete.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Characterise first**: tests that pin today's behaviour of both consumers (retry, park, replay, metrics, reason
   cap), then choose one policy for the points where they differ and say which in the ADR.
2. **Move**: the envelope half of the core-event decoders, the consumer retry / park / metrics loop and the
   replica-history repository into the library's `replica` package; each service keeps its own projection (what an
   event means for its tables) and its schema. `parked_event` has the same shape in both schemas afterwards
   (migrations per service).
3. **Runbook**: `docs/runbooks/events.md` describes one procedure instead of two.
4. **Tests**: the library part is unit-tested and inside the PIT scope; the services' `RlsSchemaMetaTest` /
   `GenericRlsIsolationTest` stay green.

Not yours: the authorisation rule (X-02) is WP134; test-support copies are WP137.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green (fresh; totals)
- [ ] `just mutation` for common-quarkus, game-service and athlete-service at or above baseline
- [ ] `just isolation-check` and `just db-role-check` run by hand in the worktree
- [ ] lines removed from the two services vs added to the library (in the handover)
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
- **Built** (commits `132897cd`..`465bd7de` plus this docs commit; every behaviour change after its red test):
  - **Characterised first** (`132897cd`): `RosterEventConsumerPolicyTest` (game: `apply-attempts` linear pauses, a failed
    park not retried, meters registered up front) and `CoreRosterConsumerPolicyTest` (athlete: `max-attempts` doubling
    backoff, park retried, meters on first use); both removed with the two loops once the library's tests pinned the
    chosen policy. The other differences were already pinned (decoder tests: reason caps; consumer and replay tests).
  - **Library** (`com.hoopsacademy.common.replica`, red `5d0a0fd3`, green `bc2b5184`): `RosterTopic`, `EventEnvelope`,
    `CoreEventDecoder<E>` + `EventMapper<E>` + `DecodedEvent` (schemas from the contracts jar, key, own tenant, event id,
    bounded reason), `ReplicaConsumer<E>` + `ReplicaApplier` + `ReplicaOutcome` + `RetryPolicy` + `ReplicaRecord`,
    `ReplicaMetrics`, `ParkedEvent(s)`, `ReplicaHousekeeping` (retention run under the lock, counted), `ReplicaSchema`,
    `JdbcReplicaHistory`, `JdbcParkedEvents`. Unit tests in PIT scope (`CoreEventDecoderTest`, `ReplicaConsumerTest`,
    `ReplicaPartsTest`, `ReplicaHousekeepingTest`); `JdbcReplicaStoresTest` on common's test migration V3 (the shared
    table shape; `SampleRlsSchemaMetaTest` / `RlsSchemaInspectorTest` declare its two global tables). New compile
    dependency `json-schema-validator` 2.0.8 (version as in game/athlete/contracts); `contracts` as a test dependency.
  - **game** (red `511c3e0d`, green `59408d1d`; `483ea0e6` / `465bd7de` create the pipeline at startup when the consumer
    is on, so the meters exist from the start): `RosterEventMapper` (payload only) replaces
    `RosterEventDecoder`; `ReplicaPipelineProducer` (decoder + consumer, created at startup), `ReplicaBookkeepingProducer`
    (stores on schema `game`), `RosterEventConsumer` and `ReplicaRetentionJob` are thin shims; `EventEnvelope`,
    `ParkedRecord(s)`, `ReplicaMetrics`, `JdbcParkedRecordRepository`, `JdbcReplicaHistoryRepository` and
    `ReplicateRoster.park` / `Outcome` are gone. `V10__parked_event_shared_shape.sql`: athlete's shape (primary key
    on the position, column `partition`, identity `id` dropped). `hoops.roster.replica.max-attempts` /
    `first-backoff` replace `apply-attempts` (env `GAME_ROSTER_REPLICA_MAX_ATTEMPTS`).
  - **athlete** (red `26988ebd`, green `ba90adc5`): `CoreEventMapper` replaces `CoreEventDecoder`; same producers and
    shims; `RosterTopic`, `DecodedEvent`, `ParkedEvent(s)`, `ParkedEventRepository`, `ReplicaHistoryRepository`,
    `ApplyRosterEvent.Outcome` are gone. `parked_event` already had the shared shape (new guard test in
    `ReplicaHousekeepingSchemaTest`).
  - Lines (main Java, `git diff --numstat 498519fb`): game -549 / +200, athlete -498 / +198 (services -1,047 / +398,
    net -649); common-quarkus +663 (about a third of it javadoc). Tests: services -182 / +273, common +809.
  - Docs: runbook `events.md` has one section "Roster replicas: game and athlete" (settings, watch, parked records,
    consumer stopped, housekeeping, replay, switching, what differs per service) instead of two; both service READMEs;
    `docs/quality/pmd.md` names; model diagrams regenerated (`game-model.md`, `athlete-model.md`).
- **Verified**: see "Verification" below.
- **Decisions/ADRs**: ADR-0062 (amends ADR-0037, amendment section appended there), indexed in `docs/adr/README.md`.
  Policy where the consumers differed: athlete's retries (5 tries, 0.5 s doubling) now also for game, and for the park
  as well as the apply; athlete's reasons (5 errors, 500 characters, no record values: game quoted the key and the
  unknown zone); game's meters (all seven topics registered at startup); athlete's `parked_event` shape; scheduler
  identity = lock name `<service>.replica-retention`.
- **Open points / follow-ups** (for the orchestrator's docs pass):
  - Root files changed (not owned by any wave-2 WP): `spotbugs-exclude.xml` (+1 match for the two JDBC stores'
    `SQL_INJECTION_JDBC`, ADR-0045 style; athlete `CoreEventDecoder` dropped from the `CT_CONSTRUCTOR_THROW` match),
    `config/pmd/exclude-pmd.properties` (the two `CyclomaticComplexity` entries renamed to the mappers).
  - `docs/quality/mutation.md` not edited (merge clash): common 414/415 (99.8 %), game 551/553 (99.6 %), athlete
    644/644 (100 %) on 2026-11-24; its row texts still name `RosterEventDecoder` / `CoreEventDecoder`.
  - `docs/domain/core-model.md` is stale on `main` (WP128's `EventBroker.sendAll`, `SeasonRepository.require`):
    `scripts/model-diagrams.sh` regenerates it; left alone (core is not mine).
  - `docs/architecture.md` / `docs/conformance.md` may mention the per-service replica classes; not edited per brief.
  - Not done: the `RosterSource` switch and resolver (X-01 item 4; the brief's scope names decoder, loop and store),
    the test-jar builders `CoreEvents` / `CoreTopics` / `ReplicaDb` (X-01 item 5, WP137), the authorisation rule
    (X-02, WP134), an in-memory "seen tenants" set for the `replica_tenant` insert (GAME-06's refinement: documented
    design, consumer path only, the verification calls it optional).
  - Deploy note: game's V10 drops `parked_event.id`; operators' saved queries `where id in (...)` must use the position
    (runbook updated). `GAME_ROSTER_REPLICA_MAX_ATTEMPTS` is new; nothing set `apply-attempts` outside the service.

### Verification
- `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` (fresh, on `465bd7de`, 2026-11-24): BUILD SUCCESS, 708 s,
  all coverage checks met, SpotBugs/PMD/CPD clean. Tests: contracts 346, common-quarkus 469, core 1257, game 556,
  athlete 1025, e2e 38 (32 skipped); 0 failures, 0 errors. The run before it had one failure,
  `RosterEventConsumerTest.theLagIsTheAgeOfTheLastEventWhenItWasProcessed` (lag 0, green alone): `@Startup` on the
  pipeline producer registered the gauges in test applications with the consumer off; fixed in `465bd7de` (systematic
  debugging: reproduced only in the full run, cause in the gauge bound to an earlier instance).
- Red runs: game `RosterEventDecoderTest` 3 failures + `RosterReplicaSchemaTest.theParkingTableHasTheSharedShape`
  before `59408d1d`; athlete `CoreRosterConsumerTest.everyTopicHasItsParkedCounterAndLagGaugeFromTheStart` failed on
  the old loop (temporary worktree at `59408d1d` with the new test) before `ba90adc5`; the library tests did not compile
  before `bc2b5184`.
- `just mutation`: common-quarkus 414/415 (99.8 %, threshold 99; the survivor is the old `CoreRosterClient.zoneOf`),
  game-service 551/553 (99.6 %, threshold 99; both survivors outside the replica), athlete-service 644/644 (100 %,
  threshold 100). Two equivalent mutants in `ReplicaConsumer` were removed by a refactor (`9440dcae`).
- `just isolation-check` (by hand, worktree): 6 tests + 4 finance Go tests passed. `just db-role-check`: 13 tests + 2
  finance Go tests passed.
- `scripts/model-diagrams.sh`: `game-model.md` and `athlete-model.md` regenerated; `just docs-build` (strict): no
  issues.

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| X-01 | Done (partly) | Decoder envelope, consumer loop, meters, history and parking stores, retention run in common; one policy; `parked_event` one shape (game V10); one runbook procedure. Source switch and test builders not moved (see open points) |
| LIB-01 | Done (as corrected) | Retention run (`ReplicaHousekeeping`) and `JdbcReplicaHistory(schema)` in common, envelope decoder with the topic list (`RosterTopic`); `@Scheduled` and the retention producer stay per service (WP98) |
| GAME-05 | Done | game's loop, decoder envelope and meters replaced by common's; keys aligned to `max-attempts` / `first-backoff`; park retried |
| GAME-06 | Done (as corrected) | Job is a shim around `ReplicaHousekeeping`, history store from common; per-tenant insert refinement skipped (optional per verification) |
| ATH-02 | Done | athlete's decoder envelope and loop replaced by common's (`CoreEventMapper` keeps the type switch); meters now eager |
| ATH-05 | Done (as corrected) | Job shim, history store from common; producer stays per service (core must not get the bean) |
