# WP120 — Observability: one Grafana LGTM pod on kind and compose, dashboards

Model: Opus · effort high. Wave 3 (2026-11-15, eighth round): starts after WP118 is merged; runs alongside WP119
(finance Go code only), WP121 and WP122 (web). You own `deploy/helm/**` (chart 0.12.0 → 0.13.0), `deploy/kind/**`,
`Tiltfile`, `infra/compose/**`, `docs/runbooks/observability.md` and your amendment in `docs/adr/0046-*.md`. You are
the wave's only kind user. You change no service code: if a service must emit something it does not, report it.
Depends on: ADR-0046, ADR-0043, the WP85 / WP86 handovers, the WP111 and WP118 handovers (five services now).
Skills: owasp-security, podman-dev-env, systematic-debugging, verification-before-completion. Worktree:
`~/code/hoops-wt/wp120-observability`, branch `wp120-observability`.

Decision 91 of 2026-11-15 (owner): one Grafana all-in-one pod (traces, logs, metrics, Grafana) behind the existing
OpenTelemetry collector, replacing the in-memory Jaeger on kind and offered as a compose profile; a few provisioned
dashboards. ADR-0046 amendment, no new ADR.

## Scope
1. **Backend**: the all-in-one Grafana OTel image pinned by digest (in the bump-pins lists), behind a chart switch;
   the collector exports traces, logs and metrics to it; Jaeger removed from kind. Dev-only: no persistence, Grafana
   reachable by port-forward only, no anonymous admin on a public host (`values-cloud.yaml` keeps it off), a
   NetworkPolicy, the pod's memory sized for the 8 GB Podman VM (measure it).
2. **Compose**: a profile (off by default) with the same backend and collector wiring; `just` entry; README line in
   `infra/compose`.
3. **Dashboards** (provisioned from files in the chart, the same files in compose): requests and errors per service,
   authorisation denials (`hoops_authz_denied_total{kind}`), security events from the logs; a trace reachable from a
   log line.
4. **Kind proof**: `up.sh --deploy`, the smoke run, then a trace through gateway → core → database and one through
   core → pdf-service visible in Grafana, logs of all five services, the three dashboards with data. Stop compose
   while proving on kind; chart tests and snapshots updated; `tilt ci` on the new chart if the VM load allows (it
   was last run on 0.9.0), otherwise say so.
5. **Docs**: the ADR-0046 amendment, `docs/runbooks/observability.md`.
6. **Retention** (WP112, `docs/security/privacy-threat-model.md` P-07): the backend gets an explicit retention limit
   for logs and traces (short, dev-sized), written in the runbook and the ADR-0046 amendment.

## Acceptance
- [ ] Chart tests green (ALL CHART TESTS PASSED), kubeconform clean; `actionlint` clean if a workflow changed
- [ ] Kind proof recorded with what was seen; compose profile started and one trace seen
- [ ] No request body or personal data in the dashboards' queries or the provisioned files
- [ ] Handover appended: chart version, the pod's memory, how to open Grafana, what is still not exported (Keycloak,
      Envoy, Redpanda logs)

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first (JDK 25). Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then a plain `git commit` with explicit paths (never `git add -A`, never
  `--no-verify`: the session refuses it). The pre-commit hooks run and may trim whitespace in generated files: re-add
  and commit again. Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit
  (it resyncs the Podman VM clock itself); under load it can time out: retry when a build has finished, never bypass
  it. End every commit message with a `Co-Authored-By:` line that names the model you are.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`.
- Gate rules: constant SQL with bound parameters (CodeQL), no nil-tenant bind without a dated acceptance (Semgrep), no
  environment-derived program names in scripts and tests (Semgrep taint). Since WP113 the PMD / CPD gate runs in
  `verify`: stay inside its thresholds, add no exclusion without a reason.
- An OpenAPI generator run can leave whitespace-only diffs in the Dart packages: discard them. Regenerate only your
  package (`scripts/gen-api.sh <svc>`). `apps/web/pubspec.lock`: commit it only with a generated package's version
  bump; revert other drift. `apps/web/lib/l10n/*.arb`: keys next to the feature's existing keys, never at the end.
- Shared index files (`docs/adr/README.md`, `docs/domain/authz-matrix.md`): append at the end, one entry per line.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
