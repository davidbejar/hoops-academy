#!/usr/bin/env bash
# Seeds the local test academy "Test Academy" through the public and platform API (WP103, decision 74):
# 2 admins, 1 coach, 10 players (each with a login), 10 parents (parent N linked to player N), one season, one
# age category, one team with the ten players. Every login gets the shared final password TEST_ACADEMY_PASSWORD
# (kcadm set-password, not temporary, no required action, e-mail verified) and is signed in once, which accepts the
# invitation. Idempotent: looks things up before creating, resets the passwords on every run.
# Then demo data (WP107, decision 80) that looks like the landing screenshots, through the API as the roles that may do it:
# an assistant coach on the team, a training week (schedules, done sessions with attendance, a cancelled session, plans built
# from the exercise catalogue, an assignment, a planned absence), a finished match (Lobos) and a live one (Tigres) with event
# logs, an open and a recovered injury, body measurements and physical tests. Skip it with SEED_ACADEMY_DEMO=0; re-run only
# the demo part (no 23 sign-ins) with SEED_ACADEMY_DEMO_ONLY=1.
# Needs: stack up (`just up`, `just seed-users`), services up (`just services-up`), .env with KEYCLOAK_ADMIN,
# KEYCLOAK_ADMIN_PASSWORD, DEV_USER_PASSWORD (super admin) and TEST_ACADEMY_PASSWORD (>= 12 characters).
# Local only: refuses a base URL other than localhost / 127.0.0.1 unless SEED_ACADEMY_ALLOW_REMOTE=1.
# Never prints a password or token; response bodies are never printed (they can carry temporary passwords).
set -euo pipefail
cd "$(dirname "$0")/../.."
# shellcheck disable=SC1091  # .env is optional and not followed
if [ -f .env ]; then set -a; . ./.env; set +a; fi

die() { echo "seed-academy: $*" >&2; exit 1; }
for v in KEYCLOAK_ADMIN KEYCLOAK_ADMIN_PASSWORD DEV_USER_PASSWORD TEST_ACADEMY_PASSWORD; do
  [ -n "${!v:-}" ] || die "missing env $v (see .env.example)"
done
[ "${#TEST_ACADEMY_PASSWORD}" -ge 12 ] || die "TEST_ACADEMY_PASSWORD must be >= 12 characters (realm password policy)"
command -v jq >/dev/null || die "jq is required"

BASE="${SEED_ACADEMY_BASE_URL:-http://localhost:8080}"
BASE="${BASE%/}"
case "$BASE" in
  http://localhost | http://localhost:* | http://127.0.0.1 | http://127.0.0.1:* | https://localhost | https://localhost:*) ;;
  *) [ "${SEED_ACADEMY_ALLOW_REMOTE:-}" = 1 ] || die "base URL $BASE is not local; set SEED_ACADEMY_ALLOW_REMOTE=1 to allow it" ;;
esac
ISSUER="$BASE/auth/realms/academy"
C="${KEYCLOAK_CONTAINER:-hoops-keycloak}"
REALM=academy
DOMAIN=hoops-academy.com
SLUG=test-academy
SEASON_NAME="Test Season"
TEAM_NAME="Test Team"
PLAYERS=10
SECONDS=0

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
RESP="$WORK/resp"; HDR="$WORK/hdr"
CREATED=0
TOKEN=""; TENANT=""; CODE=""

say() { echo "seed-academy: $*"; }

# ---------------------------------------------------------------------------------------------------- HTTP
# api METHOD PATH [JSON-BODY]: sets CODE and RESP (body, never printed). Bearer token and tenant from TOKEN / TENANT.
api() {
  local method="$1" path="$2" body="${3:-}" tries=4
  { printf 'Authorization: Bearer %s\n' "$TOKEN"; [ -z "$TENANT" ] || printf 'X-Tenant-Id: %s\n' "$TENANT"
    [ -z "${ALANG:-}" ] || printf 'Accept-Language: %s\n' "$ALANG"; } >"$HDR"
  chmod 600 "$HDR"
  while :; do
    if [ -n "$body" ]; then
      CODE=$(printf '%s' "$body" | curl -sS -o "$RESP" -w '%{http_code}' -X "$method" -H @"$HDR" \
        -H 'Content-Type: application/json' --data-binary @- "$BASE$path") || die "request $method $path failed"
    else
      CODE=$(curl -sS -o "$RESP" -w '%{http_code}' -X "$method" -H @"$HDR" "$BASE$path") || die "request $method $path failed"
    fi
    # a gateway answering 502/503/504 to a read (a service that has just started) is retried
    case "$CODE" in 502 | 503 | 504) [ "$method" = GET ] && [ $((--tries)) -gt 0 ] && { sleep 2; continue; } ;; esac
    return 0
  done
}
# need CODES...: abort (without printing the body, apart from the problem code) unless CODE is one of them.
need() {
  local c
  for c in "$@"; do [ "$CODE" = "$c" ] && return 0; done
  die "unexpected HTTP $CODE ($(jq -r '[.code, .title] | map(select(. != null)) | join(" ")' "$RESP" 2>/dev/null || true))"
}
j() { jq -r "$1" "$RESP"; }

