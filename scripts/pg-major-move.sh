#!/usr/bin/env bash
# Moves the compose database to the PostgreSQL major that infra/compose/compose.yaml names (WP144, ADR-0073;
# docs/runbooks/postgresql-major.md). Decision 115: the data is not restored, the stack starts fresh and is reseeded; the
# dump is the safety copy.
#
#   scripts/pg-major-move.sh --out DIR [--apply] [--dump-only] [--container NAME] [--old-volume NAME]
#   scripts/pg-major-move.sh --clean-up --out DIR [--remove] [--container NAME] [--old-volume NAME]
#
#   --out DIR         absolute directory outside the repository for the dump (created 0700; the dump is 0600: it holds
#                     the roles' password verifiers). Required.
#   --apply           do it. Without it: a dry run that only reads (checks, then prints what --apply would run).
#   --dump-only       with --apply: stop after the dump (the stack keeps running on the old major).
#   --container NAME  the running database container (default hoops-postgres)
#   --old-volume NAME its data volume (default hoops_pgdata)
#   --clean-up        after a move (P-14): list the copies it left, the old volume and the dumps in --out, with age.
#   --remove          with --clean-up: remove them, once the words asked for are typed at a terminal (the owner's step).
#
# Steps of --apply: checks (container running on the old volume, an older major than compose's, standard_conforming_strings
# on, the new volume absent), pg_dumpall with the OLD server's own tools inside its container (no password: the local
# socket), sha256 of the dump, `just down` (keeps every volume), `just up` (fresh bootstrap on the new volume), check the
# new major. The move never removes a volume; never prints a password. The way back is printed at the end.
# --clean-up only reads; with --remove it removes the old volume and the dump files of --out (nothing else there) when
# the move is done (the container runs the new major on the new volume), no container uses the old volume, the old
# volume is not the one compose names, and the words "remove <old volume>" are typed at a terminal.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
COMPOSE=infra/compose/compose.yaml

usage() { { echo "usage:"; sed -n '6,16p' "$0" | sed 's/^# \{0,1\}//'; } >&2; exit 2; }
die() { echo "pg-major-move: $*" >&2; exit 1; }

OUT="" APPLY=0 DUMP_ONLY=0 CLEAN_UP=0 REMOVE=0 CONTAINER=hoops-postgres OLD_VOLUME=hoops_pgdata
KEEP_DAYS=14 # docs/runbooks/postgresql-major.md: the copies are kept this long after the move
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    --out) [ $# -ge 2 ] || usage; OUT="$2"; shift ;;
    --apply) APPLY=1 ;;
    --dump-only) DUMP_ONLY=1 ;;
    --clean-up) CLEAN_UP=1 ;;
    --remove) REMOVE=1 ;;
    --container) [ $# -ge 2 ] || usage; CONTAINER="$2"; shift ;;
    --old-volume) [ $# -ge 2 ] || usage; OLD_VOLUME="$2"; shift ;;
    *) echo "pg-major-move: unknown argument $1" >&2; usage ;;
  esac
  shift
done
[ -n "$OUT" ] || usage
[ "$REMOVE" = 0 ] || [ "$CLEAN_UP" = 1 ] || usage
[ "$CLEAN_UP" = 0 ] || { [ "$APPLY" = 0 ] && [ "$DUMP_ONLY" = 0 ]; } || usage
case "$OUT" in /*) ;; *) echo "pg-major-move: --out must be an absolute path" >&2; exit 2 ;; esac
case "$OUT/" in "$ROOT"/*) echo "pg-major-move: --out must be outside the repository (the dump holds password verifiers)" >&2; exit 2 ;; esac

# What compose wants: the major of its postgres image and the volume mounted at /var/lib/postgresql.
project=$(sed -n 's/^name: *\([a-z0-9_-]*\).*/\1/p' "$COMPOSE" | head -1)
new_major=$(sed -n 's#^ *image: docker\.io/library/postgres:\([0-9][0-9]*\).*#\1#p' "$COMPOSE" | head -1)
new_key=$(sed -n 's#^ *- \([A-Za-z0-9_-]*\):/var/lib/postgresql$#\1#p' "$COMPOSE" | head -1)
[ -n "$project" ] && [ -n "$new_major" ] && [ -n "$new_key" ] || die "cannot read the postgres image and volume of $COMPOSE"
NEW_VOLUME="${project}_${new_key}"

