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

### The flip (done 2026-11-10, decision 66, WP98)
The plan was a shadow period over days in a shared environment before the flip; decision 66 skipped it (ADR-0037,
"Flip of 2026-11-10") and replaced it by the drift check below. Since WP98 game and athlete read the replica by default
(`hoops.roster.source=replica`); `rest` is the fallback switch. In a new environment: run the backfill first (a replica
only knows aggregates that have an event), then `just events-drift` (exit 0), then let the services answer.

Evidence of WP81 on compose (2026-11-07, data from rounds 1 to 4, 46 academies): before the backfill the topics held
31 of 169 persons, 12 of 64 players, 8 of 43 teams, 21 of 121 assignments, 7 of 41 staff entries, 4 of 22 guardian
links and 7 of 46 academies; the backfill appended 416 events (138, 52, 35, 100, 34, 18, 39) in 13 s, the second run 0;
afterwards every topic's live keys equal the table rows (0 missing, 0 extra), both replicas hold exactly core's counts,
parked 0, lag 0.87 to 0.99 s, group lag 0. Then `GAME_ROSTER_SOURCE=replica ATHLETE_ROSTER_SOURCE=replica just e2e`:
JourneyTest 23/23 (27 with MailSinkTest), both services logged their replica source, parked still 0, group lag 0.

## Roster replicas: game and athlete (WP68, WP69; one pipeline since WP130)
game and athlete each keep a replica of the roster data they read from core (`game.*_ref` V4, `athlete.*_ref` V6), fed
by the seven `core.*` topics (ADR-0037). `hoops.roster.source` picks what `RosterPort` and the tenant filter read; the
consumer feeds the replica in both modes, so it stays current while `rest` answers. Since WP130 (ADR-0062) both run
the same code from common-quarkus (`com.hoopsacademy.common.replica`: envelope decoder, consumer loop, meters,
bookkeeping stores, retention run) with one retry policy, one reason policy and one `parked_event` shape, so every
procedure below is the same for both; `<service>` is `game` or `athlete`, `<port>` 8082 (game) or 8083 (athlete).

| Setting | Default | What |
|---|---|---|
| `hoops.roster.source` (`GAME_ROSTER_SOURCE`, `ATHLETE_ROSTER_SOURCE`) | `replica` (since WP98; `rest` before) | `replica` = the local replica, no call to core on the request path; needs the consumer on (the service refuses to start otherwise, log `hoops.roster.source=replica needs hoops.roster.consumer.enabled=true`); `rest` = core `/internal` (cached 30 s), the fallback |
| `hoops.roster.consumer.enabled` (`GAME_ROSTER_CONSUMER_ENABLED`, `ATHLETE_ROSTER_CONSUMER_ENABLED`) | `true` | `false` stops feeding the replica (escape hatch, only with `rest`); drives `mp.messaging.incoming.core-roster.enabled` |
| `hoops.roster.replica.max-attempts` (`GAME_ROSTER_REPLICA_MAX_ATTEMPTS`, `ATHLETE_ROSTER_REPLICA_MAX_ATTEMPTS`) | `5` | tries per record when its database work (apply or park) fails, then the channel fails; game had `apply-attempts` (3, linear, park not retried) before WP130 |
| `hoops.roster.replica.first-backoff` | `PT0.5S` | pause after the first failed try, doubling after each further one (0.5 s, 1 s, 2 s, 4 s) |
| `mp.messaging.incoming.core-roster.poll-timeout`, `.fetch.max.wait.ms` | `100` | ms; with the connector's 1 s default a burst was applied one topic per second (4 s of lag, WP98) |
| `KAFKA_BOOTSTRAP_SERVERS` | `localhost:19092` (prod profile) | compose host mode; dev mode and tests use Dev Services Redpanda |
| `KAFKA_SECURITY_PROTOCOL`, `KAFKA_SASL_USERNAME`, `KAFKA_SASL_PASSWORD` | `PLAINTEXT`, `<service>-service`, empty | chart: `SASL_PLAINTEXT` + the `hoops-redpanda-<service>-service` Secret (SCRAM-SHA-256) |

