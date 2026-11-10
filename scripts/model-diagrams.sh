#!/usr/bin/env bash
# Regenerates (or checks) the Mermaid diagrams of docs/domain/<service>-model.md.
#   scripts/model-diagrams.sh            regenerate the three pages in place
#   scripts/model-diagrams.sh --check    regenerate into a temp dir; exit 1 with a diff when a page is stale
# ER diagrams come from a throwaway PostgreSQL (the compose image, infra/db/init, the service's Flyway files of
# the working tree); class diagrams from the Java sources (scripts/model_diagrams.py). The compose database is
# never touched: the container has its own name, no published port, and is removed on exit (also on failure).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
MODE=write
case "${1:-}" in
  "") ;;
  --check) MODE=check ;;
  *) echo "usage: $0 [--check]" >&2; exit 2 ;;
esac

IMAGE="$(sed -n 's/^[[:space:]]*image:[[:space:]]*\(docker.io\/library\/postgres:[^[:space:]]*\).*/\1/p' infra/compose/compose.yaml | head -1)"
[ -n "$IMAGE" ] || { echo "model-diagrams: no postgres image in infra/compose/compose.yaml" >&2; exit 1; }
CONTAINER="hoops-diagrams-pg-$$-$RANDOM"
WORK="$(mktemp -d)"
cleanup() {
  podman rm -f "$CONTAINER" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

psql_in() { podman exec -i -e PGOPTIONS="-c client_min_messages=warning" "$CONTAINER" psql -X -q -v ON_ERROR_STOP=1 -U "$1" -d hoops "${@:2}"; }

podman run -d --name "$CONTAINER" -e POSTGRES_PASSWORD=diagrams -e POSTGRES_DB=hoops "$IMAGE" >/dev/null
# The image's init server listens on the unix socket only; the real server also answers on TCP.
for _ in $(seq 1 90); do
  podman exec "$CONTAINER" pg_isready -q -h 127.0.0.1 -U postgres -d hoops && break
  sleep 1
done
podman exec "$CONTAINER" pg_isready -q -h 127.0.0.1 -U postgres -d hoops || { echo "model-diagrams: PostgreSQL did not start" >&2; exit 1; }
psql_in postgres < infra/db/init/01_roles_schemas.sql >/dev/null

# schemas per service; the one named like the service is shown unprefixed, others as <schema>_<table>
# (no associative arrays: macOS ships bash 3.2)
schemas_of() { case "$1" in core) echo "core,billing" ;; *) echo "$1" ;; esac; }

CATALOG_SQL=$(cat <<'SQL'
select json_build_object(
  'columns', (select coalesce(json_agg(json_build_object('schema', n.nspname, 'table', c.relname,
      'column', a.attname, 'ord', a.attnum, 'type', format_type(a.atttypid, a.atttypmod),
      'notnull', a.attnotnull, 'pk', coalesce(a.attnum = any(pk.conkey), false), 'rls', c.relrowsecurity)), '[]')
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
    left join pg_constraint pk on pk.conrelid = c.oid and pk.contype = 'p'
    where c.relkind in ('r', 'p') and not c.relispartition and n.nspname = any(string_to_array('@SCHEMAS@', ','))
      and c.relname <> 'flyway_schema_history'),
  'fks', (select coalesce(json_agg(json_build_object('schema', n.nspname, 'table', c.relname,
      'rschema', rn.nspname, 'rtable', rc.relname,
      'cols', (select json_agg(a.attname order by k.ord) from unnest(f.conkey) with ordinality k(attnum, ord)
               join pg_attribute a on a.attrelid = f.conrelid and a.attnum = k.attnum))), '[]')
    from pg_constraint f join pg_class c on c.oid = f.conrelid join pg_namespace n on n.oid = c.relnamespace
    join pg_class rc on rc.oid = f.confrelid join pg_namespace rn on rn.oid = rc.relnamespace
    where f.contype = 'f' and n.nspname = any(string_to_array('@SCHEMAS@', ','))),
  'uniques', (select coalesce(json_agg(json_build_object('schema', n.nspname, 'table', c.relname,
      'cols', (select json_agg(a.attname order by k.ord) from unnest(u.conkey) with ordinality k(attnum, ord)
               join pg_attribute a on a.attrelid = u.conrelid and a.attnum = k.attnum))), '[]')
    from pg_constraint u join pg_class c on c.oid = u.conrelid join pg_namespace n on n.oid = c.relnamespace
    where u.contype = 'u' and n.nspname = any(string_to_array('@SCHEMAS@', ',')))
);
SQL
)

# Flyway order: versioned files by numeric version, then repeatable (R__) files by name.
apply_migrations() {
  local dir="$1" role="$2" f
  while IFS= read -r f; do
    psql_in "$role" < "$f" >/dev/null || { echo "model-diagrams: $f failed" >&2; return 1; }
  done < <(
    { ls "$dir" | grep -E '^V[0-9]+__' | sort -t_ -k1.2 -n; ls "$dir" | grep -E '^R__' | sort; } | sed "s|^|$dir/|"
  )
}

OUT="$WORK/out"
mkdir -p "$OUT"
for svc in core game athlete; do
  apply_migrations "services/$svc-service/src/main/resources/db/migration" "${svc}_migrator"
  sql="${CATALOG_SQL//@SCHEMAS@/$(schemas_of "$svc")}"
  printf '%s\n' "$sql" | psql_in "${svc}_migrator" -At > "$WORK/$svc-catalog.json"
  python3 -I scripts/model_diagrams.py render "$svc" "$WORK/$svc-catalog.json" \
    "services/$svc-service/src/main/java/com/hoopsacademy/$svc" "docs/domain/$svc-model.md" "$OUT/$svc-model.md" "$svc"
done

if [ "$MODE" = write ]; then
  for svc in core game athlete; do cp "$OUT/$svc-model.md" "docs/domain/$svc-model.md"; done
  echo "model-diagrams: pages written"
else
  status=0
  for svc in core game athlete; do
    diff -u "docs/domain/$svc-model.md" "$OUT/$svc-model.md" || status=1
  done
  if [ "$status" -ne 0 ]; then
    echo "model-diagrams: docs/domain/*-model.md are stale; run 'just diagrams' and commit" >&2
    exit 1
  fi
  echo "model-diagrams: pages up to date"
fi
