#!/usr/bin/env bash
# Moves the compose database to the PostgreSQL major that infra/compose/compose.yaml names (WP144, ADR-0073;
# docs/runbooks/postgresql-major.md). Decision 115: the data is not restored, the stack starts fresh and is reseeded; the
# dump is the safety copy.
#
#   scripts/pg-major-move.sh --out DIR [--apply] [--dump-only] [--container NAME] [--old-volume NAME]
#
#   --out DIR         absolute directory outside the repository for the dump (created 0700; the dump is 0600: it holds
#                     the roles' password verifiers). Required.
#   --apply           do it. Without it: a dry run that only reads (checks, then prints what --apply would run).
#   --dump-only       with --apply: stop after the dump (the stack keeps running on the old major).
#   --container NAME  the running database container (default hoops-postgres)
#   --old-volume NAME its data volume (default hoops_pgdata)
#
# Steps of --apply: checks (container running on the old volume, an older major than compose's, standard_conforming_strings
# on, the new volume absent), pg_dumpall with the OLD server's own tools inside its container (no password: the local
# socket), sha256 of the dump, `just down` (keeps every volume), `just up` (fresh bootstrap on the new volume), check the
# new major. Never removes a volume; never prints a password. The way back is printed at the end.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
COMPOSE=infra/compose/compose.yaml

usage() { { echo "usage:"; sed -n '6,13p' "$0" | sed 's/^# \{0,1\}//'; } >&2; exit 2; }
die() { echo "pg-major-move: $*" >&2; exit 1; }

OUT="" APPLY=0 DUMP_ONLY=0 CONTAINER=hoops-postgres OLD_VOLUME=hoops_pgdata
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    --out) [ $# -ge 2 ] || usage; OUT="$2"; shift ;;
    --apply) APPLY=1 ;;
    --dump-only) DUMP_ONLY=1 ;;
    --container) [ $# -ge 2 ] || usage; CONTAINER="$2"; shift ;;
    --old-volume) [ $# -ge 2 ] || usage; OLD_VOLUME="$2"; shift ;;
    *) echo "pg-major-move: unknown argument $1" >&2; usage ;;
  esac
  shift
done
[ -n "$OUT" ] || usage
case "$OUT" in /*) ;; *) echo "pg-major-move: --out must be an absolute path" >&2; exit 2 ;; esac
case "$OUT/" in "$ROOT"/*) echo "pg-major-move: --out must be outside the repository (the dump holds password verifiers)" >&2; exit 2 ;; esac

# What compose wants: the major of its postgres image and the volume mounted at /var/lib/postgresql.
project=$(sed -n 's/^name: *\([a-z0-9_-]*\).*/\1/p' "$COMPOSE" | head -1)
new_major=$(sed -n 's#^ *image: docker\.io/library/postgres:\([0-9][0-9]*\).*#\1#p' "$COMPOSE" | head -1)
new_key=$(sed -n 's#^ *- \([A-Za-z0-9_-]*\):/var/lib/postgresql$#\1#p' "$COMPOSE" | head -1)
[ -n "$project" ] && [ -n "$new_major" ] && [ -n "$new_key" ] || die "cannot read the postgres image and volume of $COMPOSE"
NEW_VOLUME="${project}_${new_key}"

sql() { podman exec "$CONTAINER" psql -X -q -At -U postgres -d postgres -c "$1"; }

# --- checks (read only)
[ "$(podman inspect --format '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = true ] || die "container $CONTAINER is not running"
mounts=$(podman inspect --format '{{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}' "$CONTAINER")
case " $mounts" in *" $OLD_VOLUME:"*) ;; *) die "container $CONTAINER does not use volume $OLD_VOLUME (mounts: $mounts)" ;; esac
old_num=$(sql "show server_version_num")
old_major=$((old_num / 10000))
[ "$old_major" -lt "$new_major" ] || die "$CONTAINER already runs PostgreSQL $old_major; compose names $new_major: nothing to move"
[ "$(sql "show standard_conforming_strings")" = on ] ||
  die "standard_conforming_strings is off: a dump made so does not load into PostgreSQL 19+ (release notes); turn it on first"
if podman volume exists "$NEW_VOLUME"; then
  die "volume $NEW_VOLUME exists already: the new major must start on an empty volume (inspect it; it is not removed here)"
fi
stamp=$(date -u +%Y%m%dT%H%M%SZ)
DUMP="$OUT/pg_dumpall-$CONTAINER-pg$old_major-$stamp.sql"
echo "pg-major-move: $CONTAINER runs PostgreSQL $old_major on volume $OLD_VOLUME; compose names $new_major on $NEW_VOLUME"

if [ "$APPLY" = 0 ]; then
  echo "pg-major-move: dry run, nothing changed. --apply would run:"
  echo "  podman exec $CONTAINER pg_dumpall -U postgres > $DUMP   (umask 077; then sha256)"
  [ "$DUMP_ONLY" = 1 ] || printf '  just down    (keeps every volume)\n  just up      (fresh bootstrap of PostgreSQL %s on %s)\n' \
    "$new_major" "$NEW_VOLUME"
  exit 0
fi

# --- dump with the old server's own tools; the content is never shown
umask 077
mkdir -p "$OUT"
chmod 700 "$OUT"
podman exec "$CONTAINER" pg_dumpall -U postgres >"$DUMP"
tail -n 5 "$DUMP" | grep -q 'PostgreSQL database cluster dump complete' || die "the dump $DUMP is incomplete; the stack is untouched"
(cd "$OUT" && shasum -a 256 "$(basename "$DUMP")" >"$(basename "$DUMP").sha256")
echo "pg-major-move: dump $DUMP ($(wc -c <"$DUMP" | tr -d ' ') bytes, sha256 $(cut -c1-16 <"$DUMP.sha256")...)"
[ "$DUMP_ONLY" = 0 ] || { echo "pg-major-move: --dump-only: the stack still runs PostgreSQL $old_major"; exit 0; }

# --- the stack on the new major
just down
just up || die "just up failed after just down: the stack is down, the dump $DUMP is made and $OLD_VOLUME is kept.
  Fix the cause and run just up by hand (a second run of this script refuses: the old container is gone), or take the
  way back: the compose.yaml of before the move (postgres:$old_major, volume pgdata), then just up."
now_major=$(($(sql "show server_version_num") / 10000))
[ "$now_major" = "$new_major" ] || die "after just up $CONTAINER runs PostgreSQL $now_major, expected $new_major"
podman volume exists "$OLD_VOLUME" || die "volume $OLD_VOLUME is gone (it was not removed by this script)"
cat <<EOF
pg-major-move: $CONTAINER runs PostgreSQL $new_major on the fresh volume $NEW_VOLUME; $OLD_VOLUME (PostgreSQL $old_major) is
kept as it was and no compose file names it any more.
Next (decision 115, reseed): just seed-users; just services-up; just seed-academy; just finance-up; just events-backfill force
The way back: check out the compose.yaml of before the move (image postgres:$old_major, volume pgdata mounted at
/var/lib/postgresql/data), then just down && just up: the stack runs PostgreSQL $old_major on $OLD_VOLUME again, with the
data of the moment of the move; then just events-backfill force. The dump $DUMP is a second copy (psql -f with the
old major's tools into an empty volume). Remove $OLD_VOLUME by hand only once PostgreSQL $new_major has proven itself.
EOF