One channel `core-roster` over the seven topics, consumer group `<service>-service.roster`, `auto.offset.reset=earliest`:
a new group replays everything. `just e2e` runs both services on their replicas (the default); on core's API:
`GAME_ROSTER_SOURCE=rest ATHLETE_ROSTER_SOURCE=rest just e2e` (or export them before `e2e/bin/services-up.sh`).

Watch it:
```bash
curl -s localhost:<port>/q/metrics | grep '^hoops_roster_replica'   # events_total{topic,outcome}, parked_total{topic}, lag_seconds{topic}
curl -s localhost:<port>/q/metrics | grep '^kafka_consumer_fetch_manager_records_lag'   # offset lag per partition
podman exec hoops-redpanda rpk group describe <service>-service.roster  # LAG per topic (0 = caught up)
curl -s localhost:<port>/q/health/live | jq '.checks[] | select(.name | test("Messaging"))'
```
`outcome` is `applied` (the replica now holds the event's state), `duplicate` (a redelivered `eventId`: a redelivery or
a replay over a filled replica, nothing changed), `stale` (older than the stored row, nothing changed) or `tombstone`
(the null record after a removal, skipped). Removals are soft for every aggregate since WP82: a removed person, player,
team, assignment or tenant keeps only its id (`removed = true`) and reads leave it out. `lag_seconds` is the age of the
topic's last event when it was processed: a few seconds normally (core's poll interval plus the fetch). Since WP130
`parked_total` and `lag_seconds` exist for all seven topics from the start in both services (0 until something
happens), so a panel or alert never sees "no data".

- **Parked records** (`hoops_roster_replica_parked_total` > 0): records that broke their contract (JSON Schema, a key
  that is not `<tenantId>:<aggregateId>` of the envelope, a tenant event about another tenant, a value the service cannot
  read such as an unknown time zone) are not applied and not retried. The reason holds the schema's error paths (at most
  five, 500 characters), never a value of the record. Read them as the schema owner (the app role may only insert and
  read the coordinates):
  ```sql
  set role <service>_migrator;
  select topic, partition, kafka_offset, record_key, event_id, reason, parked_at, inspected_at
    from <service>.parked_event order by parked_at desc limit 20;
  ```
  then look at the record itself: `rpk topic consume <topic> -p <partition> -o <kafka_offset> -n 1`. The aggregate is
  repaired by its next event (state transfer) or, once the producer is fixed, by a replay. A replay parks a record
  again as a no-op (its position is the primary key).
- **Consumer stopped** (liveness and readiness DOWN, the pod restarted, log `Giving up on core.<topic>-<p>@<offset>
  after 5 attempts, stopping the consumer`): applying or parking a record failed `max-attempts` times, usually the
  database. The pod resumes from the last committed offset, which is still before the record, so nothing is lost; if it
  keeps failing at the same offset, fix the database cause. On compose restart the service (`just services-down &&
  just services-up`).
- **Broker down**: nothing to do; the replica stays readable and goes stale (readiness does not depend on the broker;
  `records_lag` and `lag_seconds` grow once events flow again); the client reconnects.

### Housekeeping: what the retention job deletes (WP82)
A daily job per service (`ReplicaRetentionJob`, one pod at a time: advisory lock `<service>.replica-retention`, which is
also the scheduler identity since WP130) deletes two kinds of bookkeeping rows, logs what it deleted (`Replica
retention: deleted N applied event ids recorded before ... ; M parked records inspected before ...: [core.person-0@17,
...]`) and counts them in `hoops_roster_replica_pruned_total{table="applied_event"|"parked_event"}`.

| Setting | Default | What |
|---|---|---|
| `hoops.roster.replica.retention.cron` | game `0 40 3 * * ?`, athlete `0 45 3 * * ?` | when it runs (`off` disables it; tests run with `off`) |
| `hoops.roster.replica.retention.applied-events` | `P7D` | `applied_event` rows older than this go; never below the topics' 7-day tombstone retention (the service refuses to start) |
| `hoops.roster.replica.retention.parked-events` | `P30D` | `parked_event` rows go this long after an operator marked them inspected |
| `hoops.roster.replica.retention.batch-size` | `1000` | applied ids deleted per transaction and tenant (`for update skip locked`) |

