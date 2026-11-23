{{- /*
Pieces of a service's ConfigMap environment. Each takes a dict with env (the map being built, changed in place) and ctx
(the chart's root context) and renders nothing.
*/ -}}

{{/* Kafka client of the umbrella's broker (WP71, ADR-0036): Service redpanda of this namespace, SASL/SCRAM as user. */}}
{{- define "hoops-lib.kafkaClientEnv" -}}
{{- $_ := set .env "KAFKA_BOOTSTRAP_SERVERS" (printf "redpanda.%s.svc.cluster.local:9092" .ctx.Release.Namespace) }}
{{- $_ := set .env "KAFKA_SECURITY_PROTOCOL" "SASL_PLAINTEXT" }}
{{- $_ := set .env "KAFKA_SASL_USERNAME" .user }}
{{- end -}}

{{/* OpenTelemetry SDK of the Rust and Go services (ADR-0046) from global.observability: OTLP HTTP/protobuf (4318) to the
umbrella's collector or global.observability.otlpEndpoint with the gRPC port swapped for 4318; resource attributes without
a tenant (service.namespace only where serviceNamespace is set). Off: SDK off. */}}
{{- define "hoops-lib.otlpHttpEnv" -}}
{{- $ns := .ctx.Release.Namespace }}
{{- $obs := dig "observability" dict (.ctx.Values.global | default dict) }}
{{- if $obs.enabled }}
{{- $endpoint := printf "http://otel-collector.%s.svc.cluster.local:4318" $ns }}
{{- with $obs.otlpEndpoint }}{{ $endpoint = replace ":4317" ":4318" . }}{{ end }}
{{- $_ := set .env "OTEL_SDK_DISABLED" "false" }}
{{- $_ := set .env "OTEL_EXPORTER_OTLP_ENDPOINT" $endpoint }}
{{- $_ := set .env "OTEL_TRACES_SAMPLER_ARG" (toString ($obs.tracesSampleRatio | default "0.1")) }}
{{- $attrs := printf "deployment.environment.name=%s,k8s.namespace.name=%s" ($obs.environment | default $ns) $ns }}
{{- if .serviceNamespace }}{{ $attrs = printf "service.namespace=hoops-academy,%s" $attrs }}{{ end }}
{{- $_ := set .env "OTEL_RESOURCE_ATTRIBUTES" $attrs }}
{{- else }}
{{- $_ := set .env "OTEL_SDK_DISABLED" "true" }}
{{- end }}
{{- end -}}
