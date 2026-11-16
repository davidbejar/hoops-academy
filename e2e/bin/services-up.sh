#!/usr/bin/env bash
# Builds (once) and starts core/game/athlete fast-jars in the background against the compose stack, then pdf-service
# and finance-service in compose (profiles `pdf` and `finance`, as `just pdf-up` / `just finance-up`): core and game
# call pdf-service on PDF_SERVICE_URL (:8084), nginx routes /api/finance to finance-service (:8085). Env comes from
# the repo .env (never printed). Logs + pids of the jars in e2e/target/services/.
#   e2e/bin/services-up.sh [--no-build]     --no-build: no jar build, and compose builds only a missing image
# E2E_WITHOUT_PDF_FINANCE=1 starts only the three jars (the journey's PDF and finance steps then fail).
# shellcheck disable=SC1091  # env.sh and .env are optional and not followed
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
[ -f scripts/env.sh ] && . scripts/env.sh
set -a; [ -f .env ] && . ./.env; set +a
export KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080/auth}"
export OIDC_AUTH_SERVER_URL="${OIDC_AUTH_SERVER_URL:-http://localhost:8080/auth/realms/academy}"
export PDF_SERVICE_URL="${PDF_SERVICE_URL:-http://localhost:8084}"   # pdf-service (`just pdf-up`), core and game
OUT="$ROOT/e2e/target/services"; mkdir -p "$OUT"
build=1; [ "${1:-}" = "--no-build" ] && build=0

if [ "$build" = 1 ]; then
  ./mvnw -q -pl services/core-service,services/game-service,services/athlete-service -am package -DskipTests
fi

# bash 3.2 (macOS): no assoc arrays
port() { case "$1" in core) echo 8081 ;; game) echo 8082 ;; athlete) echo 8083 ;; pdf) echo 8084 ;; finance) echo 8085 ;; esac; }
for s in core game athlete; do
  if [ -f "$OUT/$s.pid" ] && kill -0 "$(cat "$OUT/$s.pid")" 2>/dev/null; then echo "$s already running"; continue; fi
  nohup java -Dquarkus.http.port="$(port $s)" -jar "services/$s-service/target/quarkus-app/quarkus-run.jar" \
    >"$OUT/$s.log" 2>&1 &
  echo $! >"$OUT/$s.pid"
done

services="core game athlete"
if [ "${E2E_WITHOUT_PDF_FINANCE:-}" != 1 ]; then
  # finance's roles on an existing database (idempotent), then both images (built when missing, always unless
  # --no-build) and the containers; compose waits until they run, the loop below until they answer ready
  infra/compose/finance-db.sh
  flags=(up -d --wait); [ "$build" = 1 ] && flags+=(--build)
  podman compose --env-file .env -f infra/compose/compose.yaml --profile pdf --profile finance "${flags[@]}" \
    pdf-service finance-service
  services="$services pdf finance"
fi

for s in $services; do
  for _ in $(seq 1 90); do
    # ready = HTTP 200 and "status":"UP" on /q/health/ready (Quarkus' smallrye-health, and the Rust and Go services'
    # own; the jars and finance-service migrate before they listen)
    body=$(curl -s -w '\n%{http_code}' "http://localhost:$(port "$s")/q/health/ready" || true)
    if [ "${body##*$'\n'}" = 200 ] && printf '%s' "$body" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"UP"'; then echo "$s ready"; continue 2; fi
    sleep 2
  done
  case "$s" in
    pdf | finance) echo "$s NOT ready after 180 s, see: podman logs hoops-$s-service" >&2 ;;
    *) echo "$s NOT ready after 180 s, see $OUT/$s.log" >&2 ;;
  esac
  exit 1
done