- **applied_event**: the event ids the consumer already applied (idempotency). A redelivery comes at most as long as
  the topics keep a record, so after 7 days an id is no longer needed; an older redelivery would still be harmless
  (the row's `occurred_at` guard makes it `stale`). The tenants are listed in `<service>.replica_tenant` (global, ids
  only).
- **parked_event**: never deleted before an operator looked at it. Inspect, then mark (as `<service>_migrator`):
  ```sql
  set role <service>_migrator;
  select topic, partition, kafka_offset, record_key, event_id, reason, parked_at
    from <service>.parked_event where inspected_at is null order by parked_at;
  -- after reading the record (rpk topic consume <topic> -p <partition> -o <kafka_offset> -n 1) and fixing the cause:
  update <service>.parked_event set inspected_at = now()
   where topic = '<topic>' and partition = <partition> and kafka_offset = <kafka_offset>;
  ```
  The row goes `parked-events` (30 days) after that. Uninspected rows stay; `hoops_roster_replica_parked_total` still
  counts them since the start of the pod.

### Replay (rebuild a replica from the topics)
Needed after a broker reset, a fix of parked records, or an outage of the service longer than the tombstone retention
(7 days). The replica tables and `<service>.applied_event` must be emptied, otherwise every replayed event is a known
duplicate. With `hoops.roster.source=replica` the service answers 404 for the tenants not yet replayed: switch it to
`rest` for the replay or do it in a maintenance window.
compose:
```bash
just services-down            # or stop that service's jar only; the group must have no members
just events-replay <service>  # empties <service>.*_ref + <service>.applied_event (as <service>_migrator), rpk group seek --to start
just services-up              # the service replays and catches up (rpk group describe: LAG 0)
```
kind: `kubectl -n hoops scale deploy/<service>-service --replicas=0`; empty the tables as `<service>_migrator`
(`truncate <service>.tenant_ref, <service>.person_ref, <service>.player_ref, <service>.team_ref,
<service>.team_player_ref, <service>.team_staff_ref, <service>.guardian_link_ref, <service>.applied_event`);
`rpk_k group seek <service>-service.roster --to start`; scale back. A replay without emptying is safe too (every event
is a duplicate or stale) but does not remove entries whose removal was compacted away. `RosterReplayTest` (both
services) proves that emptying, rewinding and restarting restore the same answers.

