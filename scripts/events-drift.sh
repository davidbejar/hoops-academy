#!/usr/bin/env bash
# Drift check of the roster replicas (WP98, decision 66, ADR-0037 "Flip of 2026-11-10"): compares, per aggregate
# (tenant, person, player, team, team-player, team-staff, guardian-link), core's rows with game.*_ref and athlete.*_ref:
#   missing  core has the row; the replica has none, or only a removed one
#   extra    the replica has the row (not removed); core has not
#   differs  both have it; a replicated column differs
# Read-only: one REPEATABLE READ READ ONLY transaction as the database operator the runbooks use for inspection (compose:
# the superuser through `podman exec`; kind: the CNPG primary through `kubectl exec`). No service role is involved.
# A row that differs is checked once more after EVENTS_DRIFT_WAIT seconds (lag: an event on its way) before it counts.
# Prints counts per aggregate and service and the first differing ids (ids only, never names or logins).
# Exit 0: the replicas equal core; 1: drift; 2: the check could not run.
#   scripts/events-drift.sh            compose (container POSTGRES_CONTAINER, default hoops-postgres)   `just events-drift`
#   scripts/events-drift.sh --kind     kind/chart (namespace HOOPS_NAMESPACE, default hoops; CNPG cluster HOOPS_DB_CLUSTER,
#                                      default hoops-db)                                            `just events-drift --kind`
# Settings: EVENTS_DRIFT_WAIT (seconds before the retry, default 5), EVENTS_DRIFT_SHOW (ids shown per kind, default 5).
set -euo pipefail

MODE=compose
case "${1:-}" in
  "" | --compose) ;;
  --kind) MODE=kind ;;
  *) echo "usage: $0 [--compose | --kind]" >&2; exit 2 ;;
esac
WAIT="${EVENTS_DRIFT_WAIT:-5}"
SHOW="${EVENTS_DRIFT_SHOW:-5}"
case "$WAIT$SHOW" in *[!0-9]*) echo "events-drift: EVENTS_DRIFT_WAIT and EVENTS_DRIFT_SHOW are whole numbers" >&2; exit 2 ;; esac
AGGREGATES="tenant person player team team-player team-staff guardian-link"
SERVICES="game athlete"

psql_operator() {
  if [ "$MODE" = compose ]; then
    podman exec -i -e PGOPTIONS="-c client_min_messages=warning" "${POSTGRES_CONTAINER:-hoops-postgres}" \
      psql -X -q -At -v ON_ERROR_STOP=1 -U postgres -d hoops
  else
    local ns="${HOOPS_NAMESPACE:-hoops}" cluster="${HOOPS_DB_CLUSTER:-hoops-db}" pod
    pod=$(kubectl -n "$ns" get pods -l "cnpg.io/cluster=$cluster,cnpg.io/instanceRole=primary" \
      -o jsonpath='{.items[0].metadata.name}') && [ -n "$pod" ] || { echo "no primary of CNPG cluster $cluster in $ns" >&2; return 1; }
    kubectl -n "$ns" exec -i "$pod" -c postgres -- env PGOPTIONS="-c client_min_messages=warning" \
      psql -X -q -At -v ON_ERROR_STOP=1 -U postgres -d hoops
  fi
}

# One row per aggregate instance of a service: in core, in the replica (not removed), the id to show, and whether the
# replicated columns differ. Keys carry the tenant; ids are compared as text. $1 = schema, $2 = the staff columns it
# replicates (athlete also keeps `since`). Roles are compared as sets (sorted the same way on both sides).
compare_sql() {
  local s="$1" staff="$2"
  cat <<SQL
select '$s' svc, 'tenant' agg, c.k is not null in_core, r.k is not null in_replica, coalesce(c.id, r.id) id,
       c.v is distinct from r.v differs
  from (select id::text k, id::text id, row(status, timezone) v from core.tenant) c
  full join (select tenant_id::text k, tenant_id::text id, row(status, timezone) v
               from $s.tenant_ref where not removed) r on r.k = c.k
union all
select '$s', 'person', c.k is not null, r.k is not null, coalesce(c.id, r.id), c.v is distinct from r.v
  from (select p.tenant_id || '/' || p.id k, p.id::text id,
               row(p.given_name || ' ' || p.family_name, u.keycloak_sub,
                   array(select m.role from core.membership_role m where m.person_id = p.id order by m.role collate "C"),
                   p.active) v
          from core.person p left join core.app_user u on u.id = p.user_id) c
  full join (select tenant_id || '/' || id k, id::text id,
                    row(display_name, subject, array(select x from unnest(roles) x order by x collate "C"), active) v
               from $s.person_ref where not removed) r on r.k = c.k
union all
select '$s', 'player', c.k is not null, r.k is not null, coalesce(c.id, r.id), c.v is distinct from r.v
  from (select pl.tenant_id || '/' || pl.id k, pl.id::text id,
               row(pl.person_id, p.given_name || ' ' || p.family_name, pl.status, p.birth_date, p.gender) v
          from core.player pl join core.person p on p.id = pl.person_id) c
  full join (select tenant_id || '/' || id k, id::text id, row(person_id, display_name, status, birth_date, gender) v
               from $s.player_ref where not removed) r on r.k = c.k
union all
select '$s', 'team', c.k is not null, r.k is not null, coalesce(c.id, r.id), c.v is distinct from r.v
  from (select t.tenant_id || '/' || t.id k, t.id::text id, row(t.season_id, s.end_date, t.name) v
          from core.team t join core.season s on s.id = t.season_id) c
  full join (select tenant_id || '/' || id k, id::text id, row(season_id, season_end_date, name) v
               from $s.team_ref where not removed) r on r.k = c.k
union all
select '$s', 'team-player', c.k is not null, r.k is not null, coalesce(c.id, r.id), c.v is distinct from r.v
  from (select tenant_id || '/' || id k, id::text id,
               row(team_id, player_id, jersey_number, joined_on, left_on, invalid_reason) v from core.team_player) c
  full join (select tenant_id || '/' || id k, id::text id,
                    row(team_id, player_id, jersey_number, joined_on, left_on, invalid_reason) v
               from $s.team_player_ref where not removed) r on r.k = c.k
union all
select '$s', 'team-staff', c.k is not null, r.k is not null, coalesce(c.id, r.id), c.v is distinct from r.v
  from (select tenant_id || '/' || team_id || ':' || person_id k, team_id || ':' || person_id id, row($staff) v
          from core.team_staff) c
  full join (select tenant_id || '/' || team_id || ':' || person_id k, team_id || ':' || person_id id, row($staff) v
               from $s.team_staff_ref where not removed) r on r.k = c.k
union all
select '$s', 'guardian-link', c.k is not null, r.k is not null, coalesce(c.id, r.id), c.v is distinct from r.v
  from (select tenant_id || '/' || id k, id::text id, row(guardian_person_id, player_id) v from core.guardian_link) c
  full join (select tenant_id || '/' || id k, id::text id, row(guardian_person_id, player_id) v
               from $s.guardian_link_ref where not removed) r on r.k = c.k
SQL
}

