#!/usr/bin/env bash
# Bootstrap Job of the chart's Redpanda (WP66, ADR-0036): makes the broker match the values on every install and upgrade.
#   1. cluster properties (CONFIG_DIR/cluster-config: "<key> <value>" lines), e.g. kafka_enable_authorization true
#   2. one SCRAM-SHA-256 user per service (CONFIG_DIR/users: "<index> <name> <produce> <consume> <groups>", comma
#      separated prefixes, "-" for none; the password is $USER_PASSWORD_<index>): created when missing, otherwise its
#      password is set again (that is how a rotated Secret reaches the broker)
#   3. prefixed ACLs: produce = write+describe on topics, consume = read+describe on topics, groups = read+describe on
#      consumer groups (an ACL removed from the values stays until deleted by hand, docs/runbooks/events.md)
#   4. topics (CONFIG_DIR/topics, CONFIG_DIR/topic-config "<key>=<value>" lines, $PARTITIONS): created when missing,
#      configuration applied again when present (partitions are never changed here)
# Logs in as the superuser $SUPERUSER / $SUPERUSER_PASSWORD (the broker created it at bootstrap from RP_BOOTSTRAP_USER).
# Passwords stay in environment variables and stdin: rpk reads RPK_USER/RPK_PASS, curl reads the admin login from a
# netrc on a file descriptor and the JSON body from stdin, so no secret is on a command line.
set -euo pipefail
: "${BROKERS:?}" "${ADMIN_URL:?}" "${SUPERUSER:?}" "${CONFIG_DIR:?}" "${PARTITIONS:?}"
: "${SUPERUSER_PASSWORD:?the superuser Secret has an empty password}"
export HOME=/tmp RPK_BROKERS="$BROKERS" RPK_ADMIN_HOSTS="${ADMIN_URL#http://}" RPK_USER="$SUPERUSER" \
  RPK_PASS="$SUPERUSER_PASSWORD" RPK_SASL_MECHANISM=SCRAM-SHA-256
admin_host="${RPK_ADMIN_HOSTS%%:*}"
log() { printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*"; }

log "waiting for $ADMIN_URL/v1/status/ready"
for i in $(seq 1 60); do
  curl -sf -o /dev/null "$ADMIN_URL/v1/status/ready" && break
  [ "$i" = 60 ] && { log "broker not ready after 5 min"; exit 1; }
  sleep 5
done

log "cluster properties"
while read -r key value; do
  [ -n "$key" ] || continue
  rpk cluster config set "$key" "$value" >/dev/null
  log "  $key = $(rpk cluster config get "$key")"
done < "$CONFIG_DIR/cluster-config"

json_escape() { local s="${1//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "$s"; }
admin_netrc() { printf 'machine %s login %s password %s\n' "$admin_host" "$SUPERUSER" "$SUPERUSER_PASSWORD"; }
admin_call() { # method path name password -> HTTP status; JSON body on stdin, admin login from a netrc on an fd
  printf '{"username":"%s","password":"%s","algorithm":"SCRAM-SHA-256"}' "$(json_escape "$3")" "$(json_escape "$4")" |
    curl -s -o /dev/null -w '%{http_code}' -X "$1" -H 'Content-Type: application/json' --data-binary @- \
      --netrc-file <(admin_netrc) "$ADMIN_URL$2"
}
acl() { # principal operations resource-type prefixes
  local p IFS=,
  [ "$4" = - ] && return 0
  for p in $4; do
    rpk security acl create --allow-principal "User:$1" --operation "$2" "--$3" "$p" --resource-pattern-type prefixed >/dev/null
    log "  ACL User:$1 $2 on $3 prefix $p"
  done
}

log "users and ACLs"
# Existing users get their password set again (PUT); a POST for an existing user with another password answers 500.
existing_users=$(curl -sf --netrc-file <(admin_netrc) "$ADMIN_URL/v1/security/users")
while read -r index name produce consume groups; do
  [ -n "$index" ] || continue
  var="USER_PASSWORD_$index"; pw="${!var:-}"
  [ -n "$pw" ] || { log "user $name: empty password (Secret)"; exit 1; }
  if grep -q "\"$name\"" <<<"$existing_users"; then
    code=$(admin_call PUT "/v1/security/users/$name" "$name" "$pw"); what="password set again"
  else
    code=$(admin_call POST /v1/security/users "$name" "$pw"); what="created"
  fi
  case "$code" in 2??) log "  user $name (SCRAM-SHA-256) $what from its Secret" ;;
    *) log "user $name: $what -> HTTP $code"; exit 1 ;; esac
  acl "$name" write,describe topic "$produce"
  acl "$name" read,describe topic "$consume"
  acl "$name" read,describe group "$groups"
done < "$CONFIG_DIR/users"

log "topics"
create_flags=() set_flags=()
while read -r kv; do [ -n "$kv" ] && create_flags+=(-c "$kv") && set_flags+=(--set "$kv"); done < "$CONFIG_DIR/topic-config"
existing=$(rpk topic list | awk 'NR > 1 {print $1}')
while read -r topic; do
  [ -n "$topic" ] || continue
  if grep -qx -- "$topic" <<<"$existing"; then
    rpk topic alter-config "$topic" "${set_flags[@]}" >/dev/null; log "  kept    $topic"
  else
    rpk topic create "$topic" -p "$PARTITIONS" -r 1 "${create_flags[@]}" >/dev/null; log "  created $topic"
  fi
done < "$CONFIG_DIR/topics"
rpk topic list
log "bootstrap done"
