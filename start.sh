#!/usr/bin/env bash
# One-shot local start: Podman machine + compose stack, dev users, backend services, Flutter web app.
#   ./start.sh                 debug run in a Chrome window that Flutter opens (hot reload)
#   ./start.sh --web-server    debug run without a browser: open http://localhost:5173 in any browser yourself
#   ./start.sh --release       release build (tool/build_web.sh, as in production) served on http://localhost:5173;
#                              the most reliable mode for Safari and other non-Chrome browsers, no hot reload
#   ./start.sh --no-build      reuse the existing service jars (faster); combines with any mode above
# Quitting the web app (q or Ctrl+C) stops the backend services; the compose stack keeps running.
# ./stop.sh stops everything, from any terminal and in any state.
set -euo pipefail
cd "$(dirname "$0")"
root="$PWD"

usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; }

mode=chrome
services_flag=""
for arg in "$@"; do
  case "$arg" in
    --no-build) services_flag=--no-build ;;
    --web-server | --release)
      [ "$mode" = chrome ] || { echo "start: --web-server and --release are mutually exclusive" >&2; exit 2; }
      mode="${arg#--}" ;;
    -h | --help) usage; exit 0 ;;
    *) echo "start: unknown option $arg" >&2; usage >&2; exit 2 ;;
  esac
done

[ -f .env ] || { echo "start: .env missing; cp .env.example .env and fill in the change-me-* values" >&2; exit 1; }

# Fail before starting anything when an earlier run (or another server) still holds the web port.
WEB_PORT=5173
if holders="$(lsof -nP -iTCP:"$WEB_PORT" -sTCP:LISTEN 2>/dev/null)"; then
  echo "start: port $WEB_PORT is already in use, probably by an earlier ./start.sh that is still running:" >&2
  echo "$holders" >&2
  echo "start: run ./stop.sh first (or quit that run), then start again" >&2
  exit 1
fi

if ! podman machine inspect --format '{{.State}}' 2>/dev/null | grep -q running; then
  echo "==> starting podman machine"
  podman machine start
fi

echo "==> environment (JDK 21, Podman socket)"
# shellcheck source=scripts/env.sh
source scripts/env.sh

echo "==> compose stack (Postgres, Keycloak, nginx, MailHog)"
just up

echo "==> dev users"
just seed-users

echo "==> backend services on 8081-8083"
# Absolute path: the web app step below runs from apps/web, and the trap fires there.
trap 'echo "==> stopping backend services"; "$root/e2e/bin/services-down.sh"' EXIT
e2e/bin/services-up.sh ${services_flag:+"$services_flag"}

API=--dart-define=HOOPS_API_BASE=http://localhost:8080
cd apps/web
flutter pub get
case "$mode" in
  chrome)
    echo "==> web app (debug) in Chrome on http://localhost:5173"
    flutter run -d chrome --web-port 5173 "$API" ;;
  web-server)
    echo "==> web app (debug): open http://localhost:5173 in any browser"
    flutter run -d web-server --web-port 5173 --web-hostname localhost "$API" ;;
  release)
    echo "==> web app (release build)"
    HOOPS_ALLOW_HTTP_ISSUER=1 tool/build_web.sh "$API"
    echo "==> serving build/web: open http://localhost:5173 in any browser (Ctrl+C to stop)"
    python3 -m http.server 5173 --bind 127.0.0.1 --directory build/web ;;
esac
