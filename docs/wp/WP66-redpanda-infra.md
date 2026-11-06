# WP66 — Events infra: Redpanda in compose, chart and kind; Dev Services for tests

Model: Opus. Wave 3 (2026-11-06, fourth round): starts after WP65 is merged (kind); runs alongside WP54 (web) and
WP62 (athlete norms); you are the only agent using kind this wave. You own `infra/compose/compose.yaml`,
`deploy/helm/**`, `deploy/kind/*`, `Tiltfile`, `libs/common-quarkus` messaging config (if a shared config class is
needed), the root `pom.xml` dependency management for `quarkus-messaging-kafka`, `docs/runbooks/`, `docs/adr/0036-*.md`.
Not the services' code (WP67–WP69). Depends on: ADR-0008 (outbox + events), WP19 brief (`docs/wp/WP19-outbox-redpanda.md`),
WP46/WP65 (chart conventions, Secrets). Skills: podman-dev-env, owasp-security, verification-before-completion.
Worktree: `~/code/hoops-wt/wp66-redpanda`, branch `wp66-redpanda`.

Decision 48 of 2026-11-06: v2 events start now. Redpanda (single node, pinned image) is the broker in compose,
the chart (behind `events.enabled`, on for kind) and kind; tests use Quarkus Dev Services for Kafka (Redpanda
image pinned to the same version). ADR-0036 reserved for you (broker choice, topics and naming, retention,
auth inside the cluster, what the services will do in WP67–WP69).

## Scope
1. **compose**: `redpanda` service (pinned tag, resource-limited, dev mode, no auth) + `rpk` topic bootstrap of the
   seven topics from the WP19 brief (`core.person`, `core.player`, `core.team`, `core.team-player`,
   `core.team-staff`, `core.guardian-link`, `core.tenant`) with 1 partition each (document the key: tenant id +
   aggregate id); a `just events-topics` recipe; `just up` includes it; `.env.example` keys if any.
2. **Chart**: `redpanda` StatefulSet or the official chart as a dependency (pin; compare size/complexity and decide
   in the ADR), NetworkPolicy that admits only the three services, read-only root FS / non-root like the other
   pods, SASL/SCRAM inside the cluster with credentials from a Secret (`secrets.sh` + the WP65 ESO path), topic
   bootstrap Job; chart tests and snapshots; `kubeconform` schemas if CRDs are involved.
3. **kind**: `up.sh` deploys it with the kind values; `smoke.sh` gains a broker check (`rpk cluster health` or the
   admin API); delete the cluster at the end.
4. **Dev Services**: root pom `quarkus-messaging-kafka` managed version; a `libs/common-quarkus` note on
   `quarkus.kafka.devservices.image-name` pinned; nothing enabled in the services yet (WP67).
5. **Docs**: ADR-0036; runbooks (`kind.md`, deploy §4 in `release.md`, a short `events.md` runbook: topics, how to
   tail with `rpk`, reset a consumer group).

## Acceptance
- [ ] `just up` with Redpanda healthy and the topics present (`rpk topic list` output in the handover); `just e2e`
      still 21/21 on compose
