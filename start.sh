#!/usr/bin/env bash
# One-shot local start: Podman machine + compose stack, dev users, backend services, Flutter web app.
#   ./start.sh              build services, then run everything
#   ./start.sh --no-build   reuse the existing service jars (faster)
# Quitting the web app (q or Ctrl+C) stops the backend services; the compose stack keeps running (`just down`).
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] || { echo "start: .env missing; cp .env.example .env and fill in the change-me-* values" >&2; exit 1; }

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
trap 'echo "==> stopping backend services"; e2e/bin/services-down.sh' EXIT
e2e/bin/services-up.sh "$@"

echo "==> web app on http://localhost:5173 (API via http://localhost:8080)"
cd apps/web
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=HOOPS_API_BASE=http://localhost:8080
