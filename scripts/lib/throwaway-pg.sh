# shellcheck shell=bash
# A throwaway PostgreSQL in Podman for scripts and their tests (scripts/model-diagrams.sh, scripts/tests/events-drift.test.sh).
# Source it from the repository root; the caller sets TPG_NAME (container name prefix and message prefix) and calls
#   throwaway_pg_start PASSWORD   the compose Postgres image, database `hoops`, infra/db/init applied (roles and schemas);
#                                 sets CONTAINER, fails with "PostgreSQL did not start"
#   psql_in ROLE [psql args]      psql as ROLE, SQL on stdin
#   apply_migrations DIR ROLE     Flyway order: V<n>__*.sql by numeric version, then R__*.sql by name
#   throwaway_pg_stop             removes the container (call it from the caller's EXIT trap)
# The compose database is never touched: the container has its own name, no published port.

throwaway_pg_start() {
  local image
  image="$(sed -n 's/^[[:space:]]*image:[[:space:]]*\(docker.io\/library\/postgres:[^[:space:]]*\).*/\1/p' infra/compose/compose.yaml | head -1)"
  [ -n "$image" ] || { echo "$TPG_NAME: no postgres image in infra/compose/compose.yaml" >&2; return 1; }
  CONTAINER="hoops-$TPG_NAME-pg-$$-$RANDOM"
  podman run -d --name "$CONTAINER" -e POSTGRES_PASSWORD="$1" -e POSTGRES_DB=hoops "$image" >/dev/null
  # The image's init server listens on the unix socket only; the real server also answers on TCP.
  for _ in $(seq 1 90); do
    podman exec "$CONTAINER" pg_isready -q -h 127.0.0.1 -U postgres -d hoops && break
    sleep 1
  done
  podman exec "$CONTAINER" pg_isready -q -h 127.0.0.1 -U postgres -d hoops || { echo "$TPG_NAME: PostgreSQL did not start" >&2; return 1; }
  psql_in postgres < infra/db/init/01_roles_schemas.sql >/dev/null
}

psql_in() { podman exec -i -e PGOPTIONS="-c client_min_messages=warning" "$CONTAINER" psql -X -q -v ON_ERROR_STOP=1 -U "$1" -d hoops "${@:2}"; }

# shellcheck disable=SC2010 # file names are V<n>__<snake_case>.sql (CLAUDE.md), no odd characters
apply_migrations() {
  local dir="$1" role="$2" f
  while IFS= read -r f; do
    psql_in "$role" < "$dir/$f" >/dev/null || { echo "$TPG_NAME: $f failed" >&2; return 1; }
  done < <({ ls "$dir" | grep -E '^V[0-9]+__' | sort -t_ -k1.2 -n; ls "$dir" | grep -E '^R__' | sort; })
}

throwaway_pg_stop() { podman rm -f "${CONTAINER:-}" >/dev/null 2>&1 || true; }
