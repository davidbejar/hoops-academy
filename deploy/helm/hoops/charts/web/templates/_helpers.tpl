{{- define "web.fullname" -}}{{ default .Chart.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{- end -}}
{{- define "web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "web.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "web.labels" -}}
{{ include "web.selectorLabels" . }}
app.kubernetes.io/part-of: hoops-academy
app.kubernetes.io/component: frontend
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}
