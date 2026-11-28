#!/usr/bin/env bash
# Fetch the Semgrep registry rulesets of the semgrep workflow into a directory and check each one against the SHA-256 pinned
# in .semgrep/registry-rules.txt (TM-05). A ruleset that changed upstream stops the run: nothing unreviewed is executed.
#   scripts/semgrep-rules.sh semgrep-registry        # writes semgrep-registry/<name>.yml, e.g. java.yml
# Semgrep prefixes the rule ids of a config directory with its name ("semgrep-registry."): the workflow's gate strips it
# (scripts/sarif-gate.py --strip-rule-prefix). Refresh after a reviewed change: scripts/bump-pins.sh --apply.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
out="${1:?usage: semgrep-rules.sh <output directory>}"
mkdir -p "$out"
sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi; }
bad=0
while read -r ruleset pinned; do
  case "$ruleset" in ''|'#'*) continue ;; esac
  file="$out/${ruleset#p/}.yml"
  curl -sSfL --retry 3 -o "$file" "https://semgrep.dev/c/$ruleset"
  actual=$(sha256 "$file")
  actual="${actual%% *}"
  if [ "$actual" != "$pinned" ]; then
    echo "semgrep-rules: $ruleset changed upstream (SHA-256 $actual, pinned $pinned): review it, then scripts/bump-pins.sh --apply" >&2
    rm -f "$file"
    bad=1
  fi
done < .semgrep/registry-rules.txt
[ "$bad" = 0 ] || exit 1
echo "semgrep-rules: $(grep -vc '^#' .semgrep/registry-rules.txt) rulesets match their pinned SHA-256"
