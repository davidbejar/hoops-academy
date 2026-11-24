#!/usr/bin/env bash
# Tests deploy/kind/cnpg-patch.sh (WP146), the kind-only JSON patch of the CloudNativePG operator, against the operator
# Deployment as release 1.30.2 ships it (trimmed). Under a busy Podman VM (load 68 on 2 CPUs, a Maven build beside the
# kind install) the upstream probes (1 s timeouts, a 30 s startup budget) killed the operator into CrashLoopBackOff, so its
# webhook refused helm's apply of the Clusters. Also checks that up.sh applies the patch and waits for the operator to be
# Available right before `helm upgrade` (the image build in between takes minutes). No cluster needed: jq only.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
fail=0 total=0

upstream='{"spec":{"template":{"spec":{"containers":[{"name":"manager","args":["controller","--leader-elect",
 "--max-concurrent-reconciles=10","--config-map-name=cnpg-controller-manager-config","--webhook-port=9443"],
 "startupProbe":{"failureThreshold":6,"httpGet":{"path":"/readyz","port":9443,"scheme":"HTTPS"},"periodSeconds":5},
 "livenessProbe":{"httpGet":{"path":"/readyz","port":9443,"scheme":"HTTPS"},"periodSeconds":10},
 "readinessProbe":{"httpGet":{"path":"/readyz","port":9443,"scheme":"HTTPS"},"periodSeconds":10}}]}}}}'

check() { # check <label> <jq filter on the patch, true when right>
  total=$((total + 1))
  [ "$(jq -r "$2" <<<"$patch" 2>/dev/null)" = true ] && return 0
  fail=$((fail + 1)); printf 'FAIL %s\n' "$1"
}
value() { # value <field of the container>: the value the patch sets
  printf '(map(select(.path == "/spec/template/spec/containers/0/%s")) | .[0].value)' "$1"
}

patch=$(deploy/kind/cnpg-patch.sh <<<"$upstream" 2>&1)
check "the patch is a JSON patch of replace operations" 'type == "array" and length > 0 and all(.op == "replace")'
check "no leader election, the other arguments kept" \
  "$(value args) == [\"controller\",\"--leader-elect=false\",\"--max-concurrent-reconciles=10\",\"--config-map-name=cnpg-controller-manager-config\",\"--webhook-port=9443\"]"
check "startup budget of at least 5 minutes" "$(value startupProbe) | .periodSeconds * .failureThreshold >= 300"
check "probe timeouts of at least 5 s (default 1 s)" \
  "[$(value startupProbe), $(value livenessProbe), $(value readinessProbe)] | all(.timeoutSeconds >= 5)"
check "liveness kills only after a minute of failures" "$(value livenessProbe) | .periodSeconds * .failureThreshold >= 60"
check "the probes still ask /readyz on the webhook port" \
  "[$(value startupProbe), $(value livenessProbe), $(value readinessProbe)] | all(.httpGet.path == \"/readyz\" and .httpGet.port == 9443)"

total=$((total + 1))
if deploy/kind/cnpg-patch.sh <<<"${upstream/\"manager\"/\"other\"}" >/dev/null 2>&1; then
  fail=$((fail + 1)); echo "FAIL a Deployment whose first container is not the manager is refused"
fi

# up.sh: the patch is applied, and the operator must be Available (webhook served) right before helm applies the chart
total=$((total + 1))
grep -q 'deploy/kind/cnpg-patch.sh' deploy/kind/up.sh || { fail=$((fail + 1)); echo "FAIL up.sh does not apply cnpg-patch.sh"; }
total=$((total + 1))
awk '/wait --for=condition=Available deployment\/cnpg-controller-manager/ {w=NR} /upgrade --install hoops / {h=NR}
  END {exit !(w && h && w < h)}' deploy/kind/up.sh \
  || { fail=$((fail + 1)); echo "FAIL up.sh does not wait for the CNPG operator to be Available before helm upgrade"; }

echo "kind-cnpg-patch: $((total - fail))/$total passed"
[ "$fail" -eq 0 ]
