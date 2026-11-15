#!/usr/bin/env bash
# The Rust gates of pdf-service (ADR-0052), run by `just test-rust` (and so by `just test`) and by CI's job `rust`:
#   1. cargo fmt --check                     formatting (rustfmt.toml)
#   2. cargo clippy -D warnings              lints (Cargo.toml [workspace.lints]: clippy all + pedantic, no unwrap)
#   3. cargo llvm-cov (runs cargo test)      unit, contract, HTTP, renderer and layering tests, with coverage
#   4. scripts/coverage_gate.py              >= 80 % lines in the workspace, >= 90 % in the domain crate
#   5. cargo deny check                      RustSec advisories, licences, bans, sources (deny.toml)
# The toolchain is the one rust-toolchain.toml pins (rustup installs it on first use). Needs cargo-llvm-cov and
# cargo-deny (scripts/bootstrap.sh installs them). --offline skips the advisory database fetch of step 5.
set -euo pipefail
cd "$(dirname "$0")/.."

# rustup from Homebrew is keg-only: put it on PATH when cargo is not there yet
if ! command -v cargo >/dev/null 2>&1; then
  for dir in "$HOME/.cargo/bin" /opt/homebrew/opt/rustup/bin /usr/local/opt/rustup/bin; do
    if [ -x "$dir/cargo" ]; then PATH="$dir:$PATH"; break; fi
  done
fi
command -v cargo >/dev/null 2>&1 || { echo "pdf-service: cargo not found (scripts/bootstrap.sh installs rustup)" >&2; exit 1; }

deny_args=()
[ "${1:-}" = "--offline" ] && deny_args=(--disable-fetch)

step() { printf '\n== pdf-service: %s\n' "$*"; }
step "rustfmt";  cargo fmt --all -- --check
step "clippy";   cargo clippy --workspace --all-targets --locked -- -D warnings
step "tests with coverage"
cargo llvm-cov --workspace --locked --json --summary-only --output-path target/llvm-cov.json
step "coverage gate"; python3 -I scripts/coverage_gate.py target/llvm-cov.json
step "dependency audit"; cargo deny --locked check ${deny_args[@]+"${deny_args[@]}"}
