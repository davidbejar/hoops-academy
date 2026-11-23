# ADR-0068: The service sub-charts share a library chart; kind and the cloud VM take their operator pins from one file

- Status: Accepted
- Date: 2026-11-24
- Related: ADR-0022 and ADR-0038 (chart file copies), ADR-0031 (Gateway API), ADR-0033 (global rate limit), ADR-0050
  (cloud VM), ADR-0012 (Secrets, Reloader), ADR-0054 (distroless images), WP136, audit of 2026-11-23 (DEP-01..12,
  INF-10), decision 104

## Context
The audit of 2026-11-23 found the deploy tree built by copying. The Rust and Go services got their own sub-charts by
copying `hoops-service`: helpers, Service and HTTPRoutes were verbatim copies, the Deployment and the egress-limited
NetworkPolicy near-copies (about 300 duplicated template lines). `deploy/kind/up.sh` and `deploy/cloud/install.sh` each
carried the operator pins, the Envoy Gateway values and the Reloader install, kept equal by a drift check in
`infra/tofu/check.sh`. The chart tests stored five full umbrella renders (1.69 MB), each with the 10,000-line password
blocklist, and Tilt listed Secret and route names by hand (four of core's routes had already fallen out of the list).

## Decision
1. **Library chart `hoops-lib`** (`deploy/helm/hoops/charts/hoops-lib`, `type: library`) holds what `hoops-service`,
   `pdf-service` and `finance-service` share: `fullname`, `labels`, `selectorLabels`, `image`, `parentRefs`,
   `ruleTimeouts`, `hostnames`, `eventsEnabled`, and the templates `service`, `httproute`, `deployment` (options: the
   chart's rendered `env` section, `reloader`, a `/tmp` emptyDir), `networkPolicy` (the egress-limited one of pdf and
   finance: first ingress peers and egress targets from the chart) and the env pieces `kafkaClientEnv` and
   `otlpHttpEnv`. Every define takes the calling chart's context, so labels and values stay the caller's.
   - The umbrella lists `hoops-lib` as a vendored dependency; Helm's template names are global, so inside the umbrella
     that one copy serves every sub-chart. Each service sub-chart also declares it with `repository:
     file://../hoops-lib`, so a sub-chart rendered alone works after `helm dependency update --skip-refresh` (the chart
     tests do that on a copy; the generated `charts/` and `Chart.lock` are git-ignored). No symlink, no packaged copy in
     git (`helm package` keeps working, ADR-0022).
   - The rendered output did not change (all snapshots equal without `--update`). The sub-chart versions stay, because
     they are part of every object's `helm.sh/chart` label; the umbrella moved to 0.14.0. `run.sh` now checks that each
     dependency version names the version of the vendored chart (Helm does not).
   - The values files keep their own defaults: Helm values cannot be shared between sub-charts.
2. **One file for the shared operator pins**: `deploy/lib/platform.sh` pins Envoy Gateway, Gateway API, CloudNativePG
   and Reloader once and holds `install_reloader`, `install_envoy_gateway`, `install_cnpg` and `wait_for_platform`; both
   scripts source it and pass their own `helm` / `kubectl` (kind: `--kube-context kind-hoops`; cloud: `cloud_helm`,
   `cloud_kubectl`). The ESO pin stays in `up.sh` (kind only). `scripts/bump_pins.py` bumps the one file;
   `infra/tofu/check.sh` now fails when a script sources something else or pins one of these again.
3. **Shared shell helpers**: `deploy/lib/common.sh` (`step`, `ok`, `bad`, `warn`, `need`) for kind/, cloud/ and the
   chart tests.
4. **Snapshots as differences**: `umbrella-kind.yaml` is stored whole; `umbrella-default`, `-eso` and `-cloud` store
   only the documents that differ from `umbrella-kind` (by source, kind, namespace and name, plus a `# removed:` line
   per document they lack), `umbrella-tls` those that differ from `umbrella-default`. The blocklist body is a pointer
   to its chart file, and `run.sh` compares it byte for byte in every render. Every assertion keeps running on the
   whole renders. Diff-based snapshots were rejected: macOS and Linux `diff` may choose different hunks.
5. **Tilt** derives the `secrets` resource from what it applies (`secrets.sh` output, or the chart's ExternalSecrets
   with `--eso`) and each workload's routes and rate-limit policies from the chart by `app.kubernetes.io/name`.

## Consequences
- A change to pod hardening, probes, Gateway timeouts or the DNS/collector egress rule is one edit in `hoops-lib`;
  the snapshots show it once per render that contains it.
- A mistake in `hoops-lib` breaks every service at once; the snapshots and policy assertions catch it before a merge.
- Rendering a service sub-chart on its own needs one `helm dependency update` first.
- Snapshots shrink from 1.69 MB to 0.37 MB; a change shared by all renders shows in `umbrella-kind.yaml` and only
  where it differs in the others. A pure reordering of documents within a variant render is not detected (Helm's order
  is fixed by kind and name).
- An operator bump is one edit, still checked by `just tofu-check` and `scripts/tests/test_mirrored_pins.py`.
- Not decided here: moving the `infra/` sources into the charts (DEP-04, kept), shared values for the per-service env
  (DEP-07, WP139), the Flutter-in-container layer order (DEP-06: `flutter pub get` generates the l10n code, so it
  needs the sources first).
