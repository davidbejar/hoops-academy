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

{{/* Gateway API parentRefs (+ hostnames) of every route: the umbrella's Gateway (global.gateway, default "hoops"). */}}
{{- define "keycloak.routeCommon" -}}
{{- $g := (.Values.global | default dict).gateway | default dict -}}
parentRefs:
  - name: {{ $g.name | default "hoops" }}
    {{- with $g.namespace }}
    namespace: {{ . }}
    {{- end }}
{{- with .Values.route.hostnames }}
hostnames:
  {{- range . }}
  - {{ . | quote }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "keycloak.ruleTimeouts" -}}
{{- $g := (.Values.global | default dict).gateway | default dict -}}
{{- with ($g.requestTimeout | default "60s") -}}
timeouts: {request: {{ . }}}
{{- end }}
{{- end -}}

{{/*
X-Forwarded-Host = host[:port] of publicUrl on every rule that reaches Keycloak. With KC_PROXY_HEADERS=xforwarded and
KC_HOSTNAME_BACKCHANNEL_DYNAMIC the back-channel URLs in the discovery document (token, JWKS, userinfo) come from the
forwarded headers; Envoy sets X-Forwarded-Proto but no X-Forwarded-Host, so Keycloak would fall back to the scheme's
default port (http://localhost/...). Setting it also overwrites any client-supplied value.
Response headers Keycloak does not set itself (SD-08 of the 2026-11 review; the same set as infra/compose/nginx/
keycloak-proxy.conf): Permissions-Policy, COOP same-origin (the app signs in by same-page redirect and Keycloak is
same-origin with it), CORP same-origin (CORS requests are not affected).
*/}}
{{- define "keycloak.forwardedHostFilter" -}}
filters:
  - type: RequestHeaderModifier
    requestHeaderModifier:
      set: [{name: X-Forwarded-Host, value: {{ (urlParse .Values.publicUrl).host | quote }}}]
  - type: ResponseHeaderModifier
    responseHeaderModifier:
      set:
        - {name: Permissions-Policy, value: "camera=(), microphone=(), geolocation=(), payment=(), usb=()"}
        - {name: Cross-Origin-Opener-Policy, value: same-origin}
        - {name: Cross-Origin-Resource-Policy, value: same-origin}
{{- end -}}
