{{- define "hoops-service.fullname" -}}
{{- default .Chart.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hoops-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hoops-service.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "hoops-service.labels" -}}
{{ include "hoops-service.selectorLabels" . }}
app.kubernetes.io/part-of: hoops-academy
app.kubernetes.io/component: backend
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "hoops-service.image" -}}
{{- $g := .Values.global | default dict -}}
{{- printf "%s:%s" .Values.image.repository (toString (.Values.image.tag | default $g.imageTag | default "dev")) -}}
{{- end -}}

{{/* Gateway API parentRefs: the umbrella's Gateway (global.gateway; standalone default: Gateway "hoops"). */}}
{{- define "hoops-service.parentRefs" -}}
{{- $g := (.Values.global | default dict).gateway | default dict -}}
parentRefs:
  - name: {{ $g.name | default "hoops" }}
    {{- with $g.namespace }}
    namespace: {{ . }}
    {{- end }}
{{- end -}}

{{/* Per-rule request timeout (global.gateway.requestTimeout; ingress-nginx used 60 s proxy timeouts, Envoy 15 s). */}}
{{- define "hoops-service.ruleTimeouts" -}}
{{- $g := (.Values.global | default dict).gateway | default dict -}}
{{- with ($g.requestTimeout | default "60s") -}}
timeouts: {request: {{ . }}}
{{- end }}
{{- end -}}

{{- define "hoops-service.hostnames" -}}
{{- with .Values.route.hostnames -}}
hostnames:
  {{- range . }}
  - {{ . | quote }}
  {{- end }}
{{- end }}
{{- end -}}
