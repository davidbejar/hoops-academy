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
