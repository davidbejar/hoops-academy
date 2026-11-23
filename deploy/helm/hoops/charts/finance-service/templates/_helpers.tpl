{{- /* The shared helpers and templates are in the library chart hoops-lib (ADR-0068). */ -}}

{{/* The container's secret environment (the YAML comment is part of the rendered Deployment). */}}
{{- define "finance-service.env" -}}
# Secrets created before the install (ADR-0012): the database roles' and, with events, the broker user's.
env:
  - name: FINANCE_APP_PASSWORD
    valueFrom: {secretKeyRef: {name: {{ .Values.database.appSecret }}, key: password}}
  - name: FINANCE_MIGRATOR_PASSWORD
    valueFrom: {secretKeyRef: {name: {{ .Values.database.migratorSecret }}, key: password}}
  {{- if include "hoops-lib.eventsEnabled" . }}
  - name: KAFKA_SASL_PASSWORD
    valueFrom: {secretKeyRef: {name: {{ .Values.events.passwordSecret }}, key: password}}
  {{- end }}
{{- end -}}

{{/* Ingress: only the Envoy proxies (Envoy Gateway's namespace). */}}
{{- define "finance-service.ingressFrom" -}}
- namespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: {{ .Values.networkPolicy.gatewayNamespace }}
{{- end -}}
