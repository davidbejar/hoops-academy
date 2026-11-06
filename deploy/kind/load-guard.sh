# shellcheck shell=bash
# Sourced by deploy/kind/ratelimit-check.sh and deploy/kind/smoke.sh (WP87; docs/runbooks/troubleshooting.md, symptom D).
# Their timing (one rate-limit window per paced burst, a tight burst inside one second, events within seconds) only holds
# on a quiet machine. kind runs inside the Podman VM, whose vCPUs are threads of this host, so both loads count: the
# machine is busy when the 1-minute load average of the VM or of the host is above HOOPS_MAX_LOAD_PER_CPU (default 2) per
# CPU, i.e. 4 on the 2-CPU VM (WP63: the checks failed at a VM load of 25-37 and were exact below ~5).
MAX_LOAD_PER_CPU="${HOOPS_MAX_LOAD_PER_CPU:-2}"
LOAD_LINE=""

# "<1-minute load> <CPUs>" of this host and, on macOS, of the Podman VM (empty when podman is not there)
host_load() {
  if [ -r /proc/loadavg ]; then echo "$(cut -d' ' -f1 /proc/loadavg) $(getconf _NPROCESSORS_ONLN)"
  else echo "$(LC_ALL=C sysctl -n vm.loadavg | awk '{print $2}') $(sysctl -n hw.ncpu)"; fi
}
vm_load() {
  [ "$(uname -s)" = Darwin ] && command -v podman >/dev/null || return 0
  # shellcheck disable=SC2016 # expanded inside the VM
  podman machine ssh 'echo "$(cut -d" " -f1 /proc/loadavg) $(nproc)"' 2>/dev/null | tr -d '\r' || true
}

# Sets LOAD_LINE (printable) and succeeds when the VM or the host is above the threshold.
machine_busy() {
  local vm host
  vm=$(vm_load); host=$(host_load)
  LOAD_LINE="Podman VM load ${vm% *} on ${vm#* } CPUs, host ${host% *} on ${host#* } CPUs (threshold $MAX_LOAD_PER_CPU per CPU)"
  [ -n "$vm" ] || LOAD_LINE="host load ${host% *} on ${host#* } CPUs (threshold $MAX_LOAD_PER_CPU per CPU)"
  LC_ALL=C awk -v m="$MAX_LOAD_PER_CPU" -v a="$vm" -v b="$host" 'BEGIN {
    split(a, v, " "); split(b, h, " ")
    exit !((v[2] > 0 && v[1] > m * v[2]) || (h[2] > 0 && h[1] > m * h[2])) }'
}

# Waits up to $1 seconds (default HOOPS_LOAD_WAIT, 0) for a quiet machine; succeeds when it is quiet.
wait_for_quiet_machine() {
  local deadline=$(( $(date +%s) + ${1:-${HOOPS_LOAD_WAIT:-0}} ))
  while machine_busy; do
    [ "$(date +%s)" -lt "$deadline" ] || return 1
    echo "  (busy: $LOAD_LINE; waiting)"
    sleep 30
  done
}
