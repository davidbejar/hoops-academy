package com.hoopsacademy.common.testing;

import io.opentelemetry.sdk.common.CompletableResultCode;
import io.opentelemetry.sdk.trace.data.SpanData;
import io.opentelemetry.sdk.trace.export.SpanExporter;
import jakarta.inject.Singleton;
import java.time.Duration;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.locks.LockSupport;

/**
 * An in-memory span exporter for {@link TracingProfile} (WP143): Quarkus hands every finished span to each
 * {@link SpanExporter} bean, this one keeps them so that a test can read the spans of one request. Without the profile
 * the SDK is off and nothing reaches it.
 */
@Singleton
public class RecordedSpans implements SpanExporter {

    private static final Duration WAIT = Duration.ofSeconds(10);

    private final ConcurrentLinkedQueue<SpanData> spans = new ConcurrentLinkedQueue<>();

    @Override
    public CompletableResultCode export(Collection<SpanData> finished) {
        spans.addAll(finished);
        return CompletableResultCode.ofSuccess();
    }

    @Override
    public CompletableResultCode flush() {
        return CompletableResultCode.ofSuccess();
    }

    @Override
    public CompletableResultCode shutdown() {
        spans.clear();
        return CompletableResultCode.ofSuccess();
    }

    /**
     * The spans of {@code trace} once its root has ended (the span whose parent is the trace's remote parent: a request's
     * server span, the last of the request to end), or fails after 10 s.
     */
    public RequestTrace of(SampledTrace trace) {
        Instant deadline = Instant.now().plus(WAIT);
        while (Instant.now().isBefore(deadline)) {
            List<SpanData> found = spans.stream().filter(span -> span.getTraceId().equals(trace.traceId())).toList();
            if (found.stream().anyMatch(span -> span.getParentSpanId().equals(trace.parentSpanId()))) {
                return new RequestTrace(found);
            }
            LockSupport.parkNanos(Duration.ofMillis(20).toNanos());
        }
        throw new AssertionError("no root span of trace " + trace.traceId() + " was exported within " + WAIT);
    }
}