- [ ] `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED; kind: Redpanda ready behind the NetworkPolicy, smoke green;
      cluster deleted
- [ ] `shellcheck -S warning` and `actionlint` clean on anything touched; ADR-0036 written and indexed (append at the
      end of `docs/adr/README.md`); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it. End every commit message with the line
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Other agents run Testcontainers builds on the same machine; the compose stack ports and kind are yours this wave.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- **Built:**
  - compose: `redpanda` v26.2.6 (digest pinned), dev-container mode, 1 CPU / 1 GiB, no auth, Kafka `localhost:19092`, admin
    `localhost:19644`, volume `redpanda-data`; `redpanda-bootstrap.yaml` (no topic auto-creation, no metrics reporter);
    `redpanda-topics.sh` (seven topics, 1 partition, compacted, `retention.ms=-1`, tombstones 7 days; idempotent);
    `just events-topics`, run by `just up`.
  - Chart 0.6.0: own `templates/redpanda.yaml` + `files/redpanda-bootstrap.sh` behind `events.enabled` (on in
    `values-kind.yaml`): StatefulSet (uid 101, read-only root FS, config from a read-only ConfigMap, PVC), headless Service,
    NetworkPolicy (Kafka from the three services + Job, admin API from the Job, egress DNS only), SASL/SCRAM listener,
    admin API auth, `kafka_enable_authorization`, superuser from `RP_BOOTSTRAP_USER`, post-install/upgrade Job (cluster
    properties, users with passwords from Secrets, prefixed ACLs, topics). ESO: `externalSecrets.events` (four logins).
    NOTES. 17 new chart assertions.
  - kind: four Secrets `hoops-redpanda-{admin,core-service,game-service,athlete-service}` (basic-auth) from
    `REDPANDA_*_PASSWORD`; Tiltfile resources `redpanda`, `redpanda-bootstrap`; smoke broker block.
  - Dev Services: `quarkus.kafka.devservices.provider=redpanda` + image pin noted (commented) in `libs/common-quarkus`;
    root pom note (BOM manages `quarkus-messaging-kafka`, kafka-clients 4.2.1).
  - Docs: ADR-0036, `docs/runbooks/events.md`; `kind.md`, `release.md` §4, `rotate-secrets.md`, `infra/compose/README.md`.
- **Verified:**
  - `just up`: Redpanda healthy, `rpk topic list`:
    `core.guardian-link, core.person, core.player, core.team, core.team-player, core.team-staff, core.tenant` (1 partition,
    1 replica each), config compact / -1 / 604800000; second run "kept". A host Quarkus app round-tripped through
    `localhost:19092`. `just e2e` on compose: JourneyTest 23/23 (27 with MailSinkTest; 23 since WP57), 0 failures.
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED (112 ok, kubeconform 230/230); six mutations of the new assertions
    each failed as expected. `shellcheck -S warning` and `actionlint` clean. `trivy fs` misconfig HIGH/CRITICAL clean.
  - kind (fresh cluster, freshly imported realm, twice; the second on the final rebased tree): `up.sh --deploy --from-host`
    7 min 20 s / 6 min 48 s; Job succeeded on its first run; `smoke.sh core game athlete` SMOKE PASSED (35 checks, incl.
    the ADR-0034 audience checks WP56 asked for). NetworkPolicy/ACL probes, rotation of a service user and of the
    superuser, ESO sync of the four logins: see `kind.md` "Verification status" WP66. Cluster deleted.
  - Dev Services: throwaway `@QuarkusTest` emitter -> `@Incoming` round trip on v26.2.6 passed.
  - `./mvnw -pl libs/common-quarkus,libs/contracts verify`: 342 tests, 0 failures. Full `just test` not run (no Java change).
- **Decisions/ADRs:** ADR-0036 (own StatefulSet over the official chart; one partition; key `<tenant id>:<aggregate id>`;
  compaction; SCRAM per service + ACLs + NetworkPolicy; client settings for WP67-WP69).
- **Found:** SASL on the listener alone authenticates but does not authorise; Quarkus 3.40 needs the `redpanda` provider for
  this image; re-POSTing an existing user answers 500 (the Job PUTs).
- **Open points:** pending user action: add the four `REDPANDA_*_PASSWORD` keys to the main `.env`, or
  `secrets.sh`/`eso-store.sh` stop. Docs pass: main's `.trivyignore.yaml` KSV-0109 statement covers the snapshots but names
  only the blocklist; `redpanda-bootstrap` (a script, no credentials) fires it too. Services' `KAFKA_*` env and
  `secretEnv` are WP67-WP69's. The Job never deletes ACLs or changes partitions. Default (non-kind) sizing is unproven.
  Not run: `tilt ci`, `up.sh --eso --deploy`.
