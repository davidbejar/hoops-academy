#!/usr/bin/env bash
# Shared by the tenancy checks that the Claude Code hook .claude/hooks/tenancy-gate.sh runs before Claude's
# git commit / git push (and by `just isolation-check` / `just db-role-check`). Source it from the repo root.

# shellcheck source=../env.sh
source scripts/env.sh >/dev/null

# The tests need real Postgres (and Keycloak) containers. Fail loudly instead of skipping: a gate that quietly
# passes when Podman is down would let a broken isolation through.
require_podman() {
  if ! podman info >/dev/null 2>&1; then
    echo "✗ $HOOK_LABEL needs Podman for Testcontainers, and Podman is not reachable." >&2
    echo "  Start it:   podman machine start" >&2
    echo "  ($HOOK_CI_NOTE)" >&2
    exit 1
  fi
  sync_podman_clock
}

# The Podman VM clock falls behind or stalls after the host sleeps (chrony refuses to step); Keycloak tokens from
# Testcontainers then look expired and the checks fail with 401 (docs/runbooks/kind.md). Step the VM clock to the
# host's when they differ by more than 30 s. Only for a Podman machine (macOS); a native Podman has no VM.
sync_podman_clock() {
  command -v podman >/dev/null 2>&1 || return 0
  podman machine inspect >/dev/null 2>&1 || return 0
  local host vm
  host=$(date +%s)
  vm=$(podman machine ssh "date +%s" 2>/dev/null | tr -dc '0-9') || return 0
  [ -n "$vm" ] || return 0
  local drift=$((host - vm))
  if [ "${drift#-}" -gt 30 ]; then
    if podman machine ssh "sudo date -u -s @$(date +%s)" >/dev/null 2>&1; then
      echo "· Podman VM clock was off by ${drift}s; resynced before $HOOK_LABEL"
    else
      echo "· Podman VM clock is off by ${drift}s and could not be resynced; tokens may look expired" >&2
    fi
  fi
}

# run_maven <maven args…>: quiet on success, the failing tests and assertion messages on failure.
run_maven() {
  local log start=$SECONDS
  log=$(mktemp -t hoops-hook.XXXXXX)
  if ./mvnw -B -ntp "$@" >"$log" 2>&1; then
    # Per-module surefire totals ("Tests run: N, …" without "-- in <class>"). Zero means the filter matched nothing
    # (a renamed test class): that must not count as a pass.
    local ran
    ran=$(grep -E '^\[INFO\] Tests run: [0-9]+, Failures' "$log" | grep -v -- '-- in ' \
      | sed -E 's/.*Tests run: ([0-9]+),.*/\1/' | awk '{s+=$1} END {print s+0}')
    if [ "$ran" -eq 0 ]; then
      echo "✗ $HOOK_LABEL ran no tests: the -Dtest filter matched nothing. Full log: $log" >&2
      exit 1
    fi
    echo "✓ $HOOK_LABEL: $ran tests passed in $((SECONDS - start))s"
    rm -f "$log"
  else
    grep -A3 -E '<<< (FAIL|ERROR)|Tests run:.*(Failures: [1-9]|Errors: [1-9])|Expect|expected|but was|violations|\[ERROR\] .*(COMPILATION|cannot find)' "$log" \
      | grep -vE '^\[ERROR\] *$' | head -60 >&2 || true
    echo "✗ $HOOK_LABEL FAILED after $((SECONDS - start))s. Full log: $log" >&2
    exit 1
  fi
}
