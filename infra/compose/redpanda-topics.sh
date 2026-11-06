#!/usr/bin/env bash
# Creates the event topics on the local Redpanda (compose container hoops-redpanda) and sets their configuration;
# idempotent: existing topics keep their data and get the configuration again. ADR-0036.
#   infra/compose/redpanda-topics.sh            (`just events-topics`; `just up` runs it)
# The topic list and settings are the chart's events.topics (deploy/helm/hoops/values.yaml); deploy/helm/tests/run.sh
# fails when the two differ. One partition per topic: the key (<tenant id>:<aggregate id>) keeps the events of one
# aggregate in order, and one partition keeps all of them in order (outbox order) until a topic needs more.
set -euo pipefail
CONTAINER="${REDPANDA_CONTAINER:-hoops-redpanda}"
TOPICS=(core.person core.player core.team core.team-player core.team-staff core.guardian-link core.tenant)
PARTITIONS=1
# Compacted: the latest event per key is kept forever, so a replica can be rebuilt by replaying a topic from the start;
# tombstones (deletes) stay 7 days, so a consumer that is down for less than that still sees them.
CONFIG=(cleanup.policy=compact retention.ms=-1 delete.retention.ms=604800000)

rpk() { podman exec -e HOME=/tmp "$CONTAINER" rpk "$@"; }
podman container exists "$CONTAINER" || { echo "redpanda-topics.sh: container $CONTAINER not found (just up)" >&2; exit 1; }
existing=$(rpk topic list | awk 'NR > 1 {print $1}')
set_flags=() create_flags=()
for c in "${CONFIG[@]}"; do set_flags+=(--set "$c"); create_flags+=(-c "$c"); done
for t in "${TOPICS[@]}"; do
  if grep -qx -- "$t" <<<"$existing"; then
    rpk topic alter-config "$t" "${set_flags[@]}" >/dev/null
    echo "  kept    $t"
  else
    rpk topic create "$t" -p "$PARTITIONS" -r 1 "${create_flags[@]}" >/dev/null
    echo "  created $t"
  fi
done
rpk topic list
