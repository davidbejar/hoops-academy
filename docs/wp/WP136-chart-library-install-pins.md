# WP136 — Chart, kind, cloud: library chart for the service sub-charts; one source for the kind and cloud install pins

Model: Opus · high. Wave 3 (2026-11-23, ninth round): starts after wave 2 is merged; runs alongside WP134 (library and
services), WP135 (web). You are the only kind user of the wave. You own `deploy/**` and the `Tiltfile`; nobody else
touches them. Not `infra/**`, not `scripts/**` except `scripts/sync-chart-files.sh` if a path moves. Depends on:
ADR-0022, ADR-0038. Skills: work-package, podman-dev-env, owasp-security, test-driven-development, clean-code,
verification-before-completion. Worktree: `~/code/hoops-wt/wp136-chart-library-install-pins`, branch
`wp136-chart-library-install-pins`.

Decision 104 of 2026-11-23: everything confirmed under `deploy/` is fixed; the `infra/` copies in the chart stay
(DEP-04). ADR-0068 is reserved for you (write it for the library chart).

This work package comes from the audit of 2026-11-23 (duplication and inefficiencies). Findings: `deploy.md`
(DEP-01..12), verification `verify-deploy-infra-ci.md`, all under `~/code/hoops-academy/audit/2026-11-23/`.

## Scope
1. **Library chart (DEP-01)**: helpers, `service.yaml` and `httproute.yaml` first (exact copies), then the near-copies
   of the three service sub-charts (about 300 lines). The rendered output must not change: `deploy/helm/tests/run.sh`
   green **without** `--update`; bump the chart version.
2. **Snapshots (DEP-03, INF-10 as corrected)**: five near-identical umbrella renders, each with the password blocklist
   (0.70 MB of 1.69 MB): keep the coverage, cut the repetition if it can be done without weakening a test.
3. **Install pins (DEP-02)**: the pins and the Reloader / Envoy Gateway blocks pasted into `kind/up.sh` and
   `cloud/install.sh` come from one sourced file; `just tofu-check` keeps policing what remains.
4. **The rest**: every other DEP finding of your scope, the Containerfiles included (layer order, repeated stages)
   where the verification confirms them.

Not yours: DEP-04: leave. DEP-07 (`KEYCLOAK_URL` in the chart) is WP139: do not rename variables.

## Acceptance
- [ ] Red tests committed before each change (a pure move or deletion needs none: the existing tests are its proof)
- [ ] `deploy/helm/tests/run.sh` green without `--update` after the library chart step
- [ ] `deploy/kind/up.sh --deploy` and `deploy/kind/smoke.sh` green on a fresh cluster (evidence in the handover);
      `helm lint` and kubeconform as the tests run them
- [ ] `scripts/build-images.sh` builds every image you touched
- [ ] Handover appended, with the ID table

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- The audit files are in the main checkout, untracked, at `~/code/hoops-academy/audit/2026-11-23/` (they are not in your
  worktree). Read the findings file(s) named above **and** their verification file: where the two disagree, the verification is right.
  Do every finding of your scope whose verdict is CONFIRMED or PARTLY (as corrected); skip REFUTED, ALREADY KNOWN and
  the exclusions named above. A finding you judge not worth doing or unsafe after reading the code: leave it, and say
  why in the handover. Do not copy the audit files into the repository.
