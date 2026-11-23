{{- /* The shared helpers and templates are in the library chart hoops-lib (ADR-0068). */ -}}

{{/* Ingress: the callers only (decision 89), by app.kubernetes.io/name in this namespace. */}}
{{- define "pdf-service.ingressFrom" -}}
- podSelector:
    matchExpressions:
      - key: app.kubernetes.io/name
        operator: In
        values:
          {{- range .Values.callers }}
          - {{ . }}
          {{- end }}
{{- end -}}