# ---------------------------------------------------------------------------------------------------- tokens
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
# login_once USER PASSWORD-ENV-NAME: browser-less authorization-code + PKCE flow of client `web` (as the app does);
# sets TOKEN. Returns 1 when Keycloak does not redirect with a code (wrong password, or a required action is pending),
# 2 when the gateway rate limit (nginx zone `auth`, 60/min) answered 429.
login_once() {
  local user="$1" pwvar="$2" verifier challenge state jar form action loc code redirect="$BASE/redirect.html" hc
  jar="$WORK/jar"; : >"$jar"
  verifier=$(openssl rand 48 | b64url)
  challenge=$(printf '%s' "$verifier" | openssl dgst -sha256 -binary | b64url)
  state=$(openssl rand -hex 8)
  hc=$(curl -sS -o "$WORK/form" -w '%{http_code}' -c "$jar" -b "$jar" -G "$ISSUER/protocol/openid-connect/auth" \
    --data-urlencode client_id=web --data-urlencode response_type=code --data-urlencode "redirect_uri=$redirect" \
    --data-urlencode "scope=openid profile email offline_access" --data-urlencode "state=$state" \
    --data-urlencode "code_challenge=$challenge" --data-urlencode code_challenge_method=S256) || return 1
  [ "$hc" != 429 ] || return 2
  form=$(cat "$WORK/form")
  action=$(printf '%s' "$form" | tr '\n' ' ' | sed -n 's/.*id="kc-form-login"[^>]*action="\([^"]*\)".*/\1/p' | sed 's/&amp;/\&/g')
  [ -n "$action" ] || return 1
  # credentials travel on stdin, never on a command line
  U="$user" P="${!pwvar}" jq -jn '"username=\(env.U | @uri)&password=\(env.P | @uri)"' \
    | curl -sS -o /dev/null -D "$WORK/loc" -c "$jar" -b "$jar" --data-binary @- "$action" || return 1
  loc=$(tr -d '\r' <"$WORK/loc" | sed -n 's/^[Ll]ocation: //p')
  if [ -z "$loc" ] && grep -q ' 429 ' "$WORK/loc"; then return 2; fi
  case "$loc" in "$redirect"*) ;; *) return 1 ;; esac
  code=$(printf '%s' "$loc" | sed -n 's/.*[?&]code=\([^&#]*\).*/\1/p')
  hc=$(curl -sS -o "$WORK/tok" -w '%{http_code}' "$ISSUER/protocol/openid-connect/token" -d grant_type=authorization_code \
    -d client_id=web --data-urlencode "code=$code" --data-urlencode "redirect_uri=$redirect" \
    --data-urlencode "code_verifier=$verifier") || return 1
  [ "$hc" != 429 ] || return 2
  TOKEN=$(jq -r .access_token "$WORK/tok")
  [ -n "$TOKEN" ] && [ "$TOKEN" != null ]
}
# login USER PASSWORD-ENV-NAME: login_once, waiting out the gateway's rate limit (up to ~2 minutes).
login() {
  local tries=60 rc
  while [ $((tries--)) -gt 0 ]; do
    login_once "$@" && return 0 || rc=$?
    [ "$rc" = 2 ] || return 1
    sleep 2
  done
  return 1
}

# ---------------------------------------------------------------------------------------------------- Keycloak
# Secrets are passed through the container environment of the exec, never on a command line.
kc_login() {
  podman exec -e KCADM_PW="$KEYCLOAK_ADMIN_PASSWORD" "$C" bash -c \
    '/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user "$0" --password "$KCADM_PW" >/dev/null 2>&1' \
    "$KEYCLOAK_ADMIN" || die "cannot sign in to Keycloak as $KEYCLOAK_ADMIN (is $C running?)"
}
# finalize_logins EMAIL...: final non-temporary password, no required action, e-mail verified, enabled.
finalize_logins() {
  podman exec -e KCADM_PW="$KEYCLOAK_ADMIN_PASSWORD" -e KADMIN="$KEYCLOAK_ADMIN" -e TEST_PW="$TEST_ACADEMY_PASSWORD" "$C" bash -c '
    k=/opt/keycloak/bin/kcadm.sh
    $k config credentials --server http://localhost:8080/auth --realm master --user "$KADMIN" --password "$KCADM_PW" >/dev/null 2>&1 || exit 3
    for u in "$@"; do
      id=$($k get users -r '"$REALM"' -q "username=$u" -q exact=true --fields id --format csv --noquotes | head -n1 | tr -d "\r")
      [ -n "$id" ] || { echo "no Keycloak login for $u" >&2; exit 4; }
      $k set-password -r '"$REALM"' --userid "$id" --new-password "$TEST_PW" 2>/dev/null || { echo "Keycloak refused the password for $u (realm password policy?)" >&2; exit 5; }
      $k update "users/$id" -r '"$REALM"' -s emailVerified=true -s enabled=true -s "requiredActions=[]" >/dev/null || exit 6
    done' _ "$@" || die "setting the final password failed (see message above)"
}

# ---------------------------------------------------------------------------------------------------- phases
email() { echo "$1@$DOMAIN"; }

ensure_tenant() {
  api GET "/platform/tenants?q=$SLUG&size=200"; need 200
  local row; row=$(jq -c --arg s "$SLUG" '[.items[] | select(.slug == $s)] | first // empty' "$RESP")
  if [ -z "$row" ]; then
    api POST /platform/tenants "$(jq -nc --arg e "$(email testadmin1)" '{slug: "test-academy", name: "Test Academy",
      timezone: "Europe/Madrid", defaultLocale: "es", firstAdmin: {email: $e, givenName: "Test", familyName: "Admin 1"}}')"
    need 201
    TENANT=$(j .id); CREATED=$((CREATED + 1)); say "created academy Test Academy"
    return
  fi
  local status; status=$(printf '%s' "$row" | jq -r .status)
  [ "$status" = ACTIVE ] || die "academy $SLUG exists with status $status; reactivate it or choose another slug"
  TENANT=$(printf '%s' "$row" | jq -r .id)
}

# Member index of the academy (as the admin): "email<TAB>personId<TAB>playerId" lines in MEMBERS.
load_members() {
  api GET "/api/core/members?size=200"; need 200
  MEMBERS=$(jq -r '.items[] | [(.email // "" | ascii_downcase), .personId, (.playerId // "")] | @tsv' "$RESP")
}
member_field() { # email column(2=personId,3=playerId)
  printf '%s\n' "$MEMBERS" | awk -F'\t' -v e="$1" -v c="$2" '$1 == e { print $c; exit }'
}

