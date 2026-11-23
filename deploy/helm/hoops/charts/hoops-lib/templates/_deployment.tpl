{{- /*
The Deployment of a service. Arguments (a dict):
  ctx       the calling chart's root context
  env       the container's env section as the chart renders it (from "env:" on, unindented); empty: none
  reloader  the pod reads a Secret, so global.reloader.enabled annotates it for Stakater Reloader
  tmp       an emptyDir at /tmp (the JVM needs one; the Rust and Go binaries write nothing)
Values read from the chart: replicaCount (left out while hpa.enabled), port, image, imagePullSecrets, podSecurityContext,
securityContext, resources, metrics, podAnnotations, existingSecret, probes (mode http or tcp), nodeSelector, tolerations,
affinity. The pod rolls when the chart's templates/configmap.yaml changes (checksum/env).
*/ -}}
{{- define "hoops-lib.deployment" -}}
{{- $c := .ctx -}}
{{- $fullname := include "hoops-lib.fullname" $c -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $fullname }}
  labels:
    {{- include "hoops-lib.labels" $c | nindent 4 }}
  {{- if and .reloader (dig "reloader" "enabled" false ($c.Values.global | default dict)) }}
  annotations:
    # Stakater Reloader (WP87, ADR-0012): roll the pods when a Secret they read changes (ESO refresh, secrets.sh).
    secret.reloader.stakater.com/auto: "true"
  {{- end }}
spec:
  {{- if not ($c.Values.hpa | default dict).enabled }}
  replicas: {{ $c.Values.replicaCount }}
  {{- end }}
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      {{- include "hoops-lib.selectorLabels" $c | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "hoops-lib.labels" $c | nindent 8 }}
      annotations:
        checksum/env: {{ include (print $c.Template.BasePath "/configmap.yaml") $c | sha256sum }}
        {{- if $c.Values.metrics.enabled }}
        prometheus.io/scrape: "true"
        prometheus.io/path: {{ $c.Values.metrics.path | quote }}
        prometheus.io/port: {{ $c.Values.port | quote }}
        {{- end }}
        {{- with $c.Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      automountServiceAccountToken: false
      enableServiceLinks: false
      {{- with (default ($c.Values.global | default dict).imagePullSecrets $c.Values.imagePullSecrets) }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      securityContext:
        {{- toYaml $c.Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ $fullname }}
          image: {{ include "hoops-lib.image" $c | quote }}
          imagePullPolicy: {{ $c.Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ $c.Values.port }}
              protocol: TCP
          envFrom:
            - configMapRef:
                name: {{ $fullname }}-env
            {{- with $c.Values.existingSecret }}
            - secretRef:
                name: {{ . }}
            {{- end }}
          {{- with (.env | default "" | trim) }}
          {{- . | nindent 10 }}
          {{- end }}
          {{- with $c.Values.probes }}
          {{- $tcp := eq (default "http" .mode) "tcp" }}
          startupProbe:
            {{- if $tcp }}
            tcpSocket: {port: http}
            {{- else }}
            httpGet: {path: {{ .startup.path }}, port: http}
            {{- end }}
            periodSeconds: {{ .startup.periodSeconds }}
            failureThreshold: {{ .startup.failureThreshold }}
            timeoutSeconds: {{ .startup.timeoutSeconds }}
          livenessProbe:
            {{- if $tcp }}
            tcpSocket: {port: http}
            {{- else }}
            httpGet: {path: {{ .liveness.path }}, port: http}
            {{- end }}
            periodSeconds: {{ .liveness.periodSeconds }}
            failureThreshold: {{ .liveness.failureThreshold }}
            timeoutSeconds: {{ .liveness.timeoutSeconds }}
          readinessProbe:
            {{- if $tcp }}
            tcpSocket: {port: http}
            {{- else }}
            httpGet: {path: {{ .readiness.path }}, port: http}
            {{- end }}
            periodSeconds: {{ .readiness.periodSeconds }}
            failureThreshold: {{ .readiness.failureThreshold }}
            timeoutSeconds: {{ .readiness.timeoutSeconds }}
          {{- end }}
          resources:
            {{- toYaml $c.Values.resources | nindent 12 }}
          securityContext:
            {{- toYaml $c.Values.securityContext | nindent 12 }}
          {{- if .tmp }}
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir:
            sizeLimit: 256Mi
          {{- end }}
      {{- with $c.Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $c.Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $c.Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}
