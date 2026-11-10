#!/usr/bin/env bash
# Seeds the local test academy "Test Academy" through the public and platform API (WP103, decision 74):
# 2 admins, 1 coach, 10 players (each with a login), 10 parents (parent N linked to player N), one season, one
# age category, one team with the ten players. Every login gets the shared final password TEST_ACADEMY_PASSWORD
# (kcadm set-password, not temporary, no required action, e-mail verified) and is signed in once, which accepts the
# invitation. Idempotent: looks things up before creating, resets the passwords on every run.
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
  local method="$1" path="$2" body="${3:-}"
  { printf 'Authorization: Bearer %s\n' "$TOKEN"; [ -z "$TENANT" ] || printf 'X-Tenant-Id: %s\n' "$TENANT"; } >"$HDR"
  chmod 600 "$HDR"
  if [ -n "$body" ]; then
    CODE=$(printf '%s' "$body" | curl -sS -o "$RESP" -w '%{http_code}' -X "$method" -H @"$HDR" \
      -H 'Content-Type: application/json' --data-binary @- "$BASE$path") || die "request $method $path failed"
  else
    CODE=$(curl -sS -o "$RESP" -w '%{http_code}' -X "$method" -H @"$HDR" "$BASE$path") || die "request $method $path failed"
  fi
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

ensure_team() {
  api GET /api/core/age-categories; need 200
  CATEGORY=$(jq -r '.[] | select(.code == "U14") | .id' "$RESP")
  MAXAGE=$(jq -r '.[] | select(.code == "U14") | .maxAge' "$RESP")
  [ -n "$CATEGORY" ] && [ "$MAXAGE" != null ] || die "the academy has no age category U14"
  api GET "/api/core/teams?seasonId=$SEASON"; need 200
  TEAM=$(jq -r --arg n "$TEAM_NAME" '(.items // .)[] | select(.name == $n) | .id' "$RESP" | head -n1)
  [ -z "$TEAM" ] || return 0
  api POST /api/core/teams "$(jq -nc --arg s "$SEASON" --arg c "$CATEGORY" --arg n "$TEAM_NAME" \
    '{seasonId: $s, name: $n, ageCategoryId: $c, genderPolicy: "MIXED"}')"
  need 201; TEAM=$(j .id); CREATED=$((CREATED + 1)); say "created team $TEAM_NAME"
}

ensure_coach_staff() {
  local pid; pid=$(member_field "$(email testcoach1)" 2)
  api GET "/api/core/teams/$TEAM/staff"; need 200
  if jq -e --arg p "$pid" 'any(.[]; .person.personId == $p and .role == "COACH")' "$RESP" >/dev/null; then return 0; fi
  api PUT "/api/core/teams/$TEAM/staff/$pid" '{"role":"COACH"}'; need 200
  CREATED=$((CREATED + 1)); say "testcoach1 is the coach of $TEAM_NAME"
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
for n in $(seq 1 $PLAYERS); do ensure_member "testparentplayer$n" Test "Parent of Player $n" PARENT; done
ensure_season
ensure_team
load_members
ensure_coach_staff
api GET "/api/core/teams/$TEAM/players"; need 200; ROSTER="$WORK/roster.json"; cp "$RESP" "$ROSTER"
for n in $(seq 1 $PLAYERS); do ensure_player "$n"; done
load_members
api GET "/api/core/guardian-links?size=200"; need 200; LINKS="$WORK/links.json"; cp "$RESP" "$LINKS"
for n in $(seq 1 $PLAYERS); do ensure_guardian_link "$n"; done

# Final passwords for everybody, then one sign-in each: proves no required action is left and accepts the invitation
# (first /api/core/me). Game and athlete read the roster from their replicas: each parent is polled (deadline, no blind
# sleep) until game and athlete treat the parent as the child's guardian.
USERS="testadmin1 testadmin2 testcoach1"
for n in $(seq 1 $PLAYERS); do USERS="$USERS testplayer$n"; done
for n in $(seq 1 $PLAYERS); do USERS="$USERS testparentplayer$n"; done
emails=(); for u in $USERS; do emails+=("$(email "$u")"); done
finalize_logins "${emails[@]}"
for u in $USERS; do
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

# Record the list of logins in .env (once; other lines untouched) and print it.
LIST=""; for u in $USERS; do LIST="$LIST,$(email "$u")"; done; LIST="${LIST#,}"
if [ -f .env ] && ! grep -q '^TEST_ACADEMY_USERS=' .env; then
  [ -z "$(tail -c1 .env)" ] || echo >>.env
  echo "TEST_ACADEMY_USERS=$LIST" >>.env
  say "added TEST_ACADEMY_USERS to .env"
fi
echo "Test Academy logins (shared password: TEST_ACADEMY_PASSWORD in .env):"
for u in $USERS; do echo "  $(email "$u")"; done
if [ "$CREATED" = 0 ]; then
  say "nothing to create (passwords reset, all logins verified) in ${SECONDS}s"
else
  say "done: $CREATED things created in ${SECONDS}s"
fi
