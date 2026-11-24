#!/usr/bin/env bash
# kind only: reads the CloudNativePG operator Deployment (JSON) on stdin and prints the JSON patch deploy/kind/up.sh applies.
# - no leader election (WP86): under VM load the single replica lost its lease and crash-looped;
# - probes for a busy 2-CPU Podman VM (WP146): upstream gives 1 s timeouts and a 30 s startup budget; at a VM load of 68
#   (a Maven build beside the install) they killed the operator into CrashLoopBackOff and its webhook refused helm's apply
#   of the Clusters. Now 5 s timeouts, 5 minutes to start, a kill only after a minute of failed liveness checks.
# The cloud VM keeps the upstream manifest (deploy/lib/platform.sh). Tested by scripts/tests/kind-cnpg-patch.test.sh.
set -euo pipefail
jq -c '.spec.template.spec.containers[0] as $c
  | if $c.name != "manager" then error("first container is \($c.name), not the CNPG manager") else . end
  | "/spec/template/spec/containers/0/" as $p
  | [ {op: "replace", path: ($p + "args"),
       value: ($c.args | map(if . == "--leader-elect" then "--leader-elect=false" else . end))},
      {op: "replace", path: ($p + "startupProbe"),   value: ($c.startupProbe + {timeoutSeconds: 5, periodSeconds: 5, failureThreshold: 60})},
      {op: "replace", path: ($p + "livenessProbe"),  value: ($c.livenessProbe + {timeoutSeconds: 5, periodSeconds: 10, failureThreshold: 6})},
      {op: "replace", path: ($p + "readinessProbe"), value: ($c.readinessProbe + {timeoutSeconds: 5})} ]'