ensure_member() { # name given family role
  local n="$1" g="$2" f="$3" r="$4" e; e=$(email "$1")
  [ -z "$(member_field "$e" 2)" ] || return 0
  api POST /api/core/members "$(jq -nc --arg g "$g" --arg f "$f" --arg e "$e" --arg r "$r" \
    '{givenName: $g, familyName: $f, email: $e, roles: [$r], locale: "es"}')"
  need 201; CREATED=$((CREATED + 1)); say "created $e ($r)"
}

ensure_season() {
  api GET /api/core/seasons; need 200
  SEASON=$(jq -r --arg n "$SEASON_NAME" '[.[] | select(.name == $n)] | (first // {}) | .id // empty' "$RESP")
  [ -z "$SEASON" ] || return 0
  local today; today=$(date +%Y-%m-%d)
  api POST /api/core/seasons "$(jq -nc --arg n "$SEASON_NAME" --arg s "$(date -v-100d +%Y-%m-%d 2>/dev/null || date -d '-100 days' +%Y-%m-%d)" \
    --arg e "$(date -v+250d +%Y-%m-%d 2>/dev/null || date -d '+250 days' +%Y-%m-%d)" --argjson y "${today%%-*}" \
    '{name: $n, startsOn: $s, endsOn: $e, referenceYear: $y}')"
  need 201; SEASON=$(j .id); CREATED=$((CREATED + 1)); say "created season $SEASON_NAME"
}

ensure_team() { # sets TEAM (the main team) ; ensure_team_named NAME sets the variable it is given
  ensure_team_named "$TEAM_NAME" TEAM
}
ensure_team_named() { # name var
  api GET /api/core/age-categories; need 200
  CATEGORY=$(jq -r '.[] | select(.code == "U14") | .id' "$RESP")
  MAXAGE=$(jq -r '.[] | select(.code == "U14") | .maxAge' "$RESP")
  [ -n "$CATEGORY" ] && [ "$MAXAGE" != null ] || die "the academy has no age category U14"
  api GET "/api/core/teams?seasonId=$SEASON"; need 200
  local found; found=$(jq -r --arg n "$1" '(.items // .)[] | select(.name == $n) | .id' "$RESP" | head -n1)
  if [ -z "$found" ]; then
    api POST /api/core/teams "$(jq -nc --arg s "$SEASON" --arg c "$CATEGORY" --arg n "$1" \
      '{seasonId: $s, name: $n, ageCategoryId: $c, genderPolicy: "MIXED"}')"
    need 201; found=$(j .id); CREATED=$((CREATED + 1)); say "created team $1"
  fi
  printf -v "$2" '%s' "$found"
}

ensure_staff() { # team name role
  local tm="$1" who="$2" role="$3" pid; pid=$(member_field "$(email "$who")" 2)
  api GET "/api/core/teams/$tm/staff"; need 200
  if jq -e --arg p "$pid" --arg r "$role" 'any(.[]; .person.personId == $p and .role == $r)' "$RESP" >/dev/null; then return 0; fi
  api PUT "/api/core/teams/$tm/staff/$pid" "$(jq -nc --arg r "$role" '{role: $r}')"; need 200
  CREATED=$((CREATED + 1)); say "$who is $role of a team"
}

# Players with a login are created by the admin (ACTIVE at once, so no approval is needed) and assigned to the team
# with jersey 3+N. A player created by an earlier, interrupted run that is not on the roster is assigned now.
ensure_player() { # n
  local n="$1" e pid born month day by
  e=$(email "testplayer$n"); by=$(( $(date +%Y) - (MAXAGE - 1) ))
  month=$(printf '%02d' $(( (n * 5) % 12 + 1 ))); day=$(printf '%02d' $(( (n * 3) % 27 + 1 )))
  born="$by-$month-$day"
  pid=$(member_field "$e" 3)
  if [ -z "$pid" ]; then
    local gender=MALE; [ $((n % 2)) = 0 ] && gender=FEMALE
    api POST /api/core/players "$(jq -nc --arg g Test --arg f "Player $n" --arg b "$born" --arg ge "$gender" --arg e "$e" \
      --arg t "$TEAM" --arg j "$((n + 3))" \
      '{givenName: $g, familyName: $f, birthDate: $b, gender: $ge, email: $e, teamId: $t, jerseyNumber: $j}')"
    need 201; CREATED=$((CREATED + 1)); say "created $e (player, jersey $((n + 3)))"
    return
  fi
  if ! jq -e --arg p "$pid" 'any(.[]; .player.id == $p)' "$ROSTER" >/dev/null; then
    api POST "/api/core/teams/$TEAM/players" "$(jq -nc --arg p "$pid" --arg j "$((n + 3))" '{playerId: $p, jerseyNumber: $j}')"
    need 201; CREATED=$((CREATED + 1)); say "assigned $e to $TEAM_NAME"
  fi
}

ensure_guardian_link() { # n
  local n="$1" parent player
  parent=$(member_field "$(email "testparentplayer$n")" 2); player=$(member_field "$(email "testplayer$n")" 3)
  [ -n "$parent" ] && [ -n "$player" ] || die "cannot link parent $n: person or player is missing"
  if jq -e --arg g "$parent" --arg p "$player" 'any(.items[]; .guardian.personId == $g and .player.id == $p)' "$LINKS" >/dev/null; then
    return 0
  fi
  api POST /api/core/guardian-links "$(jq -nc --arg g "$parent" --arg p "$player" '{guardianPersonId: $g, playerId: $p}')"
  need 201; CREATED=$((CREATED + 1)); say "linked testparentplayer$n to testplayer$n"
}

