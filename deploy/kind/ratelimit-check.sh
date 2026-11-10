#!/usr/bin/env bash
# Proves the Envoy Gateway global rate limits on kind (WP40/WP46, ADR-0033; routes from WP36, ADR-0031): a burst through
# the gateway paced below the per-second cap gets its first 429 at request rpm+1 exactly, however many Envoy replicas
# share the traffic (one counter per client IP in Redis); a tight burst (all requests at once) is cut by the per-second
# rule; the percent-encoded `events%3Abatch` shares the counter, an unrelated route is not limited, and another client
# IP (a pod inside the cluster) has its own counter. The ACL check proves the Redis login of the rate limit service.
#   deploy/kind/ratelimit-check.sh [events|token|exports|acl|all|redis-down]   default: all (events, token, exports, acl)
# exports (WP100): the roster CSV export (10/min and 2/s per client IP, WP96), anonymous (401 below the limit); its %3A form
# shares the counter; the academy audit export has a counter of its own.
# acl: from a pod that the Redis NetworkPolicy admits, the rate limit user may only PING / INCRBY / EXPIRE its own keys
# (EVAL, GET, FLUSHALL, CONFIG, ... refused), and neither an anonymous client nor the `default` user gets in.
# redis-down: stops the ratelimit-redis Deployment, checks that requests pass (failClosed=false: fail open), starts it
# again and checks that the limit is back.
# Load guard (WP87, troubleshooting symptom D): the bursts need a quiet machine. Above HOOPS_MAX_LOAD_PER_CPU (default 2)
# per CPU of the Podman VM or the host (deploy/kind/load-guard.sh) they are skipped and the script ends INCOMPLETE (exit 3);
# HOOPS_LOAD_WAIT=<seconds> waits for a quiet machine first, HOOPS_LOAD_GUARD=off runs them anyway. The ACL check always runs.
# The rate limit service counts fixed windows aligned to the clock, so every burst first waits for the next minute
# (up to a minute each). Side effect: this client IP is limited on the checked routes until that window ends.
set -euo pipefail
export LC_ALL=C   # decimal point for awk/sleep (pacing) whatever the user's locale
BASE="${HOOPS_BASE_URL:-http://localhost:8090}"
CTX=(--context "kind-${KIND_CLUSTER:-hoops}")
NS="${HOOPS_NAMESPACE:-hoops}"
EG_NS=envoy-gateway-system
WHAT="${1:-all}"
fail=0
ok()  { printf '  ok   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }
# shellcheck source=deploy/kind/load-guard.sh
. "$(dirname "$0")/load-guard.sh"

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
    [ -z "${PAUSE:-}" ] || sleep "$PAUSE"
  done
}

tight_burst() { # $1 = label, $2 = rpm, $3 = rps, then curl args (URL last); max(40, 3*rps) requests at once (curl
  # --parallel), fewer than rpm, at the start of a fresh minute and just after a second boundary: only the per-second
  # rule can answer 429. Up to rps pass per one-second window (2 x rps if the burst straddles a second boundary).
  local label="$1" rpm="$2" rps="$3"; shift 3
  local n=$((3 * rps > 40 ? 3 * rps : 40)) url="${*: -1}" i codes
  local args=("${@:1:$#-1}")
  [ "$n" -lt "$rpm" ] || { bad "$label: tight burst of $n is not below rpm $rpm"; return; }
  for ((i = 1; i <= n; i++)); do args+=(-o /dev/null "$url"); done
  fresh_window
  perl -MTime::HiRes=time,sleep -e 'sleep(1.05 - (time - int(time)))'   # just after a second boundary
  codes=$(curl -s --parallel --parallel-immediate --parallel-max "$n" -w '%{http_code}\n' "${args[@]}")
  PASSED=$(printf '%s\n' "$codes" | grep -cv '^429$' || true)
  LIMITED=$(printf '%s\n' "$codes" | grep -c '^429$' || true)
  echo "  $label: $n requests at once, $PASSED passed to the backend, $LIMITED answered 429"
  [ "$LIMITED" -gt 0 ] && [ "$PASSED" -ge 1 ] && [ "$PASSED" -le $((2 * rps)) ] \
    && ok "$label: tight burst cut by the per-second rule ($PASSED <= $rps/s passed, below the $rpm/min limit)" \
    || bad "$label: tight burst: $PASSED passed, $LIMITED x 429 (expected 1..$((2 * rps)) passed and some 429)"
}

