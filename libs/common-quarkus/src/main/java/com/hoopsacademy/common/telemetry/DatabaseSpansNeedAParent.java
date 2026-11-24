package com.hoopsacademy.common.telemetry;

import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.context.Context;
import io.opentelemetry.sdk.trace.data.LinkData;
import io.opentelemetry.sdk.trace.samplers.Sampler;
import io.opentelemetry.sdk.trace.samplers.SamplingResult;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import java.util.List;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * The services' sampler (WP143, ADR-0074): the configured parent-based ratio sampler (ADR-0046: root spans kept at
 * {@code quarkus.otel.traces.sampler.arg}, children follow their parent), except that a database span without a parent
 * is dropped. A statement outside any request or job span (core's outbox poll, every second) would otherwise be a trace
 * of its own, with no request to explain it. Quarkus uses a {@link Sampler} bean instead of the one it builds from
 * {@code quarkus.otel.traces.sampler}, so this bean refuses to start for any other configured sampler, and Quarkus
 * still wraps it to keep the management paths untraced.
 */
@Singleton
public final class DatabaseSpansNeedAParent implements Sampler {

    static final String CONFIGURED = "parentbased_traceidratio";
    private static final AttributeKey<String> DB_SYSTEM = AttributeKey.stringKey("db.system");
    private static final AttributeKey<String> DB_SYSTEM_NAME = AttributeKey.stringKey("db.system.name");

    private final Sampler configured;

    @Inject
    DatabaseSpansNeedAParent(@ConfigProperty(name = "quarkus.otel.traces.sampler") String sampler,
            @ConfigProperty(name = "quarkus.otel.traces.sampler.arg", defaultValue = "1.0") double ratio) {
        if (!CONFIGURED.equals(sampler)) {
            throw new IllegalStateException("quarkus.otel.traces.sampler is " + sampler + "; " + getClass().getSimpleName()
                    + " stands in for " + CONFIGURED + " only");
        }
        this.configured = Sampler.parentBased(Sampler.traceIdRatioBased(ratio));
    }

    @Override
    public SamplingResult shouldSample(Context parentContext, String traceId, String name, SpanKind spanKind,
            Attributes attributes, List<LinkData> parentLinks) {
        if (spanKind == SpanKind.CLIENT && isDatabase(attributes)
                && !Span.fromContext(parentContext).getSpanContext().isValid()) {
            return SamplingResult.drop();
        }
        return configured.shouldSample(parentContext, traceId, name, spanKind, attributes, parentLinks);
    }

    @Override
    public String getDescription() {
        return "DatabaseSpansNeedAParent{" + configured.getDescription() + "}";
    }

    private static boolean isDatabase(Attributes attributes) {
        return attributes.get(DB_SYSTEM) != null || attributes.get(DB_SYSTEM_NAME) != null;
    }
}
