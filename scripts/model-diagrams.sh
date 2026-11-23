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

TPG_NAME=model-diagrams
# shellcheck source=scripts/lib/throwaway-pg.sh
. scripts/lib/throwaway-pg.sh
WORK="$(mktemp -d)"
cleanup() {
  throwaway_pg_stop
  rm -rf "$WORK"
}
trap cleanup EXIT

throwaway_pg_start diagrams

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
