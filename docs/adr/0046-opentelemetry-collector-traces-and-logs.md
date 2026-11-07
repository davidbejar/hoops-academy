# ADR-0046: OpenTelemetry collector in the chart: the services' traces and logs over OTLP, the backend is the environment's

- Status: Accepted
- Date: 2026-11-07
- Related: decision 60 of 2026-11-06, WP86, ADR-0017 (observability defaults: OTel in the library, SDK off), ADR-0031
  (Envoy Gateway), ADR-0012 (Secrets, Reloader amendment), ASVS 16.4.3

## Context
ADR-0017 compiled `quarkus-opentelemetry` into the three services with the SDK off, because nothing received the data:
the logs stayed on the container's stdout and ASVS 16.4.3 (logs shipped off the box) was a gap. Decision 60 asks for an
OpenTelemetry collector in the chart with the services' logs and traces exported, proven on kind. Constraints: the kind
node shares a 2-CPU / 8 GiB Podman VM with compose; the chart must not pick a vendor; no tenant id in telemetry metadata.

## Decision
**One switch, `global.observability.enabled`** (off by default, on in `values-kind.yaml`). Global, not `observability.enabled`
as briefed, because the service subcharts see only `global` (the WP87 `global.reloader.enabled` reasoning); one key, no
mirror to keep equal.

**Collector.** `otel-collector` Deployment: the core distribution `otel/opentelemetry-collector` pinned by tag and digest,
uid 10001, read-only root FS, no token, drop ALL, memory limit; config from a ConfigMap (checksum annotation rolls it).
Receivers: OTLP gRPC 4317 and HTTP 4318. Processors: `memory_limiter`, then (traces) `attributes/strip-ids`, then `batch`. Pipelines: `traces` and `logs`; no
metrics pipeline (Prometheus scrapes `/q/metrics`, ADR-0017). Exporters: `debug` (the collector's own log; verbosity
`basic` by default, `normal` on kind: one line per span with its trace id and per log record) and, on kind, `otlp_grpc`
to Jaeger. NetworkPolicy: OTLP in from the pods named in `observability.collector.clients` (the three services) and, gRPC
only, from the Envoy proxies (Envoy Gateway's namespace, labels `component=proxy` and `owning-gateway-name/-namespace` = the
Gateway); out to DNS, Jaeger and `networkPolicy.extraEgress` only.

**Trace store on kind: Jaeger v2 all-in-one, in memory** (`observability.jaeger.enabled`, capped at `maxTraces`, OTLP gRPC
from the collector only, no egress, UI by `kubectl port-forward`). Lighter than a Grafana stack, a UI that shows the
nginx/Envoy -> core -> game tree. Logs on kind are read in the collector's log (`kubectl logs deploy/otel-collector`). An
OTLP file exporter was rejected: the collector image is distroless, so the file cannot be read without a debug container.

**A real environment plugs in its backend; the chart only standardises the OTLP egress.** Either the chart collector
forwards: `observability.collector.exporters` (collector syntax, e.g. `otlp_http` to Grafana Cloud / Tempo + Loki, or a
vendor's OTLP endpoint), `pipelineExporters.{traces,logs}`, credentials as `${env:VAR}` from `secretEnv` (a Secret, ADR-0012;
Reloader rolls the collector), `networkPolicy.extraEgress` for the route out. Or the platform runs its own collector/agent:
`observability.collector.enabled=false` + `global.observability.otlpEndpoint` (the render fails without it; Jaeger needs the
chart collector). Retention, access control and integrity of the stored logs (16.4.2) belong to that backend.

**Services** (through the chart env, behind the switch): `QUARKUS_OTEL_SDK_DISABLED=false`,
`QUARKUS_OTEL_EXPORTER_OTLP_ENDPOINT` (the collector Service, gRPC), `QUARKUS_OTEL_TRACES_SAMPLER_ARG` =
`global.observability.tracesSampleRatio` (0.1 by default, 1.0 on kind), `QUARKUS_OTEL_RESOURCE_ATTRIBUTES` =
`service.namespace=hoops-academy,deployment.environment.name=<environment|namespace>,k8s.namespace.name=<namespace>`
(`service.name`/`service.version` come from Quarkus). Off: `QUARKUS_OTEL_SDK_DISABLED=true` (moved from the per-service
`env` values into the subchart). Two keys are build-time in Quarkus 3.40 and so live in each service's
`application.properties`: `quarkus.otel.logs.enabled=true` (the log handler; it exports only when the SDK is on) and
`quarkus.otel.traces.sampler=parentbased_traceidratio` (the ratio is the runtime `sampler.arg`, default 1.0, so the build
default behaves as before). Export failures are logged by the exporter and never touch health: a collector outage leaves
the services ready (proved on kind by scaling it to 0: one `Failed to export ... Timeout 10000 (ms)` warning per batch, no
restart, `smoke.sh` green; data of the outage is dropped, no disk buffer).

**Edge spans.** When the chart renders the `EnvoyProxy` (kind), it sets `telemetry.tracing` (OpenTelemetry provider,
`host: otel-collector.<namespace>.svc.cluster.local`, `port: 4317`, `samplingFraction` = the same ratio): Envoy starts the
trace and sends W3C `traceparent`, the services' parent-based sampler follows its decision. By DNS name, not `backendRefs`:
on kind, with `backendRefs` and the collector scaled to 0, Envoy Gateway set the Gateway `Accepted=False` ("Invalid tracing
backendRefs ...: no ready endpoints for the related Service hoops/otel-collector") and dropped its `Programmed` condition
(traffic and endpoint updates went on, but every status check failed); by name the Gateway stays `Programmed` and Envoy
only fails to connect. The NetworkPolicy admits the proxies by `component=proxy` + `owning-gateway-name/-namespace`, not by
`app.kubernetes.io/managed-by=envoy-gateway`: Tilt rewrites that label to `tilt`, even inside a NetworkPolicy selector.
Clusters whose EnvoyProxy is the platform's configure it there.

**Tenant id.** Never a resource or span attribute: the chart test checks the resource attributes, no code sets span
attributes, and the collector deletes the span attributes that carry concrete paths or message keys (`/internal/usage/
{tenantId}`, `/platform/tenants/{id}`, Kafka keys `<tenant>:<id>`) before any exporter; `http.route` and the span names are
templates. On kind no span of a `/platform/tenants/{id}/usage` trace contained the tenant id. A log record carries the MDC as attributes (Quarkus' OTel log handler), so `tenantId` travels with the log
line exactly as in the JSON console log of ADR-0017 and the security events of WP85: the shipped log is that log, and
without the tenant a tenant-scoped incident could not be investigated. Personal data rules of the log content stay those
of the log statements (no names, e-mails, tokens).

## Consequences
- ASVS 16.4.3 met on the chart side (logs leave the pod over OTLP); the backend's storage is the environment's.
- Every service span and log costs an OTLP export; sampling bounds traces, not logs. The `batch` processor and the
  services' batch processors keep it to a few requests per second.
- The debug exporter prints log bodies into the collector's own log; in a real environment set `debugVerbosity: basic`
  (default) so it only counts.
- Chart 0.9.0 (`hoops-service` 0.7.0); images must be rebuilt for the two build-time keys.
