#!/usr/bin/env bash
# Checks that the local toolchain matches what the build expects. Exit code 1 if anything blocking is missing.
set -uo pipefail
ok=0; fail=0
check() { # name, command, [required]
  local name="$1" cmd="$2" req="${3:-required}"
  if out=$(bash -c "$cmd" 2>&1); then printf '  \033[32m✔\033[0m %-26s %s\n' "$name" "$(echo "$out" | head -1)"; ok=$((ok+1));
  else printf '  \033[31m✘\033[0m %-26s %s\n' "$name" "missing ($req)"; [ "$req" = required ] && fail=$((fail+1)); fi
}
echo "Toolchain:"
check "JDK 21"            "test -n \"\${JAVA_HOME:-}\" && \"\$JAVA_HOME/bin/java\" -version 2>&1 | grep -E '\"21\.' "
check "maven"             "mvn -v | head -1"
check "podman"            "podman --version"
check "podman machine"    "podman machine inspect --format '{{.State}} rootful={{.Rootful}} cpus={{.Resources.CPUs}} mem={{.Resources.Memory}}MiB' | grep running"
check "podman compose"    "podman compose version 2>&1 | head -1"
check "kind"              "kind --version" optional
check "helm"              "helm version --short" optional
check "tilt"              "tilt version" optional
check "kubectl"           "kubectl version --client | head -1" optional
check "flutter"           "flutter --version | head -1"
check "gitleaks"          "gitleaks version"
check "pre-commit"        "pre-commit --version"
check "openapi-generator" "openapi-generator --version 2>&1 | head -1"
check "trivy"             "trivy --version | head -1" optional
check "just"              "just --version"
echo "Environment (source scripts/env.sh first):"
check "DOCKER_HOST"       "test -n \"\${DOCKER_HOST:-}\" && echo \$DOCKER_HOST"
check "ryuk privileged"   "grep -q '^ryuk.container.privileged=true' ~/.testcontainers.properties && echo configured || test \"\${TESTCONTAINERS_RYUK_DISABLED:-}\" = true && echo 'disabled (rootless)'"
check "docker API via podman" "curl -s --unix-socket \"\${DOCKER_HOST#unix://}\" http://d/_ping"
echo
echo "$ok ok, $fail blocking problems"
[ "$fail" -eq 0 ]
