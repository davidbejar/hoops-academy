{{- define "keycloak.fullname" -}}{{ default .Chart.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{- end -}}
{{- define "keycloak.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keycloak.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "keycloak.labels" -}}
{{ include "keycloak.selectorLabels" . }}
app.kubernetes.io/part-of: hoops-academy
app.kubernetes.io/component: identity
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}
