#!/usr/bin/env bash
# Source this file: `source scripts/env.sh`
# Sets JAVA_HOME to JDK 25 and points Docker-API clients (Testcontainers, Quarkus Dev Services, Tilt) at Podman.

# Pick a JDK whose major version is exactly _JDK_MAJOR (java_home -v 25 would also accept newer JDKs). An already-set
# JAVA_HOME (CI: actions/setup-java) or the java on PATH wins when it has that major. Keep it equal to
# maven.compiler.release in pom.xml (scripts/tests/test_jdk_pins.py).
_JDK_MAJOR=25
_is_jdk() { [ -n "$1" ] && [ -x "$1/bin/java" ] && "$1/bin/java" -version 2>&1 | grep -q "\"${_JDK_MAJOR}\\."; }
_pick_jdk() {
  local c
  if _is_jdk "${JAVA_HOME:-}"; then echo "$JAVA_HOME"; return 0; fi
  c=$(command -v java 2>/dev/null) && c=$(cd "$(dirname "$(readlink -f "$c" 2>/dev/null || echo "$c")")/.." && pwd) \
    && _is_jdk "$c" && { echo "$c"; return 0; }
  for c in "/opt/homebrew/opt/openjdk@${_JDK_MAJOR}/libexec/openjdk.jdk/Contents/Home" \
           "/usr/local/opt/openjdk@${_JDK_MAJOR}/libexec/openjdk.jdk/Contents/Home" \
           "$(/usr/libexec/java_home -v "${_JDK_MAJOR}" 2>/dev/null || true)"; do
    if _is_jdk "$c"; then echo "$c"; return 0; fi
  done
  return 1
}
if JH=$(_pick_jdk); then
  export JAVA_HOME="$JH"
else
  echo "warn: JDK ${_JDK_MAJOR} not found (run scripts/bootstrap.sh)" >&2
fi
[ -n "${JAVA_HOME:-}" ] && export PATH="$JAVA_HOME/bin:$PATH"

# Podman API socket for Docker-API clients. macOS: the podman machine's forwarded socket. Linux (CI): the rootless
# service socket, or whatever DOCKER_HOST already points at. Every probe tolerates failure (callers may run with set -e).
if command -v podman >/dev/null 2>&1; then
  SOCK=""
  if [ -n "${DOCKER_HOST:-}" ] && [ -S "${DOCKER_HOST#unix://}" ]; then
    SOCK="${DOCKER_HOST#unix://}"
  else
    SOCK=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null || true)
    if [ -z "$SOCK" ] || [ ! -S "$SOCK" ]; then
      for c in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock" /run/podman/podman.sock; do
        [ -S "$c" ] && { SOCK="$c"; break; }
      done
    fi
  fi
  if [ -n "$SOCK" ] && [ -S "$SOCK" ]; then
    export DOCKER_HOST="unix://$SOCK"
    export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
    export TESTCONTAINERS_HOST_OVERRIDE=localhost
    # Ryuk needs a privileged container; rootless Podman cannot provide one.
    if podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null | grep -q true; then
      export TESTCONTAINERS_RYUK_DISABLED=true
    else
      export TESTCONTAINERS_RYUK_PRIVILEGED=true
    fi
  else
    echo "warn: podman API socket not found (macOS: podman machine start; Linux: systemctl --user start podman.socket)" >&2
  fi
fi

export KIND_EXPERIMENTAL_PROVIDER=podman
