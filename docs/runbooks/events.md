# Runbook: events (Redpanda)

ADR-0036 (WP66): one Redpanda node carries core's roster events to game and athlete (ADR-0008 v2). The publisher
(WP67) and the replicas (WP68, WP69) add their own sections at the end of this file.

| | compose (`just up`) | kind / chart (`events.enabled`) |
|---|---|---|
| Broker | container `hoops-redpanda`, volume `hoops_redpanda-data` | StatefulSet `redpanda` (pod `redpanda-0`), PVC `data-redpanda-0` |
| Kafka API | `localhost:19092` (host), `redpanda:9092` (compose network) | `redpanda.<namespace>.svc.cluster.local:9092` |
| Auth | none (127.0.0.1 only) | SASL_PLAINTEXT, SCRAM-SHA-256; one user per service + superuser `admin`; ACLs enforced |
| Admin API | `localhost:19644` | `:9644`, superuser basic auth, reachable only from the bootstrap Job (NetworkPolicy) |
| Topics | `just events-topics` (run by `just up`) | Job `redpanda-bootstrap` (Helm post-install/upgrade hook) |

## Topics
`core.person`, `core.player`, `core.team`, `core.team-player`, `core.team-staff`, `core.guardian-link`, `core.tenant`:
one partition each, `cleanup.policy=compact`, `retention.ms=-1`, tombstones kept 7 days (`delete.retention.ms`). Key
`<tenant id>:<aggregate id>`. The list and settings live in `infra/compose/redpanda-topics.sh` and in the chart's
`events.topics` (`deploy/helm/hoops/values.yaml`); `deploy/helm/tests/run.sh` fails when they differ. Topic
auto-creation is off: add a topic in both places, then `just events-topics` / `helm upgrade`.

## rpk
compose (no login):
```bash
podman exec hoops-redpanda rpk cluster health
podman exec hoops-redpanda rpk topic list
podman exec hoops-redpanda rpk topic describe core.person -c          # configuration
podman exec -it hoops-redpanda rpk topic consume core.person -o start -f '%k %v\n'   # tail from the start (Ctrl-C)
podman exec hoops-redpanda rpk group list
```
kind: `rpk` runs inside `redpanda-0` as the superuser, whose password is already in that container's environment
(`RP_ADMIN_PASSWORD`); keep the single quotes so it is expanded there, not in your shell:
```bash
rpk_k() { kubectl -n hoops exec -i redpanda-0 -c redpanda -- bash -c \
  "RPK_USER=admin RPK_PASS=\"\$RP_ADMIN_PASSWORD\" RPK_SASL_MECHANISM=SCRAM-SHA-256 rpk $*"; }
kubectl -n hoops exec redpanda-0 -c redpanda -- rpk cluster health   # no login needed (status endpoint)
rpk_k topic list
rpk_k "topic consume core.person -o start -f '%k %v\n'"
rpk_k security user list
rpk_k security acl list
kubectl -n hoops logs job/redpanda-bootstrap                          # what the last bootstrap did
```
`deploy/kind/smoke.sh` checks health, the bootstrap Job, SASL, `kafka_enable_authorization`, the topics and the users.

## Reset a consumer group (replay)
A consumer group can be moved only while it has no members:
```bash
kubectl -n hoops scale deploy/game-service --replicas=0               # compose: stop the service (just services-down)
rpk_k group describe game-service.roster
rpk_k group seek game-service.roster --to start                       # or --to end, --to <unix ms timestamp>
kubectl -n hoops scale deploy/game-service --replicas=1
```
compose: the same `rpk group seek` through `podman exec hoops-redpanda`. `rpk group delete <group>` forgets the group's
offsets completely (the consumer then starts at its `auto.offset.reset`). Groups start with the service name
(`game-service.`, `athlete-service.`): the ACLs allow no other names.

A consumer that was down longer than 7 days may have missed tombstones (deletes): replay it from the start.

