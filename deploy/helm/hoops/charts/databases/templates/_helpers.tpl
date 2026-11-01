{{- define "databases.labels" -}}
app.kubernetes.io/part-of: hoops-academy
app.kubernetes.io/component: database
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}