# ---------------------------------------------------------------------------------------------------- run
say "target $BASE"
kc_login

login "superadmin@$DOMAIN" DEV_USER_PASSWORD || die "super admin sign-in failed (just seed-users, DEV_USER_PASSWORD)"
ensure_tenant
# The first admin's login exists now (created above or earlier): give it the final password, then act as that admin.
finalize_logins "$(email testadmin1)"
login "$(email testadmin1)" TEST_ACADEMY_PASSWORD || die "testadmin1 cannot sign in with the shared password"

load_members
ensure_member testadmin2 Test "Admin 2" ADMIN
ensure_member testcoach1 Test "Coach 1" COACH
ensure_member testassistant1 Test "Assistant 1" ASSISTANT_COACH
for n in $(seq 1 $PLAYERS); do ensure_member "testparentplayer$n" Test "Parent of Player $n" PARENT; done
ensure_season
ensure_team
load_members
ensure_staff "$TEAM" testcoach1 COACH
ensure_staff "$TEAM" testassistant1 ASSISTANT_COACH
api GET "/api/core/teams/$TEAM/players"; need 200; ROSTER="$WORK/roster.json"; cp "$RESP" "$ROSTER"
for n in $(seq 1 $PLAYERS); do ensure_player "$n"; done
load_members
api GET "/api/core/guardian-links?size=200"; need 200; LINKS="$WORK/links.json"; cp "$RESP" "$LINKS"
for n in $(seq 1 $PLAYERS); do ensure_guardian_link "$n"; done