- Behaviour must not change except where a finding is a bug; a bug fix starts with its failing test.
- Commit: `gitleaks protect --staged`, then plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace: re-add and commit again.
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit; it is expected, do
  not try to bypass it; if it times out under load, retry when a build has finished. End every commit message with a
  `Co-Authored-By:` line naming the model that did the work (for example
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md, docs/conformance.md, docs/roadmap.md,
  docs/architecture.md; what they need goes in this file's Handover. `docs/adr/README.md`: append your ADR line at the
  end, one line.
- Finish per the `work-package` skill. The Handover ends with a table `| ID | Done / Skipped | What changed or why
  not |` with one row per finding ID of your scope. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points, ID table (work-package skill). -->

- Built:
  - Library chart `deploy/helm/hoops/charts/hoops-lib` (ADR-0068): the helpers, Service, HTTPRoutes, Deployment,
    egress-limited NetworkPolicy and the Kafka / OTLP env pieces of `hoops-service`, `pdf-service` and
    `finance-service`. The sub-charts keep their files (so the `# Source:` lines stay) as one `include` each plus a
    small chart-specific hook (`<chart>.env`, `<chart>.ingressFrom`). Umbrella 0.14.0; the sub-chart versions stay,
    because they are in every object's `helm.sh/chart` label. Chart templates: 860 lines out, 521 in (410 of them the
    library), about 340 duplicated lines gone. Sub-charts declare `hoops-lib` with `repository: file://../hoops-lib`;
    `run.sh` renders and lints them alone on a copy after `helm dependency update --skip-refresh`.
  - Snapshots (DEP-03 / INF-10): `umbrella-kind.yaml` whole; default, eso and cloud keep only the documents that differ
    from umbrella-kind, tls those that differ from default; the blocklist body is a pointer that `run.sh` compares byte
    for byte with the chart file in all five renders. 1.69 MB -> 0.37 MB. Same output with macOS awk and Ubuntu mawk
    (checked in an ubuntu:24.04 container).
  - `deploy/lib/platform.sh`: the Envoy Gateway, Gateway API, CNPG and Reloader pins once, plus `install_reloader`,
    `install_envoy_gateway`, `install_cnpg`, `wait_for_platform`; `up.sh` and `install.sh` source it.
    `deploy/lib/common.sh`: `step`, `ok`, `bad`, `warn`, `need` for kind/, cloud/ and `run.sh`.
  - Tilt: the `secrets` resource and each workload's routes and rate-limit policies come from what is deployed. The hand
    lists had drifted: core's four rate-limited routes and their policies were "uncategorized" (`tilt alpha
    tiltfile-result` before/after, with and without `--eso`).
  - `service.containerignore` drops `services/pdf-service` and `services/finance-service`; stale pin prose and comments
    in the Containerfiles and `kind-config.yaml`; `run.sh` checks that each dependency version names the vendored
    chart's version (Helm does not: a mismatch rendered and linted cleanly).
  - Bug found on the kind proof and fixed: `up.sh --deploy` without `--from-host` stopped under macOS bash 3.2
    (`BUILD_FLAGS[@]: unbound variable`, an empty array under `set -u`).
- Verified:
  - `deploy/helm/tests/run.sh` green **without** `--update` after the library chart (all seven snapshots byte-equal);
    `--update` used once, for the DEP-03 format change only, then green again. Mutations caught: a changed TLS host
    (umbrella-tls snapshot plus three policy checks), one changed blocklist line (sync drift and four snapshots), a
    wrong alias version. `helm lint --strict` and kubeconform (397 resources, 0 invalid) as `run.sh` runs them;
    `helm package` of the umbrella renders the same as the snapshot.
  - `python3 -I -m unittest discover -s scripts/tests`: 71 tests OK (1 skipped). `just tofu-check` (infra/tofu/check.sh):
    PASSED. `shellcheck -x`: cloud scripts and `deploy/lib` clean; kind scripts and `run.sh` show the same 237
    pre-existing findings before and after.
  - Kind proof (`.env` from `.env.example`, deleted afterwards): `deploy/kind/up.sh --deploy` created the cluster and
    installed Reloader, Envoy Gateway and CNPG through `deploy/lib/platform.sh` ("Gateway API CRDs v1.6.1"). After the
    bash 3.2 fix, `scripts/build-images.sh` built and loaded all six images (core, game and athlete through the Maven
    stage with the trimmed context, web, pdf, finance). `helm upgrade --install --wait` then aborted on API-server TLS
    handshake timeouts. After 39 min the pods still failed their probes on timeouts, even nginx `/healthz`. Load average
    in the Podman VM was about 30 on 2 CPUs, shared with the compose stack and other agents' Testcontainers runs.
    `smoke.sh` was **not run** (no Ready stack). The rendered manifests are byte-equal to main's. Cluster deleted.
  - `just test` not run: no Java, Rust, Go or Dart source changed, and the VM was saturated.
- Decisions/ADRs: ADR-0068 (library chart, one pins file, delta snapshots, shared helpers, Tilt lists derived).
- Open points / follow-ups:
  - Re-run the kind proof on a quiet machine: `just kind-up --deploy` (or `deploy/kind/up.sh --deploy`), then
    `deploy/kind/seed-users.sh` and `deploy/kind/smoke.sh core game athlete`.
  - Outside the brief's file list, needed by DEP-02: `scripts/bump_pins.py` (the pins now live in `deploy/lib/platform.sh`;
    allowed by the orchestrator), `scripts/tests/test_mirrored_pins.py` (now asserts the one file and that kind/cloud
    pin nothing themselves) and the "cloud install pins = kind pins" step of `infra/tofu/check.sh` (without it
    `just tofu-check` fails). Docs updated: ADR-0031 upgrade path, `docs/runbooks/{kind,cloud,release}.md`.
  - Not mine, now stale: the `.github/dependabot.yml` comment ("kind pins in deploy/kind/up.sh"); the
    `go-hexagonal-service` and `rust-service` skills could mention `hoops-lib` for chart changes.
  - `values.yaml`: the `rosterSource` expressions now call `hoops-lib.eventsEnabled`; a private `values-local.yaml`
    that used `hoops-service.*` helpers in a `tpl` string must follow.

| ID | Done / Skipped | What changed or why not |
|---|---|---|
| DEP-01 | Done | `hoops-lib` library chart; output unchanged (run.sh green without `--update`); umbrella 0.14.0 |
| DEP-02 | Done | `deploy/lib/platform.sh` (pins and install functions), sourced by `up.sh` and `install.sh`; bump_pins, pin test and tofu check follow |
| DEP-03 | Done | delta snapshots and blocklist pointer, 1.69 MB -> 0.37 MB; every assertion still on whole renders |
| INF-10 | Done | as DEP-03 (the blocklist in the snapshots); the chart copy itself stays (DEP-04) |
| DEP-04 | Skipped | decision 104 / ALREADY KNOWN: the `infra/` copies stay |
| DEP-05 | Done in part | Rust and Go trees out of the Maven context; the pom-first layer split skipped: CI runners keep no layer cache (verification) |
| DEP-06 | Done in part | stale "hermetic, CI" comment fixed; reorder skipped: `generate: true` makes `flutter pub get` need `l10n.yaml` and the ARB files, the stage is unused by CI and could not be built here |
| DEP-07 | Skipped | WP139 (brief) |
| DEP-08 | Done | Tilt Secret and route lists derived; four drifted core routes and policies regrouped |
| DEP-09 | Done | `deploy/lib/common.sh` |
| DEP-10 | Done in part | `quiet_helm` gone, stale comments trimmed, alias versions checked by run.sh; the nginx step stays (base still nginx 1.30.6-r1 on 2026-11-24) |
| DEP-11 | Done in part | dated pin prose replaced by ADR references; labels via `--label` skipped (`scripts/build-images.sh` and `images.yml` are not mine, and both builders would need the same flags) |
| DEP-12 | Skipped | seconds per run; the ad-hoc renders sit next to their assertions; the second lint only runs after a failure (verification) |
