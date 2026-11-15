{{- define "pdf-service.fullname" -}}
{{- default .Chart.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pdf-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pdf-service.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "pdf-service.labels" -}}
{{ include "pdf-service.selectorLabels" . }}
app.kubernetes.io/part-of: hoops-academy
app.kubernetes.io/component: backend
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "pdf-service.image" -}}
{{- $g := .Values.global | default dict -}}
{{- printf "%s:%s" .Values.image.repository (toString (.Values.image.tag | default $g.imageTag | default "dev")) -}}
{{- end -}}
