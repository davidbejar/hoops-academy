package com.hoopsacademy.common.telemetry;

import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.context.Context;
import io.opentelemetry.sdk.trace.data.LinkData;
import io.opentelemetry.sdk.trace.samplers.Sampler;
import io.opentelemetry.sdk.trace.samplers.SamplingResult;
import java.util.List;

/** WP143, ADR-0074 (red: the configured sampler only). */
public class DatabaseSpansNeedAParent implements Sampler {

    static final String CONFIGURED = "parentbased_traceidratio";

    private final Sampler configured;

    DatabaseSpansNeedAParent(String sampler, double ratio) {
        this.configured = Sampler.parentBased(Sampler.traceIdRatioBased(ratio));
    }

    @Override
    public SamplingResult shouldSample(Context parentContext, String traceId, String name, SpanKind spanKind,
            Attributes attributes, List<LinkData> parentLinks) {
        return configured.shouldSample(parentContext, traceId, name, spanKind, attributes, parentLinks);
    }

    @Override
    public String getDescription() {
        return configured.getDescription();
    }
}
