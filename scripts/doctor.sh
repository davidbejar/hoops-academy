#!/usr/bin/env bash
# Checks that the local toolchain matches what the build expects. Exit code 1 if anything blocking is missing.
# Sourced by scripts/tests/doctor-podman-dropin.test.sh: the checks run only when executed.
set -uo pipefail
ok=0; fail=0
check() { # name, command, [required]
  local name="$1" cmd="$2" req="${3:-required}"
  if out=$(bash -c "$cmd" 2>&1); then printf '  \033[32m✔\033[0m %-26s %s\n' "$name" "$(echo "$out" | head -1)"; ok=$((ok+1));
  else printf '  \033[31m✘\033[0m %-26s %s\n' "$name" "missing ($req)"; [ "$req" = required ] && fail=$((fail+1)); fi
}

# The Podman API service must run with --time=0, or its idle exit drops Testcontainers/compose connections
# ("localhost:2375 failed to respond"). A machine made with infra/podman/machine-playbook.yml has the drop-in; an older
# one gets it here. One ssh call reads the unit; only a missing drop-in costs more. The service is restarted only when
# no container runs (a restart ends the API connection other builds use), otherwise the restart is left pending.
# shellcheck disable=SC2016 # expanded by the shell inside the machine
PODMAN_DROPIN_DIR='$HOME/.config/systemd/user/podman.service.d'
effective_execstart() { grep -E '^ExecStart=.+' <<<"$1" | tail -1; }
ensure_podman_dropin() {
  local unit running exec_line
  unit=$(podman machine ssh 'systemctl --user cat podman.service' 2>&1) || { echo "cannot read podman.service in the machine"; return 1; }
  if grep -qE '^ExecStart=.*--time=0' <<<"$unit"; then
    echo "drop-in present: $(effective_execstart "$unit")"
    return 0
  fi
  running=$(podman machine ssh "mkdir -p $PODMAN_DROPIN_DIR && printf '%s\\n' '[Service]' 'ExecStart=' 'ExecStart=/usr/bin/podman \$LOGGING system service --time=0' > $PODMAN_DROPIN_DIR/no-timeout.conf && systemctl --user daemon-reload && echo RUNNING=\$(podman ps -q | wc -l)" 2>&1 | sed -n 's/^RUNNING=//p') || true
  [ -n "$running" ] || { echo "could not write the drop-in"; return 1; }
  unit=$(podman machine ssh 'systemctl --user cat podman.service' 2>&1)
  exec_line=$(effective_execstart "$unit")
  if [ "$running" -eq 0 ]; then
    podman machine ssh 'systemctl --user restart podman.service' >/dev/null 2>&1 || { echo "drop-in written, restart failed"; return 1; }
    echo "drop-in written, service restarted: $exec_line"
  else
    echo "drop-in written; restart is pending, $running container(s) running (podman machine ssh 'systemctl --user restart podman.service' when idle): $exec_line"
  fi
}

main() {
echo "Toolchain:"
check "JDK 25"            "test -n \"\${JAVA_HOME:-}\" && \"\$JAVA_HOME/bin/java\" -version 2>&1 | grep -E '\"25\.' "
check "maven"             "mvn -v | head -1"
check "podman"            "podman --version"
check "podman machine"    "podman machine inspect --format '{{.State}} rootful={{.Rootful}} cpus={{.Resources.CPUs}} mem={{.Resources.Memory}}MiB' | grep running"
check "podman compose"    "podman compose version 2>/dev/null | grep -i version | head -1"
if podman machine inspect --format '{{.State}}' 2>/dev/null | grep -q running; then
  if out=$(ensure_podman_dropin); then printf '  \033[32m✔\033[0m %-26s %s\n' "podman API --time=0" "$out"; ok=$((ok+1));
  else printf '  \033[31m✘\033[0m %-26s %s\n' "podman API --time=0" "$out"; fail=$((fail+1)); fi
fi
check "kind"              "kind --version" optional
check "helm"              "helm version --short" optional
check "tilt"              "tilt version" optional
check "kubectl"           "kubectl version --client 2>/dev/null | head -1" optional
check "flutter"           "flutter --version | head -1"
check "gitleaks"          "gitleaks version"
check "pre-commit"        "pre-commit --version"
check "openapi-generator" "openapi-generator --version 2>&1 | head -1"
check "trivy"             "trivy --version | head -1" optional
check "just"              "just --version"
echo "Environment (source scripts/env.sh first):"
check "DOCKER_HOST"       "test -n \"\${DOCKER_HOST:-}\" && echo \$DOCKER_HOST"
check "ryuk"              "if grep -qs '^ryuk.container.privileged=true' ~/.testcontainers.properties; then echo 'privileged (rootful)'; elif [ \"\${TESTCONTAINERS_RYUK_DISABLED:-}\" = true ]; then echo 'disabled (rootless machine)'; else exit 1; fi"
check "docker API via podman" "curl -s --unix-socket \"\${DOCKER_HOST#unix://}\" http://d/_ping"
echo
echo "$ok ok, $fail blocking problems"
[ "$fail" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