## Users, ACLs and rotation (kind / chart)
The Job `redpanda-bootstrap` runs after every `helm install`/`upgrade` (Tilt applies it like any Job). It sets the
cluster properties (`events.redpanda.clusterConfig`), creates or updates the SCRAM users of `events.users` with the
passwords of their Secrets, adds their prefixed ACLs and creates missing topics. It never deletes anything:
```bash
rpk_k security acl delete --allow-principal User:game-service --operation read --topic core. \
  --resource-pattern-type prefixed --no-confirm                        # an ACL removed from the values
```
Rotate a service user: change its Secret (`.env` + `deploy/kind/secrets.sh | kubectl apply -f -`, or the ESO source) and
run the Job again (`helm upgrade`, or with Tilt trigger `redpanda-bootstrap`). Reloader (chart 0.8.0, WP87) restarts the
service when its Secret changes; without it, `kubectl -n hoops rollout restart deploy/<service>` after the Job.

### Rotate the superuser
The broker reads `RP_BOOTSTRAP_USER` only when the cluster is created, so change the broker first, then the Secret:
```bash
new=$(openssl rand -hex 24)                                           # in a shell without history
printf '%s\n' "$new" | kubectl -n hoops exec -i redpanda-0 -c redpanda -- bash -c '
  read -r NEW
  printf "{\"username\":\"admin\",\"password\":\"%s\",\"algorithm\":\"SCRAM-SHA-256\"}" "$NEW" |
    curl -sf -o /dev/null -w "%{http_code}\n" -X PUT -H "Content-Type: application/json" --data-binary @- \
      --netrc-file <(printf "machine localhost login admin password %s\n" "$RP_ADMIN_PASSWORD") \
      http://localhost:9644/v1/security/users/admin'                  # 200
# then: REDPANDA_ADMIN_PASSWORD=$new in .env (or the ESO source), deploy/kind/secrets.sh | kubectl apply -f -;
# Reloader restarts redpanda-0 (its RP_ADMIN_PASSWORD follows the Secret); without Reloader:
kubectl -n hoops rollout restart statefulset/redpanda
unset new
```

## Reset the broker
compose: `podman rm -f hoops-redpanda && podman volume rm hoops_redpanda-data && just up` (all events gone; the
consumers must then rebuild from core, WP68/WP69). kind: `kubectl -n hoops delete statefulset redpanda && kubectl -n hoops
delete pvc data-redpanda-0`, then `helm upgrade` (or Tilt) recreates both and the Job bootstraps again.

## Troubleshooting
- `SASL_AUTHENTICATION_FAILED`: wrong password or the Job has not run since the Secret changed (see rotation).
- `TOPIC_AUTHORIZATION_FAILED` / `GROUP_AUTHORIZATION_FAILED`: the user has no ACL for that topic or the group name does
  not start with the service name; `rpk_k security acl list`.
- A client times out connecting on kind: the NetworkPolicy admits only pods whose `app.kubernetes.io/name` is one of
  `events.users` (the services) or `redpanda-bootstrap`.
