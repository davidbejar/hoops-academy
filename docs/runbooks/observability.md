# Runbook: traces, logs and metrics (OpenTelemetry, Grafana LGTM)

WP86, WP120, [ADR-0046](../adr/0046-opentelemetry-collector-traces-and-logs.md) and its amendment. The services export their
traces and logs over OTLP to the chart's collector `otel-collector`, which also scrapes their `/q/metrics`; the Envoy proxy
adds the edge span. On kind and in the compose profile `observability` the collector sends all three signals to one Grafana
LGTM pod `lgtm` (Grafana, Loki, Tempo, Prometheus). Switch: `global.observability.enabled` (on in `values-kind.yaml`, off by
default); backend: `observability.lgtm.enabled` (on in `values-kind.yaml`, off in `values-cloud.yaml`, which keeps an
in-memory Jaeger for the traces).

## What flows where
| Source | Signal | To |
|---|---|---|
| core, game, athlete (`QUARKUS_OTEL_*` from the chart) | traces (server, REST client, Kafka spans), logs (every log record, MDC as attributes) | `otel-collector:4317` (OTLP gRPC) |
| pdf-service, finance-service (`OTEL_*` from the chart) | traces and logs (security events as attributes) | `otel-collector:4318` (OTLP/HTTP) |
| Envoy proxy (`EnvoyProxy.spec.telemetry.tracing`, when the chart renders the EnvoyProxy) | edge span, W3C `traceparent` to the services | `otel-collector:4317` |
| the five services' `/q/metrics` | `hoops_authz_denied_total`, Micrometer (`http_server_requests_*`, JVM), the replica and outbox counters | scraped by `otel-collector` every 30 s (job = Service name) |
| `otel-collector` | traces, logs, metrics | `debug` exporter (counts in its own log); kind: `lgtm:4317`; cloud: traces to `jaeger:4317`; elsewhere the backend you configure |
| `lgtm` | Loki (logs), Tempo (traces, span metrics `traces_spanmetrics_*` into Prometheus), Prometheus (metrics) | Grafana, port-forward only |

Sampling: Envoy and the services sample root spans at `global.observability.tracesSampleRatio` (0.1 default, 1.0 on kind);
children follow the parent. Logs and scraped metrics are not sampled; span metrics count sampled spans only. Span attributes
with concrete paths or Kafka keys (`url.full`, `url.path`, `url.query`, `http.url`, `http.target`,
`messaging.kafka.message.key`) are deleted in the collector, so no tenant id leaves in a span; the route template
(`http.route`) and the span names stay. Log records keep their MDC (`tenantId`, as in the JSON console log).

## kind: open Grafana
```bash
source scripts/env.sh
deploy/kind/up.sh --deploy            # or tilt up (Tilt forwards Grafana to :3000 already)
deploy/kind/seed-users.sh
deploy/kind/smoke.sh core game athlete finance
kubectl -n hoops port-forward svc/lgtm 3000:3000        # http://localhost:3000
```
No login: the browser is an anonymous **Viewer** (Explore allowed); the login form and basic auth are off, so the image's
`admin/admin` does not work and nobody can change data sources or install plugins. Grafana has no route and the pod has
no egress: only who can port-forward in namespace `hoops` sees it (operators, P-07).

Dashboards, folder **Hoops Academy** (files in `deploy/helm/hoops/files/grafana/dashboards`, read-only in the UI):
- **requests and errors**: server spans per second, 5xx (status ERROR) per second and ratio, p95 latency per service (the
  Envoy gateway `hoops.hoops` included; `/q/` probe and scrape spans left out), requests by operation (route templates),
  and core / game / athlete HTTP statuses from Micrometer.
- **authorisation denials**: `hoops_authz_denied_total` by kind and by service (`job`).
- **security events**: the `authz_denied` log records by kind, by service, the most refused route templates, and the
  events themselves with kind, status, route, reason and a `trace_id` link to Tempo. Subject, roles and tenant are dropped
  by the query (`keep`); Explore on Loki still shows them to the operator (they are in the record, ADR-0046).