### Switching between `replica` and `rest`
`replica` is the default since WP98. It needs core to have published every aggregate (a replica only knows aggregates
that changed after core's publisher went live; data older than WP67 needs a core backfill), `parked_total` 0,
`lag_seconds` in seconds, and on Kubernetes the chart wiring the Kafka client. Back to core's API:
`GAME_ROSTER_SOURCE=rest` / `ATHLETE_ROSTER_SOURCE=rest` and a restart ("Rollback to rest" below).

### What differs per service
- **game**: the academy name (WP117, V7 `game.tenant_ref.name`) is printed on the match sheet PDF and read from the
  replica in both sources (core's `/internal` API has none). A tenant whose last `tenant.changed` was applied before V7
  has no name until core sends the next one (any academy edit), `just events-backfill force`, or a replay; until then
  the sheet prints "Hoops Academy". With `rest` and the consumer off the sheet always prints that fallback.
- **athlete**: a tenant event also refreshes `athlete.tenant_registry` (the nightly materialisation knows the tenant and
  its zone before anyone calls); a tenant removal leaves the registry alone.

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
| core publisher | on (`CORE_OUTBOX_POLL_INTERVAL` default `1s`) | `CORE_OUTBOX_ENABLED=false` (chart 0.10.0, WP91: no Kafka producer, no broker warnings) and `CORE_OUTBOX_POLL_INTERVAL=off`; the outbox still fills |
| game / athlete consumer | on | `GAME_ROSTER_CONSUMER_ENABLED=false`, `ATHLETE_ROSTER_CONSUMER_ENABLED=false` |
| roster source | `game.rosterSource` / `athlete.rosterSource` -> `GAME_ROSTER_SOURCE` / `ATHLETE_ROSTER_SOURCE`; empty (default, chart 0.10.0) = `replica`; `rest` rolls a service back | empty = `rest` (an explicit `replica` is refused) |

The render also refuses: a service without its `events.users` entry (name = the service, `passwordSecret:
hoops-redpanda-<service>`), a `rosterSource` other than empty/`rest`/`replica`, and `KAFKA_*` in a service's `env`/`secretEnv`
while events are on (the chart owns the client). The off switches live in `<service>.events.offEnv`; a service's `env`
overrides them (a managed Kafka with `events.enabled=false`: set `KAFKA_*`, `CORE_OUTBOX_ENABLED: "true"` and
`CORE_OUTBOX_POLL_INTERVAL` in `env`, the
password through `secretEnv`). Check a release: `kubectl -n hoops get configmap core-service-env -o yaml | grep -E 'KAFKA|OUTBOX'`.

Watch it on kind (`/q/metrics` is not routed, and the distroless service images have no curl: port-forward, ADR-0054):
```bash
curl -s localhost:8090/api/core/q/health/ready | jq '.checks[] | select(.name == "outbox-publisher")'   # UP, state OK
m() { kubectl -n hoops port-forward deploy/$1 "1$2:$2" >/dev/null & local pf=$!; sleep 2; curl -s "localhost:1$2/q/metrics"; kill $pf; }
m core-service 8081 | grep -E '^hoops_outbox_(pending|lag|broker_available|published_total)'
m game-service 8082 | grep '^hoops_roster_replica'                  # events_total{outcome,topic}, parked_total, lag_seconds
m athlete-service 8083 | grep '^hoops_roster_replica'
rpk_k "group describe game-service.roster"                          # TOTAL-LAG 0 = caught up (section "rpk")
```
`deploy/kind/smoke.sh core game athlete` does all of this: it seeds a fresh academy (first admin: the seeded `admin1`, a
season, a team, a player), waits for `hoops_outbox_pending` 0 and both groups' lag 0, and checks parked 0 and that game
and athlete answer for the new academy.

**Fresh install: no restart (WP100).** The Job `redpanda-bootstrap` is a post-install hook, so Helm runs it only after
`--wait`, when the services are already up: they start before their broker users exist and log `SASL authentication
failed`. game and athlete reconnect by themselves once the Job has run; core replaces its producer after
`hoops.outbox.producer-reset-after` failed sends (WP81, section "Core publisher") and drains the outbox. WP71's restart of
core in `deploy/kind/up.sh` is gone; WP100 proved the recovery on a fresh `up.sh --eso --deploy` (handover of WP100).

Roll one service back to core's API (ADR-0037 "Rollback to rest"; since chart 0.10.0 both read their replica wherever
the events are on):
```bash
helm upgrade hoops deploy/helm/hoops -n hoops -f deploy/helm/hoops/values-kind.yaml \
  --set athlete.rosterSource=rest --wait             # only athlete's ConfigMap changes; its pod rolls (checksum)
kubectl -n hoops logs deploy/athlete-service | grep 'Roster source'     # REST
```
Back: the same without the `--set` (or `replica`). With Tilt, put `athlete: {rosterSource: rest}` into the git-ignored
`values-local.yaml`. A release with `events.enabled=false` renders `rest` for both.

Secret rotation of a service's broker login (`hoops-redpanda-<service>`): the password is an env var, so a changed Secret
reaches no running pod by itself and Helm does not roll the Deployment for it (its checksum covers the ConfigMap only).
Since chart 0.8.0 (WP87) Reloader rolls the service as soon as the Secret changes (`global.reloader.enabled`); the broker
takes the new password only when the Job runs. Order: change the Secret (`secrets.sh` / ESO; Reloader restarts the
service), then run the Job (`helm upgrade`, or trigger `redpanda-bootstrap` in Tilt). Without Reloader: the Job first, then
`kubectl -n hoops rollout restart deploy/<service>`. Between the two steps a connection with the other password fails
with `SASL_AUTHENTICATION_FAILED`; core's publisher turns `DEGRADED` and catches up once both agree, a consumer resumes
from its committed offset. Only that service's pod restarts (the superuser
`hoops-redpanda-admin` restarts `redpanda-0`, section "Rotate the superuser").

