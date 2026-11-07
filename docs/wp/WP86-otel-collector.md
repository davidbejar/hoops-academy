# WP86 — Chart: OpenTelemetry collector, services' traces and logs exported, proven on kind

Model: Opus. Wave 2 (2026-11-06, fifth round): starts after wave 1 is merged (WP87 chart 0.8.0); runs alongside
WP73/74/75 (web), WP80 (services), WP89 (CI). You are the only kind user this wave. You own `deploy/helm/**`,
`deploy/kind/*`, `Tiltfile`, `docs/runbooks/{kind,observability}.md` (new), `docs/security/asvs-checklist.md` row
16.4.3, and in the services ONLY `src/main/resources/application.properties` OTel keys (logs export, resource
attributes) plus `libs/common-quarkus` OTel config if a shared default is needed (tell WP80 through the orchestrator
before touching `libs/common-quarkus`; prefer env through the chart). Depends on: WP87 (chart 0.8.0, Reloader),
`quarkus-opentelemetry` already in `libs/common-quarkus` (`QUARKUS_OTEL_SDK_DISABLED=true` in the chart today).
ADR-0046 reserved for you. Skills: podman-dev-env, owasp-security, verification-before-completion. Worktree:
`~/code/hoops-wt/wp86-otel-collector`, branch `wp86-otel-collector`.

Decision 60 of 2026-11-06: an OpenTelemetry collector in the chart with the services' logs and traces exported
(ASVS 16.4.3), proven on kind.

## Scope
0. **WP87's kind proofs first** (its handover lists the order; the machine was saturated during WP87): the
   Reloader rotation proof (rotate `GAME_APP_PASSWORD` through ESO and a `hoops-redpanda-game-service` password: the
   pods restart by themselves, `smoke.sh` green after), a deploy with `events.enabled=false`, the game replica flip,
   `tilt ci`, `up.sh --eso` with the events, a complete `up.sh --eso --deploy`. Record each in `kind.md`
   "Verification status" under WP87/WP86. Wait for a quiet host (load guard of WP87: below 2 per CPU) before each.
