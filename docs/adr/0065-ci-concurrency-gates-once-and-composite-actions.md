# ADR-0065: CI runs each gate once, cancels superseded pull request runs and shares its set-up in composite actions

- Status: Accepted
- Date: 2026-11-24
- Related: ADR-0045 (SAST/DAST gates), ADR-0052 and ADR-0055 (Rust and Go pins), ADR-0057 (docs site), WP133, audit of
  2026-11-23 (CI-01..14, LIB-09)

## Context
The audit found the pipeline built job by job: the same 5-20 lines of set-up pasted three to seven times, static gates
run twice (`dependency-check` ran `verify`), a Quarkus `package` of the whole reactor only to fill `~/.m2` for Trivy,
four copies of the image scan / SBOM / push steps, no concurrency group on the heavy workflows (a superseded push kept
a 130-minute `e2e` run alive), tool versions written in up to seven places, and CI re-typing recipes that the justfile
says CI runs.

## Decision
1. **Concurrency.** `ci`, `e2e`, `codeql` and `semgrep` share a group per pull request ref and cancel the superseded
   run. Every other event (push to `main`, schedule, dispatch) gets the run id as its group, so it is never cancelled
   and never replaces a queued run (a plain per-ref group with `cancel-in-progress: false` still drops a queued run).
   `images`, `pages` and `bump-pins` keep their rules.
2. **Gates once.** `dependency-check` runs `compile` and then `dependency-check:aggregate` directly (SpotBugs, PMD and
   CPD stay in `backend`; `compile` first so the reactor modules resolve from `target/classes`, otherwise the plugin
   skips `common-quarkus` and `contracts`). `trivy-fs` fills `~/.m2` with `dependency:go-offline` (Trivy reported the
   same packages and findings as after a `package`). The Python tests of `scripts/tests` run once, in a `scripts` job
   of `ci`, not inside the Semgrep workflow. The `charts` job of `images.yml` is deleted: it gated no push and repeated
   `helm-chart-tests`. No scanner (Trivy, gitleaks, dependency-check, CodeQL, Semgrep, ZAP) runs on fewer events.
3. **Composite actions** under `.github/actions/`: `setup-java`, `setup-flutter`, `setup-pinned-chrome`, `setup-go`,
   `setup-chart-tools` and `image-publish` (scan, SBOM upload, push). Each third-party action inside them stays pinned to
   a commit SHA; Dependabot scans the folder. A job runs `actions/checkout` before its first local action.
4. **One place per tool.** Chrome, Go (for CI), kubeconform and gitleaks are named in one action each; the JDK in
   `setup-java`. The Trivy tag in `infra/tofu/check.sh` joins the weekly bump. `test_toolchain_pins.py` keeps `go.mod`,
   the Go action and `finance.Containerfile` equal, and `rust-toolchain.toml` and `pdf.Containerfile` equal; the Go and
   Rust bumps stay manual (ADR-0052, ADR-0055).
5. **Recipes.** CI calls `just docs-build`, `just web-format-check`, `just web-test` and `just diagrams-check`.
6. `scripts/gen-api.sh` reads `openapi-generator.version` from the root pom and stops on any other local generator.

## Consequences
- A pull request pays for its latest push only. A run on `main` is always complete.
- A workflow change is one edit in the action instead of three to seven; the cost is that a mistake in an action breaks
  every job that uses it at once, and a local action cannot be tried without a push (`actionlint` does not read
  `action.yml`).
- `env-jdk.test.sh` and the Claude hook's `tenancy-gate.test.sh` assume a macOS developer machine and stay out of CI.
- Not decided here: building the service jars once for `e2e` and `zap-baseline` (CI-01 part a), the double build of the
  pdf and finance images on `main` (CI-06), and moving the ZAP baseline into `e2e` (CI-08, ADR-0045 keeps it in `ci`).
