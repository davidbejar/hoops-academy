#!/usr/bin/env bash
# Source this file: `source scripts/env.sh`
# Sets JAVA_HOME to JDK 21 and points Docker-API clients (Testcontainers, Quarkus Dev Services, Tilt) at Podman.

# Pick a JDK whose major version is exactly 21 (java_home -v 21 would also accept newer JDKs).
_pick_jdk21() {
  local c
  for c in /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
           /usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
           "$(/usr/libexec/java_home -v 21 2>/dev/null)"; do
    [ -x "$c/bin/java" ] || continue
    if "$c/bin/java" -version 2>&1 | grep -q '"21\.'; then echo "$c"; return 0; fi
  done
  return 1
}
if JH=$(_pick_jdk21); then
  export JAVA_HOME="$JH"
else
  echo "warn: JDK 21 not found (run scripts/bootstrap.sh)" >&2
fi
[ -n "${JAVA_HOME:-}" ] && export PATH="$JAVA_HOME/bin:$PATH"

if command -v podman >/dev/null 2>&1; then
  SOCK=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
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
    echo "warn: podman machine socket not found; is the machine running? (podman machine start)" >&2
  fi
fi

export KIND_EXPERIMENTAL_PROVIDER=podman
