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
- [x] Chart tests green (ALL CHART TESTS PASSED), kubeconform clean; `actionlint` clean if a workflow changed
- [x] Kind proof recorded with what was seen; compose profile started and one trace seen
- [x] No request body or personal data in the dashboards' queries or the provisioned files
- [x] Handover appended: chart version, the pod's memory, how to open Grafana, what is still not exported (Keycloak,
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
- Built:
  - Chart **0.13.0** (sub-charts `pdf-service` and `finance-service` 0.2.0): `observability.lgtm` = `grafana/otel-lgtm`
    0.41.0 pinned by index digest (amd64 + arm64), on in `values-kind.yaml`, explicitly off in `values-cloud.yaml` (which keeps
    the in-memory Jaeger); Jaeger removed from kind. Pod: uid 10001, read-only root FS, drop ALL, no token, `Recreate`,
    emptyDirs only (`/data` capped 2 Gi, `/var/tempo`, `/tmp`), the image's health script as startup (10 min) / readiness /
    liveness probe. Grafana: anonymous **Viewer** with Explore, login form and basic auth off (the image's `admin/admin` is
    unusable), no plugin download, update check, reporting or news. Service ClusterIP (4317, 3000), no route; NetworkPolicy:
    OTLP from the collector only, no egress.
  - **Retention 24 h** (P-07) for Loki, Tempo (scheduler and worker) and Prometheus through the image's `*_EXTRA_ARGS`
    flags (no config file copied); 24 h is Loki's minimum.
  - Collector: new `metrics` pipeline (OTLP + `prometheus` receiver scraping `/q/metrics` of the enabled services in
    `observability.collector.metrics.targets`, job = Service name, 30 s); traces, logs and metrics to `otlp_grpc/lgtm`;
    `pipelineExporters.metrics`; egress to `lgtm:4317` and each scraped port; pdf-service and finance-service admit the
    collector on their port. kind `debugVerbosity` back to `basic` (no log bodies in the collector's log).
  - Dashboards (`deploy/helm/hoops/files/grafana`, folder "Hoops Academy", read-only, replacing the image's RED/JVM ones):
    requests and errors (Tempo span metrics, `/q/` spans excluded; Micrometer statuses), authorisation denials
    (`hoops_authz_denied_total` by kind / service), security events (Loki; `keep` drops subject, roles, tenant; trace link).
  - Compose profile `observability` (`just observability-up` / `observability-down`, `down` includes it): the same collector
    image, processors and pipelines (`infra/compose/otel-collector.yaml`), the same LGTM pin, environment and dashboard
    files, tmpfs data, Grafana on 127.0.0.1:3000; pdf-service / finance-service export with `HOOPS_OTEL_SDK_DISABLED=false`.
    README line. Tilt: `lgtm` resource, port-forward 3000. `scripts/bump_pins.py`: one pin over chart and compose
    (`test_observability_pins.py`, red first in 90a349fe). Chart tests: LGTM, retention, Grafana settings, policies,
    dashboard privacy (no subject/roles/tenant/e-mail/user/path/body in any query; log panels keep six fields + trace id),
    compose equal to the chart, cloud keeps Jaeger.
  - Docs: ADR-0046 amendment; `docs/runbooks/observability.md` rewritten (Grafana, retention, memory, compose, not exported,
    troubleshooting); `docs/runbooks/kind.md` capacity line, port table.
- Verified (2026-11-16):
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED (231 ok, snapshots re-recorded), kubeconform 397 resources valid;
    rendered kind and cloud collector configs and the compose one pass `otelcol validate`. `just test-hooks`: 55/55, 5/5,
    3/3, 43 Python tests OK (1 skipped). `actionlint` clean (no workflow changed). Bump script resolves the new pin (latest =
    pinned).
  - **Compose** (shared stack kept running): `just observability-up` healthy in 24 s; pdf-service started with
    `HOOPS_OTEL_SDK_DISABLED=false`, ten refused calls: traces in Tempo (e.g. `pdf-service POST /internal/pdf/match-sheet`),
    ten `authz_denied` records in Loki, `hoops_authz_denied_total{job="pdf-service"}` 5 + 5 in Prometheus, three dashboards
    provisioned. Containers removed afterwards.
  - **kind** (compose stopped 10:15-10:43 WIB, restored with `podman start`, then `just up` + `just seed-users` from the main
    checkout): `up.sh`, images built from this branch (`build-images.sh --from-host`, before the window, because the local
    images predated WP116/117) and loaded with `--no-package --skip-web-build --kind-load`, then up.sh's `helm upgrade
    --install` (so `up.sh --deploy` minus the rebuild). All pods Ready; `seed-users.sh`; `smoke.sh core game athlete finance`
    SMOKE PASSED (60 ok, busy-machine mode). In Grafana: trace `hoops.hoops ingress` -> router -> `core-service GET
    /api/core/teams`; the roster PDF `hoops.hoops` -> `core-service GET /api/core/teams/{teamId}/roster:export` ->
    `POST /internal/pdf/team-roster` (client) -> `pdf-service POST /internal/pdf/team-roster` -> `render` (200, `%PDF-`);
    logs of all five services in Loki (core 131, game 139, athlete 150, pdf 198, finance 14 in 30 min); Tempo traces of
    all five plus Envoy; every dashboard query returned data (requests 5-6 series, authz 7 kinds, security events 24 log
    lines); a `not_member` log line's `trace_id` opened its trace; the tenant id appeared in no span of the proof traces and
    in no dashboard result. Grafana: anonymous Viewer, `admin/admin` 403, creating a data source 403, Service ClusterIP.
  - **Memory**: `lgtm` working set 529-677 Mi, anon 507 Mi, `memory.current` 1164 Mi (640 Mi page cache), peak 1257 Mi;
    idle 0.13 core; `/data` 70 MB after the proof. Whole node 3.45 GiB working set; VM 4.6 / 7.9 GB used, 3.3 GB available.
    It fits with compose stopped. Under VM load 40 (startup of all JVMs) core and athlete were restarted by their own
    liveness probes and `lgtm`'s probe timed out once (no restart); that is symptom D of the kind runbook, not memory.
- Decisions/ADRs: ADR-0046 amendment (no new ADR). Choices: retention 24 h (P-07 suggested up to 30 days; Loki's minimum,
  dev-sized); metrics scraped by the collector rather than by LGTM's Prometheus (everything behind the collector); the
  anonymous Viewer instead of a generated admin password (nothing to store, no admin at all); cloud keeps Jaeger; requests
  and errors from Tempo span metrics (the only per-request source for all five services).
- Open points / follow-ups:
  - **Services must emit** (not changed here): no database spans anywhere (core / game / athlete need
    `quarkus.datasource.jdbc.telemetry=true`, build-time; finance pgx has no tracer), so "gateway -> core -> database"
    ends at core; pdf-service and finance-service trace their own `/q/health` probes and `/q/metrics` scrapes (filtered in
    the dashboard, still stored); pdf-service and finance-service have no request metrics (only span metrics cover them).
  - Still not exported: Keycloak's log and events, Envoy's access log and metrics, Redpanda, CNPG / Postgres, Envoy
    Gateway and operator logs.
  - Seen once under VM load 40: core's spans of one trace stored twice (same span id; most likely an OTLP retry after an
    exporter timeout); not seen on a quiet VM.
  - `tilt ci` not run (the VM was at load 10-40 during the window; it would rebuild every image inside the compose-down
    window); Tilt resource changed (jaeger -> lgtm, port 3000) but unproven.
  - Not mine, for the docs pass: `docs/security/privacy-threat-model.md` P-07 / retention table can now say "24 h on kind
    and compose (WP120)"; `docs/runbooks/release.md` still says Jaeger is "for kind only" (it is the cloud's now).
  - `just test` not run: no Java, Rust or Go code changed (chart, compose, scripts, docs only).
