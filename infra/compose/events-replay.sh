#!/usr/bin/env bash
# Rebuilds a service's roster replica from core's compacted topics on the compose stack (ADR-0037):
# empties the replica tables (<schema>.*_ref and <schema>.applied_event, as the schema owner) and moves every consumer
# group of the service (<service>-service.*) to the start of the topics. The service must be stopped first: a group
# can be moved only while it has no members. Start the service afterwards; it replays and catches up.
#   infra/compose/events-replay.sh game        (`just events-replay game`)
set -euo pipefail
SERVICE="${1:?usage: events-replay.sh game|athlete}"
case "$SERVICE" in game | athlete) ;; *) echo "events-replay.sh: unknown service $SERVICE (game, athlete)" >&2; exit 2 ;; esac
PG="${POSTGRES_CONTAINER:-hoops-postgres}"
RP="${REDPANDA_CONTAINER:-hoops-redpanda}"
OWNER="${SERVICE}_migrator"

rpk() { podman exec -e HOME=/tmp "$RP" rpk "$@"; }
psql_owner() { podman exec -i "$PG" psql -v ON_ERROR_STOP=1 -qtA -U postgres -d hoops -c "set role $OWNER" -c "$1"; }

groups=$(rpk group list | awk -v p="${SERVICE}-service." 'NR > 1 && index($2, p) == 1 {print $2}')
[ -n "$groups" ] || { echo "events-replay.sh: no consumer group ${SERVICE}-service.* yet (the service never consumed)" >&2; exit 1; }
for g in $groups; do
  state=$(rpk group describe "$g" | awk '$1 == "STATE" {print $2}')
  case "$state" in Empty | Dead) ;; *) echo "events-replay.sh: group $g is $state; stop $SERVICE-service first" >&2; exit 1 ;; esac
done

tables=$(psql_owner "select string_agg(format('%I.%I', schemaname, tablename), ', ' order by tablename) from pg_tables
                      where schemaname = '$SERVICE' and (tablename like '%\_ref' or tablename = 'applied_event')")
[ -n "$tables" ] || { echo "events-replay.sh: no replica tables in schema $SERVICE" >&2; exit 1; }
psql_owner "truncate $tables"
echo "  emptied $tables"
for g in $groups; do
  rpk group seek "$g" --to start >/dev/null
  echo "  rewound $g"
done
echo "Start ${SERVICE}-service: it replays the topics from the start (watch hoops_roster_replica_events_total)."
