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

## Security events
ADR-0043 (WP85). Two sources, both in the logs; nothing extra to deploy.

**Services** (`core`, `game`, `athlete`): one WARN record of category `hoops.security` per refused request, message
`authz_denied kind=<kind> outcome=<status> tenant=<id> subject=<sub> roles=<roles> resource="<METHOD /route/{template}>"
reason="<reason>"`, the same values as MDC fields (`security.event=authz_denied`, `security.kind`, `security.outcome`,
`tenantId`, `security.subject`, `security.roles`, `security.resource`, `security.reason`): in the JSON console log under
`mdc`, in the OTLP log record as attributes, so they reach the collector and the backend with every other log line.

| kind | status | decided by | reason |
|---|---|---|---|
| `unauthenticated` | 401 | tenant filter, `@Authenticated` / `@RolesAllowed` | `no credentials` |
| `invalid_token` | 401 | Quarkus OIDC (`AuthenticationFailureEvent`), a token without `sub` | `expired`, `not_yet_valid`, `audience`, `signature`, `issuer`, `invalid`, `no_sub` |
| `not_member` | 404 | tenant filter | `no membership in the requested tenant` |
| `tenant_mismatch` | 404 | tenant filter (the resolver answered another tenant's membership: a bug, never bound) | `membership resolved for another tenant` |
| `role` | 403 | `@RequiresTenantRole` | `Requires one of [...]` |
| `fine_grained` | 403 | `Authz.require`, any `AccessDeniedException` of a use case | the check's text, e.g. `Not staff of this team` |
| `realm_role` | 403 | `@RolesAllowed` (`super_admin` on /platform, `service` on /internal) | `Resource#method` |

Never in an event: tokens, claims of a refused token, names, e-mails, exception messages; the subject is the `sub` id.
Metric: `hoops_authz_denied_total{kind}` on `/q/metrics` (every kind present from start at 0).
```bash
# compose / dev: the plain console format shows the message
grep 'hoops.security\|authz_denied' <service log>
# kind, through the collector (debugVerbosity normal):
kubectl -n hoops logs deploy/otel-collector | grep -B1 -A2 authz_denied
# rate per kind (Prometheus): sum by (kind) (rate(hoops_authz_denied_total[5m]))
curl -s localhost:8081/q/metrics | grep hoops_authz_denied_total   # one service directly
```
A burst of `not_member` / `invalid_token` from one client is probing; many `fine_grained` for one subject after a
release is more likely a role-matrix regression (compare with `docs/domain/authz-matrix.md`).

**Keycloak** (realm `academy`): the `jboss-logging` event listener writes every login, logout, token, password, OTP and
lockout event as a line of category `org.keycloak.events` (`type="LOGIN_ERROR", realmName="academy", clientId=..., userId=...,
ipAddress=..., error="invalid_user_credentials", ..., username="<e-mail>"`): failures at WARN, successes at INFO
(`KC_SPI_EVENTS_LISTENER__JBOSS_LOGGING__SUCCESS_LEVEL=info`). Admin events (`operationType=..., resourceType=...,
resourcePath=...`) without representation. The user events of the realm's list and the admin events are also stored in
Keycloak's database for 30 days: admin console, realm `academy`, "Events" (user / admin), or
`GET /auth/admin/realms/academy/events?type=LOGIN_ERROR`. The `username` field is the login's e-mail: Keycloak's log and
store are the only places that hold it (ADR-0043).
```bash
podman logs hoops-keycloak 2>&1 | grep 'org.keycloak.events'                  # compose
kubectl -n hoops logs deploy/keycloak | grep 'org.keycloak.events'        # kind (the pod's log; not exported over OTLP)
```
An existing compose realm gets the event settings from `just seed-users`; on kind recreate the Keycloak database
(`IGNORE_EXISTING`, ADR-0038) or set them in the admin console (Realm settings, "Events").

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
