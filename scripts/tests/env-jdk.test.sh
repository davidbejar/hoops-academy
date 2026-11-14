#!/usr/bin/env bash
# Tests of the JDK choice in scripts/env.sh with stub JDKs (run: just test-hooks). env.sh must select a JDK whose major
# version is exactly 25: a JAVA_HOME that is a 25 is kept, one that is a 21 (or a 26) is never kept. Podman is kept off
# PATH so the socket probe is skipped.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
fail=0 total=0
stubs=$(mktemp -d)
trap 'rm -rf "$stubs"' EXIT

stub_jdk() { # stub_jdk <name> <version string>
  mkdir -p "$stubs/$1/bin"
  printf '#!/bin/sh\necho "openjdk version \\"%s\\" 2026-10-22" >&2\n' "$2" >"$stubs/$1/bin/java"
  chmod +x "$stubs/$1/bin/java"
}
stub_jdk jdk21 21.0.9
stub_jdk jdk25 25.0.5.0.2
stub_jdk jdk26 26.0.1

chosen() { # chosen <JAVA_HOME before sourcing>: prints JAVA_HOME after sourcing env.sh in a clean shell
  env -i HOME="$HOME" PATH=/usr/bin:/bin JAVA_HOME="$1" bash -c 'source scripts/env.sh 2>/dev/null; echo "${JAVA_HOME:-}"'
}

expect() { # expect <label> <condition result 0/1> <detail>
  total=$((total + 1))
  [ "$2" = 0 ] && return 0
  fail=$((fail + 1)); printf 'FAIL %s: %s\n' "$1" "$3"
}

got=$(chosen "$stubs/jdk25"); [ "$got" = "$stubs/jdk25" ]; expect "a JAVA_HOME that is a 25 is kept" $? "got [$got]"
got=$(chosen "$stubs/jdk21"); [ "$got" != "$stubs/jdk21" ]; expect "a JAVA_HOME that is a 21 is replaced" $? "got [$got]"
got=$(chosen "$stubs/jdk26"); [ "$got" != "$stubs/jdk26" ]; expect "a JAVA_HOME that is a 26 is replaced" $? "got [$got]"

echo "env-jdk: $((total - fail))/$total passed"
[ "$fail" -eq 0 ]
