#!/usr/bin/env bash
# Tests of ensure_podman_dropin in scripts/doctor.sh with a stubbed `podman` (run: just test-hooks). The real machine is
# never touched: the branches "drop-in present", "missing, containers running (restart pending)" and "missing, idle
# (restart)" are driven through the stub. Several agents share one Podman VM, so this must never restart its service.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
# shellcheck source=scripts/doctor.sh disable=SC1091
source scripts/doctor.sh
fail=0 total=0
state=$(mktemp -d)
trap 'rm -rf "$state"' EXIT

UNIT_BASE=$'# /usr/lib/systemd/user/podman.service\n[Service]\nExecStart=/usr/bin/podman $LOGGING system service\n'
DROPIN=$'# /var/home/core/.config/systemd/user/podman.service.d/no-timeout.conf\n[Service]\nExecStart=\nExecStart=/usr/bin/podman $LOGGING system service --time=0\n'

# podman machine ssh <script>: the stub tells the three calls apart by what the script contains.
podman() {
  [ "$1 $2" = "machine ssh" ] || { echo "unexpected podman $*" >&2; return 99; }
  local script=$3
  echo "ssh" >>"$state/calls"
  case "$script" in
    *restart*) echo restart >>"$state/actions" ;;
    *daemon-reload*) touch "$state/dropin"; echo "write+reload" >>"$state/actions"; echo "RUNNING=$(cat "$state/running")" ;;
    *"systemctl --user cat"*) printf '%s' "$UNIT_BASE"; [ -e "$state/dropin" ] && printf '%s' "$DROPIN"; true ;;
    *) echo "unexpected script: $script" >&2; return 98 ;;
  esac
}

scenario() { # scenario <label> <dropin present 0/1> <running containers> <expected actions> <expected output regex>
  local label=$1 present=$2 running=$3 want_actions=$4 want_out=$5 out rc got
  total=$((total + 1))
  rm -f "$state/dropin" "$state/actions" "$state/calls"; : >"$state/actions"
  echo "$running" >"$state/running"
  [ "$present" = 1 ] && touch "$state/dropin"
  out=$(ensure_podman_dropin 2>&1); rc=$?
  got=$(paste -sd, "$state/actions")
  if [ "$rc" -eq 0 ] && [ "$got" = "$want_actions" ] && grep -qE "$want_out" <<<"$out"; then return 0; fi
  fail=$((fail + 1))
  printf 'FAIL %s: rc=%s actions=[%s] (want [%s]) output:\n%s\n' "$label" "$rc" "$got" "$want_actions" "$out"
}

scenario "present: nothing is written or restarted" 1 0 "" 'ExecStart=.*--time=0'
scenario "present: a single ssh call" 1 3 "" 'present'
scenario "missing, containers running: written, restart pending" 0 4 "write+reload" 'restart is pending'
scenario "missing, idle: written and restarted" 0 0 "write+reload,restart" 'ExecStart=.*--time=0'

# one ssh call to read when the drop-in is present
rm -f "$state/dropin" "$state/calls"; touch "$state/dropin"; echo 0 >"$state/running"
total=$((total + 1))
ensure_podman_dropin >/dev/null 2>&1
if [ "$(wc -l <"$state/calls" | tr -d ' ')" != 1 ]; then fail=$((fail + 1)); echo "FAIL present case used more than one ssh call"; fi

echo "doctor podman drop-in: $((total - fail))/$total passed"
[ "$fail" -eq 0 ]
