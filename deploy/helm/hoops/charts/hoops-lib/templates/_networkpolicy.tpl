{{- /*
NetworkPolicy of a service that also limits its egress (pdf-service, finance-service). Arguments (a dict):
  ctx      the calling chart's root context
  from     the peers of the first ingress rule, as the chart renders them (from "- " on, unindented)
  targets  egress targets {podLabels, port} of this namespace, in order (DNS comes first, the collector last)
Values read from the chart: networkPolicy.egress.{enabled, collector, extra}. With the umbrella's collector
(global.observability on, no otlpEndpoint) the collector may scrape the http port and receives OTLP on its port.
*/ -}}
{{- define "hoops-lib.networkPolicy" -}}
{{- $c := .ctx -}}
{{- $np := $c.Values.networkPolicy -}}
{{- $obs := dig "observability" dict ($c.Values.global | default dict) -}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "hoops-lib.fullname" $c }}
  labels:
    {{- include "hoops-lib.labels" $c | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "hoops-lib.selectorLabels" $c | nindent 6 }}
  policyTypes: [Ingress{{ if $np.egress.enabled }}, Egress{{ end }}]
  ingress:
    - from:
        {{- .from | trim | nindent 8 }}
      ports:
        - {port: http, protocol: TCP}
    {{- if and $obs.enabled (not $obs.otlpEndpoint) }}
    # the umbrella's collector scrapes /q/metrics (WP120); it holds no token, so the API stays closed to it
    - from:
        - podSelector:
            matchLabels:
              {{- toYaml $np.egress.collector.podLabels | nindent 14 }}
      ports:
        - {port: http, protocol: TCP}
    {{- end }}
  {{- if $np.egress.enabled }}
  egress:
    - to:
        - namespaceSelector:
            matchLabels: {kubernetes.io/metadata.name: kube-system}
          podSelector:
            matchLabels: {k8s-app: kube-dns}
      ports:
        - {port: 53, protocol: UDP}
        - {port: 53, protocol: TCP}
    {{- $targets := .targets }}
    {{- if and $obs.enabled (not $obs.otlpEndpoint) }}
    {{- $targets = append $targets $np.egress.collector }}
    {{- end }}
    {{- range $target := $targets }}
    - to:
        - podSelector:
            matchLabels:
              {{- toYaml $target.podLabels | nindent 14 }}
      ports:
        - {port: {{ $target.port }}, protocol: TCP}
    {{- end }}
    {{- with $np.egress.extra }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
{{- end -}}