Explore: **Tempo** (search by service, span name, or a trace id: a Problem response carries `"traceId"`), **Loki**
(`{service_name="core-service"}`; a line's `trace_id` field links to its trace, and a trace's spans link back to their
logs), **Prometheus**. The same from a shell, through Grafana's data source proxy:
```bash
G=http://localhost:3000/api/datasources/proxy/uid
curl -s -G "$G/tempo/api/search" --data-urlencode 'q={ resource.service.name = "pdf-service" }' | jq '.traces[0]'
curl -s "$G/tempo/api/v2/traces/<trace id>" | jq -r '.trace.resourceSpans[] | (.resource.attributes[]
  | select(.key=="service.name") | .value.stringValue) as $s | .scopeSpans[].spans[] | "\($s) \(.name)"'
curl -s -G "$G/loki/loki/api/v1/query" --data-urlencode 'query=sum by (service_name) (count_over_time({service_name=~".+"} [15m]))'
curl -s "$G/prometheus/api/v1/query" --data-urlencode 'query=sum by (job, kind) (hoops_authz_denied_total)'
```
Example (WP120 on kind): admin1's roster PDF `GET /api/core/teams/{teamId}/roster:export` (`Accept: application/pdf`) is
one trace `hoops.hoops ingress` -> `router httproute/hoops/core-service-roster-export/rule/0 egress` -> `core-service GET
/api/core/teams/{teamId}/roster:export` -> `core-service POST /internal/pdf/team-roster` (client) -> `pdf-service POST
/internal/pdf/team-roster` -> `pdf-service render`. Since WP143 (ADR-0074) core, game, athlete and finance add one
client span per SQL statement under the span that runs it (`db.system = postgresql`, `db.statement` parameterised,
never a bound value; the first is the tenant's `set_config`); a database span without a parent is dropped, so the
scheduled jobs and core's outbox poll start no trace. In Grafana: TraceQL `{ span.db.system = "postgresql" }`.

## Retention, storage, memory (dev only)
- **24 h** for logs (Loki compactor retention), traces (Tempo block retention) and metrics (Prometheus TSDB):
  `observability.lgtm.retention` (Loki: a multiple of 24h, its minimum), passed as the image's `LOKI_EXTRA_ARGS`,
  `TEMPO_EXTRA_ARGS`, `PROMETHEUS_EXTRA_ARGS`. Check: `kubectl -n hoops exec deploy/lgtm -- curl -s localhost:3100/config |
  grep retention_period` (`1d`), `... localhost:3200/status/config | grep block_retention` (`24h0m0s` twice).
- **No persistence**: `/data` is an emptyDir capped at 2 Gi (`dataSizeLimit`), `/var/tempo` and `/tmp` emptyDirs; a restart
  or any change of the dashboards or settings (the pod's checksum) starts empty. Compose: tmpfs.
- **Memory** (WP120, kind, all five services, after the smoke run and the proof traffic): working set 530-680 Mi, anon
  ~510 Mi; the cgroup also holds ~640 Mi of page cache (the 2.7 GB image's binaries), so `memory.current` reads ~1.2 Gi
  against the 1280 Mi limit; the cache is reclaimed before an OOM. Request 512 Mi, limit 1280 Mi
  (`observability.lgtm.resources`). The whole node: ~3.4 GiB working set, the VM 4.6 of 7.9 GB used with compose stopped.
  Idle CPU ~0.13 core. Startup: ~10 s on a quiet VM, 216 s (Grafana) at VM load 40; the startup probe allows 10 min.
- An OOM-kill or a liveness failure of `lgtm` loses the data and the collector's batches for that time; the services are
  unaffected.

## compose: the profile `observability`
```bash
just observability-up        # otel-collector (127.0.0.1:4317/4318) + lgtm (Grafana http://localhost:3000)
QUARKUS_OTEL_SDK_DISABLED=false ./mvnw -pl services/core-service quarkus:dev   # exports to localhost:4317
HOOPS_OTEL_SDK_DISABLED=false just pdf-up                                      # or finance-up: OTLP to otel-collector:4318
just observability-down      # removes both containers and their data
```
Same image pins, collector processors and pipelines (`infra/compose/otel-collector.yaml`), Grafana settings, retention and
dashboard files as the chart (`deploy/helm/tests/run.sh` compares them). The collector scrapes the five services on their
host ports through `host.containers.internal`; one that is not running logs a `Failed to scrape Prometheus endpoint`
warning every 30 s and nothing else. Data lives in tmpfs (512 MB, inside the container's 1536 MB memory limit). WP120:
pdf-service with `HOOPS_OTEL_SDK_DISABLED=false` and ten refused calls gave traces in Tempo, the ten `authz_denied`
records in Loki and `hoops_authz_denied_total{job="pdf-service"}` in Prometheus.

## Not exported
Keycloak's log and events (`org.keycloak.events`, see Security events below), Envoy's access log and its metrics, Redpanda,
CloudNativePG / Postgres, Envoy Gateway and the operators: `kubectl logs` / `podman logs` as before. The scheduled
jobs' SQL (no parent span, above). pdf-service and finance-service trace their own `/q/health` probes and the collector's `/q/metrics` scrapes (the
requests dashboard filters `/q/`).

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
# kind / compose profile: Grafana, dashboard "security events", or Explore on Loki:
#   {service_name=~".+"} | security_event="authz_denied"
# without Grafana, with debugVerbosity normal (prints log bodies, not the default):
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
       pipelineExporters: {traces: [otlp_http/backend], logs: [otlp_http/backend], metrics: [otlp_http/backend]}
       secretEnv: [{name: OTLP_AUTH, secretName: hoops-otel-backend, key: auth}]   # Secret created outside the chart
       networkPolicy:
         extraEgress: [{ports: [{port: 443, protocol: TCP}]}]                      # narrow `to:` if you can
   ```
   The credential stays in the Secret (ADR-0012); with `global.reloader.enabled` the collector rolls when it changes.
   With ESO, add an `externalSecrets.secrets` entry for it.
2. **The platform's collector/agent**: `observability.collector.enabled=false` and
   `global.observability.otlpEndpoint=http://<agent>:4317`. No collector, no LGTM, no Jaeger, no edge tracing from the chart
   (configure the EnvoyProxy tracing of the platform's gateway there).

Keep `debugVerbosity: basic` outside kind (the debug exporter would copy log bodies into the collector's own log).
Retention, access control and integrity of the stored logs are the backend's (ASVS 16.4.2). Do not copy the dev LGTM
settings (anonymous Viewer, 24 h, no persistence) into a real environment.

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
- No data in Grafana: `kubectl -n hoops logs deploy/otel-collector | grep -i 'error\|fail'` (export to `lgtm:4317`,
  scrapes); `kubectl -n hoops get pod -l app.kubernetes.io/name=lgtm` (restarted = empty); in Prometheus `up` by `job`
  shows the scrapes (0 = the NetworkPolicy or the service).
- `lgtm` not Ready: `kubectl -n hoops logs deploy/lgtm` lists each component's startup; the health script
  (`/otel-lgtm/docker/healthcheck.sh`) checks Grafana, Loki, Tempo, Prometheus and the image's collector. Set
  `ENABLE_LOGS_ALL=true` in the Deployment (or `ENABLE_LOGS_LOKI`, ...) to see a component's own log.
- Dashboards missing: they come from the ConfigMap `lgtm-dashboards` (provider `lgtm-dashboard-provider`, folder Hoops
  Academy); a JSON error is in Grafana's log (`ENABLE_LOGS_GRAFANA=true`).
