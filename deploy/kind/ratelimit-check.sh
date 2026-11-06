#!/usr/bin/env bash
# Proves the Envoy Gateway global rate limits on kind (WP40, ADR-0033; routes from WP36, ADR-0031): a burst through the
# gateway gets its first 429 at request rpm+1 exactly, however many Envoy replicas share the traffic (one counter per
# client IP in Redis), the percent-encoded `events%3Abatch` shares that counter, an unrelated route is not limited, and
# another client IP (a pod inside the cluster) has its own counter.
#   deploy/kind/ratelimit-check.sh [events|token|all|redis-down]      default: all
# redis-down: stops the ratelimit-redis Deployment, checks that requests pass (failClosed=false: fail open), starts it
# again and checks that the limit is back.
# The rate limit service counts fixed one-minute windows aligned to the clock, so every burst first waits for the next
# window (up to a minute each). Side effect: this client IP is limited on the checked routes until that window ends.
set -euo pipefail
BASE="${HOOPS_BASE_URL:-http://localhost:8090}"
CTX=(--context "kind-${KIND_CLUSTER:-hoops}")
NS="${HOOPS_NAMESPACE:-hoops}"
EG_NS=envoy-gateway-system
WHAT="${1:-all}"
fail=0
ok()  { printf '  ok   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }

fresh_window() { # sleep until the cluster clock (HTTP Date of an unlimited route) is 1 s into the next minute
  local s
  s=$(curl -s -D - -o /dev/null "$BASE/api/game/q/health/ready" | tr -d '\r' \
    | sed -n 's/^[Dd]ate: .* [0-9][0-9]:[0-9][0-9]:\([0-9][0-9]\) GMT$/\1/p')
  s=$((10#${s:-0}))
  echo "  (waiting $((61 - s)) s for a fresh rate-limit window)"
  sleep $((61 - s))
}

FIRST=0 PASSED=0 LIMITED=0
send() { # $1 = number of requests, then curl args; sets FIRST (first 429), PASSED, LIMITED
  local n="$1" i c; shift
  FIRST=0 PASSED=0 LIMITED=0
  for ((i = 1; i <= n; i++)); do
    c=$(curl -s -o /dev/null -w '%{http_code}' "$@")
    if [ "$c" = 429 ]; then LIMITED=$((LIMITED + 1)); [ "$FIRST" -gt 0 ] || FIRST=$i
    else PASSED=$((PASSED + 1)); fi
  done
}

burst() { # $1 = label, $2 = rpm, then curl args; 2*rpm+10 requests from the start of a window: first 429 = rpm+1
  local label="$1" rpm="$2"; shift 2
  local n=$((2 * rpm + 10))
  fresh_window
  send "$n" "$@"
  echo "  $label: $n requests, $PASSED passed to the backend, $LIMITED answered 429 (first 429 at request #$FIRST)"
  [ "$FIRST" = $((rpm + 1)) ] && ok "$label: first 429 at #$((rpm + 1)) (one counter of $rpm/min for all Envoy replicas)" \
    || bad "$label: first 429 at #$FIRST, expected #$((rpm + 1))"
}

replicas_served() { # $1 = text unique to the burst's requests (match id of this run) in the access logs; every replica > 0
  local p c n=0 served=""
  sleep 2   # Envoy flushes its access log about once a second
  for p in $(kubectl "${CTX[@]}" -n "$EG_NS" get pods -l gateway.envoyproxy.io/owning-gateway-name=hoops -o name); do
    c=$(kubectl "${CTX[@]}" -n "$EG_NS" logs "$p" -c envoy --since=10m | grep -c -- "$1" || true)
    served="$served ${p#pod/}=$c"; n=$((n + 1))
    [ "$c" -gt 0 ] || { bad "Envoy replica ${p#pod/} served none of the burst"; return; }
  done
  ok "$n Envoy replica(s) shared the burst (access-log lines per replica):$served"
}

match="00000000-0000-0000-0000-$(printf '%012d' $$)"
EVENTS=(-X POST -H 'Content-Type: application/json' --data '[]' "$BASE/api/game/matches/$match/events:batch")
if [ "$WHAT" = all ] || [ "$WHAT" = events ]; then
  echo "== events:batch (120/min per client IP)"
  burst "POST /api/game/matches/<id>/events:batch" 120 "${EVENTS[@]}"
  replicas_served "$match"
  c=$(curl -s -o /dev/null -w '%{http_code}' --path-as-is -X POST -H 'Content-Type: application/json' --data '[]' \
    "$BASE/api/game/matches/$match/events%3Abatch")
  [ "$c" = 429 ] && ok "events%3Abatch shares the counter (429)" || bad "events%3Abatch -> $c (expected 429: same route, same counter)"
  c=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/api/game/q/health/ready")
  [ "$c" = 200 ] && ok "other game routes not limited (/api/game/q/health/ready -> 200)" || bad "/api/game/q/health/ready -> $c"
  # Another client IP: the web pod (busybox wget) calls the Envoy Service inside the cluster.
  out=$(kubectl "${CTX[@]}" -n "$NS" exec deploy/web -- wget -q -S -O /dev/null --header 'Content-Type: application/json' \
    --post-data '[]' "http://hoops-gateway.$EG_NS.svc/api/game/matches/$match/events:batch" 2>&1 || true)
  code=$(printf '%s\n' "$out" | sed -n 's/^ *HTTP\/[0-9.]* \([0-9]*\).*/\1/p' | tail -1)
  [ -n "$code" ] && [ "$code" != 429 ] && ok "another client IP (web pod) has its own counter ($code)" \
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
if [ "$WHAT" = redis-down ]; then
  echo "== Redis down (failClosed=false: fail open)"
  K=(kubectl "${CTX[@]}" -n "$NS")
  "${K[@]}" scale deployment/ratelimit-redis --replicas=0 >/dev/null
  "${K[@]}" wait --for=delete pod -l app.kubernetes.io/name=ratelimit-redis --timeout=120s >/dev/null 2>&1 || true
  [ -z "$("${K[@]}" get pods -l app.kubernetes.io/name=ratelimit-redis -o name)" ] && ok "ratelimit-redis stopped" || bad "ratelimit-redis still running"
  start=$(date +%s)
  send 130 "${EVENTS[@]}"
  echo "  events:batch with Redis down: 130 requests, $PASSED passed to the backend, $LIMITED answered 429 ($(($(date +%s) - start)) s)"
  [ "$LIMITED" = 0 ] && ok "no 429 while Redis is down (requests pass unlimited)" || bad "$LIMITED requests limited while Redis is down"
  "${K[@]}" scale deployment/ratelimit-redis --replicas=1 >/dev/null
  "${K[@]}" rollout status deployment/ratelimit-redis --timeout=180s >/dev/null && ok "ratelimit-redis started again" || bad "ratelimit-redis did not start"
  burst "POST /api/game/matches/<id>/events:batch after Redis is back" 120 "${EVENTS[@]}"
fi

[ "$fail" = 0 ] && echo "RATE LIMIT CHECK PASSED" || { echo "RATE LIMIT CHECK FAILED"; exit 1; }
