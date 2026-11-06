#!/usr/bin/env bash
# Smoke test of the kind deployment through the Envoy Gateway (http://localhost:8090 by default).
#   deploy/kind/smoke.sh [service...]        default services: core game athlete
# core is deployed since WP18: with `core` in the list the script also logs the seeded `superadmin` in (PKCE, no browser)
# and checks GET /api/core/me (200, superAdmin=true) and GET /platform/tenants (200).
# Checks: pods Ready, Gateway programmed, OIDC issuer, /internal -> 403, web /, each service's /q/health/ready via the gateway,
# the event broker when deployed (health, bootstrap Job, SASL, ACLs on, topics, users; WP66), and with core and the broker
# the events (WP71: publisher health, a seeded academy drained from core's outbox into both replicas, nothing parked),
# client-credentials tokens from Keycloak, and that each API rejects anonymous calls (401), accepts a token minted for
# it (anything but 401: core's token at game and athlete, game's token at core) and rejects a token that is not for it
# (the service's own token, 401: ADR-0034 audiences). Client secrets are read from .env and sent as form bodies over stdin.
# Load (WP87, troubleshooting symptom D): prints the Podman VM and host load; on a busy machine (deploy/kind/load-guard.sh)
# it warns and waits three times as long for the events (270 s instead of 90 s).
set -euo pipefail
cd "$(dirname "$0")/../.."
BASE="${HOOPS_BASE_URL:-http://localhost:8090}"
SERVICES=("$@"); [ ${#SERVICES[@]} -gt 0 ] || SERVICES=(core game athlete)
CTX=(--context "kind-${KIND_CLUSTER:-hoops}" -n "${HOOPS_NAMESPACE:-hoops}")
fail=0
ok()  { printf '  ok   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }
warn() { printf '  WARN %s\n' "$*"; }
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
# shellcheck source=deploy/kind/load-guard.sh
. deploy/kind/load-guard.sh

echo "== machine load"
PATIENCE=90
if machine_busy; then warn "busy machine: $LOAD_LINE; event checks wait 270 s (troubleshooting symptom D)"; PATIENCE=270
else ok "quiet machine: $LOAD_LINE"; fi

echo "== pods"
kubectl "${CTX[@]}" get pods -o wide
not_ready=$(kubectl "${CTX[@]}" get pods --no-headers | awk '$3!="Completed" && $3!="Succeeded" {split($2,a,"/"); if (a[1]!=a[2]) print $1}')
[ -z "$not_ready" ] && ok "all pods Ready" || bad "not ready: $not_ready"

echo "== gateway"
prog=$(kubectl "${CTX[@]}" get gateway hoops -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null || true)
[ "$prog" = True ] && ok "Gateway hoops programmed" || bad "Gateway hoops Programmed='$prog'"
disco=$(curl -s "$BASE/auth/realms/academy/.well-known/openid-configuration")
issuer=$(echo "$disco" | sed -n 's/.*"issuer":"\([^"]*\)".*/\1/p')
[ "$issuer" = "$BASE/auth/realms/academy" ] && ok "issuer $issuer" || bad "issuer '$issuer'"
# back-channel URLs come from X-Forwarded-Host, which the Keycloak routes set to the public host (a spoofed one is ignored)
tep=$(curl -s -H 'X-Forwarded-Host: evil.example' "$BASE/auth/realms/academy/.well-known/openid-configuration" |
  sed -n 's/.*"token_endpoint":"\([^"]*\)".*/\1/p')
[ "$tep" = "$BASE/auth/realms/academy/protocol/openid-connect/token" ] && ok "token_endpoint $tep (spoofed X-Forwarded-Host ignored)" \
  || bad "token_endpoint '$tep'"
c=$(code "$BASE/internal/x"); [ "$c" = 403 ] && ok "/internal/x -> 403" || bad "/internal/x -> $c"
# Envoy normalises the path (RFC 3986, merged slashes) before routing: encoded or dotted variants hit the deny routes too
for p in //internal/x /%69nternal/x /auth/admin/ /auth/realms/academy/../master/ /auth/realms/%6Daster/; do
  c=$(code --path-as-is "$BASE$p"); [ "$c" = 403 ] && ok "$p -> 403" || bad "$p -> $c"
done
if [[ " ${SERVICES[*]} " == *" core "* ]]; then  # with core absent the path falls through to the SPA (200)
  c=$(code "$BASE/api/core/internal/authz/x/y"); [ "$c" != 200 ] && ok "/api/core/internal/... -> $c (not exposed)" || bad "/api/core/internal exposed"
fi
c=$(code "$BASE/"); [ "$c" = 200 ] && ok "web / -> 200" || bad "web / -> $c"

for s in "${SERVICES[@]}"; do
  body=$(curl -s "$BASE/api/$s/q/health/ready")
  if echo "$body" | grep -q '"status": *"UP"'; then ok "/api/$s/q/health/ready UP"
  elif echo "$body" | grep -q '"instance": *"/q/health/ready"'; then
    warn "/api/$s/q/health/ready routed+rewritten to the service, which has no quarkus-smallrye-health (404)"
  else bad "/api/$s/q/health/ready: $body"; fi
  c=$(code "$BASE/api/$s/q/metrics"); [ "$c" != 200 ] && ok "/api/$s/q/metrics not exposed ($c)" || bad "/api/$s/q/metrics exposed"
done

if [[ " ${SERVICES[*]} " == *" game "* ]]; then
  # The rate-limited regex route forwards the colon path byte-for-byte (anonymous -> the service's 401); the
  # percent-encoded form also reaches the service unchanged (its Problem echoes the path; Quarkus answers 404 for it).
  m=00000000-0000-0000-0000-000000000001
  body=$(curl -s -X POST -H 'Content-Type: application/json' --data '[]' "$BASE/api/game/matches/$m/events:batch")
  echo "$body" | grep -q '"status":401' && echo "$body" | grep -q "events:batch" && ok "events:batch reaches game-service unchanged (401)" \
    || bad "events:batch: $body"
  body=$(curl -s --path-as-is -X POST -H 'Content-Type: application/json' --data '[]' "$BASE/api/game/matches/$m/events%3Abatch")
  echo "$body" | grep -q 'events%3Abatch' && ok "events%3Abatch forwarded undecoded" || bad "events%3Abatch: $body"
fi

# Event broker (WP66, ADR-0036; events.enabled in values-kind.yaml): health, bootstrap Job, SASL required, ACLs enforced,
# the seven topics and the three service users. rpk runs inside redpanda-0; the superuser password stays in that
# container's environment (single quotes: expanded there, never on this host's command line).
if kubectl "${CTX[@]}" get statefulset redpanda >/dev/null 2>&1; then
  echo "== event broker"
  rp() { kubectl "${CTX[@]}" exec redpanda-0 -c redpanda -- bash -c "$1" 2>&1; }
  # shellcheck disable=SC2016 # expanded inside the container
  as_admin='RPK_USER=admin RPK_PASS="$RP_ADMIN_PASSWORD" RPK_SASL_MECHANISM=SCRAM-SHA-256'
  rp 'rpk cluster health' | grep 'Healthy: *true' >/dev/null && ok "rpk cluster health: healthy" || bad "rpk cluster health: $(rp 'rpk cluster health' | tr '\n' ' ')"
  st=$(kubectl "${CTX[@]}" get job redpanda-bootstrap -o jsonpath='{.status.succeeded}' 2>/dev/null || true)
  [ "$st" = 1 ] && ok "Job redpanda-bootstrap succeeded" || bad "Job redpanda-bootstrap succeeded='$st'"
  anon=$(rp 'rpk topic list' || true)   # fails on purpose; pipefail would hide the match
  echo "$anon" | grep -q 'SASL is required' && ok "Kafka without a login refused (SASL required)" || bad "Kafka without a login: $anon"
  rp "$as_admin rpk cluster config get kafka_enable_authorization" | grep -x true >/dev/null && ok "ACLs enforced (kafka_enable_authorization)" || bad "kafka_enable_authorization not true"
  topics=$(rp "$as_admin rpk topic list" | awk 'NR > 1 && $2 == 1 {print $1}' | sort | tr '\n' ' ')
  [ "$topics" = "core.guardian-link core.person core.player core.team core.team-player core.team-staff core.tenant " ] \
    && ok "7 topics, 1 partition each: $topics" || bad "topics: '$topics'"
  users=$(rp "$as_admin rpk security user list" | awk 'NR > 1 {print $1}' | sort | tr '\n' ' ')
  [ "$users" = "admin athlete-service core-service game-service " ] && ok "SCRAM users: $users" || bad "users: '$users'"
fi

echo "== tokens (client credentials, realm role 'service'; audiences per ADR-0034)"
# A secured GET endpoint per service (anonymous -> 401; a token for it -> anything else, e.g. 400/404 without tenant).
api_path() { case "$1" in core) echo /api/core/me ;; game) echo /api/game/matches ;; athlete) echo /api/athlete/training-schedules ;; esac; }
# A service's client-credentials token is for the services it calls, never for itself: core calls game and athlete,
# game and athlete call core.
caller_of() { case "$1" in core) echo game ;; game|athlete) echo core ;; esac; }
set -a; . ./.env; set +a
service_token() {  # $1 = core|game|athlete -> access token of client <$1>-service (empty on failure)
  local var
  var="$(echo "$1" | tr '[:lower:]' '[:upper:]')_SERVICE_CLIENT_SECRET"
  printf 'grant_type=client_credentials&client_id=%s-service&client_secret=%s' "$1" "${!var}" |
    curl -s -X POST "$BASE/auth/realms/academy/protocol/openid-connect/token" \
      -H 'Content-Type: application/x-www-form-urlencoded' --data-binary @- | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'
}
for s in "${SERVICES[@]}"; do
  caller=$(caller_of "$s")
  token=$(service_token "$caller")
  own=$(service_token "$s")
  [ -n "$token" ] && [ -n "$own" ] || { bad "$s: no token from $caller-service or $s-service"; continue; }
  iss=$(echo "$token" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | sed -n 's/.*"iss":"\([^"]*\)".*/\1/p' || true)
  [ "$iss" = "$BASE/auth/realms/academy" ] && ok "$caller-service token iss $iss" || bad "$caller-service token iss '$iss'"
  p=$(api_path "$s")
  anon=$(code "$BASE$p")
  authd=$(code -H "Authorization: Bearer $token" "$BASE$p")
  wrong=$(code -H "Authorization: Bearer $own" "$BASE$p")
  [ "$anon" = 401 ] && [ "$authd" != 401 ] && [ "$wrong" = 401 ] \
    && ok "$p anonymous 401, $caller-service token $authd, own $s-service token 401 (not its audience)" \
    || bad "$p anonymous $anon, $caller-service token $authd, own $s-service token $wrong (want 401 / not 401 / 401)"
