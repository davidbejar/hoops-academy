package com.hoopsacademy.common.testing;

import io.quarkus.test.junit.QuarkusTestProfile;
import java.util.Map;

/**
 * The OpenTelemetry SDK on, as with {@code QUARKUS_OTEL_SDK_DISABLED=false} in the chart, with every span handed to
 * {@link RecordedSpans} as it ends and nothing sent over OTLP: a collector listening on localhost:4317 (the owner's
 * {@code just observability-up}) must not receive test spans. The build keys of the services (the JDBC wrapper) stay
 * those of production.
 */
public class TracingProfile implements QuarkusTestProfile {

    @Override
    public Map<String, String> getConfigOverrides() {
        return Map.of(
                "quarkus.otel.sdk.disabled", "false",
                "quarkus.otel.simple", "true",
                "quarkus.otel.exporter.otlp.enabled", "false",
                "quarkus.otel.traces.sampler.arg", "1.0");
    }
}
