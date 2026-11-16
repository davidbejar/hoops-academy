{{- define "finance-service.fullname" -}}
{{- default .Chart.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "finance-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "finance-service.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "finance-service.labels" -}}
{{ include "finance-service.selectorLabels" . }}
app.kubernetes.io/part-of: hoops-academy
app.kubernetes.io/component: backend
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "finance-service.image" -}}
{{- $g := .Values.global | default dict -}}
{{- printf "%s:%s" .Values.image.repository (toString (.Values.image.tag | default $g.imageTag | default "dev")) -}}
{{- end -}}

{{/* "true" when the umbrella's event broker is on (global.events.enabled, the mirror of events.enabled). */}}
{{- define "finance-service.eventsEnabled" -}}
{{- if (((.Values.global | default dict).events | default dict).enabled) }}true{{ end -}}
{{- end -}}

{{- define "finance-service.parentRefs" -}}
{{- $g := (.Values.global | default dict).gateway | default dict -}}
parentRefs:
  - name: {{ $g.name | default "hoops" }}
    {{- with $g.namespace }}
    namespace: {{ . }}
    {{- end }}
{{- end -}}

{{- define "finance-service.ruleTimeouts" -}}
{{- $g := (.Values.global | default dict).gateway | default dict -}}
{{- with ($g.requestTimeout | default "60s") -}}
timeouts: {request: {{ . }}}
{{- end }}
{{- end -}}

{{- define "finance-service.hostnames" -}}
{{- with .Values.route.hostnames -}}
hostnames:
  {{- range . }}
  - {{ . | quote }}
  {{- end }}
{{- end }}
{{- end -}}
