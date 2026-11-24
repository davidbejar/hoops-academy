#!/usr/bin/env bash
# Smoke test of the kind deployment through the Envoy Gateway (http://localhost:8090 by default).
#   deploy/kind/smoke.sh [service...]        default services: core game athlete
# core is deployed since WP18: with `core` in the list the script also logs the seeded `superadmin` in (PKCE, no browser)
# and checks GET /api/core/me (200, superAdmin=true) and GET /platform/tenants (200).
# pdf-service (when deployed, WP111): no route, a render with core's token from a core-labelled pod, other pods refused.
# finance-service (when deployed, WP118): with core and the broker, its replica catches up, admin1 creates a fee plan through
# the gateway, a second academy's admin reads nothing of it, and its pods connect as finance_app (not owner, no BYPASSRLS).
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
# shellcheck source=deploy/lib/common.sh
. deploy/lib/common.sh
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
  [ "$users" = "admin athlete-service core-service finance-service game-service " ] && ok "SCRAM users: $users" || bad "users: '$users'"
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
  if [ "$s" = finance ]; then # no service calls finance (no client of its own): every service token is the wrong audience
    token=$(service_token core)
    anon=$(code "$BASE/api/finance/settings"); wrong=$(code -H "Authorization: Bearer $token" "$BASE/api/finance/settings")
    [ -n "$token" ] && [ "$anon" = 401 ] && [ "$wrong" = 401 ] \
      && ok "/api/finance/settings anonymous 401, core-service token 401 (not its audience)" \
      || bad "/api/finance/settings anonymous $anon, core-service token $wrong (want 401 / 401)"
    continue
  fi
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
  # Browser-less authorization-code + PKCE login of client `web` (scripts/lib/oidc-login.sh); password DEV_USER_PASSWORD
  # from .env (never printed)
  # shellcheck source=scripts/lib/oidc-login.sh
  . scripts/lib/oidc-login.sh
  user_token() {  # $1 = username -> its access token on stdout (nothing on failure)
    oidc_login "$BASE/auth/realms/academy" "$BASE/redirect.html" "$1" DEV_USER_PASSWORD "openid profile email" \
      && printf '%s' "$OIDC_ACCESS_TOKEN"
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
# new academy (athlete from its replica when ATHLETE_ROSTER_SOURCE=replica). Metrics are read through a port-forward (not
# routed; the distroless images have no curl, ADR-0054).
if [[ " ${SERVICES[*]} " == *" core "* ]] && [ -n "${utok:-}" ] && kubectl "${CTX[@]}" get statefulset redpanda >/dev/null 2>&1; then
  echo "== events (WP71: outbox publisher, roster replicas)"
  port_of() { case "$1" in core-service) echo 8081 ;; game-service) echo 8082 ;; athlete-service) echo 8083 ;; finance-service) echo 8085 ;; esac; }
  metrics() { # through a port-forward: the distroless images have no curl and no shell (ADR-0054)
    local port local_port pid out=""
    port=$(port_of "$1"); local_port=$((port + 20000))
    kubectl "${CTX[@]}" port-forward "deploy/$1" "$local_port:$port" >/dev/null 2>&1 & pid=$!
    for _ in $(seq 40); do curl -s -o /dev/null "localhost:$local_port/q/health/live" && break; sleep 0.25; done
    out=$(curl -s "localhost:$local_port/q/metrics" || true)
    kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
    printf '%s\n' "$out"; }
  # sum of the samples of metric $1, 0 when absent (field 2: the value; an OpenMetrics exemplar may follow it)
  total() { { grep "^$1" || true; } | awk '{s += $2} END {printf "%d", s}'; }
  group_lag() { rp "$as_admin rpk group describe $1" | awk '$1 == "TOTAL-LAG" {print $2}'; }
  eventually() { for _ in $(seq "$PATIENCE"); do "$@" && return 0; sleep 1; done; return 1; }
  pub=$(curl -s "$BASE/api/core/q/health/ready" | jq -r '.checks[] | select(.name == "outbox-publisher") | "\(.status) \(.data.state)"')
  [ "$pub" = "UP OK" ] && ok "core readiness outbox-publisher: $pub" || bad "core readiness outbox-publisher: '$pub' (want UP OK)"
  [ "$(metrics core-service | total hoops_outbox_broker_available)" = 1 ] && ok "core: hoops_outbox_broker_available 1" \
    || bad "core: broker not available to the publisher"
  kafka_login() { # service:client; core's producer exists only once it has sent (lazy), so it is checked after the seed
    local n; n=$(metrics "${1%:*}-service" | total "kafka_${1#*:}_successful_authentication_total")
    [ "$n" -ge 1 ] && ok "${1%:*}-service: Kafka ${1#*:} logged in as ${1%:*}-service (SCRAM, $n successful authentications)" \
      || bad "${1%:*}-service: no successful Kafka authentication"; }
  kafka_login game:consumer; kafka_login athlete:consumer
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
    kafka_login core:producer
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
    # finance-service (WP118, ADR-0055; finance.enabled): its replica of core.tenant / core.person makes admin1 the ADMIN of
    # the new academy; a fee plan through the gateway; a second academy whose first admin is coach1 never reads it.
    if kubectl "${CTX[@]}" get deployment finance-service >/dev/null 2>&1; then
      echo "== finance-service (membership replica, fee plan through the gateway, another academy)"
      eventually caught_up finance && ok "finance-service.roster: group lag 0" \
        || bad "finance-service.roster: group lag $(group_lag finance-service.roster)"
      fin() { # METHOD path token tenant [json] -> "status body"
        local data=(); [ $# -lt 5 ] || data=(-H 'Content-Type: application/json' --data-binary "$5")
        curl -s -w '\n%{http_code}' -X "$1" "$BASE$2" -H "Authorization: Bearer $3" -H "X-Tenant-Id: $4" ${data[@]+"${data[@]}"}; }
      status() { tail -1 <<<"$1"; }
      cur=$(fin PUT /api/finance/settings "$atok" "$tenant" '{"currency":"EUR"}')
      plan=$(fin POST /api/finance/fee-plans "$atok" "$tenant" "$(jq -n --arg s "$season" --arg t "$team" \
        '{name: "Smoke monthly", seasonId: $s, teamId: $t, amountMinor: 4500, cadence: "MONTHLY", firstPeriod: "2026-09"}')")
      plan_id=$(sed '$d' <<<"$plan" | jq -r '.id // empty')
      [ "$(status "$cur")" = 200 ] && [ "$(status "$plan")" = 201 ] && [ -n "$plan_id" ] \
        && ok "finance: admin1 chose EUR and created fee plan $plan_id through the gateway (200, 201)" \
        || bad "finance: currency $(status "$cur"), fee plan $(status "$plan"): $(head -c 300 <<<"$plan")"
      c=$(status "$(fin GET "/api/finance/fee-plans/$plan_id" "$atok" "$tenant")")
      [ "$c" = 200 ] && ok "finance: admin1 reads the plan (200)" || bad "finance: admin1 reads the plan -> $c"
      slug_b="smoke-b-$(date +%s)"
      # Academy B's two events (tenant.changed, person.changed) must be published before the consumer lag means anything:
      # core's outbox polls every second, and a lag of 0 before the publish let the checks below run ahead of the replica
      # (WP144: 404 "no membership" 20 ms before finance applied the events, twice in a row).
      published_b=$(metrics core-service | total hoops_outbox_published_total)
      published_since() { [ "$(metrics core-service | total hoops_outbox_published_total)" -ge $(( $1 + 2 )) ]; }
      tenant_b=$(jq -n --arg s "$slug_b" '{slug: $s, name: ("Smoke " + $s), timezone: "Asia/Jakarta", defaultLocale: "id",
          firstAdmin: {email: "coach1@hoops-academy.com", givenName: "Casey", familyName: "Coach"}}' |
        curl -s -X POST "$BASE/platform/tenants" -H "Authorization: Bearer $utok" -H 'Content-Type: application/json' \
          --data-binary @- | jq -r '.id // empty')
      btok=$([ -n "$tenant_b" ] && user_token coach1@hoops-academy.com || true)
      eventually published_since "$published_b" || true
      eventually caught_up finance || true
      in_b=$(status "$(fin GET /api/finance/fee-plans "$btok" "$tenant_b")")
      by_id=$(status "$(fin GET "/api/finance/fee-plans/$plan_id" "$btok" "$tenant_b")")
      foreign=$(status "$(fin GET "/api/finance/fee-plans/$plan_id" "$btok" "$tenant")")
      list_b=$(fin GET /api/finance/fee-plans "$btok" "$tenant_b" | sed '$d' | jq -r '.items | length')
      [ -n "$tenant_b" ] && [ "$in_b" = 200 ] && [ "$list_b" = 0 ] && [ "$by_id" = 404 ] && [ "$foreign" = 404 ] \
        && ok "finance: academy B's admin lists nothing of A (200, 0 plans), A's plan by id 404, naming A's tenant 404" \
        || bad "finance: academy B (tenant '$tenant_b'): list $in_b ($list_b), by id $by_id, A's tenant $foreign"
      c=$(code "$BASE/api/finance/settings" -H "X-Tenant-Id: $tenant"); [ "$c" = 401 ] && ok "finance: anonymous -> 401" \
        || bad "finance: anonymous -> $c"
      role=$(kubectl "${CTX[@]}" exec hoops-db-1 -c postgres -- psql -tA -U postgres -d hoops -c "select r.rolsuper, r.rolbypassrls,
          (select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'finance'
             and pg_has_role('finance_app', c.relowner, 'MEMBER')),
          has_schema_privilege('finance_app', 'finance', 'CREATE'),
          (select count(*) from pg_stat_activity where usename = 'finance_app')
          from pg_roles r where r.rolname = 'finance_app'" 2>/dev/null | tr '|' ' ')
      [ "$(cut -d' ' -f1-4 <<<"$role")" = "f f 0 f" ] && [ "$(cut -d' ' -f5 <<<"$role")" -ge 1 ] \
        && ok "finance: the pods connect as finance_app ($(cut -d' ' -f5 <<<"$role") sessions): no superuser, no BYPASSRLS, owns nothing in finance, no CREATE" \
        || bad "finance: database role finance_app: '$role'"
    fi
  fi
fi

# pdf-service (WP111, ADR-0052; pdf.enabled): internal only, decision 89. No gateway route; a probe pod labelled like
# core-service takes core's client-credentials token from Keycloak inside the cluster (the secret from Secret
# hoops-oidc-core-service, never in the pod spec or on this host's command line) and posts a team roster: a PDF when
# core's token carries the pdf-service audience (realm mapper on client core-service, ADR-0034), else 401. Pods without a
# caller's label (unlabelled, athlete-service) are refused by the NetworkPolicy: the connection times out.
if kubectl "${CTX[@]}" get deployment pdf-service >/dev/null 2>&1; then
  echo "== pdf-service (internal only: core and game)"
  PROBE_IMAGE=docker.io/curlimages/curl:8.17.0@sha256:935d9100e9ba842cdb060de42472c7ca90cfe9a7c96e4dacb55e79e560b3ff40
  c=$(code -X POST "$BASE/internal/pdf/team-roster"); [ "$c" = 403 ] && ok "gateway: /internal/pdf/team-roster -> 403 (no route)" || bad "gateway /internal/pdf -> $c"
  aud=$(service_token core | cut -d. -f2 | tr '_-' '/+' | { base64 -d 2>/dev/null || true; } | jq -r '(.aud // []) | if type == "array" then join(" ") else . end' 2>/dev/null || true)
  probe() { # $1 = pod name, $2 = labels JSON, $3 = script; prints the pod's log
    local overrides
    overrides=$(jq -n --arg img "$PROBE_IMAGE" --arg script "$3" --argjson labels "$2" \
      --rawfile body services/pdf-service/crates/adapters/tests/fixtures/team-roster.json '{apiVersion: "v1",
      metadata: {labels: $labels}, spec: {automountServiceAccountToken: false, containers: [{name: "probe", image: $img,
      command: ["sh", "-c", $script], env: [{name: "BODY", value: $body},
        {name: "CS", valueFrom: {secretKeyRef: {name: "hoops-oidc-core-service", key: "client-secret"}}}],
      securityContext: {runAsNonRoot: true, runAsUser: 100, allowPrivilegeEscalation: false,
        capabilities: {drop: ["ALL"]}, readOnlyRootFilesystem: true}}]}}')
    kubectl "${CTX[@]}" run "$1" --restart=Never --image="$PROBE_IMAGE" --overrides="$overrides" >/dev/null
    kubectl "${CTX[@]}" wait --for=jsonpath='{.status.phase}'=Succeeded "pod/$1" --timeout=120s >/dev/null 2>&1 || true
    kubectl "${CTX[@]}" logs "$1" 2>&1 || true
    kubectl "${CTX[@]}" delete pod "$1" --wait=false >/dev/null 2>&1 || true
  }
  # shellcheck disable=SC2016 # expanded inside the probe pod
  render='tok=$(curl -s -X POST http://keycloak:8080/auth/realms/academy/protocol/openid-connect/token \
      -d grant_type=client_credentials -d client_id=core-service --data-urlencode "client_secret=$CS" |
    sed -n "s/.*\"access_token\":\"\([^\"]*\)\".*/\1/p")
  [ -n "$tok" ] || { echo "no token"; exit 0; }
  post() { curl -s -m 30 -X POST http://pdf-service:8084/internal/pdf/team-roster -H "Authorization: Bearer $tok" \
    -H "Content-Type: application/json" --data-binary "$BODY" "$@"; }
  post -o /dev/null -w "status=%{http_code} type=%{content_type} size=%{size_download}\n"
  echo "magic=$(post | head -c 5)"
  echo "web=$(curl -s -m 10 -o /dev/null -w "%{http_code}" -X POST http://pdf-service:8084/internal/pdf/team-roster \
    -H "Content-Type: application/json" --data-binary "$BODY")"'
  out=$(probe "pdf-probe-core-$$" '{"app.kubernetes.io/name": "core-service"}' "$render")
  printf '%s\n' "$out" | sed 's/^/  | /'
  if [[ " $aud " == *" pdf-service "* ]]; then
    printf '%s\n' "$out" | grep -q '^status=200 type=application/pdf size=[1-9]' && printf '%s\n' "$out" | grep -qx 'magic=%PDF-' \
      && ok "a pod labelled core-service renders a team roster with core's token (200, application/pdf, %PDF-)" \
      || bad "pdf-service did not render with core's token"
  else
    warn "core-service's token lacks the pdf-service audience (realm mapper not added yet, WP116); its call is refused"
    printf '%s\n' "$out" | grep -q '^status=401 ' && ok "core's token without the pdf-service audience -> 401" || bad "pdf-service with core's token: $out"
  fi
  printf '%s\n' "$out" | grep -qx 'web=401' && ok "a call without a token -> 401" || bad "pdf-service without a token"
  # shellcheck disable=SC2016 # expanded inside the probe pod
  reach='curl -s -m 5 -o /dev/null http://pdf-service:8084/q/health/ready; echo "exit=$?"'
  for labels in '{"run": "pdf-probe"}' '{"app.kubernetes.io/name": "athlete-service"}'; do
    out=$(probe "pdf-probe-other-$$-$RANDOM" "$labels" "$reach")
    printf '%s\n' "$out" | grep -qx 'exit=28' && ok "NetworkPolicy: a pod labelled $labels cannot reach pdf-service (timeout)" \
      || bad "NetworkPolicy: a pod labelled $labels: $out"
  done
fi

[ "$fail" = 0 ] && echo "SMOKE PASSED" || { echo "SMOKE FAILED"; exit 1; }
