#!/usr/bin/env bash
# Tests of the JDK choice in scripts/env.sh with stub JDKs (run: just test-hooks). env.sh must select a JDK whose major
# version is exactly 25: a JAVA_HOME that is a 25 is kept, one that is a 21 (or a 26) is replaced by the 25 on PATH.
# Hermetic (WP146): the replacement is a stub 25 on PATH, not whatever JDK 25 the machine has (macOS found Homebrew's
# through java_home; a Linux runner has none outside PATH, so 2 of 3 failed there). Podman is kept off PATH so the socket
# probe is skipped.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
fail=0 total=0
stubs=$(cd "$(mktemp -d)" && pwd -P) # physical path: env.sh resolves the java on PATH (macOS: /var is /private/var)
trap 'rm -rf "$stubs"' EXIT

stub_jdk() { # stub_jdk <name> <version string>
  mkdir -p "$stubs/$1/bin"
  printf '#!/bin/sh\necho "openjdk version \\"%s\\" 2026-10-22" >&2\n' "$2" >"$stubs/$1/bin/java"
  chmod +x "$stubs/$1/bin/java"
}
stub_jdk jdk21 21.0.9
stub_jdk jdk25 25.0.5.0.2
stub_jdk jdk26 26.0.1
stub_jdk path25 25.0.5.0.2

chosen() { # chosen <JAVA_HOME before sourcing>: prints JAVA_HOME after sourcing env.sh in a clean shell, stub 25 on PATH
  # shellcheck disable=SC2016 # expanded by the inner shell
  env -i HOME="$HOME" PATH="$stubs/path25/bin:/usr/bin:/bin" JAVA_HOME="$1" \
    bash -c 'source scripts/env.sh 2>/dev/null; echo "${JAVA_HOME:-}"'
}

expect() { # expect <label> <condition result 0/1> <detail>
  total=$((total + 1))
  [ "$2" = 0 ] && return 0
  fail=$((fail + 1)); printf 'FAIL %s: %s\n' "$1" "$3"
}

is() { [ "$1" = "$2" ] && echo 0 || echo 1; } # is <got> <want>: 0 when equal
got=$(chosen "$stubs/jdk25"); expect "a JAVA_HOME that is a 25 is kept" "$(is "$got" "$stubs/jdk25")" "got [$got]"
got=$(chosen "$stubs/jdk21"); expect "a JAVA_HOME that is a 21 is replaced by the 25 on PATH" \
  "$(is "$got" "$stubs/path25")" "got [$got]"
got=$(chosen "$stubs/jdk26"); expect "a JAVA_HOME that is a 26 is replaced by the 25 on PATH" \
  "$(is "$got" "$stubs/path25")" "got [$got]"

echo "env-jdk: $((total - fail))/$total passed"
[ "$fail" -eq 0 ]