sql() { podman exec "$CONTAINER" psql -X -q -At -U postgres -d postgres -c "$1"; }

# --- clean-up (P-14): the copies a move leaves, the old volume and the dumps; dry run unless --remove
age_days() { echo $((($(date +%s) - $1) / 86400)); }
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }
clean_up() {
  local dumps=() f created users running="" mounts="" major="" answer
  [ "$OLD_VOLUME" != "$NEW_VOLUME" ] || die "$OLD_VOLUME is the volume compose names: the clean-up never removes it"
  shopt -s nullglob
  dumps=("$OUT"/pg_dumpall-*.sql "$OUT"/pg_dumpall-*.sql.sha256)
  shopt -u nullglob
  echo "pg-major-move: copies a move left (kept $KEEP_DAYS days after the move, docs/runbooks/postgresql-major.md):"
  if podman volume exists "$OLD_VOLUME"; then
    created=$(podman volume inspect --format '{{.CreatedAt.Unix}}' "$OLD_VOLUME")
    users=$(podman ps -a --filter "volume=$OLD_VOLUME" --format '{{.Names}}' | awk 'NF' | paste -sd ' ' -)
    echo "  volume $OLD_VOLUME, created $(age_days "$created") days ago${users:+, used by: $users}"
  else
    echo "  volume $OLD_VOLUME: none"
  fi
  for f in ${dumps[@]+"${dumps[@]}"}; do echo "  file $f, $(age_days "$(mtime "$f")") days old"; done
  [ "${#dumps[@]}" -gt 0 ] || echo "  no dump in $OUT"
  if [ "$REMOVE" = 0 ]; then
    echo "pg-major-move: dry run, nothing removed. The owner removes them with --clean-up --out $OUT --remove"
    echo "  (the words are typed at a terminal) once PostgreSQL $new_major has run $KEEP_DAYS days and its checks are green."
    return 0
  fi
  [ -t 0 ] || die "--remove asks for the words typed at a terminal, so only a person at one can remove the copies (P-14)"
  [ -z "${users:-}" ] || die "a container uses $OLD_VOLUME ($users): remove it first; nothing removed"
  [ "$(podman inspect --format '{{.State.Running}}' "$CONTAINER" 2>/dev/null)" = true ] && running=1
  [ -z "$running" ] || mounts=$(podman inspect --format '{{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}' "$CONTAINER")
  [ -z "$running" ] || major=$(($(sql "show server_version_num") / 10000))
  case " $mounts" in *" $NEW_VOLUME:"*) ;; *) major="" ;; esac
  [ "$major" = "$new_major" ] ||
    die "the move is not done: $CONTAINER does not run PostgreSQL $new_major on $NEW_VOLUME; nothing removed"
  read -r -p "Type 'remove $OLD_VOLUME' to remove the volume and the ${#dumps[@]} dump file(s) above: " answer
  [ "$answer" = "remove $OLD_VOLUME" ] || die "not confirmed; nothing removed"
  if podman volume exists "$OLD_VOLUME"; then podman volume rm "$OLD_VOLUME" >/dev/null; fi
  for f in ${dumps[@]+"${dumps[@]}"}; do rm -f -- "$f"; done
  echo "pg-major-move: removed $OLD_VOLUME and ${#dumps[@]} dump file(s); the stack runs on $NEW_VOLUME"
}
# --- end of clean-up

if [ "$CLEAN_UP" = 1 ]; then
  clean_up
  exit 0
fi

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
old major's tools into an empty volume). Once PostgreSQL $new_major has run $KEEP_DAYS days with green checks, the owner removes
both copies: scripts/pg-major-move.sh --clean-up --out $OUT (a dry run that lists them), then the same with --remove.
EOF