acl_check() { # Redis ACL of ratelimit-redis, probed from a pod the NetworkPolicy admits (envoy-ratelimit label)
  local image host out
  image=$(kubectl "${CTX[@]}" -n "$NS" get deploy/ratelimit-redis -o jsonpath='{.spec.template.spec.containers[0].image}')
  host="ratelimit-redis.$NS.svc.cluster.local"
  # The login comes from the Secret the rate limit pods use (REDIS_AUTH=<user>:<password>), never from this script.
  # shellcheck disable=SC2016 # expanded inside the probe pod
  local script='set -f; u=${RL_AUTH%%:*}; export REDISCLI_AUTH=${RL_AUTH#*:}; r() { redis-cli --no-auth-warning -h "$H" "$@" 2>&1 | head -1; }
k="$KEYS_PREFIX"acl-check
echo "anonymous PING: $(env -u REDISCLI_AUTH redis-cli -h "$H" PING 2>&1 | head -1)"
echo "default + rate limit password: $(r --user default PING)"
echo "user: $u"
for c in "PING" "INCRBY $k 1" "EXPIRE $k 5" "INCRBY other-key 1" "GET $k" "EVAL return 1 0" "FLUSHALL" "KEYS *" \
         "SET $k 1" "CONFIG GET maxmemory" "ACL LIST" "INFO" "SCRIPT FLUSH" "MULTI"; do
  echo "$c -> $(r --user "$u" $c)"
done'
  local overrides
  overrides=$(cat <<JSON
{"apiVersion": "v1", "metadata": {"labels": {"app.kubernetes.io/name": "envoy-ratelimit"}},
 "spec": {"automountServiceAccountToken": false, "containers": [{"name": "acl-check", "image": "$image",
   "command": ["sh", "-c", $(printf '%s' "$script" | python3 -I -c 'import json,sys; print(json.dumps(sys.stdin.read()))')],
   "env": [{"name": "H", "value": "$host"},
           {"name": "KEYS_PREFIX", "value": "$NS/hoops/"},
           {"name": "RL_AUTH", "valueFrom": {"secretKeyRef": {"name": "envoy-ratelimit-redis-auth", "key": "auth"}}}],
   "securityContext": {"runAsNonRoot": true, "runAsUser": 999, "allowPrivilegeEscalation": false,
                       "capabilities": {"drop": ["ALL"]}, "readOnlyRootFilesystem": true}}]}}
JSON
)
  # Not `run -i --rm`: attaching races with the short script and loses its first lines. Run, wait, read the log, delete.
  local pod="acl-check-$$" E=(kubectl "${CTX[@]}" -n "$EG_NS")
  "${E[@]}" run "$pod" --restart=Never --image="$image" --overrides="$overrides" >/dev/null
  "${E[@]}" wait --for=jsonpath='{.status.phase}'=Succeeded "pod/$pod" --timeout=120s >/dev/null 2>&1 || true
  out=$("${E[@]}" logs "$pod" 2>&1 || true)
  "${E[@]}" delete pod "$pod" --wait=false >/dev/null 2>&1 || true
  printf '%s\n' "$out" | sed 's/^/  | /'
  expect() { printf '%s\n' "$out" | grep -q -- "$1" && ok "$2" || bad "$2 (expected: $1)"; }
  expect '^anonymous PING: NOAUTH' "anonymous client refused (NOAUTH)"
  expect '^default + rate limit password: .*WRONGPASS' "default user cannot authenticate (off)"
  expect '^PING -> PONG$' "rate limit user: PING"
  expect '^INCRBY .*acl-check 1 -> [0-9][0-9]*$' "rate limit user: INCRBY on its keys"
  expect '^EXPIRE .*acl-check 5 -> 1$' "rate limit user: EXPIRE on its keys"
  expect '^INCRBY other-key 1 -> NOPERM' "rate limit user: other keys refused"
  local c
  for c in GET EVAL FLUSHALL KEYS SET ACL INFO SCRIPT MULTI; do
    expect "^$c .*-> NOPERM" "rate limit user: $c refused (NOPERM)"
  done
  expect '^CONFIG GET maxmemory -> ERR unknown command' "CONFIG does not exist (renamed away)"
}

