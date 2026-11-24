package com.hoopsacademy.common.testing;

import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import io.opentelemetry.api.trace.TraceFlags;
import io.opentelemetry.api.trace.TraceState;
import io.opentelemetry.context.Context;
import java.security.SecureRandom;
import java.util.HexFormat;

/**
 * A fresh W3C trace context with the sampled flag, sent as {@code traceparent} so that one request's spans can be
 * told apart from Flyway's, the scheduler's and the consumers' (WP143).
 */
public record SampledTrace(String traceId, String parentSpanId) {

    private static final SecureRandom RANDOM = new SecureRandom();

    public static SampledTrace random() {
        return new SampledTrace(hex(16), hex(8));
    }

    /** The {@code traceparent} header value: version 00, the ids, flags 01 (sampled). */
    public String traceparent() {
        return "00-" + traceId + "-" + parentSpanId + "-01";
    }

    /** The same remote parent as a context, for a span a test starts itself. */
    public Context context() {
        return Context.root().with(Span.wrap(
                SpanContext.createFromRemoteParent(traceId, parentSpanId, TraceFlags.getSampled(), TraceState.getDefault())));
    }

    private static String hex(int bytes) {
        byte[] id = new byte[bytes];
        RANDOM.nextBytes(id);
        return HexFormat.of().formatHex(id);
    }
}