1. **Collector**: `otel-collector` Deployment (pinned image by tag + digest, non-root, read-only FS, NetworkPolicy:
   OTLP in from the three services only) behind `observability.enabled` (on in kind values); receivers OTLP gRPC/HTTP;
   exporters: `debug`/logging and a file or an in-cluster backend you pick that is light enough for kind (e.g. a
   pinned Jaeger all-in-one for traces and the collector's own log output, or an OTLP file exporter); say in ADR-0046
   what a real environment would plug in (Grafana stack / vendor) and that the chart only standardises the OTLP egress.
2. **Services**: `QUARKUS_OTEL_SDK_DISABLED=false`, `QUARKUS_OTEL_EXPORTER_OTLP_ENDPOINT`, logs export on
   (`quarkus.otel.logs.enabled` or the Quarkus 3.x equivalent), resource attributes (service name, version, tenant
   never as an attribute: PII rule), sampling (parent-based, ratio in values), through the chart env behind the switch.
   Health unaffected when the collector is down (export failures are logged, not fatal: test by scaling it to 0).
3. **Chart tests**: red first: the collector objects when enabled, none when disabled; the services' env; policies;
   kubeconform; snapshots. Chart 0.8.0 → 0.9.0.
4. **kind proof**: `up.sh --deploy`, run the journey or the smoke, show a trace from nginx → core → game (trace id
   in the collector output) and the services' logs arriving; collector down: services stay ready.
5. **Docs**: ADR-0046; `docs/runbooks/observability.md` (how to see traces and logs on kind, what to configure
   elsewhere); ASVS 16.4.3 row.

## Acceptance
- [ ] `deploy/helm/tests/run.sh` ALL CHART TESTS PASSED (new assertions red first); `shellcheck -S warning` clean;
      `trivy fs` misconfig clean
- [ ] kind: trace and logs evidence in the handover; collector-down proof; cluster deleted
- [ ] `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0` green if any service property changed (totals)
- [ ] ADR-0046 indexed (append at the end of `docs/adr/README.md`); handover appended

## Working rules
- Work only in your worktree on your branch; `source scripts/env.sh` first. Do not touch `main`, do not push.
- Commit: `gitleaks protect --staged`, then `git commit --no-verify` with explicit paths (never `git add -A`).
  Conventional Commits. A Claude Code hook runs a ~40 s tenant-isolation test before every commit (it resyncs the
  Podman VM clock itself); it is expected, do not try to bypass it; under host load it may time out: retry one
  `git commit` per command. End every commit message with the lines
  `Co-Authored-By: <the model doing the work, e.g. Claude Opus 5.5> <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Fuaj1aLz4Zxsb2XaUQBcMq`.
- Other agents build at the same time: on a Testcontainers "localhost:2375 failed to respond" or a port clash, re-run
  that module alone with `-Dquarkus.http.test-port=0`. Keep the Mac awake for long runs: `caffeinate -dims -t 14400 &`,
  kill it before reporting.
- Do not edit README.md, docs/HANDOVER.md, docs/wp/FOLLOW-UPS.md; notes go in this file's Handover.
- Finish per the `work-package` skill. Final report to the orchestrator, at most 300 words.

## Handover
- **Built:**
  - Chart 0.9.0 (`hoops-service` 0.7.0), switch `global.observability.enabled` (default off, on in `values-kind.yaml`):
    `templates/observability.yaml` renders `otel-collector` (core distribution `otel/opentelemetry-collector:0.163.2` by digest,
    uid 10001, read-only root FS, drop ALL, no token, 64-256 Mi; OTLP gRPC 4317 / HTTP 4318; `memory_limiter` -> span attribute
    stripping (`url.full`, `url.path`, `url.query`, `http.url`, `http.target`, `messaging.kafka.message.key`) -> `batch`;
    pipelines `traces` and `logs`, no metrics; `debug` exporter, `basic` by default, `normal` on kind) and, on kind,
    `jaeger` (`jaegertracing/jaeger:2.22.0` by digest, in memory, 5000 traces, OTLP gRPC only). NetworkPolicies: collector
    admits the three services (by name) and, gRPC only, this Gateway's Envoy proxies (`component=proxy` +
    `owning-gateway-name/-namespace`), egress DNS + Jaeger + `networkPolicy.extraEgress`; Jaeger admits the collector only,
    no egress. Backend wiring for other environments: `observability.collector.exporters` / `pipelineExporters` /
    `secretEnv` (Reloader annotation when set) / `extraEgress`, or `collector.enabled=false` + `global.observability.otlpEndpoint`
    (render guards for both).
  - Services: the subchart sets `QUARKUS_OTEL_SDK_DISABLED=false`, `QUARKUS_OTEL_EXPORTER_OTLP_ENDPOINT`,
    `QUARKUS_OTEL_TRACES_SAMPLER_ARG` (`tracesSampleRatio`, 0.1 default, 1.0 kind) and `QUARKUS_OTEL_RESOURCE_ATTRIBUTES`
    (`service.namespace`, `deployment.environment.name`, `k8s.namespace.name`; no tenant) when on, `SDK_DISABLED=true` when off
    (removed from the per-service `env` values). Build-time keys in the three `application.properties`:
    `quarkus.otel.logs.enabled=true`, `quarkus.otel.traces.sampler=parentbased_traceidratio`. `libs/common-quarkus` untouched.
  - Edge: the kind `EnvoyProxy` gets `telemetry.tracing` (OpenTelemetry, `host`/`port` of the collector, same ratio).
  - Step 0 fixes found by the WP87 proofs: CNPG role Secrets carry `cnpg.io/reload: "true"` (ExternalSecret `labels`,
    `secrets.sh` `db_role`); `up.sh` runs the CNPG operator with `--leader-elect=false`.
  - Tilt resources `otel-collector`, `jaeger` (UI :16686). Docs: ADR-0046 (indexed), `docs/runbooks/observability.md` (new),
    `kind.md` (Verification status WP86, capacity, URL table), `rotate-secrets.md` (D: the label; status), ASVS 16.4.3 Met (chart).
