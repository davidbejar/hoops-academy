# ADR-0036: Redpanda as the event broker: topics, keys, retention, auth inside the cluster

- Status: Accepted
- Date: 2026-11-06
- Related: decision 48 of 2026-11-06, WP66 (infrastructure), WP67 (core outbox publisher), WP68/WP69 (replicas in game
  and athlete), ADR-0008 (sync REST for v1, outbox + Redpanda for v2), WP19 brief, ADR-0012 (Secrets)

## Context
Decision 48 starts the v2 events of ADR-0008: core writes its roster changes to a transactional outbox and publishes
them; game and athlete keep local replicas instead of calling core's `/internal` API for every authorisation. WP66 puts
the broker in place for every environment (compose, the Helm chart, kind, the tests) before any service uses it, so
WP67 to WP69 only write service code. Constraints: a 2-CPU / 8 GiB Podman VM runs compose and kind side by side; no
Node; Secrets never in git or in rendered manifests; tenant isolation must not depend on the broker.

## Decision
1. **Broker: Redpanda, one node, `docker.io/redpandadata/redpanda:v26.2.6`** (pinned by digest
   `sha256:8b1076e0d61b...` in compose and the chart; 14 days old when chosen). Kafka API compatible, so the services use
   the standard `quarkus-messaging-kafka` client (kafka-clients 4.2.1 from the Quarkus BOM, no version override in the
   root pom). One C++ binary without a JVM or ZooKeeper, which matters on the small VM (about 110 MB resident idle in
   compose, Seastar memory capped at 512M on kind, 1G by default). One node only: replication factor 1, no rack
   awareness. A second node is a values change plus seed servers, not in scope.
2. **The same version everywhere.** compose (`infra/compose/compose.yaml`), the chart (`events.redpanda.image`) and the
   Quarkus Dev Services for the tests (`libs/common-quarkus`: `quarkus.kafka.devservices.provider=redpanda` and
   `image-name`, commented until WP67 adds the extension) name the same tag; `deploy/helm/tests/run.sh` fails when they
   differ. Quarkus 3.40 defaults to the `upstream-kafka-native` provider and to Redpanda v24.1.2 for the `redpanda`
   provider; both are overridden. A `@QuarkusTest` round trip (emitter -> topic -> `@Incoming`) passed on v26.2.6 with
   the provider set. Without it the Redpanda image's entrypoint rejects the start command of the default Kafka
   container (`rpk: unknown shorthand flag: 'c'`).
3. **Chart: own StatefulSet instead of the official `redpanda` chart.** The official chart (26.2.5, 68 files)
   renders 20 objects for one node: four cert-manager `Certificate`s and four `Issuer`s (TLS on by default, CRDs needed),
   two `Secret`s, RBAC, a `busybox:latest` init image and a post-install Job. It conflicts with three chart rules
   (no Secret rendered, pinned images, no CRDs we do not validate) and would need most of its defaults turned off. The
   own template (`templates/redpanda.yaml` and `files/redpanda-bootstrap.sh`, about 360 lines) is a ConfigMap with the node
   configuration, a headless Service `redpanda`, a StatefulSet with one persistent volume, a NetworkPolicy, and a
   bootstrap Job with its ConfigMap. It follows the conventions of `ratelimit-redis`: non-root (uid 101), read-only root
   FS (the node configuration is a read-only ConfigMap; the `redpanda` binary runs directly, not `rpk redpanda start`,
   which rewrites `redpanda.yaml`), all capabilities dropped, no service account token, memory limit. Behind
   `events.enabled` (off by default, on in `values-kind.yaml` with `developer_mode` and 512M). A production cluster may
   prefer the Redpanda operator; the services only see a bootstrap address and SCRAM credentials, so that swap does not
   touch them.
4. **Topics `<producer>.<aggregate>`**, from the WP19 brief: `core.person`, `core.player`, `core.team`,
   `core.team-player`, `core.team-staff`, `core.guardian-link`, `core.tenant`. Created explicitly (compose:
   `just events-topics`; chart: the bootstrap Job); `auto_create_topics_enabled` is off, so a typo in a producer fails
   instead of creating a topic. **One partition each**: all events of a topic stay in outbox order, which is what a
   replica needs. The partition count can grow later (`rpk topic add-partitions`); the key keeps the order per
   aggregate then.
5. **Key: `<tenant id>:<aggregate id>`** (two UUIDs, colon separated, e.g.
   `2b1c...:9f0e...`). The tenant id is part of the key so compaction can never merge two tenants' records, even if
   aggregate ids were ever reused across tenants. Every event also carries `tenantId` in its envelope (WP67), and the
   consumers bind the tenant from the event, never from a request.
