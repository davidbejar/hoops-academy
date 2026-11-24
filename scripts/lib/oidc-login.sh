# shellcheck shell=bash
# Browser-less OpenID Connect sign-in of a user, as the app performs it: authorization code + PKCE (S256) of client `web`
# (INF-02: the one copy for events-backfill.sh, seed-academy.sh, deploy/kind/smoke.sh, apps/web/tool/keycloak_login_check.sh).
# Source it, then:
#   oidc_login ISSUER REDIRECT_URI USERNAME PASSWORD_VARIABLE [SCOPE]
# ISSUER is the realm as the browser sees it (e.g. http://localhost:8080/auth/realms/academy), REDIRECT_URI one of the
# client's registered URIs, PASSWORD_VARIABLE the NAME of the variable holding the password (read here, sent on stdin,
# never on a command line). SCOPE defaults to the app's "openid profile email offline_access"; OIDC_CLIENT_ID to web.
# Sets OIDC_ACCESS_TOKEN and OIDC_REFRESH_TOKEN and prints nothing. Returns 1 when Keycloak shows no login form, redirects
# without a code or with another state (wrong password, pending required action, unregistered redirect URI) or refuses the
# code; 2 when a gateway rate limit answered 429 (callers may wait and retry). Needs curl and openssl.

oidc_login() {
  local dir rc=0
  OIDC_ACCESS_TOKEN="" OIDC_REFRESH_TOKEN=""
  dir=$(mktemp -d) || return 1
  _oidc_login_in "$dir" "$@" || rc=$?
  rm -rf "$dir"
  return "$rc"
}

_oidc_b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# _oidc_field JSON-FILE NAME: a string member of the token response
_oidc_field() { tr -d '\n' <"$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }

_oidc_login_in() {
  local dir="$1" issuer="$2" redirect="$3" user="$4" pwvar="$5" scope="${6:-openid profile email offline_access}"
  local client="${OIDC_CLIENT_ID:-web}" jar="$1/jar" verifier challenge state hc action loc
  verifier=$(openssl rand 48 | _oidc_b64url)
  challenge=$(printf '%s' "$verifier" | openssl dgst -sha256 -binary | _oidc_b64url)
  state=$(openssl rand -hex 16)
  hc=$(curl -sS -o "$dir/form" -w '%{http_code}' -c "$jar" -b "$jar" -G "$issuer/protocol/openid-connect/auth" \
    --data-urlencode "client_id=$client" --data-urlencode response_type=code --data-urlencode "redirect_uri=$redirect" \
    --data-urlencode "scope=$scope" --data-urlencode "state=$state" \
    --data-urlencode "code_challenge=$challenge" --data-urlencode code_challenge_method=S256 2>/dev/null) || return 1
  [ "$hc" != 429 ] || return 2
  action=$(tr '\n' ' ' <"$dir/form" | sed -n 's/.*id="kc-form-login"[^>]*action="\([^"]*\)".*/\1/p' | sed 's/&amp;/\&/g')
  [ -n "$action" ] || return 1
  # the password goes from the variable through printf (a builtin) to curl's stdin, URL-encoded by curl
  printf '%s' "${!pwvar}" | curl -sS -o /dev/null -D "$dir/login" -c "$jar" -b "$jar" "$action" \
    --data-urlencode "username=$user" --data-urlencode "password@-" 2>/dev/null || return 1
  loc=$(tr -d '\r' <"$dir/login" | sed -n 's/^[Ll]ocation: //p')
  if [ -z "$loc" ] && grep -q '^HTTP/[0-9.]* 429' "$dir/login"; then return 2; fi
  case "$loc" in "$redirect"*) ;; *) return 1 ;; esac
  [ "$(printf '%s' "$loc" | sed -n 's/.*[?&]state=\([^&#]*\).*/\1/p')" = "$state" ] || return 1
  printf '%s' "$loc" | sed -n 's/.*[?&]code=\([^&#]*\).*/\1/p' >"$dir/code"
  [ -s "$dir/code" ] || return 1
  hc=$(curl -sS -o "$dir/tokens" -w '%{http_code}' "$issuer/protocol/openid-connect/token" \
    -d grant_type=authorization_code --data-urlencode "client_id=$client" --data-urlencode "code@$dir/code" \
    --data-urlencode "redirect_uri=$redirect" --data-urlencode "code_verifier=$verifier" 2>/dev/null) || return 1
  [ "$hc" != 429 ] || return 2
  [ "$hc" = 200 ] || return 1
  OIDC_ACCESS_TOKEN=$(_oidc_field "$dir/tokens" access_token)
  # shellcheck disable=SC2034  # read by the caller
  OIDC_REFRESH_TOKEN=$(_oidc_field "$dir/tokens" refresh_token)
  [ -n "$OIDC_ACCESS_TOKEN" ]
}
