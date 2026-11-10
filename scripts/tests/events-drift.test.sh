#!/usr/bin/env bash
# Tests scripts/events-drift.sh (WP98) against a throwaway PostgreSQL: the compose image, infra/db/init and the Flyway
# files of core, game and athlete of the working tree. core's rows and both replicas are planted equal (exit 0), then
# for every aggregate and both services one difference of each kind (missing, extra, differs: exit 1, the id named),
# a lag that heals during the retry (exit 0), and a database that cannot be reached (exit 2). The compose database is
# never touched: the container has its own name, no published port, and is removed on exit (also on failure).
#   scripts/tests/events-drift.test.sh        (`just events-drift-test`)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
IMAGE="$(sed -n 's/^[[:space:]]*image:[[:space:]]*\(docker.io\/library\/postgres:[^[:space:]]*\).*/\1/p' infra/compose/compose.yaml | head -1)"
[ -n "$IMAGE" ] || { echo "events-drift.test: no postgres image in infra/compose/compose.yaml" >&2; exit 1; }
CONTAINER="hoops-drift-test-pg-$$-$RANDOM"
WORK="$(mktemp -d)"
cleanup() {
  podman rm -f "$CONTAINER" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

psql_in() { podman exec -i -e PGOPTIONS="-c client_min_messages=warning" "$CONTAINER" psql -X -q -v ON_ERROR_STOP=1 -U "$1" -d hoops "${@:2}"; }
sql() { printf '%s\n' "$1" | psql_in postgres >/dev/null; }

podman run -d --name "$CONTAINER" -e POSTGRES_PASSWORD=drift-test -e POSTGRES_DB=hoops "$IMAGE" >/dev/null
for _ in $(seq 1 90); do
  podman exec "$CONTAINER" pg_isready -q -h 127.0.0.1 -U postgres -d hoops && break
  sleep 1
done
podman exec "$CONTAINER" pg_isready -q -h 127.0.0.1 -U postgres -d hoops || { echo "events-drift.test: PostgreSQL did not start" >&2; exit 1; }
psql_in postgres < infra/db/init/01_roles_schemas.sql >/dev/null

# Flyway order: versioned files by numeric version, then repeatable (R__) files by name (as scripts/model-diagrams.sh).
apply_migrations() {
  local dir="$1" role="$2" f
  while IFS= read -r f; do
    psql_in "$role" < "$dir/$f" >/dev/null || { echo "events-drift.test: $f failed" >&2; return 1; }
  done < <(
    cd "$dir" && { printf '%s\n' V*__*.sql | sort -t_ -k1.2 -n; for r in R__*.sql; do [ -e "$r" ] && echo "$r"; done; }
  )
}
for svc in core game athlete; do
  apply_migrations "services/$svc-service/src/main/resources/db/migration" "${svc}_migrator"
done

# ---- fixture: two academies; in the first a coach (admin too, with a login), a player with a birth date, a parent,
# a season, a team, the player's assignment, the coach's staff entry and the parent's guardian link ----------------------
T1=11111111-1111-4111-8111-000000000001
T2=11111111-1111-4111-8111-000000000002
U1=22222222-2222-4222-8222-000000000001
P1=33333333-3333-4333-8333-000000000001
P2=33333333-3333-4333-8333-000000000002
P3=33333333-3333-4333-8333-000000000003
PL=44444444-4444-4444-8444-000000000002
S1=55555555-5555-4555-8555-000000000001
AC=55555555-5555-4555-8555-0000000000ac
TM=66666666-6666-4666-8666-000000000001
TP=77777777-7777-4777-8777-000000000001
GL=88888888-8888-4888-8888-000000000001
NEW=99999999-9999-4999-8999-000000000009
GONE=99999999-9999-4999-8999-000000000008

sql "
insert into core.tenant (id, slug, name, status, timezone, default_locale) values
  ('$T1', 'drift-a', 'Drift A', 'ACTIVE', 'Europe/Madrid', 'es'),
  ('$T2', 'drift-b', 'Drift B', 'SUSPENDED', 'Asia/Jakarta', 'id');
insert into core.app_user (id, keycloak_sub) values ('$U1', 'sub-of-ana');
insert into core.person (id, tenant_id, user_id, given_name, family_name, birth_date, gender, active) values
  ('$P1', '$T1', '$U1', 'Ana', 'Coach', null, null, true),
  ('$P2', '$T1', null, 'Leo', 'Player', '2012-03-04', 'MALE', true),
  ('$P3', '$T1', null, 'Pam', 'Parent', null, null, false);
insert into core.membership_role (tenant_id, person_id, role) values
  ('$T1', '$P1', 'COACH'), ('$T1', '$P1', 'ADMIN'), ('$T1', '$P2', 'PLAYER'), ('$T1', '$P3', 'PARENT');
insert into core.player (id, tenant_id, person_id, status) values ('$PL', '$T1', '$P2', 'ACTIVE');
insert into core.season (id, tenant_id, name, start_date, end_date, reference_year)
  values ('$S1', '$T1', '2026/27', '2026-09-01', '2027-06-30', 2026);
insert into core.age_category (id, tenant_id, code, name, max_age, sort_rank) values ('$AC', '$T1', 'U14', 'Under 14', 14, 1);
insert into core.team (id, tenant_id, season_id, name, age_category_id, gender_policy)
  values ('$TM', '$T1', '$S1', 'Lions', '$AC', 'MIXED');
insert into core.team_player (id, tenant_id, team_id, player_id, jersey_number, joined_on)
  values ('$TP', '$T1', '$TM', '$PL', '7', '2026-09-10');
insert into core.team_staff (tenant_id, team_id, person_id, role, since) values ('$T1', '$TM', '$P1', 'COACH', '2026-09-01');
insert into core.guardian_link (id, tenant_id, guardian_person_id, player_id) values ('$GL', '$T1', '$P3', '$PL');"

# The replicas as the consumers write them: literal values (never copied from core, so a shared mistake cannot hide),
# roles in another order than core's, one removed row of an aggregate core no longer has (not drift).
seed_replica() { # schema
  local s="$1" since_col="" since_val=""
  if [ "$s" = athlete ]; then since_col=", since" since_val=", '2026-09-01'"; fi
  sql "
truncate $s.tenant_ref, $s.person_ref, $s.player_ref, $s.team_ref, $s.team_player_ref, $s.team_staff_ref, $s.guardian_link_ref;
insert into $s.tenant_ref (tenant_id, status, timezone, occurred_at, event_id) values
  ('$T1', 'ACTIVE', 'Europe/Madrid', now(), gen_random_uuid()),
  ('$T2', 'SUSPENDED', 'Asia/Jakarta', now(), gen_random_uuid());
insert into $s.person_ref (tenant_id, id, display_name, subject, roles, active, occurred_at, event_id) values
  ('$T1', '$P1', 'Ana Coach', 'sub-of-ana', '{COACH,ADMIN}', true, now(), gen_random_uuid()),
  ('$T1', '$P2', 'Leo Player', null, '{PLAYER}', true, now(), gen_random_uuid()),
  ('$T1', '$P3', 'Pam Parent', null, '{PARENT}', false, now(), gen_random_uuid());
insert into $s.person_ref (tenant_id, id, removed, occurred_at, event_id)
  values ('$T1', '$GONE', true, now(), gen_random_uuid());
insert into $s.player_ref (tenant_id, id, person_id, display_name, status, birth_date, gender, occurred_at, event_id)
  values ('$T1', '$PL', '$P2', 'Leo Player', 'ACTIVE', '2012-03-04', 'MALE', now(), gen_random_uuid());
insert into $s.team_ref (tenant_id, id, season_id, season_end_date, name, occurred_at, event_id)
  values ('$T1', '$TM', '$S1', '2027-06-30', 'Lions', now(), gen_random_uuid());
insert into $s.team_player_ref (tenant_id, id, team_id, player_id, jersey_number, joined_on, left_on, invalid_reason,
  occurred_at, event_id) values ('$T1', '$TP', '$TM', '$PL', '7', '2026-09-10', null, null, now(), gen_random_uuid());
insert into $s.team_staff_ref (tenant_id, id, team_id, person_id, role, removed, occurred_at, event_id$since_col)
  values ('$T1', gen_random_uuid(), '$TM', '$P1', 'COACH', false, now(), gen_random_uuid()$since_val);
insert into $s.guardian_link_ref (tenant_id, id, guardian_person_id, player_id, removed, occurred_at, event_id)
  values ('$T1', '$GL', '$P3', '$PL', false, now(), gen_random_uuid());"
}
seed() { seed_replica game; seed_replica athlete; }

passed=0 failed=0
ok() { passed=$((passed + 1)); echo "ok   $1"; }
bad() { failed=$((failed + 1)); echo "FAIL $1"; sed 's/^/     | /' "$WORK/out"; }
drift() { # [wait seconds]: runs the check, output in $WORK/out, exit code in $rc
  rc=0
  POSTGRES_CONTAINER="$CONTAINER" EVENTS_DRIFT_WAIT="${1:-0}" scripts/events-drift.sh >"$WORK/out" 2>&1 || rc=$?
}
expect_drift() { # name service aggregate kind id
  drift
  if [ "$rc" = 1 ] && grep -qx "drift: $2 $3 $4 $5" "$WORK/out" && [ "$(grep -c '^drift: ' "$WORK/out")" = 1 ]; then
    ok "$1"
  else
    bad "$1 (exit $rc, expected 1 and only 'drift: $2 $3 $4 $5')"
  fi
}

# ---- equal ---------------------------------------------------------------------------------------------------------
seed
drift
if [ "$rc" = 0 ] && grep -Eq '^person +game +3 +3 +0 +0 +0$' "$WORK/out" && grep -Eq '^tenant +athlete +2 +2 +0 +0 +0$' "$WORK/out" \
  && grep -Eq '^team-staff +athlete +1 +1 +0 +0 +0$' "$WORK/out" && ! grep -q '^drift: ' "$WORK/out"; then
  ok "replicas equal to core (roles in another order, a removed row core no longer has): exit 0 with the counts"
else
  bad "equal replicas (exit $rc)"
fi

# ---- one difference of each kind per aggregate and service --------------------------------------------------------
# aggregate | the replica row's key | the id the check names | an extra row (insert values) | a changed column
cases() {
  cat <<EOF
tenant|tenant_ref|tenant_id = '$T1'|$T1|(tenant_id, status, timezone, occurred_at, event_id) values ('$NEW', 'ACTIVE', 'UTC', now(), gen_random_uuid())|timezone = 'UTC'
person|person_ref|id = '$P1'|$P1|(tenant_id, id, display_name, roles, active, occurred_at, event_id) values ('$T1', '$NEW', 'Ghost', '{}', true, now(), gen_random_uuid())|roles = '{ADMIN}'
player|player_ref|id = '$PL'|$PL|(tenant_id, id, person_id, display_name, status, occurred_at, event_id) values ('$T1', '$NEW', '$P1', 'Ghost', 'ACTIVE', now(), gen_random_uuid())|birth_date = '2012-03-05'
team|team_ref|id = '$TM'|$TM|(tenant_id, id, season_id, season_end_date, name, occurred_at, event_id) values ('$T1', '$NEW', '$S1', '2027-06-30', 'Ghosts', now(), gen_random_uuid())|season_end_date = '2027-07-31'
team-player|team_player_ref|id = '$TP'|$TP|(tenant_id, id, team_id, player_id, joined_on, occurred_at, event_id) values ('$T1', '$NEW', '$TM', '$PL', '2026-09-11', now(), gen_random_uuid())|jersey_number = '8'
team-staff|team_staff_ref|team_id = '$TM' and person_id = '$P1'|$TM:$P1|(tenant_id, id, team_id, person_id, role, removed, occurred_at, event_id) values ('$T1', gen_random_uuid(), '$NEW', '$P1', 'COACH', false, now(), gen_random_uuid())|role = 'ASSISTANT_COACH'
guardian-link|guardian_link_ref|id = '$GL'|$GL|(tenant_id, id, guardian_person_id, player_id, removed, occurred_at, event_id) values ('$T1', '$NEW', '$P1', '$PL', false, now(), gen_random_uuid())|guardian_person_id = '$P1'
EOF
}
extra_id() { case "$1" in team-staff) echo "$NEW:$P1" ;; *) echo "$NEW" ;; esac; }
while IFS='|' read -r agg table key id extra change; do
  for s in game athlete; do
    seed; sql "delete from $s.$table where $key"
    expect_drift "$agg missing in $s" "$s" "$agg" missing "$id"
    seed; sql "insert into $s.$table $extra"
    expect_drift "$agg extra in $s (present, not removed, gone in core)" "$s" "$agg" extra "$(extra_id "$agg")"
    seed; sql "update $s.$table set $change where $key"
    expect_drift "$agg differs in $s" "$s" "$agg" differs "$id"
  done
