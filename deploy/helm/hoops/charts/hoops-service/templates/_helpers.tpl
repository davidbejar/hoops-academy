{{- /* The shared helpers and templates are in the library chart hoops-lib (ADR-0068). */ -}}

{{/* The container's secret environment: secretEnv plus, with events on, the broker password of this service's SCRAM user
(WP71): Secret hoops-redpanda-<name>, created before the install. KAFKA_* stays the chart's while events are on. */}}
{{- define "hoops-service.env" -}}
{{- $fullname := include "hoops-lib.fullname" . }}
{{- $secretEnv := .Values.secretEnv }}
{{- if include "hoops-lib.eventsEnabled" . }}
{{- range $secretEnv }}
{{- if hasPrefix "KAFKA_" .name }}{{ fail (printf "%s: secretEnv %s is set by the chart while events are on (global.events.enabled)" $fullname .name) }}{{ end }}
{{- end }}
{{- $secretEnv = append $secretEnv (dict "name" "KAFKA_SASL_PASSWORD" "secretName" (printf "hoops-redpanda-%s" $fullname) "key" "password") }}
{{- end }}
{{- with $secretEnv }}
env:
  {{- range . }}
  - name: {{ .name }}
    valueFrom:
      secretKeyRef:
        name: {{ .secretName }}
        key: {{ .key }}
        {{- if .optional }}
        optional: true
        {{- end }}
  {{- end }}
{{- end }}
{{- end -}}