- **Verified:**
  - `deploy/helm/tests/run.sh`: ALL CHART TESTS PASSED, **175 ok** (WP87: 144), kubeconform 246/246. Red first: `17ef9f9`
    (22 FAIL against chart 0.8.0: collector, Jaeger, policies, pipelines, services' env, build keys, edge tracing, the
    external-collector and backend variants, guards), `52768ff` (CNPG label: 16 missing), `571bab3` (edge by DNS name and
    proxies by owning gateway). `shellcheck -S warning -x` (run.sh, deploy/kind/*.sh) clean; `trivy fs --scanners misconfig
    --severity HIGH,CRITICAL --ignorefile .trivyignore.yaml --exit-code 1 .` exit 0; `kubectl apply --dry-run=server` of the
    final kind render (ESO on) on the cluster: 82 objects, clean.
  - `./mvnw -B -ntp -T 1C verify -Dquarkus.http.test-port=0`: common-quarkus, contracts, e2e (27, 23 skipped), game 411,
    core 871 green; athlete failed once on the known Podman idle-connection flake (`ReplicaAuthzRulesTest`, Kafka Dev Services:
    `localhost:2375 failed to respond`, WP87), re-run alone (`-pl services/athlete-service -am`): **835 tests, 0 failures**,
    BUILD SUCCESS.
  - kind, WP87's six proofs (details and times in `kind.md` "Verification status" WP86): (6) `up.sh --eso --deploy
    --from-host` complete on the second run (13 min 31 s; first run lost the API server at VM load ~30; CNPG operator lost its
    lease, fixed), `smoke.sh` passed; (5) `--eso` with the events: same run, outbox 0 -> 6, both replicas +6; (1) rotation:
    `GAME_APP_PASSWORD` and `REDPANDA_GAME_SERVICE_PASSWORD` through ESO, Reloader restarted game-service in the second the
    Secret changed (log `Changes detected in 'hoops-db-game-app' ... updated 'game-service'`), broker side after `helm upgrade`
    (Job 7 s), `smoke.sh` passed; the DB side needed `cnpg.io/reload` (found, fixed, re-proved on 0.9.0 with no manual step:
    CNPG applied the password within 18 s, new pod Ready in 61 s); (3) `game.rosterSource=replica`: smoke passed with
    "roster source replica"; (2) `events.enabled=false`: all Ready, smoke passed, game/athlete quiet, core's producer not
    (open point); (4) `helm uninstall` + `tilt ci -- --eso --from-host` (chart 0.9.0): all workloads healthy in 4 min 32 s.
  - Traces: superadmin `GET /platform/tenants/{id}/usage` through the gateway = one trace `3b41a334b2f6cb13948017dda52f4ee7`:
    `hoops.hoops ingress` -> `router httproute/hoops/core-service-platform/rule/0 egress` -> `core-service GET
    /platform/tenants/{tenantId}/usage` -> 2 core client spans -> `game-service` and `athlete-service GET
    /internal/usage/{tenantId}`, every span id in the collector's debug output and in Jaeger (`/api/v3/traces/<id>`); the tenant
    id in 0 places of the trace, no `url.path`/`url.full` in the collector output. A 404 Problem carried `traceId` = its trace.
  - Logs: 215 log records from core, game and athlete in the collector within minutes of start (Flyway, startup, the
    `hoops.audit` lines), resource `service.name`, `service.namespace=hoops-academy`, `deployment.environment.name=kind`,
    `host.name=<pod>`.
  - NetworkPolicy: pod in `envoy-gateway-system` with the proxy + owning-gateway labels CONNECTED to 4317; only
    `component=proxy` REFUSED; unlabelled pod in `hoops` REFUSED (Redis policy control: same probe CONNECTED to 6379).
  - Collector down (`scale --replicas=0`): services Ready, 0 restarts, `/q/health/ready` UP, one `VertxGrpcSender: Failed to
    export ... Timeout 10000 (ms) fired` WARN per batch, `smoke.sh` passed (after the `host`/`port` change; with `backendRefs`
    the Gateway went `Accepted=False`, see Decisions); scaled back: Envoy + core spans of the next trace in the collector, logs
    from all three services. Cluster deleted.
- **Decisions/ADRs:** ADR-0046 (indexed). One switch `global.observability.enabled` instead of the briefed
  `observability.enabled` (subcharts see only `global`, as WP87's Reloader switch). Collector = core distribution, debug
  exporter; Jaeger v2 in memory for kind traces (file exporter rejected: distroless, unreadable); the backend is the
  environment's (exporter/secretEnv/egress values or an external collector). Edge tracing by DNS name, not `backendRefs`
  (collector outage un-accepted the Gateway). Proxies admitted by owning-gateway labels (Tilt rewrites `managed-by` even in
  selectors). Span attributes with concrete paths and Kafka keys deleted in the collector; tenant never a resource/span
  attribute; log records keep the MDC `tenantId` like the JSON console log (ADR-0017, WP85 events). Two Quarkus keys are
  build-time, so they live in the services' `application.properties` (no `libs/common-quarkus` change). CNPG role Secrets
  labelled `cnpg.io/reload`; CNPG operator without leader election on kind. Chart 0.9.0, `hoops-service` 0.7.0.
- **Open points / follow-ups:**
  - core with `events.enabled=false`: its Kafka producer `core-events` keeps connecting to `localhost:19092` (2 WARN lines
    every 6-10 s). Needs `mp.messaging.outgoing.core-events.enabled=${CORE_EVENTS_PRODUCER_ENABLED:true}` in core's
    `application.properties` (owner of core) plus the env in `core.events.offEnv`; an env var alone cannot address the channel
    (`MP_MESSAGING_OUTGOING_CORE_EVENTS_ENABLED` maps to channel `core`: core crash-looped with SRMSG00071, rolled back).
  - Envoy Gateway marks a Gateway `Accepted=False` when a tracing `backendRefs` Service has no ready endpoint: kept away by the
    DNS name; worth an upstream issue / a note for clusters that configure their own EnvoyProxy.
  - The Podman API idle-connection flake (WP87 root cause, pending user action: `podman system service --time=0` drop-in) hit
    the full build once more.
  - kind under other agents' Testcontainers builds: the first `up.sh` lost the API server, ESO's webhook readiness flapped
    (first `helm uninstall` timed out), envoy-gateway restarted 7 times; the load guard waits, but the VM is shared.
  - Not built: logs of Keycloak, Envoy access logs and Redpanda to the collector (only the three services and Envoy spans);
    metrics stay Prometheus. Retention/integrity of shipped logs = the backend's (16.4.2).
  - Docs pass: README / HANDOVER / FOLLOW-UPS (WP87's "kind proofs not run" can be closed), `release.md` (chart 0.9.0, the
    observability values for a real environment; not my file this wave).
