#!/usr/bin/env bash
# Stops everything ./start.sh started, whatever state it is in (still running in another terminal, or already
# interrupted with Ctrl+C): the Flutter web app and its Chrome window, the backend services, the compose stack.
# Safe to run repeatedly. The Podman machine itself is left running (`podman machine stop` if wanted).
set -euo pipefail
cd "$(dirname "$0")"

WEB_PORT=5173
SERVICE_PORTS="8081 8082 8083"

# Sends TERM, waits up to 10 s, then KILL.
stop_pids() {
  local what="$1"; shift
  [ "$#" -gt 0 ] || return 0
  echo "stopping $what (pid $*)"
  kill "$@" 2>/dev/null || true
  local _ p alive
  for _ in $(seq 1 20); do
    alive=""
    for p in "$@"; do kill -0 "$p" 2>/dev/null && alive="$alive $p"; done
    [ -z "$alive" ] && return 0
    sleep 0.5
  done
  # shellcheck disable=SC2086
  kill -9 $alive 2>/dev/null || true
}

# Listeners on a port whose command line matches a pattern (so unrelated programs on the port are left alone).
listeners() { # port pattern
  local pid
  for pid in $(lsof -nP -t -iTCP:"$1" -sTCP:LISTEN 2>/dev/null || true); do
    ps -p "$pid" -o command= 2>/dev/null | grep -Eq "$2" && echo "$pid"
  done
  return 0
}

stop_web() {
  local pids
  # flutter_tools serves the app itself (default and --web-server modes), python's http.server serves the
  # release build (--release); also catch a `flutter run` that is still starting (not listening yet).
  pids=$( { listeners "$WEB_PORT" 'dart|flutter|http\.server'; pgrep -f "flutter_tools.*run.*--web-port[= ]$WEB_PORT" || true; } | sort -u)
  # shellcheck disable=SC2086
  stop_pids "web app" $pids
  # The Chrome that flutter launched uses a throw-away profile; your normal Chrome is not touched.
  pids=$(pgrep -f 'flutter_tools_chrome_device' || true)
  # shellcheck disable=SC2086
  stop_pids "flutter's Chrome window" $pids
}

stop_services() {
  e2e/bin/services-down.sh
  # Leftovers: `quarkus:dev` runs or service jars whose pid file is gone.
  local port pids
  for port in $SERVICE_PORTS; do
    pids=$(listeners "$port" 'java')
    # shellcheck disable=SC2086
    stop_pids "java on :$port" $pids
  done
}

stop_stack() {
  if ! podman machine inspect --format '{{.State}}' 2>/dev/null | grep -q running; then
    echo "podman machine not running: compose stack already down"
    return 0
  fi
  [ -f .env ] || { echo "stop: .env missing, cannot run just down" >&2; return 1; }
  just down
}

main() {
  echo "==> web app";          stop_web
  echo "==> backend services"; stop_services
  echo "==> compose stack";    stop_stack
  echo "==> all stopped"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
