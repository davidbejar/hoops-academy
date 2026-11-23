# shellcheck shell=bash
# Output and tool helpers of the deploy scripts (DEP-09, ADR-0068): kind/, cloud/ and helm/tests/run.sh source this file.
# A checking script sets fail=0 first; `bad` sets it to 1 and the script decides at its end.
# shellcheck disable=SC2034 # fail is read by the sourcing script
step() { printf '\n==> %s\n' "$*"; }
ok()   { printf '  ok   %s\n' "$*"; }
bad()  { printf '  FAIL %s\n' "$*"; fail=1; }
warn() { printf '  WARN %s\n' "$*"; }
need() { # tools...: exit with "<script>: <tool> not found" on the first one missing
  local t
  for t in "$@"; do command -v "$t" >/dev/null || { echo "$(basename "$0"): $t not found" >&2; exit 1; }; done
}
