#!/usr/bin/env bash
# Builds (once) and starts core/game/athlete fast-jars in the background against the compose stack.
# Env comes from the repo .env (never printed). Logs + pids in e2e/target/services/.
#   e2e/bin/services-up.sh [--no-build]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
[ -f scripts/env.sh ] && . scripts/env.sh
set -a; [ -f .env ] && . ./.env; set +a
export KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080/auth}"
export OIDC_AUTH_SERVER_URL="${OIDC_AUTH_SERVER_URL:-http://localhost:8080/auth/realms/academy}"
OUT="$ROOT/e2e/target/services"; mkdir -p "$OUT"

if [ "${1:-}" != "--no-build" ]; then
  ./mvnw -q -pl services/core-service,services/game-service,services/athlete-service -am package -DskipTests
fi

port() { case "$1" in core) echo 8081 ;; game) echo 8082 ;; athlete) echo 8083 ;; esac; }  # bash 3.2 (macOS): no assoc arrays
for s in core game athlete; do
  if [ -f "$OUT/$s.pid" ] && kill -0 "$(cat "$OUT/$s.pid")" 2>/dev/null; then echo "$s already running"; continue; fi
  nohup java -Dquarkus.http.port="$(port $s)" -jar "services/$s-service/target/quarkus-app/quarkus-run.jar" \
    >"$OUT/$s.log" 2>&1 &
  echo $! >"$OUT/$s.pid"
done
for s in core game athlete; do
  for i in $(seq 1 90); do
    # game/athlete have no smallrye-health (404): any HTTP answer means the server is up (Flyway ran before listening)
    c=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$(port $s)/q/health/ready" || true)
    if [ "$c" != 000 ] && [ -n "$c" ]; then echo "$s ready"; continue 2; fi
    sleep 2
  done
  echo "$s NOT ready after 180 s, see $OUT/$s.log" >&2; exit 1
done
