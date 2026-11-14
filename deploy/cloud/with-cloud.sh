#!/usr/bin/env bash
# Runs a deploy/kind script (smoke.sh, seed-users.sh, ratelimit-check.sh) against the cloud deployment (WP104). Those
# scripts address the cluster as context kind-$KIND_CLUSTER and the gateway as $HOOPS_BASE_URL, so this gives them a
# temporary copy of the cloud kubeconfig whose context is named kind-hoops-cloud (mode 600, removed on exit), the public
# URL from the tofu outputs, and the gateway's self-signed certificate as curl's CA bundle. They read .env as on kind.
# NOT YET RUN: no cloud account this round (decision 77).
#   deploy/cloud/with-cloud.sh deploy/kind/smoke.sh core game athlete      (= just cloud-smoke core game athlete)
#   deploy/cloud/with-cloud.sh deploy/kind/seed-users.sh                   (= just cloud-seed-users)
set -euo pipefail
cd "$(dirname "$0")/../.."
# shellcheck source=deploy/cloud/lib.sh
. deploy/cloud/lib.sh
need tofu kubectl
[ $# -ge 1 ] && [ -x "$1" ] || { echo "usage: deploy/cloud/with-cloud.sh deploy/kind/<script>.sh [args...]" >&2; exit 2; }
[ -s "$CLOUD_KUBECONFIG" ] || { echo "with-cloud.sh: $CLOUD_KUBECONFIG missing: just cloud-kubeconfig" >&2; exit 1; }
[ -s "$CLOUD_CERT" ] || { echo "with-cloud.sh: $CLOUD_CERT missing: just cloud-install <tag> writes it" >&2; exit 1; }

url=$(tofu_output public_url)
umask 077
cfg=$(mktemp)
trap 'rm -f "$cfg"' EXIT
KUBECONFIG="$CLOUD_KUBECONFIG" kubectl config view --raw --minify --context "$CLOUD_CONTEXT" > "$cfg"
KUBECONFIG="$cfg" kubectl config rename-context "$CLOUD_CONTEXT" "kind-$CLOUD_CONTEXT" >/dev/null

KUBECONFIG="$cfg" KIND_CLUSTER="$CLOUD_CONTEXT" HOOPS_BASE_URL="$url" CURL_CA_BUNDLE="$CLOUD_CERT" "$@"