## Drift check (WP98)
Since the flip (ADR-0037, "Flip of 2026-11-10") game and athlete answer from their replicas, so a replica that differs
from core gives wrong answers (a member unknown: 404; a role or a team missing: 403 or a shorter list). The drift check
finds that on demand. It is read-only: one `REPEATABLE READ READ ONLY` transaction as the operator (compose: the
superuser through `podman exec`; kind: the CNPG primary through `kubectl exec`); no service role is involved.
```bash
just events-drift                        # compose (container hoops-postgres; POSTGRES_CONTAINER to change it)
just events-drift --kind                 # kind/chart: the primary of CNPG cluster hoops-db in namespace hoops
                                         #   (HOOPS_DB_CLUSTER, HOOPS_NAMESPACE to change them)
EVENTS_DRIFT_WAIT=15 just events-drift   # seconds before a differing row is checked again (default 5)
EVENTS_DRIFT_SHOW=20 just events-drift   # ids shown per service, aggregate and kind (default 5)
just events-drift-test                   # the check against planted differences (throwaway PostgreSQL, ~1 min)
```
Per aggregate (tenant, person, player, team, team-player, team-staff, guardian-link) and service it prints core's rows,
the replica's rows (not removed) and how many are:
- **missing**: core has the row, the replica has none or only a removed one (the event never arrived, or was parked);
- **extra**: the replica has the row, not removed, and core has not (a removal that never arrived);
- **differ**: both have it and a replicated column differs (display name, login subject, roles as a set, active; player
  person, name, status, birth date, gender; team season, season end, name; assignment team, player, jersey, joined, left,
  invalid reason; staff role, and in athlete `since`; guardian link guardian and player; tenant status and time zone).

then `drift: <service> <aggregate> <kind> <id>` for the first ids (team-staff: `<team id>:<person id>`; ids only, never
names or logins). A row that differs is checked again after `EVENTS_DRIFT_WAIT` seconds; only rows that still differ
count (`... matched on the retry (lag, not drift)` otherwise). Exit 0: the replicas equal core; 1: drift; 2: the check
could not run (database unreachable, a schema missing, an unknown option).

On drift:
1. Lag first: `rpk group describe <service>-service.roster` (`TOTAL-LAG` 0?), `hoops_outbox_pending` in core (0?); run
   the check again with a longer `EVENTS_DRIFT_WAIT`.
2. Parked records (`hoops_roster_replica_parked_total` > 0, the `parked_event` table): the event broke its contract;
   fix the producer, then replay.
3. **missing** in both services for aggregates older than core's publisher: run the backfill (`just events-backfill`).
4. Anything else: switch the service to `rest` (below), replay its replica ("Replay (rebuild a replica from the topics)"), check again (exit 0),
   switch back to `replica`.

## Rollback to rest (WP98)
One setting per service and a restart; nothing is lost and nothing has to be replayed afterwards, because the consumer
feeds the replica in both modes and core's `/internal` API is unchanged:
```bash
GAME_ROSTER_SOURCE=rest ATHLETE_ROSTER_SOURCE=rest e2e/bin/services-up.sh     # compose (just services-down first)
helm upgrade hoops deploy/helm/hoops -n hoops -f deploy/helm/hoops/values-kind.yaml \
  --set game.rosterSource=rest --set athlete.rosterSource=rest --wait          # chart
```
Back to the replica: drop the overrides (compose) or set `replica` (chart), after `just events-drift` exits 0.
