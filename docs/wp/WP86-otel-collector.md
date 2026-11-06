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
<!-- Appended by the agent when done: Built, Verified, Decisions/ADRs, Open points (work-package skill). -->
