# Runbook: traces and logs (OpenTelemetry)

WP86, [ADR-0046](../adr/0046-opentelemetry-collector-traces-and-logs.md). The services export their traces and logs over
OTLP to the chart's collector `otel-collector`; the Envoy proxy adds the edge span. Metrics stay on Prometheus
(`/q/metrics`, ADR-0017). Switch: `global.observability.enabled` (on in `values-kind.yaml`, off by default).

## What flows where
| Source | Signal | To |
|---|---|---|
| core, game, athlete (`QUARKUS_OTEL_*` from the chart) | traces (server, REST client, Kafka spans), logs (every log record, MDC as attributes) | `otel-collector:4317` (OTLP gRPC) |
| Envoy proxy (`EnvoyProxy.spec.telemetry.tracing`, when the chart renders the EnvoyProxy) | edge span, W3C `traceparent` to the services | `otel-collector:4317` |
| `otel-collector` | traces and logs | `debug` exporter (its own log), on kind traces to `jaeger:4317`; elsewhere the backend you configure |

Sampling: Envoy and the services sample root spans at `global.observability.tracesSampleRatio` (0.1 default, 1.0 on kind);
children follow the parent. Logs are not sampled. Span attributes with concrete paths or Kafka keys (`url.full`, `url.path`,
`url.query`, `http.url`, `http.target`, `messaging.kafka.message.key`) are deleted in the collector, so no tenant id leaves
in a span; the route template (`http.route`) and the span names stay. Log records keep their MDC (`tenantId`, as in the
JSON console log).

## kind: see a trace
```bash
source scripts/env.sh
deploy/kind/up.sh --deploy            # or tilt up; values-kind.yaml switches observability on
deploy/kind/seed-users.sh
deploy/kind/smoke.sh core game athlete
# the collector prints one line per span: "<span name> <trace id> <span id> <attributes>"
kubectl -n hoops logs deploy/otel-collector | grep '/platform/tenants'
# Jaeger UI (in-memory, 5000 traces, lost on restart); Tilt forwards it already
kubectl -n hoops port-forward svc/jaeger 16686:16686    # http://localhost:16686
curl -s localhost:16686/api/v3/services                  # core-service, game-service, athlete-service, hoops.hoops (Envoy)
curl -s localhost:16686/api/v3/traces/<trace id> | jq -r '.result.resourceSpans[] | (.resource.attributes[]
  | select(.key=="service.name") | .value.stringValue) as $s | .scopeSpans[].spans[] | "\($s) \(.name)"'
```
A request through the gateway gives one trace. Example (WP86 on kind, superadmin `GET /platform/tenants/{id}/usage`):
`hoops.hoops ingress` -> `hoops.hoops router httproute/hoops/core-service-platform/rule/0 egress` -> `core-service GET
/platform/tenants/{tenantId}/usage` -> two `core-service GET /internal/usage/{tenantId}` client spans -> `game-service` and
`athlete-service GET /internal/usage/{tenantId}`. game/athlete -> core `/internal/...` shows the same way with
`rosterSource=rest`. A Problem response carries the trace id (`"traceId":"..."`): paste it into the UI's search box.

## kind: see the logs
```bash
kubectl -n hoops logs deploy/otel-collector | grep -A3 'ResourceLog' | grep -v '^--'
# "ResourceLog #0 deployment.environment.name=kind host.name=<pod> ... service.name=core-service ..."
# then one line per record: "<message> <attributes>", e.g. the audit trail
# "audit action=tenant.created target=tenant:<id> actor=<sub> tenant=<id> bridge.name=hoops.audit code.function.name=..."
```
`debugVerbosity: normal` (kind) prints one line per span and per log record; `basic` (default) prints only counts.

## Collector down
Export failures are logged by the services (`VertxGrpcSender: Failed to export ... Timeout 10000 (ms) fired`, once per
failed batch) and never affect health; the Gateway stays `Programmed` (Envoy reaches the collector by DNS name, ADR-0046):
```bash
kubectl -n hoops scale deploy/otel-collector --replicas=0
deploy/kind/smoke.sh core game athlete        # still green; the services stay Ready
kubectl -n hoops scale deploy/otel-collector --replicas=1
```
Data produced while the collector is down is dropped after the exporters' retries (no disk buffer).

## Another environment
The chart standardises the OTLP egress; the backend is the environment's (Grafana Cloud / Tempo + Loki, a vendor's OTLP
endpoint, the platform's own collector). Two ways:
1. **The chart collector forwards** (values overlay):
   ```yaml
   global:
     observability: {enabled: true, tracesSampleRatio: "0.1", environment: production}
   observability:
     collector:
       exporters:
         otlp_http/backend:
           endpoint: https://otlp.example.net/otlp
           headers: {authorization: "Basic ${env:OTLP_AUTH}"}
       pipelineExporters: {traces: [otlp_http/backend], logs: [otlp_http/backend]}
       secretEnv: [{name: OTLP_AUTH, secretName: hoops-otel-backend, key: auth}]   # Secret created outside the chart
       networkPolicy:
         extraEgress: [{ports: [{port: 443, protocol: TCP}]}]                      # narrow `to:` if you can
   ```
   The credential stays in the Secret (ADR-0012); with `global.reloader.enabled` the collector rolls when it changes.
   With ESO, add an `externalSecrets.secrets` entry for it.
2. **The platform's collector/agent**: `observability.collector.enabled=false` and
   `global.observability.otlpEndpoint=http://<agent>:4317`. No collector, no Jaeger, no edge tracing from the chart
   (configure the EnvoyProxy tracing of the platform's gateway there).

Keep `debugVerbosity: basic` outside kind (the debug exporter would copy log bodies into the collector's own log).
Retention, access control and integrity of the stored logs are the backend's (ASVS 16.4.2).

## Troubleshooting
- No spans in the collector: `kubectl -n hoops get cm core-service-env -o yaml | grep OTEL` (SDK `false`, endpoint);
  the service log shows `Failed to export` when the collector is unreachable; the NetworkPolicy admits only pods named in
  `observability.collector.clients` and Envoy proxies.
- No Envoy span: `kubectl -n hoops get envoyproxy hoops -o yaml | grep -A6 tracing`; the proxy pods must carry the labels
  `app.kubernetes.io/component=proxy` and `gateway.envoyproxy.io/owning-gateway-name=hoops` (the NetworkPolicy admits
  only those; not `managed-by`, which Tilt rewrites to `tilt` even inside selectors). Envoy's view:
  `kubectl -n envoy-gateway-system port-forward <envoy pod> 19000` and `curl -s localhost:19000/clusters | grep tracing`
  (`cx_connect_fail` > 0 = the policy or the Service).
- Collector OOM: raise `observability.collector.resources.limits.memory`; `memory_limiter` refuses data above 80 % of it.
