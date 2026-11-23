{{- define "hoops-lib.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "hoops-lib.fullname" . }}
  labels:
    {{- include "hoops-lib.labels" . | nindent 4 }}
spec:
  type: ClusterIP
  selector:
    {{- include "hoops-lib.selectorLabels" . | nindent 4 }}
  ports:
    - name: http
      port: {{ .Values.port }}
      targetPort: http
      protocol: TCP
{{- end -}}
