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
Rotate a service user: change its Secret (`.env` + `deploy/kind/secrets.sh | kubectl apply -f -`, or the ESO source),
run the Job again (`helm upgrade`, or with Tilt trigger `redpanda-bootstrap`), then restart the service.

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
# then: REDPANDA_ADMIN_PASSWORD=$new in .env (or the ESO source), deploy/kind/secrets.sh | kubectl apply -f -,
kubectl -n hoops rollout restart statefulset/redpanda                 # the pod's RP_ADMIN_PASSWORD follows the Secret
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
| `KAFKA_BOOTSTRAP_SERVERS` | `localhost:19092` (prod profile) | compose host mode; dev mode and tests use Dev Services Redpanda |
| `KAFKA_SECURITY_PROTOCOL`, `KAFKA_SASL_USERNAME`, `KAFKA_SASL_PASSWORD` | `PLAINTEXT`, `core-service`, empty | chart: `SASL_PLAINTEXT` + the `hoops-redpanda-core-service` Secret (SCRAM-SHA-256) |

Watch it:
```bash
curl -s localhost:8081/q/health/ready | jq '.checks[] | select(.name == "outbox-publisher")'   # state OK | DEGRADED
curl -s localhost:8081/q/metrics | grep '^hoops_outbox'        # published_total{topic}, pending, lag_seconds, broker_available
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
- **A row that never goes out** while others do: another transaction holds its lock (or an older row of the same
  aggregate). Find it in `pg_locks` / `pg_stat_activity`; the publisher never skips ahead of it for that aggregate.
- **Republish** (a consumer lost a topic and replaying it is not enough): `update core.outbox set published_at = null
  where topic = 'core.<aggregate>' and tenant_id = '<id>'` as the schema owner; the events go out again with their
  original `eventId`, which the consumers ignore if they have applied it. Prefer replaying the compacted topic.
- Rows with `topic` null are core's internal v1 notifications (`player.approved`, `tenant.suspended`, ...): never
  published, kept for billing and audits.

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
nothing changed) or `tombstone` (skipped; removals are soft, `removed = true`). `lag_seconds` is the age of the last
event when it was processed: a few seconds normally (core's poll interval plus the fetch).

- **Parked records** (`hoops_roster_replica_parked_total` > 0): records that broke their contract (JSON Schema, key
  `<tenantId>:<aggregateId>`) are not applied and not retried. Read them as the schema owner (game_app may only insert):
  ```sql
  set role game_migrator;
  select parked_at, topic, kafka_partition, kafka_offset, record_key, event_id, reason from game.parked_event order by id desc limit 20;
  ```
  then look at the record itself: `rpk topic consume <topic> -p <partition> -o <offset> -n 1`. The aggregate is
  repaired by its next event or, once the producer is fixed, by a replay.
- **Consumer stopped** (liveness and readiness DOWN, log `Applying event ... failed 3 times, stopping the consumer`):
  usually the database. The orchestrator restarts the pod; it resumes from the committed offset, nothing is lost. On
  compose restart game (`just services-down && just services-up`).
- **Broker down**: nothing to do in game; the replica stays readable and goes stale (`lag_seconds` grows once events
  flow again); the client reconnects.

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
  record after a removal, skipped). `lag_seconds` is how old the topic's last event was when athlete applied it.
- **Parked records** (`parked_total` > 0): a record broke the contract (schema, envelope, or a key that is not
  `<tenantId>:<aggregateId>` of its envelope). It is skipped, never applied. The app role may only insert into the
  table; read it as `athlete_migrator`:
  ```sql
  select topic, partition, kafka_offset, record_key, event_id, reason, parked_at from athlete.parked_event order by parked_at desc;
  ```
  then look at the record (`rpk topic consume <topic> -o <kafka_offset> -n 1`). The aggregate's next event repairs the
  replica (state transfer); after a producer fix, replay.
- **The consumer stopped** (liveness DOWN, pod restarted, a "Giving up on core.<topic>-0@<offset>" error in the log):
  applying (or parking) a record failed `max-attempts` times (database). The pod resumes from the last committed offset; if it
  keeps failing at the same offset, fix the database cause.
- **Broker down**: athlete keeps serving from the replica (readiness does not depend on the broker); the replica only
  gets older, `records_lag` grows once the broker is back and drains.

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