6. **Retention: compacted topics** (`cleanup.policy=compact`, `retention.ms=-1`): the latest event per key stays
   forever, so a replica is rebuilt by replaying a topic from the start (WP19 acceptance: "replica equals core after
   replay from empty") and no event is lost because a consumer was down. A delete is a tombstone (null value) kept 7
   days (`delete.retention.ms=604800000`): a consumer that is down longer misses the delete and must replay from the
   start (`docs/runbooks/events.md`). Older events of the same key go away after compaction, so the events are state
   transfer (the full current aggregate in every event), not a change log. compose and chart use the same settings.
7. **Auth inside the cluster (chart): SASL/SCRAM-SHA-256 + ACLs + NetworkPolicy.**
   - The Kafka listener requires SASL (`authentication_method: sasl`); the admin API requires the superuser's basic
     auth (`admin_api_require_auth`; its status endpoints, used by the probes, stay open). No TLS inside the cluster:
     the pod network is the trust boundary, as for Postgres; SCRAM does not send the password.
   - `kafka_enable_authorization: true`. Found in WP66: with SASL configured only on the listener (`enable_sasl` false,
     the newer way), Redpanda authenticates but does **not** authorise; a fresh SCRAM user without any ACL created a
     topic. The chart sets the property at bootstrap and the Job sets it again on every upgrade.
   - One superuser `admin`, created by Redpanda at bootstrap from `RP_BOOTSTRAP_USER` (built in the pod spec from the
     Secret via `$(RP_ADMIN_PASSWORD)`, so no value is rendered). Used only by the bootstrap Job and operators.
   - One SCRAM user per service, named like the service (`core-service`, `game-service`, `athlete-service`) with
     prefixed ACLs from `events.users`: core writes `core.*` (write + describe); game and athlete read `core.*`
     (read + describe) and use consumer groups starting with their name (`game-service.`, `athlete-service.`, e.g.
     `game-service.roster`). The bootstrap Job creates the users through the admin API (password in a JSON body on
     stdin, the admin login from a netrc on a file descriptor, never on a command line) and sets each password again
     on every run, so a rotated Secret reaches the broker with the next `helm upgrade`.
   - NetworkPolicy: Kafka (9092) only from pods labelled `app.kubernetes.io/name` = one of the users (the services'
     own labels) or `redpanda-bootstrap`; the admin API (9644) only from the bootstrap Job; egress DNS only (the
     metrics reporter is off as well).
   - Secrets `hoops-redpanda-admin` and `hoops-redpanda-<service>` (kubernetes.io/basic-auth, username = user), from
     `.env` `REDPANDA_*_PASSWORD` on kind (`deploy/kind/secrets.sh`) or from the External Secrets Operator
     (`externalSecrets.events`, WP65 path).
   - compose has no auth: it binds to 127.0.0.1 only and holds development data.
8. **What the services will do (WP67 to WP69).** Client settings, by environment variable so the chart can wire them
   when WP67 to WP69 turn the clients on (not done in WP66: a `secretKeyRef` to a Secret that only exists with
   `events.enabled` would stop the pods of a release without events):
   `KAFKA_BOOTSTRAP_SERVERS` = `localhost:19092` (compose, host mode) or `redpanda.<namespace>.svc.cluster.local:9092`
   (chart); on the chart additionally `kafka.security.protocol=SASL_PLAINTEXT`, `kafka.sasl.mechanism=SCRAM-SHA-256`
   and a `ScramLoginModule` JAAS config with the service's user and the `password` key of `hoops-redpanda-<service>`.
   WP67: core's outbox publisher, producer keyed as in 5, at-least-once. WP68/WP69: consumers in groups
   `<service>.<projection>`, idempotent upserts (duplicate `eventId` ignored, older `occurredAt` never overwrites
   newer), tenant bound per event.

## Consequences
- One more stateful workload on kind (512 Mi request, 768 Mi limit, 1 Gi volume) and in compose (1 CPU, 1 GiB limit,
  volume `redpanda-data`). `just down` keeps the volume, like `pgdata`, so the outbox and the topics stay consistent.
- The broker is not on the request path yet; nothing changes for the services until WP67 to WP69.
- An ACL removed from `events.users` is not removed by the Job (it only adds); remove it with `rpk security acl delete`
  (runbook). Partitions are never changed by the Job.
- The superuser's password is set only at bootstrap; rotating it is a manual `rpk security user update` before the
  Secret changes (`docs/runbooks/events.md`, `rotate-secrets.md`). The service users rotate with the Secret plus a
  `helm upgrade` (the Job) and a restart of the service.
- No schema registry and no HTTP proxy: the event contracts are JSON Schemas in `libs/contracts/events` (WP67),
  validated by the consumers.

## Alternatives considered
- **Apache Kafka (KRaft) or Strimzi**: the reference implementation, but a JVM broker (about 1 GiB more on the VM) and,
  with Strimzi, an operator and CRDs. Redpanda speaks the same protocol, so the decision is reversible without code
  changes.
- **The official Redpanda chart or operator**: see 3; worth reconsidering for a multi-node production cluster.
- **mTLS between the services and the broker**: needs a CA and certificate rotation (cert-manager) for little gain
  inside the cluster network; SCRAM per service gives the same identity for the ACLs.
- **Delete retention (time based)**: simpler, but a replica could no longer be rebuilt from the topic once events age
  out; compaction keeps the latest state per key.