burst() { # $1 = label, $2 = rpm, $3 = rps, then curl args; 2*rpm+10 requests from the start of a window, at most rps/2
  # per second (so the per-second rule never fires): first 429 = rpm+1
  local label="$1" rpm="$2" rps="$3"; shift 3
  local n=$((2 * rpm + 10)) pause start
  pause=$(awk -v r="$rps" 'BEGIN { printf "%.3f", 2 / r }')
  fresh_window
  start=$(date +%s)
  PAUSE="$pause" send "$n" "$@"
  echo "  $label: $n requests in $(($(date +%s) - start)) s, $PASSED passed to the backend, $LIMITED answered 429 (first 429 at request #$FIRST)"
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

echo "== machine load"
TIMING=1 skipped=""
if wait_for_quiet_machine; then ok "quiet machine: $LOAD_LINE"
elif [ "${HOOPS_LOAD_GUARD:-on}" = off ]; then
  echo "  WARN busy machine: $LOAD_LINE; timing checks run anyway (HOOPS_LOAD_GUARD=off): expect troubleshooting symptom D"
else
  echo "  WARN busy machine: $LOAD_LINE; the bursts are skipped (re-run when it is quiet, HOOPS_LOAD_WAIT=<s> to wait)"
  TIMING=0
fi
want() { [ "$WHAT" = "$1" ] || { [ "$WHAT" = all ] && [ "$1" != redis-down ]; }; }
timed() { [ "$TIMING" = 1 ] || { skipped="$skipped $1"; return 1; }; }   # $1 = mode; records it when skipped

match="00000000-0000-0000-0000-$(printf '%012d' $$)"
EVENTS=(-X POST -H 'Content-Type: application/json' --data '[]' "$BASE/api/game/matches/$match/events:batch")
if want events && timed events; then
  echo "== events:batch (120/min and 20/s per client IP)"
  burst "POST /api/game/matches/<id>/events:batch" 120 20 "${EVENTS[@]}"
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
  tight_burst "POST /api/game/matches/<id>/events:batch" 120 20 "${EVENTS[@]}"
fi
if want token && timed token; then
  echo "== token endpoint (60/min and 10/s per client IP)"
  TOKEN=(-X POST -d 'grant_type=client_credentials&client_id=ratelimit-check&client_secret=wrong'
         "$BASE/auth/realms/academy/protocol/openid-connect/token")
  burst "POST /auth/realms/academy/protocol/openid-connect/token" 60 10 "${TOKEN[@]}"
  c=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/auth/realms/academy/.well-known/openid-configuration")
  [ "$c" = 200 ] && ok "rest of /auth not limited (discovery -> 200)" || bad "discovery -> $c"
  tight_burst "POST /auth/realms/academy/protocol/openid-connect/token" 60 10 "${TOKEN[@]}"
fi
if want exports && timed exports; then
  echo "== CSV exports (10/min and 2/s per client IP)"
  team="00000000-0000-0000-0000-$(printf '%012d' $$)"
  burst "GET /api/core/teams/<id>/roster:export" 10 2 "$BASE/api/core/teams/$team/roster:export"
  c=$(curl -s -o /dev/null -w '%{http_code}' --path-as-is "$BASE/api/core/teams/$team/roster%3Aexport")
  [ "$c" = 429 ] && ok "roster%3Aexport shares the counter (429)" || bad "roster%3Aexport -> $c (expected 429: same route, same counter)"
  c=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/api/core/audit-events:export")
  [ "$c" = 401 ] && ok "audit-events:export has its own counter (401 anonymous, not 429)" || bad "audit-events:export -> $c (expected 401)"
fi
if want acl; then
  echo "== Redis ACL (user of the rate limit service)"
  acl_check
fi
if want redis-down && timed redis-down; then
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
  burst "POST /api/game/matches/<id>/events:batch after Redis is back" 120 20 "${EVENTS[@]}"
fi

[ "$fail" = 0 ] || { echo "RATE LIMIT CHECK FAILED"; exit 1; }
[ -z "$skipped" ] || { echo "RATE LIMIT CHECK INCOMPLETE: skipped on a busy machine:$skipped"; exit 3; }
echo "RATE LIMIT CHECK PASSED"