# Prints "C|service|aggregate|core rows|replica rows" and "D|service|aggregate|kind|id" lines, sorted.
check() {
  {
    echo "begin transaction isolation level repeatable read, read only;"
    echo "with compared as ("
    compare_sql game "role"
    echo "union all"
    compare_sql athlete "role, since"
    cat <<'SQL'
)
select line from (
  select 'C|' || svc || '|' || agg || '|' || count(*) filter (where in_core) || '|' || count(*) filter (where in_replica)
         as line
    from compared group by svc, agg
  union all
  select 'D|' || svc || '|' || agg || '|'
         || case when not in_replica then 'missing' when not in_core then 'extra' else 'differs' end || '|' || id
    from compared where not in_core or not in_replica or differs
) lines order by line;
commit;
SQL
  } | psql_operator
}

first=$(mktemp) second=$(mktemp) stuck=$(mktemp) drift=$(mktemp) errors=$(mktemp)
trap 'rm -f "$first" "$second" "$stuck" "$drift" "$errors"' EXIT
trap 'echo "events-drift: failed unexpectedly (line $LINENO)" >&2; exit 2' ERR
run() { # file
  if ! check >"$1" 2>"$errors"; then
    echo "events-drift: the check could not run ($MODE):" >&2
    sed 's/^/  /' "$errors" >&2
    exit 2
  fi
}

echo "events-drift: core vs the game and athlete replicas ($MODE, one repeatable read, read only transaction)"
run "$first"
result="$first"
lagged=0
if grep -q '^D|' "$first"; then
  echo "events-drift: $(grep -c '^D|' "$first") rows differ; checking them again in ${WAIT}s (lag)"
  sleep "$WAIT"
  run "$second"
  # drift = differs in both runs (same service, aggregate and id); the second run's kind and counts count
  key() { awk -F'|' '$1 == "D" {print $2 "|" $3 "|" $5}' "$1" | sort -u; }
  comm -12 <(key "$first") <(key "$second") >"$stuck"
  lagged=$(comm -23 <(key "$first") <(key "$second") | grep -c . || true)
  awk -F'|' 'FILENAME == ARGV[1] { keep[$0] = 1; next } $1 != "D" || ($2 "|" $3 "|" $5) in keep' "$stuck" "$second" \
    >"$drift"
  result="$drift"
fi

printf '%-14s %-8s %6s %8s %8s %6s %7s\n' aggregate service core replica missing extra differ
for agg in $AGGREGATES; do
  for svc in $SERVICES; do
    awk -F'|' -v svc="$svc" -v agg="$agg" -v fmt='%-14s %-8s %6d %8d %8d %6d %7d\n' '
      $1 == "C" && $2 == svc && $3 == agg { core = $4; replica = $5 }
      $1 == "D" && $2 == svc && $3 == agg { n[$4]++ }
      END { printf fmt, agg, svc, core, replica, n["missing"], n["extra"], n["differs"] }' "$result"
  done
done
awk -F'|' -v show="$SHOW" '$1 == "D" {
    group = $2 " " $3 " " $4
    if (++n[group] <= show) print "drift: " group " " $5
    else more[group]++
  }
  END { for (g in more) print "drift: " g " ... and " more[g] " more" }' "$result"

drifted=$(grep -c '^D|' "$result" || true)
if [ "$lagged" -gt 0 ]; then
  echo "events-drift: $lagged rows differed at first and matched on the retry (lag, not drift)"
fi
if [ "$drifted" -gt 0 ]; then
  echo "events-drift: DRIFT in $drifted rows (runbook docs/runbooks/events.md, \"Drift check\")"
  exit 1
fi
echo "events-drift: the replicas equal core"