done

if [[ " ${SERVICES[*]} " == *" core "* ]]; then
  echo "== seeded user through core (/api/core/me, /platform)"
  # Browser-less authorization-code + PKCE login of client `web` (as apps/web/tool/keycloak_login_check.sh).
  user_token() {  # $1 = username; password = DEV_USER_PASSWORD from .env (never printed)
    local iss="$BASE/auth/realms/academy" redir="$BASE/redirect.html" jar v c form action loc code
    jar=$(mktemp); trap 'rm -f "$jar"' RETURN
    b64() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
    v=$(openssl rand 48 | b64); c=$(printf '%s' "$v" | openssl dgst -sha256 -binary | b64)
    form=$(curl -fsS -c "$jar" -b "$jar" -G "$iss/protocol/openid-connect/auth" --data-urlencode client_id=web \
      --data-urlencode response_type=code --data-urlencode "redirect_uri=$redir" --data-urlencode "scope=openid profile email" \
      --data-urlencode state=smoke --data-urlencode "code_challenge=$c" --data-urlencode code_challenge_method=S256) || return 1
    action=$(printf '%s' "$form" | tr '\n' ' ' | sed -n 's/.*id="kc-form-login"[^>]*action="\([^"]*\)".*/\1/p' | sed 's/&amp;/\&/g')
    [ -n "$action" ] || return 1
    loc=$(printf 'username=%s&password=%s' "$1" "$DEV_USER_PASSWORD" |
      curl -sS -o /dev/null -D - -c "$jar" -b "$jar" "$action" --data-binary @- | tr -d '\r' | sed -n 's/^[Ll]ocation: //p')
    code=$(printf '%s' "$loc" | sed -n 's/.*[?&]code=\([^&#]*\).*/\1/p'); [ -n "$code" ] || return 1
    curl -fsS "$iss/protocol/openid-connect/token" -d grant_type=authorization_code -d client_id=web \
      --data-urlencode "code=$code" --data-urlencode "redirect_uri=$redir" --data-urlencode "code_verifier=$v" |
      sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'
  }
  utok=$(user_token superadmin@hoops-academy.com || true)
  if [ -z "$utok" ]; then bad "superadmin PKCE login failed (run deploy/kind/seed-users.sh first?)"
  else
    me=$(curl -s -H "Authorization: Bearer $utok" "$BASE/api/core/me")
    echo "$me" | grep -q '"superAdmin":true' && ok "/api/core/me -> superadmin" || bad "/api/core/me: $me"
    c=$(code -H "Authorization: Bearer $utok" "$BASE/platform/tenants")
    [ "$c" = 200 ] && ok "/platform/tenants -> 200" || bad "/platform/tenants -> $c"
    c=$(code -H "Authorization: Bearer $utok" "$BASE/internal/usage/00000000-0000-0000-0000-000000000000")
    [ "$c" = 403 ] && ok "/internal with a user token -> 403" || bad "/internal with a user token -> $c"
  fi
