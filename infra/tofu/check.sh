#!/usr/bin/env bash
# `just tofu-check` (WP104, ADR-0050): everything that can be proven about infra/tofu without a cloud account, locally
# and in CI. fmt, init (provider from the registry, lock file read-only), validate, `tofu test` (plans against a mocked
# provider), the config scan (trivy), shellcheck of the cloud scripts, the cloud install pins against deploy/kind/up.sh,
# and no state, plan or variable file tracked by git. It never plans or applies against Alibaba Cloud: the cloud
# credentials are removed from its environment and the state passphrase is a throwaway (no state is written).
set -euo pipefail
cd "$(dirname "$0")/../.."
TOFU_DIR=infra/tofu
TRIVY_IMAGE=aquasec/trivy:0.76.1   # same pin as the trivy-fs job in .github/workflows/ci.yml
fail=0
ok()  { printf '  ok   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }
step() { printf '== %s\n' "$*"; }

unset ALIBABA_CLOUD_ACCESS_KEY_ID ALIBABA_CLOUD_ACCESS_KEY_SECRET ALIBABA_CLOUD_SECURITY_TOKEN ALIBABA_CLOUD_PROFILE \
  ALICLOUD_ACCESS_KEY ALICLOUD_SECRET_KEY ALICLOUD_PROFILE
export TF_VAR_state_passphrase=tofu-check-only-no-state-is-written NO_COLOR=1 TF_IN_AUTOMATION=1
tofu() { command tofu -chdir="$TOFU_DIR" "$@"; }

step "OpenTofu version"
want=$(tr -d '[:space:]' < "$TOFU_DIR/.opentofu-version")
have=$(command tofu version -json | sed -n 's/.*"terraform_version": *"\([^"]*\)".*/\1/p')
if [ "$have" = "$want" ]; then ok "tofu $have (= .opentofu-version)"
else bad "tofu $have, .opentofu-version pins $want (brew upgrade opentofu, or bump both)"; fi

step "fmt"
if tofu fmt -check -recursive -diff >/dev/null; then ok "tofu fmt -check -recursive"; else tofu fmt -check -recursive -diff || true; bad "tofu fmt (run: tofu -chdir=$TOFU_DIR fmt -recursive)"; fi

step "init + validate"
if tofu init -input=false -backend=false -lockfile=readonly -no-color >"${TMPDIR:-/tmp}/tofu-init.$$" 2>&1; then ok "init (provider per .terraform.lock.hcl)"
else cat "${TMPDIR:-/tmp}/tofu-init.$$"; bad init; fi
rm -f "${TMPDIR:-/tmp}/tofu-init.$$"
if tofu validate -no-color; then ok validate; else bad validate; fi

step "test (mocked provider, plans only)"
if out=$(tofu test -no-color 2>&1); then
  ok "$(echo "$out" | grep -E '^Success!')"
else echo "$out" | grep -v '^$'; bad "tofu test"; fi

step "config scan (trivy config)"
# Trivy ships no Alibaba Cloud checks (ADR-0050): the security rules of this module are asserted by the tests above.
if command -v trivy >/dev/null; then trivy=(trivy)
else trivy=(docker run --rm -v "$PWD:/src" -w /src "$TRIVY_IMAGE"); fi
if "${trivy[@]}" config --quiet --exit-code 1 --severity LOW,MEDIUM,HIGH,CRITICAL "$TOFU_DIR"; then ok "trivy config $TOFU_DIR: no finding"
else bad "trivy config $TOFU_DIR"; fi

# Checkov has a few Alibaba Cloud rules (CKV_ALI_*, e.g. no SSH from 0.0.0.0/0); run when installed (brew install checkov).
if command -v checkov >/dev/null; then
  if checkov -d "$TOFU_DIR" --framework terraform --quiet --compact; then ok "checkov (Alibaba Cloud rules)"; else bad checkov; fi
else echo "  skip checkov (not installed; optional)"; fi

step "shellcheck"
scripts=("$TOFU_DIR/check.sh" deploy/cloud/*.sh)
if command -v shellcheck >/dev/null; then
  if shellcheck -x "${scripts[@]}"; then ok "shellcheck ${scripts[*]}"; else bad shellcheck; fi
else echo "  skip shellcheck (not installed)"; fi

step "cloud install pins = kind pins"
# deploy/cloud/install.sh installs the same operators as deploy/kind/up.sh; a bump of one must bump the other.
pin() { sed -n "s/^$1=\"\(.*\)\"$/\1/p" "$2"; }
for v in ENVOY_GATEWAY_VERSION GATEWAY_API_VERSION CNPG_VERSION RELOADER_CHART_VERSION RELOADER_CHART_DIGEST RELOADER_IMAGE_DIGEST; do
  k=$(pin "$v" deploy/kind/up.sh); c=$(pin "$v" deploy/cloud/install.sh)
  if [ -n "$k" ] && [ "$k" = "$c" ]; then ok "$v $c"; else bad "$v: kind '$k', cloud '$c'"; fi
done

step "nothing secret or stateful tracked by git"
tracked=$(git ls-files "$TOFU_DIR" | grep -E '(\.tfstate|\.tfplan|\.tfvars(\.json)?$|(^|/)\.terraform/|crash\.log)' || true)
if [ -z "$tracked" ]; then ok "no state, plan, tfvars or .terraform/ under $TOFU_DIR in git"; else bad "tracked: $tracked"; fi
for f in terraform.tfvars terraform.tfstate terraform.tfstate.backup plan.tfplan .terraform/providers; do
  git check-ignore -q "$TOFU_DIR/$f" || bad ".gitignore does not ignore $TOFU_DIR/$f"
done
ok "terraform.tfvars, state, plans and .terraform/ are git-ignored (unless a FAIL above)"
if git ls-files --error-unmatch "$TOFU_DIR/.terraform.lock.hcl" >/dev/null 2>&1; then ok "lock file committed"
else bad ".terraform.lock.hcl is not committed"; fi

if [ "$fail" = 0 ]; then echo "TOFU CHECK PASSED"; else echo "TOFU CHECK FAILED"; exit 1; fi