# Final passwords for everybody, then one sign-in each: proves no required action is left and accepts the invitation
# (first /api/core/me). Game and athlete read the roster from their replicas: each parent is polled (deadline, no blind
# sleep) until game and athlete treat the parent as the child's guardian.
USERS="testadmin1 testadmin2 testcoach1 testassistant1"
for n in $(seq 1 $PLAYERS); do USERS="$USERS testplayer$n"; done
for n in $(seq 1 $PLAYERS); do USERS="$USERS testparentplayer$n"; done
emails=(); for u in $USERS; do emails+=("$(email "$u")"); done
finalize_logins "${emails[@]}"
[ "${SEED_ACADEMY_DEMO_ONLY:-}" = 1 ] || for u in $USERS; do
  login "$(email "$u")" TEST_ACADEMY_PASSWORD || die "$u cannot sign in with the shared password (required action pending?)"
  tenant_keep="$TENANT"; TENANT=""; api GET /api/core/me; TENANT="$tenant_keep"; need 200
  jq -e --arg t "$TENANT" 'any(.memberships[]; .tenant.id == $t)' "$RESP" >/dev/null || die "$u is not a member of the academy"
  case "$u" in
    testparentplayer*)
      player=$(member_field "$(email "testplayer${u#testparentplayer}")" 3)
      deadline=$((SECONDS + 60))
      while :; do
        api GET "/api/game/players/$player/season-stats?seasonId=$SEASON"; g=$CODE
        api GET "/api/athlete/planned-absences?playerId=$player"; a=$CODE
        [ "$g" = 200 ] && [ "$a" = 200 ] && break
        [ "$SECONDS" -lt "$deadline" ] || die "game/athlete replicas did not learn the guardian link of $u within 60 s (game $g, athlete $a)"
        sleep 1
      done ;;
  esac
done

# ---------------------------------------------------------------------------------------------------- demo data (WP107)
# Players are addressed by their number: demo player N is testplayerN (jersey N+3). The landing pictures show Sara Vidal
# (4), Iker Sanz (5), Ana Ruiz (7), Noa Pardo (8), Leo Gil (10), Hugo Rey (11), Lía Marín (13): here those are players
# 1, 2, 4, 5, 7, 8 and 10. The names stay "Test Player N" (they are the logins' names).
ZONE=Europe/Madrid
dayin() { # offset in days from today -> YYYY-MM-DD
  if [ "$1" -ge 0 ]; then date -v"+$1d" +%Y-%m-%d 2>/dev/null || date -d "$1 days" +%Y-%m-%d
  else date -v"$1d" +%Y-%m-%d 2>/dev/null || date -d "$1 days" +%Y-%m-%d; fi
}
weekday_of() { date -j -f %Y-%m-%d "$1" +%u 2>/dev/null || date -d "$1" +%u; } # 1 = Monday
zone_epoch() { TZ=$ZONE date -j -f '%Y-%m-%d %H:%M:%S' "$1 $2:00" +%s 2>/dev/null || TZ=$ZONE date -d "$1 $2:00" +%s; }
iso_of_epoch() { date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ; }
# Stable UUID (version 7 layout) of a name: the same event gets the same id on every run, so a re-run is all DUPLICATE.
uuid_of() {
  local h; h=$(printf '%s' "$1" | openssl dgst -md5 -hex | awk '{print $NF}')
  printf '%s-%s-7%s-8%s-%s' "${h:0:8}" "${h:8:4}" "${h:13:3}" "${h:17:3}" "${h:20:12}"
}
pid() { printf '%s\n' "$PIDS" | awk -v n="$1" '$1 == n { print $2; exit }'; }
countof() { jq -r "$1" "$RESP"; }
DOW=(x MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY SUNDAY)

# ---- training: schedules, sessions of the last two weeks (done, with attendance), plans
SLOTS='main|1|17:30|90|Pabellón Norte
main|3|17:30|90|Pabellón Norte
main|5|17:00|60|Pista exterior
inf|2|18:30|90|Pabellón Sur
inf|4|18:30|90|Pabellón Sur'
team_of() { if [ "$1" = main ]; then echo "$TEAM"; else echo "$TEAM2"; fi; }

ensure_schedules() {
  local week_start; week_start=$(dayin $((1 - $(date +%u))))
  local which dow time mins place t
  while IFS='|' read -r which dow time mins place; do
    t=$(team_of "$which")
    api GET "/api/athlete/training-schedules?teamId=$t"; need 200
    if jq -e --arg d "${DOW[$dow]}" --arg s "$time" 'any(.[]; .dayOfWeek == $d and (.startTime | .[0:5]) == $s)' "$RESP" >/dev/null; then continue; fi
    api POST /api/athlete/training-schedules "$(jq -nc --arg t "$t" --arg d "${DOW[$dow]}" --arg s "$time" --argjson m "$mins" \
      --arg p "$place" --arg v "$week_start" '{teamId: $t, dayOfWeek: $d, startTime: $s, durationMinutes: $m, location: $p, validFrom: $v}')"
    need 201; CREATED=$((CREATED + 1)); say "created schedule ${DOW[$dow]} $time ($which team)"
  done <<<"$SLOTS"
}

# The two weeks before today: a session for every slot (the schedules only materialise from today on), all DONE.
ensure_past_sessions() {
  local k day dow which sdow time mins place t at
  for k in $(seq 14 -1 1); do
    day=$(dayin "-$k"); dow=$(weekday_of "$day")
    while IFS='|' read -r which sdow time mins place; do
      [ "$sdow" = "$dow" ] || continue
      t=$(team_of "$which"); at=$(iso_of_epoch "$(zone_epoch "$day" "$time")")
      api GET "/api/athlete/training-sessions?teamId=$t&from=$day&to=$day"; need 200
      if jq -e --arg a "$at" 'any(.items[]; .startsAt[0:16] == $a[0:16])' "$RESP" >/dev/null; then continue; fi
      api POST /api/athlete/training-sessions "$(jq -nc --arg t "$t" --arg a "$at" --argjson m "$mins" --arg p "$place" \
        '{teamId: $t, startsAt: $a, durationMinutes: $m, location: $p}')"
      need 201; CREATED=$((CREATED + 1)); say "created session $day $time ($which team)"
    done <<<"$SLOTS"
  done
}

# Sessions of the last two weeks that are still PLANNED become DONE; the main team's get an attendance sheet: mostly
# present, player 4 absent now and then, player 7 sometimes late (as in the demo).
ensure_done_and_attendance() {
  local t sid n=0 rows
  for t in "$TEAM" "$TEAM2"; do
    api GET "/api/athlete/training-sessions?teamId=$t&from=$(dayin -14)&to=$(dayin -1)&size=100"; need 200
    rows=$(jq -r '.items | sort_by(.startsAt) | .[] | select(.status != "CANCELLED") | [.id, .status] | @tsv' "$RESP")
    while IFS=$'\t' read -r sid st; do
      [ -n "$sid" ] || continue
      n=$((n + 1))
      if [ "$st" = PLANNED ]; then
        api PATCH "/api/athlete/training-sessions/$sid" '{"status":"DONE"}'; need 200
        CREATED=$((CREATED + 1)); say "session marked done"
      fi
      [ "$t" = "$TEAM" ] || continue
      api GET "/api/athlete/training-sessions/$sid/attendance"; need 200
      jq -e 'any(.entries[]; .status != null)' "$RESP" >/dev/null && continue
      local entries; entries=$(jq -c --arg n "$n" --arg a "$(pid 4)" --arg l "$(pid 7)" '[.entries[] | .playerId as $p
        | if $p == $a and ($n | tonumber) % 5 == 2 then {playerId: $p, status: "ABSENT", note: "Enferma"}
          elif $p == $l and ($n | tonumber) % 4 == 1 then {playerId: $p, status: "LATE", minutesLate: 10}
          else {playerId: $p, status: "PRESENT"} end]' "$RESP")
      [ "$entries" != "[]" ] || continue
      api PUT "/api/athlete/training-sessions/$sid/attendance" "$(jq -nc --argjson e "$entries" '{entries: $e}')"; need 200
      CREATED=$((CREATED + 1)); say "recorded attendance"
    done <<<"$rows"
  done
}

# ensure_plan NAME DESCRIPTION EXERCISE-NAMEKEY...: a tenant plan whose items are copied from catalogue exercises.
ensure_plan() { # sets PLAN
  local name="$1" desc="$2"; shift 2
  api GET "/api/athlete/training-plans?size=100"; need 200
  PLAN=$(jq -r --arg n "$name" '[.items[] | select(.name == $n and .template == false)] | (first // {}) | .id // empty' "$RESP")
  if [ -z "$PLAN" ]; then
    api POST /api/athlete/training-plans "$(jq -nc --arg n "$name" --arg d "$desc" '{name: $n, description: $d}')"
    need 201; PLAN=$(j .id); CREATED=$((CREATED + 1)); say "created plan $name"
  fi
  api GET "/api/athlete/training-plans/$PLAN"; need 200
  [ "$(countof '.itemCount')" = 0 ] || return 0
  local ids="" key
  api GET "/api/athlete/exercises?size=200"; need 200
  for key in "$@"; do
    ids="$ids$(jq -c --arg k "$key" '[.items[] | select(.nameKey == $k)] | (first // empty) | {exerciseId: .id}' "$RESP")"$'\n'
  done
  ids=$(printf '%s' "$ids" | jq -sc .)
  [ "$ids" != "[]" ] || die "catalogue exercises for plan $name not found"
  ALANG=es api POST "/api/athlete/training-plans/$PLAN/items:copy" "$(jq -nc --argjson i "$ids" '{items: $i}')"; need 200 201
  CREATED=$((CREATED + 1)); say "added the exercises to plan $name"
}

ensure_training_extras() {
  local main_plan
  ensure_plan "Calentamiento Mini" "Rutina de 15 minutos antes de entrenar" \
    easy-jog-and-skips dynamic-leg-swings chest-and-bounce-pass-pairs free-throw-line-shots
  main_plan="$PLAN"
  ensure_plan "Condicionamiento semanal" "Resistencia y velocidad por intervalos" cooper-test line-sprints defensive-slide-intervals
  # assignment of the warm-up plan to the team, due in 5 days, and player 4's completion
  api GET "/api/athlete/plan-assignments?teamId=$TEAM&size=100"; need 200
  ASG=$(jq -r --arg p "$main_plan" '[.items[] | select(.plan.id == $p)] | (first // {}) | .id // empty' "$RESP")
  if [ -z "$ASG" ]; then
    api POST /api/athlete/plan-assignments "$(jq -nc --arg p "$main_plan" --arg t "$TEAM" --arg d "$(dayin 5)" \
      '{planId: $p, teamId: $t, dueOn: $d, notes: "Para la semana que viene"}')"
    need 201; ASG=$(j .id); CREATED=$((CREATED + 1)); say "assigned the warm-up plan to the team"
  fi
  api GET "/api/athlete/plan-assignments/$ASG/progress"; need 200
  if [ "$(countof '.counts.DONE // 0')" = 0 ]; then
    api PUT "/api/athlete/plan-assignments/$ASG/completions/$(pid 4)" '{"status":"DONE"}'; need 200
    CREATED=$((CREATED + 1)); say "player 4 completed the plan"
  fi
  # upcoming sessions made by the Monday/Wednesday/Friday schedules: the first is cancelled, the next carries the plan
  api GET "/api/athlete/training-sessions?teamId=$TEAM&from=$(dayin 0)&to=$(dayin 14)&size=100"; need 200
  local up; up=$(jq -c '[.items | sort_by(.startsAt) | .[] | select(.scheduleId != null)]' "$RESP")
  if ! jq -e 'any(.[]; .status == "CANCELLED")' <<<"$up" >/dev/null; then
    api POST "/api/athlete/training-sessions/$(jq -r '[.[] | select(.status == "PLANNED")][0].id' <<<"$up")/cancel" '{"reason":"Pabellón cerrado por obras"}'
    need 200; CREATED=$((CREATED + 1)); say "cancelled the first upcoming session"
    up=$(jq -c '[.[]]' <<<"$up")
  fi
  api GET "/api/athlete/training-sessions?teamId=$TEAM&from=$(dayin 0)&to=$(dayin 14)&size=100"; need 200
  if ! jq -e --arg p "$main_plan" 'any(.items[]; .planId == $p)' "$RESP" >/dev/null; then
    local target; target=$(jq -r '[.items | sort_by(.startsAt) | .[] | select(.scheduleId != null and .status == "PLANNED")][0].id' "$RESP")
    api PATCH "/api/athlete/training-sessions/$target" "$(jq -nc --arg p "$main_plan" '{planId: $p}')"; need 200
    CREATED=$((CREATED + 1)); say "the next session carries the warm-up plan"
  fi
  # player 4 announces an absence for two days from the day after tomorrow
  api GET "/api/athlete/planned-absences?playerId=$(pid 4)&size=100"; need 200
  if ! jq -e 'any(.items[]; .reason == "Torneo de ajedrez")' "$RESP" >/dev/null; then
    api POST /api/athlete/planned-absences "$(jq -nc --arg p "$(pid 4)" --arg f "$(dayin 2)" --arg t "$(dayin 3)" \
      '{playerId: $p, fromDate: $f, toDate: $t, reason: "Torneo de ajedrez"}')"
    need 201; CREATED=$((CREATED + 1)); say "planned absence of player 4"
  fi
}

# ---- matches
# emit_events MATCH-ID START-EPOCH (stdin: "TYPE PERIOD CLOCK PLAYER-NUMBER|- PAYLOAD-JSON|-" per line) -> batch JSON
events_json() {
  local m="$1" t="$2" n=0 type period clock pn payload items="" who
  while read -r type period clock pn payload; do
    [ -n "$type" ] || continue
    n=$((n + 1)); t=$((t + 20)); who=""; [ "$pn" = - ] || who=$(pid "$pn")
    items="$items$(jq -nc --arg id "$(uuid_of "$m:$n")" --argjson seq "$n" --arg type "$type" --argjson period "$period" \
      --argjson clock "$clock" --arg at "$(iso_of_epoch "$t")" --arg p "$who" --arg payload "$payload" \
      '{id: $id, deviceId: "seed-bench", clientSeq: $seq, type: $type, period: $period, clockSecondsRemaining: $clock, recordedAtClient: $at}
       + (if $p != "" then {playerId: $p} else {} end) + (if $payload != "-" then {payload: ($payload | fromjson)} else {} end)')"$'\n'
  done
  printf '%s' "$items" | jq -sc '{events: .}'
}

# Tigres, in progress: Q1 running, Us 4 - 9 (Leo Gil = player 7 and Iker Sanz = player 2 have 2 points each).
tigres_script() {
  cat <<'E'
PERIOD_START 1 600 - -
OPPONENT_SCORE 1 570 - {"points":3}
SHOT 1 545 7 {"points":2,"made":true}
OPPONENT_SCORE 1 520 - {"points":2}
REBOUND 1 505 2 {"kind":"DEFENSIVE"}
SHOT 1 480 2 {"points":2,"made":true}
ASSIST 1 480 5 -
OPPONENT_SCORE 1 450 - {"points":2}
SHOT 1 420 4 {"points":2,"made":false}
REBOUND 1 405 1 {"kind":"DEFENSIVE"}
OPPONENT_SCORE 1 390 - {"points":2}
E
}

# Lobos, finished 7 days ago: four periods, six shots each, rotating over seven players.
lobos_script() {
  local p i k=0 s a pts made clock shooters=(1 2 4 5 7 8 10)
  for p in 1 2 3 4; do
    echo "PERIOD_START $p 600 - -"
    [ "$p" != 3 ] || { echo "SUB_OUT 3 590 1 -"; echo "SUB_IN 3 590 8 -"; }
    for i in 0 1 2 3 4 5; do
      k=$((k + 1)); clock=$((570 - i * 90)); s=${shooters[$((k % 7))]}; a=${shooters[$(((k + 3) % 7))]}
      pts=2; [ $((k % 5)) != 0 ] || pts=3; [ $((k % 7)) != 3 ] || pts=1
      made=true; [ $((k % 3)) != 0 ] || made=false
      echo "SHOT $p $clock $s {\"points\":$pts,\"made\":$made}"
      [ "$made" = false ] || echo "ASSIST $p $clock $a -"
      [ $((k % 2)) != 0 ] || echo "OPPONENT_SCORE $p $((clock - 30)) - {\"points\":$((2 + (k % 9 == 0)))}"
      echo "REBOUND $p $((clock - 45)) ${shooters[$(((k + 1) % 7))]} {\"kind\":\"DEFENSIVE\"}"
      [ $((k % 4)) != 0 ] || echo "FOUL $p $((clock - 55)) ${shooters[$(((k + 2) % 7))]} {\"kind\":\"PERSONAL\"}"
      [ $((k % 6)) != 0 ] || echo "STEAL $p $((clock - 60)) ${shooters[$(((k + 4) % 7))]} -"
      [ $((k % 8)) != 0 ] || echo "TURNOVER $p $((clock - 65)) ${shooters[$(((k + 5) % 7))]} -"
    done
    echo "PERIOD_END $p 0 - -"
  done
}

roster_json() { # all ten players, the first five of the picture's order start
  local n starters=" 1 2 4 5 7 " out="" st
  for n in $(seq 1 $PLAYERS); do
    st=false; case "$starters" in *" $n "*) st=true ;; esac
    out="$out$(jq -nc --arg p "$(pid "$n")" --arg j "$((n + 3))" --argjson s "$st" '{playerId: $p, jerseyNumber: $j, isStarter: $s}')"$'\n'
  done
  printf '%s' "$out" | jq -sc '{entries: .}'
}

# ensure_match OPPONENT HOME|AWAY SCHEDULED-EPOCH VENUE TARGET(SCHEDULED|LIVE|FINISHED); events come from SCRIPT-FUNCTION
ensure_match() {
  local opp="$1" ha="$2" at="$3" venue="$4" target="$5" script="${6:-}" mid st seq
  api GET "/api/game/matches?teamId=$TEAM&size=100"; need 200
  mid=$(jq -r --arg o "$opp" '[.items[] | select(.opponentName == $o)] | (first // {}) | .id // empty' "$RESP")
  if [ -z "$mid" ]; then
    api POST /api/game/matches "$(jq -nc --arg t "$TEAM" --arg o "$opp" --arg h "$ha" --arg a "$(iso_of_epoch "$at")" --arg v "$venue" \
      '{teamId: $t, opponentName: $o, homeAway: $h, scheduledAt: $a, venue: $v}')"
    need 201; mid=$(j .id); CREATED=$((CREATED + 1)); say "created match against $opp"
  fi
  api GET "/api/game/matches/$mid"; need 200; st=$(j .status)
  [ "$target" != SCHEDULED ] || return 0
  if [ "$st" = SCHEDULED ]; then
    # the replicated roster may lag a moment behind core: retry while the game service answers 422
    local tries=30
    while :; do
      api PUT "/api/game/matches/$mid/roster" "$(roster_json)"
      [ "$CODE" = 422 ] && [ $((--tries)) -gt 0 ] && { sleep 2; continue; }
      need 200; break
    done
    api POST "/api/game/matches/$mid/start"; need 200; st=LIVE
    CREATED=$((CREATED + 1)); say "started the match against $opp"
  fi
  if [ "$st" = LIVE ]; then
    api POST "/api/game/matches/$mid/events:batch" "$($script | events_json "$mid" "$at")"; need 200
    seq=$(jq -r '[.results[] | select(.status == "ACCEPTED")] | length' "$RESP")
    [ "$seq" = 0 ] || { CREATED=$((CREATED + 1)); say "stored $seq events of the match against $opp"; }
    if [ "$target" = FINISHED ]; then
      api POST "/api/game/matches/$mid/finish"; need 200
      CREATED=$((CREATED + 1)); say "finished the match against $opp"
    fi
  fi
}

# ---- health
ensure_injury() { # playerNo bodyPart severity description occurredDays expectedDays RECOVERED-days|-
  local p; p=$(pid "$1")
  api GET "/api/athlete/injuries?playerId=$p&size=100"; need 200
  if jq -e --arg b "$2" 'any(.items[]; .bodyPart == $b)' "$RESP" >/dev/null; then return 0; fi
  api POST /api/athlete/injuries "$(jq -nc --arg p "$p" --arg o "$(dayin "$5")" --arg b "$2" --arg s "$3" --arg d "$4" --arg e "$(dayin "$6")" \
    '{playerId: $p, occurredOn: $o, bodyPart: $b, severity: $s, description: (if $d == "" then null else $d end), expectedReturnOn: $e} | with_entries(select(.value != null))')"
  need 201; local id; id=$(j .id); CREATED=$((CREATED + 1)); say "recorded injury $2 of player $1"
  if [ "$7" != - ]; then
    api PATCH "/api/athlete/injuries/$id" "$(jq -nc --arg a "$(dayin "$7")" '{status: "RECOVERED", actualReturnOn: $a}')"; need 200
    say "injury of player $1 recovered"
  fi
}

ensure_measurements() { # player number
  local n="$1" p h w; p=$(pid "$n")
  api GET "/api/athlete/body-measurements?playerId=$p&size=100"; need 200
  [ "$(countof 'if type == "array" then length else (.items | length) end')" = 0 ] || return 0
  local ago dh dw
  for spec in "200 0 0" "100 2.5 1.5" "10 4 2.7"; do
    read -r ago dh dw <<<"$spec"
    h=$(LC_ALL=C awk -v n="$n" -v d="$dh" 'BEGIN { printf "%.1f", 146 + n * 1.1 + d }'); w=$(LC_ALL=C awk -v n="$n" -v d="$dw" 'BEGIN { printf "%.1f", 36 + n * 0.8 + d }')
    api POST /api/athlete/body-measurements "$(jq -nc --arg p "$p" --arg m "$(dayin "-$ago")" --argjson h "$h" --argjson w "$w" \
      '{playerId: $p, measuredOn: $m, heightCm: $h, weightKg: $w}')"
    need 201
  done
  CREATED=$((CREATED + 1)); say "recorded 3 body measurements of player $n"
}

ensure_tests() { # player number
  local n="$1" p; p=$(pid "$n")
  api GET "/api/athlete/physical-test-results?playerId=$p&size=200"; need 200
  [ "$(countof 'if type == "array" then length else (.items | length) end')" = 0 ] || return 0
  local spec code ago value tid
  for spec in "SPRINT_20M 120 $(LC_ALL=C awk -v n="$n" 'BEGIN { printf "%.2f", 4.55 - n * 0.03 }')" \
              "SPRINT_20M 20 $(LC_ALL=C awk -v n="$n" 'BEGIN { printf "%.2f", 4.40 - n * 0.03 }')" \
              "VERTICAL_JUMP 20 $((22 + n))" "SIT_AND_REACH 20 $((8 + n % 7))"; do
    read -r code ago value <<<"$spec"
    api GET /api/athlete/physical-test-types; need 200
    tid=$(jq -r --arg c "$code" '.[] | select(.code == $c) | .id' "$RESP")
    api POST /api/athlete/physical-test-results "$(jq -nc --arg p "$p" --arg t "$tid" --arg m "$(dayin "-$ago")" --argjson v "$value" \
      '{playerId: $p, testTypeId: $t, measuredOn: $m, value: $v}')"
    need 201
  done
  CREATED=$((CREATED + 1)); say "recorded 4 physical test results of player $n"
}

seed_demo_data() {
  say "demo data"
  login "$(email testadmin1)" TEST_ACADEMY_PASSWORD || die "testadmin1 cannot sign in with the shared password"
  load_members
  PIDS=""; for n in $(seq 1 $PLAYERS); do PIDS="$PIDS$n $(member_field "$(email "testplayer$n")" 3)"$'\n'; done
  ensure_team_named "Infantil A" TEAM2
  ensure_staff "$TEAM2" testcoach1 COACH
  login "$(email testcoach1)" TEST_ACADEMY_PASSWORD || die "testcoach1 cannot sign in with the shared password"
  # the athlete and game services learn the roster from core's events: wait (deadline) until they know player 7
  local deadline=$((SECONDS + 60))
  while :; do
    api GET "/api/athlete/players/$(pid 7)/availability"; local a=$CODE
    api GET "/api/game/players/$(pid 7)/season-stats?seasonId=$SEASON"; local g=$CODE
    [ "$a" = 200 ] && [ "$g" = 200 ] && break
    [ "$SECONDS" -lt "$deadline" ] || die "athlete/game replicas do not know the players within 60 s (athlete $a, game $g)"
    sleep 1
  done
  ensure_schedules
  ensure_past_sessions
  ensure_done_and_attendance
  ensure_training_extras
  ensure_match Lobos HOME "$(( $(date +%s) - 7 * 86400 ))" "Pabellón Norte" FINISHED lobos_script
  ensure_match Tigres HOME "$(( $(date +%s) - 25 * 60 ))" "Pabellón Norte" LIVE tigres_script
  ensure_match Águilas AWAY "$(( $(date +%s) + 3 * 86400 ))" "Pabellón Norte" SCHEDULED
  ensure_injury 7 "rodilla izquierda" MODERATE "Golpe en un entrenamiento" -6 12 -
  ensure_injury 4 "tobillo derecho" MINOR "" -60 -50 -52
  for n in 1 2 4 5 7 8 10; do ensure_measurements "$n"; ensure_tests "$n"; done
}
[ "${SEED_ACADEMY_DEMO:-1}" = 0 ] || seed_demo_data

# Record the list of logins in .env (once; other lines untouched) and print it.
LIST=""; for u in $USERS; do LIST="$LIST,$(email "$u")"; done; LIST="${LIST#,}"
if [ -f .env ] && ! grep -qxF "TEST_ACADEMY_USERS=$LIST" .env; then
  if grep -q '^TEST_ACADEMY_USERS=' .env; then grep -v '^TEST_ACADEMY_USERS=' .env >"$WORK/env" && cat "$WORK/env" >.env; fi
  [ -z "$(tail -c1 .env)" ] || echo >>.env
  echo "TEST_ACADEMY_USERS=$LIST" >>.env
  say "set TEST_ACADEMY_USERS in .env"
fi
echo "Test Academy logins (shared password: TEST_ACADEMY_PASSWORD in .env):"
for u in $USERS; do echo "  $(email "$u")"; done
if [ "$CREATED" = 0 ]; then
  say "nothing to create (passwords reset, all logins verified) in ${SECONDS}s"
else
  say "done: $CREATED things created in ${SECONDS}s"
fi