fi

# Events (WP71, ADR-0036/0037): core's outbox publisher and the game/athlete roster replicas on the broker. A fresh academy
# whose first admin is the seeded admin1 (an existing login is linked, no temporary password) gets a season, a team and a
# player; then core's outbox drains, both consumer groups catch up with nothing parked, and game and athlete answer for the
# new academy (athlete from its replica when ATHLETE_ROSTER_SOURCE=replica). Metrics are read inside the pods (not routed).
if [[ " ${SERVICES[*]} " == *" core "* ]] && [ -n "${utok:-}" ] && kubectl "${CTX[@]}" get statefulset redpanda >/dev/null 2>&1; then
  echo "== events (WP71: outbox publisher, roster replicas)"
  port_of() { case "$1" in core-service) echo 8081 ;; game-service) echo 8082 ;; athlete-service) echo 8083 ;; esac; }
  metrics() { kubectl "${CTX[@]}" exec "deploy/$1" -c "$1" -- curl -s "localhost:$(port_of "$1")/q/metrics" 2>/dev/null || true; }
  # sum of the samples of metric $1, 0 when absent (field 2: the value; an OpenMetrics exemplar may follow it)
  total() { { grep "^$1" || true; } | awk '{s += $2} END {printf "%d", s}'; }
  group_lag() { rp "$as_admin rpk group describe $1" | awk '$1 == "TOTAL-LAG" {print $2}'; }
  eventually() { for _ in $(seq "$PATIENCE"); do "$@" && return 0; sleep 1; done; return 1; }
  pub=$(curl -s "$BASE/api/core/q/health/ready" | jq -r '.checks[] | select(.name == "outbox-publisher") | "\(.status) \(.data.state)"')
  [ "$pub" = "UP OK" ] && ok "core readiness outbox-publisher: $pub" || bad "core readiness outbox-publisher: '$pub' (want UP OK)"
  [ "$(metrics core-service | total hoops_outbox_broker_available)" = 1 ] && ok "core: hoops_outbox_broker_available 1" \
    || bad "core: broker not available to the publisher"
  for s in core:producer game:consumer athlete:consumer; do
    n=$(metrics "${s%:*}-service" | total "kafka_${s#*:}_successful_authentication_total")
    [ "$n" -ge 1 ] && ok "${s%:*}-service: Kafka ${s#*:} logged in as ${s%:*}-service (SCRAM, $n successful authentications)" \
      || bad "${s%:*}-service: no successful Kafka authentication"
  done
  source_of() { kubectl "${CTX[@]}" get configmap "$1-service-env" -o jsonpath="{.data.$(echo "$1" | tr '[:lower:]' '[:upper:]')_ROSTER_SOURCE}"; }
  echo "  roster source: game $(source_of game), athlete $(source_of athlete)"
  before_p=$(metrics core-service | total hoops_outbox_published_total)
  before_g=$(metrics game-service | total 'hoops_roster_replica_events_total{.*outcome="applied"')
  before_a=$(metrics athlete-service | total 'hoops_roster_replica_events_total{.*outcome="applied"')
  # seed: academy (tenant + first admin person) -> season -> team -> player on the team (person, player, team-player)
  slug="smoke-$(date +%s)"; day() { date -u -v"$1"d +%F 2>/dev/null || date -u -d "$1 days" +%F; }
  tenant=$(jq -n --arg s "$slug" '{slug: $s, name: ("Smoke " + $s), timezone: "Europe/Madrid", defaultLocale: "en",
      firstAdmin: {email: "admin1@hoops-academy.com", givenName: "Alex", familyName: "Admin"}}' |
    curl -s -X POST "$BASE/platform/tenants" -H "Authorization: Bearer $utok" -H 'Content-Type: application/json' --data-binary @- |
    jq -r 'select(.temporaryPassword == null) | .id // empty')
  atok=$([ -n "$tenant" ] && user_token admin1@hoops-academy.com || true)
  api() { # METHOD path [json] -> body, as admin1 in the new academy
    local data=(); [ $# -lt 3 ] || data=(--data-binary "$3")
    curl -s -X "$1" "$BASE$2" -H "Authorization: Bearer $atok" -H "X-Tenant-Id: $tenant" -H 'Content-Type: application/json' \
      ${data[@]+"${data[@]}"}; }
  if [ -z "$tenant" ] || [ -z "$atok" ]; then bad "seed: academy $slug with admin1 as first admin (tenant '$tenant')"
  else
    cat=$(api GET /api/core/age-categories | jq -c '.[] | select(.code == "U14") | {id, maxAge}')
    season=$(api POST /api/core/seasons "$(jq -n --arg a "$(day -100)" --arg b "$(day +250)" --argjson y "$(date -u +%Y)" \
      '{name: "Smoke", startsOn: $a, endsOn: $b, referenceYear: $y}')" | jq -r '.id // empty')
    team=$(api POST /api/core/teams "$(jq -n --arg s "$season" --arg c "$(echo "$cat" | jq -r .id)" \
      '{seasonId: $s, name: "Smoke U14", ageCategoryId: $c, genderPolicy: "MIXED"}')" | jq -r '.id // empty')
    player=$(api POST /api/core/players "$(jq -n --arg t "$team" --arg b "$(( $(date -u +%Y) - $(echo "$cat" | jq -r .maxAge) + 1 ))-03-15" \
      '{givenName: "Sam", familyName: "Smoke", birthDate: $b, gender: "FEMALE", teamId: $t, jerseyNumber: "9"}')" | jq -r '.player.id // empty')
    [ -n "$season" ] && [ -n "$team" ] && [ -n "$player" ] && ok "seed: academy $slug (admin1), season, team, player $player" \
      || bad "seed: season '$season' team '$team' player '$player'"
    # the seed writes at least 5 events (tenant, admin person, team, player person + player, assignment): all published
    published() { local m; m=$(metrics core-service); [ "$(echo "$m" | total hoops_outbox_pending)" = 0 ] \
      && [ "$(echo "$m" | total hoops_outbox_published_total)" -ge $((before_p + 5)) ]; }
    caught_up() { [ "$(group_lag "$1-service.roster")" = 0 ]; }
    eventually published && ok "core: hoops_outbox_pending 0, published $before_p -> $(metrics core-service | total hoops_outbox_published_total)" \
      || bad "core: pending $(metrics core-service | total hoops_outbox_pending), published $before_p -> $(metrics core-service | total hoops_outbox_published_total) (never sent: events.md 'Kubernetes')"
    for s in game athlete; do
      eventually caught_up "$s" || bad "$s-service.roster: group lag $(group_lag "$s-service.roster")"
      m=$(metrics "$s-service")
      applied=$(echo "$m" | total 'hoops_roster_replica_events_total{.*outcome="applied"')
      before=$([ "$s" = game ] && echo "$before_g" || echo "$before_a")
      parked=$(echo "$m" | total hoops_roster_replica_parked_total)
      lag=$(echo "$m" | { grep '^hoops_roster_replica_lag_seconds' || true; } | LC_ALL=C awk '$2 > max {max = $2} END {printf "%.2f", max}')
      [ "$(group_lag "$s-service.roster")" = 0 ] && [ "$applied" -ge $((before + 5)) ] && [ "$parked" = 0 ] \
        && ok "$s replica: group lag 0, applied $before -> $applied (+$((applied - before))), parked 0, max event lag ${lag} s" \
        || bad "$s replica: lag $(group_lag "$s-service.roster"), applied $before -> $applied, parked $parked"
    done
    c=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $atok" -H "X-Tenant-Id: $tenant" "$BASE/api/game/matches?teamId=$team")
    [ "$c" = 200 ] && ok "game: admin1 lists the new team's matches (200, roster source $(source_of game))" || bad "game: matches of the new team -> $c"
    av=$(api GET "/api/athlete/players/$player/availability" | jq -r '.available // empty')
    [ "$av" = true ] && ok "athlete: the new player's availability (available=true, roster source $(source_of athlete))" \
      || bad "athlete: availability of the new player: '$av'"
  fi
fi

[ "$fail" = 0 ] && echo "SMOKE PASSED" || { echo "SMOKE FAILED"; exit 1; }
