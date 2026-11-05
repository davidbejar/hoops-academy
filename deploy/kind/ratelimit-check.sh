#!/usr/bin/env bash
# Proves the Envoy Gateway local rate limits on kind (WP36, ADR-0031): a burst through the gateway gets 429 once the
# client's bucket is empty, the percent-encoded `events%3Abatch` shares that bucket, an unrelated route is not limited,
# and another client IP (a pod inside the cluster) still has its own full bucket.
#   deploy/kind/ratelimit-check.sh [events|token|all]      default: all
# Side effect: this client IP is limited on the checked routes until the bucket refills (at most one minute). Run it
# after the smoke test / e2e journey, or wait a minute before them.
set -euo pipefail
BASE="${HOOPS_BASE_URL:-http://localhost:8090}"
CTX=(--context "kind-${KIND_CLUSTER:-hoops}")
NS="${HOOPS_NAMESPACE:-hoops}"
WHAT="${1:-all}"
fail=0
ok()  { printf '  ok   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }

burst() { # $1 = label, $2 = rpm, then curl args; sends 2*rpm+10 requests (one bucket refill cannot hide the limit)
  local label="$1" rpm="$2"; shift 2
  local n=$((2 * rpm + 10)) i c first=0 limited=0 passed=0
  for ((i = 1; i <= n; i++)); do
    c=$(curl -s -o /dev/null -w '%{http_code}' "$@")
    if [ "$c" = 429 ]; then limited=$((limited + 1)); [ "$first" -gt 0 ] || first=$i
    else passed=$((passed + 1)); fi
  done
  echo "  $label: $n requests, $passed passed to the backend, $limited answered 429 (first 429 at request #$first)"
  [ "$limited" -gt 0 ] && [ "$first" -gt 1 ] && ok "$label limited after a burst (bucket $rpm/min)" || bad "$label not rate-limited"
}

match="00000000-0000-0000-0000-$(printf '%012d' $$)"
if [ "$WHAT" = all ] || [ "$WHAT" = events ]; then
  echo "== events:batch (120/min per client IP)"
  burst "POST /api/game/matches/<id>/events:batch" 120 -X POST -H 'Content-Type: application/json' --data '[]' \
    "$BASE/api/game/matches/$match/events:batch"
  c=$(curl -s -o /dev/null -w '%{http_code}' --path-as-is -X POST -H 'Content-Type: application/json' --data '[]' \
    "$BASE/api/game/matches/$match/events%3Abatch")
  [ "$c" = 429 ] && ok "events%3Abatch shares the bucket (429)" || bad "events%3Abatch -> $c (expected 429: same route, same bucket)"
  c=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/api/game/q/health/ready")
  [ "$c" = 200 ] && ok "other game routes not limited (/api/game/q/health/ready -> 200)" || bad "/api/game/q/health/ready -> $c"
  # Another client IP: the web pod (busybox wget) calls the Envoy Service inside the cluster.
  out=$(kubectl "${CTX[@]}" -n "$NS" exec deploy/web -- wget -q -S -O /dev/null --header 'Content-Type: application/json' \
    --post-data '[]' "http://hoops-gateway.envoy-gateway-system.svc/api/game/matches/$match/events:batch" 2>&1 || true)
  code=$(printf '%s\n' "$out" | sed -n 's/^ *HTTP\/[0-9.]* \([0-9]*\).*/\1/p' | tail -1)
  [ -n "$code" ] && [ "$code" != 429 ] && ok "another client IP (web pod) has its own bucket ($code)" \
    || bad "another client IP got '${code:-no answer}': $out"
fi
if [ "$WHAT" = all ] || [ "$WHAT" = token ]; then
  echo "== token endpoint (60/min per client IP)"
  burst "POST /auth/realms/academy/protocol/openid-connect/token" 60 -X POST \
    -d 'grant_type=client_credentials&client_id=ratelimit-check&client_secret=wrong' \
    "$BASE/auth/realms/academy/protocol/openid-connect/token"
  c=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/auth/realms/academy/.well-known/openid-configuration")
  [ "$c" = 200 ] && ok "rest of /auth not limited (discovery -> 200)" || bad "discovery -> $c"
fi

[ "$fail" = 0 ] && echo "RATE LIMIT CHECK PASSED" || { echo "RATE LIMIT CHECK FAILED"; exit 1; }
