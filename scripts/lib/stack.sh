# shellcheck shell=bash
# The local stack's facts the start, stop and check scripts share (INF-12). Sourced by start.sh, stop.sh,
# scripts/doctor.sh and e2e/bin/services-up.sh. infra/compose/nginx.conf names the same ports (its upstreams).

# The Flutter web app (debug server or the release build) and the origin the realm allows for it.
WEB_PORT=5173
# Host port of each service as nginx and the scripts reach it (bash 3.2: no associative arrays).
service_port() {
  case "$1" in core) echo 8081 ;; game) echo 8082 ;; athlete) echo 8083 ;; pdf) echo 8084 ;; finance) echo 8085 ;;
    *) echo "service_port: unknown service $1" >&2; return 1 ;; esac
}
# The Java services e2e/bin/services-up.sh starts on the host (pdf and finance run in compose).
JAVA_SERVICES="core game athlete"
# True when the Podman machine runs.
machine_running() { podman machine inspect --format '{{.State}}' 2>/dev/null | grep -q running; }