- `redpanda-0` restarts with an out-of-memory kill: the container limit must stay well above `events.redpanda.memory`
  (Seastar's memory, `--memory`); kind uses 512M with a 768Mi limit.
- The bootstrap Job fails: `kubectl -n hoops logs job/redpanda-bootstrap`; it waits up to 5 min for the broker and is
  retried 6 times.

## Core publisher (WP67)
core appends every roster change to `core.outbox` in the same transaction and publishes it (ADR-0008 amended). The
contracts are `libs/contracts/events/core.<aggregate>.schema.json`.

| Setting | Default | What |
|---|---|---|
| `hoops.outbox.poll-interval` (`CORE_OUTBOX_POLL_INTERVAL`) | `1s` | publisher period; `off` stops publishing (the outbox still fills) |
| `hoops.outbox.batch-size` (`CORE_OUTBOX_BATCH_SIZE`) | `100` | rows per transaction and tenant |
| `hoops.outbox.send-timeout` (`CORE_OUTBOX_SEND_TIMEOUT`) | `PT10S` | wait for the broker's acknowledgement before the run gives up |
| `hoops.outbox.producer-reset-after` (`CORE_OUTBOX_PRODUCER_RESET_AFTER`) | `3` | failed sends in a row after which the Kafka producer is replaced (WP81) |
| `hoops.outbox.backfill.chunk-size` | `200` | aggregates per transaction of the events backfill (WP81) |
| `KAFKA_BOOTSTRAP_SERVERS` | `localhost:19092` (prod profile) | compose host mode; dev mode and tests use Dev Services Redpanda |
| `KAFKA_SECURITY_PROTOCOL`, `KAFKA_SASL_USERNAME`, `KAFKA_SASL_PASSWORD` | `PLAINTEXT`, `core-service`, empty | chart: `SASL_PLAINTEXT` + the `hoops-redpanda-core-service` Secret (SCRAM-SHA-256) |
| `kafka.request.timeout.ms`, `kafka.delivery.timeout.ms`, `kafka.max.block.ms`, `kafka.linger.ms` | `5000`, `8000`, `5000`, `0` | the producer's timeouts (any `kafka.*` key reaches it; acks=all, idempotence and the serializers are fixed in code) |

Watch it:
```bash
curl -s localhost:8081/q/health/ready | jq '.checks[] | select(.name == "outbox-publisher")'   # state OK | DEGRADED
curl -s localhost:8081/q/metrics | grep '^hoops_outbox'        # published_total{topic}, pending, lag_seconds, broker_available,
                                                               # producer_resets_total, backfill_appended_total{topic}
podman exec -it hoops-redpanda rpk topic consume core.team -o start -f '%k %v\n'
```
Backlog per tenant (as the schema owner or `core_platform`; payloads stay unreadable to the platform role):
```sql
select tenant_id, count(*), min(occurred_at) from core.outbox
 where published_at is null and topic is not null group by tenant_id order by 3;
```
- **Broker down**: the API keeps working, `state` turns `DEGRADED`, `hoops_outbox_broker_available` 0 and the lag grows.
  Nothing to do in core: when the broker is back the next runs drain the backlog in order. A run stops at the first
  failed send and retries next period.
- **Core started before its broker user existed** (fresh Helm install, WP71): the first login fails and the idempotent
  producer would never recover by itself. Since WP81 core replaces its producer after
  `hoops.outbox.producer-reset-after` failed sends in a row (log `... sends in a row failed (last: ...); replacing the
  Kafka producer`, `hoops_outbox_producer_resets_total` +1) and drains the backlog once the user exists: no restart.
  The counter also grows slowly during a plain outage (one replacement per three failed runs); that is expected.
- **A row that never goes out** while others do: another transaction holds its lock (or an older row of the same
  aggregate). Find it in `pg_locks` / `pg_stat_activity`; the publisher never skips ahead of it for that aggregate.
- **Republish** (a consumer lost a topic and replaying it is not enough): `update core.outbox set published_at = null
  where topic = 'core.<aggregate>' and tenant_id = '<id>'` as the schema owner; the events go out again with their
  original `eventId`, which the consumers ignore if they have applied it. Prefer replaying the compacted topic.
- Rows with `topic` null are core's internal v1 notifications (`player.approved`, `tenant.suspended`, ...): never
  published, kept for billing and audits.

## Backfill and shadow period (WP81)
Roster data written before core's publisher went live (WP67) has no event, so a replica built from the topics does not
know it (ADR-0037 "When rest flips"). The backfill appends one `<aggregate>.changed` per live aggregate without a roster
event to the outbox, from the current state and under the writers' locks; the publisher sends it like any change.

```bash
just events-backfill                       # compose: every academy; signs in as the seeded superadmin (DEV_USER_PASSWORD)
just events-backfill <tenant-id>           # one academy
just events-backfill force                 # every live aggregate again (a fresh snapshot; consumers see newer state)
# elsewhere: POST /platform/events/backfill as a super admin, body {"tenantId": "...", "force": false} (both optional)
```
The answer counts the academies, the failed ones (logged, the others go on; run again) and the events per topic.
Idempotent: without `force` a second run appends nothing. Each academy that got events has an audit row
`tenant.events_backfilled` (`force`, `events`, `topics`); `/q/metrics` shows `hoops_outbox_backfill_appended_total{topic}`
and the log one line per academy. A person's player follows its person and is counted under `core.player`.

Check that the topics hold every row (compose; the latest record per key is a `.changed`, removed keys excluded):
```bash
podman exec hoops-redpanda rpk topic describe core.person -p      # high watermark per partition
podman exec -i hoops-postgres psql -U postgres -d hoops -c 'select count(*) from core.person'
```

### Shadow period, then the flip
1. Run the backfill with both services on `rest` (the default); the consumers fill the replicas in the shadow.
2. Watch, over days in a shared environment: `hoops_roster_replica_parked_total` stays 0 in game and athlete, the
   `hoops_roster_replica_lag_seconds` gauges stay in seconds, both groups' `TOTAL-LAG` is 0 (`rpk group describe`),
   and the replica row counts equal core's (`game.*_ref`, `athlete.*_ref` without `removed` rows vs `core.*`).
3. Run the journeys with both replicas: `GAME_ROSTER_SOURCE=replica ATHLETE_ROSTER_SOURCE=replica just e2e`.
4. The flip (ADR-0037) then needs a decision of the owner: change the default of `hoops.roster.source` (or the chart's
   `game.rosterSource` / `athlete.rosterSource`) to `replica`; `rest` stays the fallback switch.

Evidence of WP81 on compose (2026-11-07, data from rounds 1 to 4, 46 academies): before the backfill the topics held
31 of 169 persons, 12 of 64 players, 8 of 43 teams, 21 of 121 assignments, 7 of 41 staff entries, 4 of 22 guardian
links and 7 of 46 academies; the backfill appended 416 events (138, 52, 35, 100, 34, 18, 39) in 13 s, the second run 0;
afterwards every topic's live keys equal the table rows (0 missing, 0 extra), both replicas hold exactly core's counts,
parked 0, lag 0.87 to 0.99 s, group lag 0. Then `GAME_ROSTER_SOURCE=replica ATHLETE_ROSTER_SOURCE=replica just e2e`:
JourneyTest 23/23 (27 with MailSinkTest), both services logged their replica source, parked still 0, group lag 0.

## Game roster replica (WP68)
game keeps a replica of the roster data it reads from core (`game.*_ref`, V4), fed by the `core.*` topics (ADR-0037).
`hoops.roster.source` picks what `RosterPort` and the tenant filter read; the consumer feeds the replica in both modes.

| Setting | Default | What |
|---|---|---|
| `hoops.roster.source` (`GAME_ROSTER_SOURCE`) | `rest` | `rest` = core `/internal` (cached 30 s); `replica` = the local replica, no call to core on the request path |
| `mp.messaging.incoming.core-roster.enabled` (`GAME_ROSTER_CONSUMER_ENABLED`) | `true` | `false` stops feeding the replica (escape hatch; only with `rest`) |
| `hoops.roster.replica.apply-attempts` | `3` | attempts per event (1 s, 2 s between) before the consumer stops |
| `KAFKA_BOOTSTRAP_SERVERS` | `localhost:19092` (prod profile) | compose host mode; dev mode and tests use Dev Services Redpanda |
| `KAFKA_SECURITY_PROTOCOL`, `KAFKA_SASL_USERNAME`, `KAFKA_SASL_PASSWORD` | `PLAINTEXT`, `game-service`, empty | chart: `SASL_PLAINTEXT` + the `hoops-redpanda-game-service` Secret (SCRAM-SHA-256) |

Consumer group `game-service.roster` (one channel `core-roster` over the seven topics), `auto.offset.reset=earliest`:
a new group replays everything.

Watch it:
```bash
curl -s localhost:8082/q/metrics | grep '^hoops_roster_replica'   # events_total{topic,outcome}, parked_total{topic}, lag_seconds{topic}
podman exec hoops-redpanda rpk group describe game-service.roster  # LAG per topic (0 = caught up)
curl -s localhost:8082/q/health/live | jq '.checks[] | select(.name | test("Messaging"))'
```
`outcome` is `applied`, `duplicate` (a redelivered `eventId`, nothing changed), `stale` (older than the stored row,
nothing changed) or `tombstone` (skipped; removals are soft, `removed = true`; since WP82 for every aggregate: a removed
person, player, team, assignment or tenant keeps only its id and reads leave it out). `lag_seconds` is the age of the last
event when it was processed: a few seconds normally (core's poll interval plus the fetch).

- **Parked records** (`hoops_roster_replica_parked_total` > 0): records that broke their contract (JSON Schema, key
  `<tenantId>:<aggregateId>`) are not applied and not retried. Read them as the schema owner (game_app may only insert):
  ```sql
  set role game_migrator;
  select id, parked_at, inspected_at, topic, kafka_partition, kafka_offset, record_key, event_id, reason
    from game.parked_event order by id desc limit 20;
  ```
  then look at the record itself: `rpk topic consume <topic> -p <partition> -o <offset> -n 1`. The aggregate is
  repaired by its next event or, once the producer is fixed, by a replay.
- **Consumer stopped** (liveness and readiness DOWN, log `Applying event ... failed 3 times, stopping the consumer`):
  usually the database. The orchestrator restarts the pod; it resumes from the committed offset, nothing is lost. On
  compose restart game (`just services-down && just services-up`).
- **Broker down**: nothing to do in game; the replica stays readable and goes stale (`lag_seconds` grows once events
  flow again); the client reconnects.

### Housekeeping: what the retention job deletes (WP82)
A daily job (`ReplicaRetentionJob`, one pod at a time: advisory lock `game.replica-retention`) deletes two kinds of
bookkeeping rows, logs what it deleted (`Replica retention: deleted N applied event ids recorded before ... ; M parked
records inspected before ...: [core.person-0@17, ...]`) and counts them in
`hoops_roster_replica_pruned_total{table="applied_event"|"parked_event"}`.

| Setting | Default | What |
|---|---|---|
| `hoops.roster.replica.retention.cron` | `0 40 3 * * ?` | when it runs (`off` disables it; tests run with `off`) |
| `hoops.roster.replica.retention.applied-events` | `P7D` | `applied_event` rows older than this go; never below the topics' 7-day tombstone retention (game refuses to start) |
| `hoops.roster.replica.retention.parked-events` | `P30D` | `parked_event` rows go this long after an operator marked them inspected |
| `hoops.roster.replica.retention.batch-size` | `1000` | applied ids deleted per transaction and tenant (`for update skip locked`) |

- **applied_event**: the event ids the consumer already applied (idempotency). A redelivery comes at most as long as
  the topics keep a record, so after 7 days an id is no longer needed; an older redelivery would still be harmless
  (the row's `occurred_at` guard makes it `stale`). The tenants are listed in `game.replica_tenant` (global, ids only).
- **parked_event**: never deleted before an operator looked at it. Inspect, then mark (as `game_migrator`):
  ```sql
  set role game_migrator;
  select id, parked_at, topic, kafka_partition, kafka_offset, record_key, event_id, reason
    from game.parked_event where inspected_at is null order by id;
  -- after reading the record (rpk topic consume <topic> -p <partition> -o <offset> -n 1) and fixing the cause:
  update game.parked_event set inspected_at = now() where id in (...);
  ```
  The row goes `parked-events` (30 days) after that. Uninspected rows stay; `hoops_roster_replica_parked_total` still
  counts them since the start of the pod.

### Replay (rebuild the replica from the topics)
Needed after a broker reset, a fix of parked records, or a game outage longer than the tombstone retention (7 days).
The replica tables and `game.applied_event` must be emptied, otherwise every replayed event is a known duplicate.
compose:
```bash
just services-down            # or stop the game jar only; the group must have no members
just events-replay game       # empties game.*_ref + game.applied_event (as game_migrator), rpk group seek --to start
just services-up              # game replays and catches up (rpk group describe: LAG 0)
```
kind: `kubectl -n hoops scale deploy/game-service --replicas=0`; empty the tables as `game_migrator`
(`truncate game.tenant_ref, game.person_ref, game.player_ref, game.team_ref, game.team_player_ref, game.team_staff_ref,
game.guardian_link_ref, game.applied_event`); `rpk_k group seek game-service.roster --to start`; scale back. With
`hoops.roster.source=replica`, switch to `rest` for the duration (requests would otherwise see an empty replica).

### Before switching to `replica`
ADR-0037 "When rest flips to replica": core has published every aggregate (a replica only knows aggregates that changed
after core's publisher went live; data older than WP67 needs a core backfill), `parked_total` is 0, `lag_seconds` stays
in seconds, and the chart wires the Kafka client. Switch with `GAME_ROSTER_SOURCE=replica` and a restart; back with
`rest`.

## Athlete replica (WP69)
athlete keeps a local copy of core's roster in `athlete.*_ref` (V6), fed by core's events (ADR-0037, athlete section).
`hoops.roster.source` decides whether the use cases' `RosterPort` and the tenant filter's membership read it
(`replica`) or core's `/internal` API (`rest`, the default). The consumer runs in both modes, so the replica fills in
the shadow while REST answers.

| Setting | Default | What |
|---|---|---|
| `hoops.roster.source` (`ATHLETE_ROSTER_SOURCE`) | `rest` | `replica` = RosterPort + membership from the replica; needs the consumer on (startup fails otherwise) |
| `hoops.roster.consumer.enabled` (`ATHLETE_ROSTER_CONSUMER_ENABLED`) | `true` | consumer of channel `core-roster` (all seven `core.*` topics), group `athlete-service.roster` |
| `hoops.roster.replica.max-attempts` (`ATHLETE_ROSTER_REPLICA_MAX_ATTEMPTS`) | `5` | tries per record when the database fails (backoff 0.5 s, doubling); then the channel fails |
| `KAFKA_BOOTSTRAP_SERVERS` | `localhost:19092` (prod profile) | compose host mode; dev mode and tests use Dev Services Redpanda |
| `KAFKA_SECURITY_PROTOCOL`, `KAFKA_SASL_USERNAME`, `KAFKA_SASL_PASSWORD` | `PLAINTEXT`, `athlete-service`, empty | chart: `SASL_PLAINTEXT` + the `hoops-redpanda-athlete-service` Secret (SCRAM-SHA-256) |

Run it on compose with the replica: `ATHLETE_ROSTER_SOURCE=replica just e2e` (or export it before `e2e/bin/services-up.sh`).

Watch it:
```bash
curl -s localhost:8083/q/metrics | grep '^hoops_roster_replica'   # events_total{topic,outcome}, parked_total{topic}, lag_seconds{topic}
curl -s localhost:8083/q/metrics | grep '^kafka_consumer_fetch_manager_records_lag'   # offset lag per partition
podman exec hoops-redpanda rpk group describe athlete-service.roster
```
- `outcome`: `applied` (the replica now holds the event's state), `duplicate` (eventId seen before: a redelivery or a
  replay over a filled replica), `stale` (an older event of an aggregate the replica holds newer), `tombstone` (the null
  record after a removal, skipped). Removals are soft for every aggregate since WP82: a removed person, player, team,
  assignment or tenant keeps only its id (`removed = true`) and reads leave it out; a tenant removal leaves
  `athlete.tenant_registry` alone. `lag_seconds` is how old the topic's last event was when athlete applied it.
- **Parked records** (`parked_total` > 0): a record broke the contract (schema, envelope, or a key that is not
  `<tenantId>:<aggregateId>` of its envelope). It is skipped, never applied. The app role may only insert into the
  table; read it as `athlete_migrator`:
  ```sql
  select topic, partition, kafka_offset, record_key, event_id, reason, parked_at, inspected_at
    from athlete.parked_event order by parked_at desc;
  ```
  then look at the record (`rpk topic consume <topic> -o <kafka_offset> -n 1`). The aggregate's next event repairs the
  replica (state transfer); after a producer fix, replay.
- **The consumer stopped** (liveness DOWN, pod restarted, a "Giving up on core.<topic>-0@<offset>" error in the log):
  applying (or parking) a record failed `max-attempts` times (database). The pod resumes from the last committed offset; if it
  keeps failing at the same offset, fix the database cause.
- **Broker down**: athlete keeps serving from the replica (readiness does not depend on the broker); the replica only
  gets older, `records_lag` grows once the broker is back and drains.

### Athlete housekeeping (WP82)
The same job as game's (`ReplicaRetentionJob`, advisory lock `athlete.replica-retention`, same log line and
`hoops_roster_replica_pruned_total{table}`), with the same keys: `hoops.roster.replica.retention.cron` (default
`0 45 3 * * ?`, `off` disables it), `.applied-events` (`P7D`, never below the 7-day tombstone retention: athlete refuses
to start), `.parked-events` (`P30D` after the inspection) and `.batch-size` (`1000`). Tenants come from
`athlete.replica_tenant`. Inspect and mark parked rows as `athlete_migrator`:
```sql
select topic, partition, kafka_offset, record_key, event_id, reason, parked_at
  from athlete.parked_event where inspected_at is null order by parked_at;
update athlete.parked_event set inspected_at = now() where topic = '<topic>' and partition = <p> and kafka_offset = <o>;
```
Uninspected rows are never deleted.

### Replay the athlete replica
Rebuilds the replica from the compacted topics, e.g. after the consumer was down longer than the 7 days tombstones are
kept, or after a parked-record fix. With `source=replica` athlete answers 404 for the tenants not yet replayed, so
switch to `rest` for the replay or do it in a maintenance window.
```bash
# 1. stop athlete (the group must have no members): just services-down / kubectl -n hoops scale deploy/athlete-service --replicas=0
# 2. empty the replica as the schema owner (truncate is not subject to RLS; applied_event too, or every event is a duplicate)
psql "postgresql://athlete_migrator@localhost:5432/hoops" -c 'truncate athlete.tenant_ref, athlete.person_ref,
  athlete.player_ref, athlete.team_ref, athlete.team_player_ref, athlete.team_staff_ref, athlete.guardian_link_ref,
  athlete.applied_event'
# 3. move the group to the start of the seven topics
podman exec hoops-redpanda rpk group seek athlete-service.roster --to start      # kind: rpk_k "group seek athlete-service.roster --to start"
# 4. start athlete; the replica is complete when records_lag is 0 for every core.* partition
```
A replay without step 2 is safe too (every event is a duplicate or stale) but does not remove entries whose removal
was compacted away. `RosterReplayTest` proves step 2 to 4 restore the same answers.
## Kubernetes (chart, WP71)
Chart 0.7.0 wires the three services to the in-chart broker. One switch, set twice because a service subchart sees only
its own values and `global`: `events.enabled` (broker, Job, NetworkPolicy, ESO logins) and its mirror
`global.events.enabled` (the services' Kafka client). The render fails when they differ, so an overlay cannot turn on one
half; `values-kind.yaml` sets both.

| | `events.enabled=true` | `events.enabled=false` (default) |
|---|---|---|
| `KAFKA_BOOTSTRAP_SERVERS` | `redpanda.<namespace>.svc.cluster.local:9092` | not set |
| `KAFKA_SECURITY_PROTOCOL` | `SASL_PLAINTEXT` (SCRAM-SHA-256 is the services' own setting) | not set |
| `KAFKA_SASL_USERNAME` | the service's name (`core-service`, `game-service`, `athlete-service`) | not set |
| `KAFKA_SASL_PASSWORD` | Secret `hoops-redpanda-<service>`, key `password` (a `secretKeyRef`, never in the ConfigMap) | not set |
| core publisher | on (`CORE_OUTBOX_POLL_INTERVAL` default `1s`) | `CORE_OUTBOX_POLL_INTERVAL=off` (the outbox still fills) |
| game / athlete consumer | on | `GAME_ROSTER_CONSUMER_ENABLED=false`, `ATHLETE_ROSTER_CONSUMER_ENABLED=false` |
| roster source | `game.rosterSource` / `athlete.rosterSource` -> `GAME_ROSTER_SOURCE` / `ATHLETE_ROSTER_SOURCE`, default `rest` | `rest` only (`replica` is refused) |

The render also refuses: a service without its `events.users` entry (name = the service, `passwordSecret:
hoops-redpanda-<service>`), a `rosterSource` other than `rest`/`replica`, and `KAFKA_*` in a service's `env`/`secretEnv`
while events are on (the chart owns the client). The off switches live in `<service>.events.offEnv`; a service's `env`
overrides them (a managed Kafka with `events.enabled=false`: set `KAFKA_*` and `CORE_OUTBOX_POLL_INTERVAL` in `env`, the
password through `secretEnv`). Check a release: `kubectl -n hoops get configmap core-service-env -o yaml | grep -E 'KAFKA|OUTBOX'`.

Watch it on kind (`/q/metrics` is not routed; read it inside the pod):
```bash
curl -s localhost:8090/api/core/q/health/ready | jq '.checks[] | select(.name == "outbox-publisher")'   # UP, state OK
m() { kubectl -n hoops exec deploy/$1 -c $1 -- curl -s localhost:$2/q/metrics; }
m core-service 8081 | grep -E '^hoops_outbox_(pending|lag|broker_available|published_total)'
m game-service 8082 | grep '^hoops_roster_replica'                  # events_total{outcome,topic}, parked_total, lag_seconds
m athlete-service 8083 | grep '^hoops_roster_replica'
rpk_k "group describe game-service.roster"                          # TOTAL-LAG 0 = caught up (section "rpk")
```
`deploy/kind/smoke.sh core game athlete` does all of this: it seeds a fresh academy (first admin: the seeded `admin1`, a
season, a team, a player), waits for `hoops_outbox_pending` 0 and both groups' lag 0, and checks parked 0 and that game
and athlete answer for the new academy.

**Fresh install: restart core once after the Job.** The Job `redpanda-bootstrap` is a post-install hook, so Helm runs it
only after `--wait`, when the services are already up: they start before their broker users exist and log `SASL
authentication failed`. game and athlete reconnect by themselves once the Job has run. core's idempotent producer does not
when its very first producer-id request failed authentication: every record then expires ("Expiring 1 record(s) ...
8000 ms has passed since batch creation", `hoops_outbox_pending` grows, state `DEGRADED`) until the pod restarts. Later
authentication failures (a user deleted or a password changed while core runs) heal by themselves once the user is back
(WP71: 2 pending, healed 10 s after the Job). `deploy/kind/up.sh` restarts core when its log shows the failure; Tilt
deploys core after `redpanda-bootstrap`; anywhere else: `kubectl -n hoops rollout restart deploy/core-service` after the
first install. The real fix (the producer recovering) is a core-service follow-up.

Flip one service to its replica (ADR-0037; the default stays `rest` until "When rest flips"):
```bash
helm upgrade hoops deploy/helm/hoops -n hoops -f deploy/helm/hoops/values-kind.yaml \
  --set athlete.rosterSource=replica --wait          # only athlete's ConfigMap changes; its pod rolls (checksum)
kubectl -n hoops logs deploy/athlete-service | grep 'Roster source'     # REPLICA (replica consumer on)
```
Back: the same with `rest`. With Tilt, put `athlete: {rosterSource: replica}` into the git-ignored `values-local.yaml`.

Secret rotation of a service's broker login (`hoops-redpanda-<service>`): the password is an env var, so a changed Secret
reaches no running pod by itself and Helm does not roll the Deployment for it (its checksum covers the ConfigMap only).
Since chart 0.8.0 (WP87) Reloader rolls the service as soon as the Secret changes (`global.reloader.enabled`); the broker
takes the new password only when the Job runs. Order: change the Secret (`secrets.sh` / ESO; Reloader restarts the
service), then run the Job (`helm upgrade`, or trigger `redpanda-bootstrap` in Tilt). Without Reloader: the Job first, then
`kubectl -n hoops rollout restart deploy/<service>`. Between the two steps a connection with the other password fails
with `SASL_AUTHENTICATION_FAILED`; core's publisher turns `DEGRADED` and catches up once both agree, a consumer resumes
from its committed offset. Only that service's pod restarts (the superuser
`hoops-redpanda-admin` restarts `redpanda-0`, section "Rotate the superuser").