done < <(cases)

seed; sql "update game.person_ref set removed = true, display_name = null, roles = null, active = null where id = '$P2'"
expect_drift "a removed replica row of a live aggregate is missing" game person missing "$P2"
seed; sql "update athlete.team_staff_ref set since = '2026-10-01'"
expect_drift "athlete's staff since date is compared" athlete team-staff differs "$TM:$P1"
seed; sql "update core.person set given_name = 'Anna' where id = '$P1'"
drift
if [ "$rc" = 1 ] && grep -qx "drift: game person differs $P1" "$WORK/out" && grep -qx "drift: athlete person differs $P1" "$WORK/out" \
  && ! grep -q 'Anna\|Coach\|sub-of-ana' "$WORK/out"; then
  ok "a change in core differs in both replicas; the output names ids only, no personal data"
else
  bad "core changed (exit $rc)"
fi
sql "update core.person set given_name = 'Ana' where id = '$P1'"

# ---- lag: a difference that heals before the retry is not drift ------------------------------------------------------
seed; sql "delete from game.team_player_ref where id = '$TP'"
rc=0
POSTGRES_CONTAINER="$CONTAINER" EVENTS_DRIFT_WAIT=5 scripts/events-drift.sh >"$WORK/out" 2>&1 &
check=$!
sleep 2
seed_replica game
wait "$check" || rc=$?
if [ "$rc" = 0 ] && grep -q 'matched on the retry' "$WORK/out" && ! grep -q '^drift: ' "$WORK/out"; then
  ok "a row that catches up during the retry wait is lag, not drift: exit 0"
else
  bad "lag (exit $rc)"
fi

# ---- could not run -----------------------------------------------------------------------------------------------------
rc=0
POSTGRES_CONTAINER="hoops-drift-test-missing-$$" EVENTS_DRIFT_WAIT=0 scripts/events-drift.sh >"$WORK/out" 2>&1 || rc=$?
if [ "$rc" = 2 ]; then ok "no database: exit 2"; else bad "no database (exit $rc, expected 2)"; fi
rc=0
scripts/events-drift.sh --nonsense >"$WORK/out" 2>&1 || rc=$?
if [ "$rc" = 2 ]; then ok "unknown option: exit 2"; else bad "unknown option (exit $rc, expected 2)"; fi

echo "events-drift.test: $passed passed, $failed failed"
[ "$failed" = 0 ]
