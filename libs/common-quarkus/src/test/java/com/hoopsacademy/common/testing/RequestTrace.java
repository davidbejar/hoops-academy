package com.hoopsacademy.common.testing;

import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.sdk.trace.data.EventData;
import io.opentelemetry.sdk.trace.data.SpanData;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/** The exported spans of one request (WP143): its root (the server span), the database spans under it, their text. */
public record RequestTrace(List<SpanData> spans) {

    /** The attribute that marks a database client span (old and stable semantic conventions). */
    private static final Set<String> DB_SYSTEM = Set.of("db.system", "db.system.name");

    public RequestTrace {
        spans = List.copyOf(spans);
    }

    /** The span whose parent is not in the trace (a request's server span, or a test's own span). */
    public SpanData root() {
        Set<String> ids = spans.stream().map(SpanData::getSpanId).collect(Collectors.toSet());
        return spans.stream().filter(span -> !ids.contains(span.getParentSpanId())).findFirst()
                .orElseThrow(() -> new AssertionError("no root span in " + names()));
    }

    public List<SpanData> databaseSpans() {
        return spans.stream().filter(RequestTrace::isDatabaseSpan).toList();
    }

    /** True when {@code span} descends from the root (directly or through internal spans). */
    public boolean isUnderRoot(SpanData span) {
        Map<String, SpanData> byId = spans.stream().collect(Collectors.toMap(SpanData::getSpanId, Function.identity()));
        String root = root().getSpanId();
        Optional<SpanData> parent = Optional.ofNullable(byId.get(span.getParentSpanId()));
        while (parent.isPresent()) {
            if (parent.get().getSpanId().equals(root)) {
                return true;
            }
            parent = Optional.ofNullable(byId.get(parent.get().getParentSpanId()));
        }
        return false;
    }

    /**
     * Everything a span exports as text: its name, status description, every attribute and every event with its
     * attributes (an exception event carries the driver's message). A privacy test searches this for seeded values.
     */
    public String exportedText() {
        return spans.stream().map(RequestTrace::text).collect(Collectors.joining("\n"));
    }

    public List<String> names() {
        return spans.stream().map(SpanData::getName).toList();
    }

    private static boolean isDatabaseSpan(SpanData span) {
        return span.getAttributes().asMap().keySet().stream().anyMatch(key -> DB_SYSTEM.contains(key.getKey()));
    }

    private static String text(SpanData span) {
        return Stream.of(Stream.of(span.getName(), span.getStatus().getDescription(), text(span.getAttributes())),
                span.getEvents().stream().map(RequestTrace::text))
                .flatMap(Function.identity()).collect(Collectors.joining(" | "));
    }

    private static String text(EventData event) {
        return event.getName() + " " + text(event.getAttributes());
    }

    private static String text(Attributes attributes) {
        return attributes.asMap().entrySet().stream().map(entry -> entry.getKey().getKey() + "=" + entry.getValue())
                .collect(Collectors.joining(", "));
    }
}
