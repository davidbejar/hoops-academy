//! Logs and traces (ADR-0046): JSON lines on stdout always; with an OTLP endpoint (`OTEL_SDK_DISABLED=false`, chart's
//! `global.observability`) also the spans and the log records over OTLP HTTP/protobuf to the collector, root spans
//! sampled at `OTEL_TRACES_SAMPLER_ARG` (parent-based, so a sampled caller's trace continues here through W3C
//! `traceparent`). Resource: `service.name=pdf-service`, its version, `service.namespace=hoops-academy` and whatever
//! `OTEL_RESOURCE_ATTRIBUTES` adds; never a tenant. Spans carry the method, route and status only (see `http`).

use axum::http::HeaderMap;
use opentelemetry::KeyValue;
use opentelemetry::propagation::Extractor;
use opentelemetry::trace::TracerProvider as _;
use opentelemetry_appender_tracing::layer::OpenTelemetryTracingBridge;
use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::Resource;
use opentelemetry_sdk::logs::SdkLoggerProvider;
use opentelemetry_sdk::propagation::TraceContextPropagator;
use opentelemetry_sdk::trace::{Sampler, SdkTracerProvider};
use tracing_opentelemetry::OpenTelemetrySpanExt;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::{EnvFilter, Layer, filter};

use crate::config::Config;

/// Flushes the exporters when dropped (end of `main`).
#[derive(Debug, Default)]
pub struct Telemetry {
    traces: Option<SdkTracerProvider>,
    logs: Option<SdkLoggerProvider>,
}

impl Drop for Telemetry {
    fn drop(&mut self) {
        if let Some(traces) = self.traces.take() {
            let _ = traces.shutdown();
        }
        if let Some(logs) = self.logs.take() {
            let _ = logs.shutdown();
        }
    }
}

/// Installs the global subscriber (once, from `main`).
pub fn init(config: &Config) -> Result<Telemetry, String> {
    opentelemetry::global::set_text_map_propagator(TraceContextPropagator::new());
    let stdout =
        tracing_subscriber::fmt::layer().json().flatten_event(true).with_current_span(false).with_span_list(false);
    let mut telemetry = Telemetry::default();
    let (trace_layer, log_layer) = match &config.otlp_endpoint {
        Some(endpoint) => {
            let endpoint = endpoint.trim_end_matches('/');
            let resource = Resource::builder()
                .with_service_name("pdf-service")
                .with_attributes([
                    KeyValue::new("service.version", env!("CARGO_PKG_VERSION")),
                    KeyValue::new("service.namespace", "hoops-academy"),
                ])
                .build();
            let spans = opentelemetry_otlp::SpanExporter::builder()
                .with_http()
                .with_endpoint(format!("{endpoint}/v1/traces"))
                .build()
                .map_err(|e| format!("OTLP span exporter: {e}"))?;
            let traces = SdkTracerProvider::builder()
                .with_resource(resource.clone())
                .with_sampler(Sampler::ParentBased(Box::new(Sampler::TraceIdRatioBased(config.traces_sample_ratio))))
                .with_batch_exporter(spans)
                .build();
            let records = opentelemetry_otlp::LogExporter::builder()
                .with_http()
                .with_endpoint(format!("{endpoint}/v1/logs"))
                .build()
                .map_err(|e| format!("OTLP log exporter: {e}"))?;
            let logs = SdkLoggerProvider::builder().with_resource(resource).with_batch_exporter(records).build();
            let trace_layer = tracing_opentelemetry::layer().with_tracer(traces.tracer("pdf-service"));
            // the exporters' own crates log through tracing too: never feed those records back into the exporter
            let log_layer = OpenTelemetryTracingBridge::new(&logs).with_filter(filter::filter_fn(|meta| {
                !["opentelemetry", "reqwest", "hyper", "h2", "tower"].iter().any(|t| meta.target().starts_with(t))
            }));
            telemetry.traces = Some(traces);
            telemetry.logs = Some(logs);
            (Some(trace_layer), Some(log_layer))
        }
        None => (None, None),
    };
    tracing_subscriber::registry()
        .with(EnvFilter::try_new(&config.log_filter).map_err(|_| "PDF_LOG is not a log filter".to_owned())?)
        .with(stdout)
        .with(trace_layer)
        .with(log_layer)
        .try_init()
        .map_err(|e| format!("logging: {e}"))?;
    Ok(telemetry)
}

/// Continues the caller's trace (W3C `traceparent`) when it sent one.
pub fn link_remote_parent(span: &tracing::Span, headers: &HeaderMap) {
    let context = opentelemetry::global::get_text_map_propagator(|propagator| propagator.extract(&Headers(headers)));
    let _ = span.set_parent(context);
}

struct Headers<'a>(&'a HeaderMap);

impl Extractor for Headers<'_> {
    fn get(&self, key: &str) -> Option<&str> {
        self.0.get(key).and_then(|value| value.to_str().ok())
    }

    fn keys(&self) -> Vec<&str> {
        self.0.keys().map(axum::http::HeaderName::as_str).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn headers_are_read_for_the_propagator() {
        let mut map = HeaderMap::new();
        map.insert("traceparent", "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01".parse().unwrap());
        let headers = Headers(&map);
        assert_eq!(headers.get("traceparent").map(str::len), Some(55));
        assert_eq!(headers.keys(), ["traceparent"]);
        assert_eq!(headers.get("tracestate"), None);
    }
}
