package com.hoopsacademy.common.testing;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Handler;
import java.util.logging.LogRecord;
import org.jboss.logmanager.ExtLogRecord;
import org.jboss.logmanager.Logger;

/**
 * Captures the security events (log category {@value #CATEGORY}) written while it is open, with the logging MDC each
 * record carried (the event's structured fields). For {@code @QuarkusTest}s of the library and the services:
 * <pre>{@code
 * try (SecurityEventCapture events = SecurityEventCapture.open()) {
 *     given().header("X-Tenant-Id", OTHER_TENANT).get("/api/...").then().statusCode(404);
 *     assertThat(events.single()).containsEntry("security.kind", "not_member");
 * }
 * }</pre>
 * Each event is a map of its MDC fields plus {@code message} and {@code level}.
 */
public final class SecurityEventCapture implements AutoCloseable {

    /** The log category of the security events (ADR-0043). */
    public static final String CATEGORY = "hoops.security";

    private final Logger logger = Logger.getLogger(CATEGORY);
    private final List<Map<String, String>> events = new ArrayList<>();
    private final Handler handler = new Handler() {
        @Override
        public void publish(LogRecord record) {
            Map<String, String> event = new LinkedHashMap<>();
            if (record instanceof ExtLogRecord ext) {
                event.putAll(ext.getMdcCopy());
                event.put("message", ext.getFormattedMessage());
            } else {
                event.put("message", record.getMessage());
            }
            event.put("level", record.getLevel().getName());
            synchronized (events) {
                events.add(event);
            }
        }

        @Override
        public void flush() {
            // nothing buffered
        }

        @Override
        public void close() {
            // nothing to release
        }
    };

    private SecurityEventCapture() {
        logger.addHandler(handler);
    }

    public static SecurityEventCapture open() {
        return new SecurityEventCapture();
    }

    /** The events so far, oldest first. */
    public List<Map<String, String>> events() {
        synchronized (events) {
            return List.copyOf(events);
        }
    }

    /** The only event so far; fails when there is none or more than one. */
    public Map<String, String> single() {
        List<Map<String, String>> all = events();
        if (all.size() != 1) {
            throw new AssertionError("expected exactly one security event, got " + all.size() + ": " + all);
        }
        return all.getFirst();
    }

    @Override
    public void close() {
        logger.removeHandler(handler);
    }
}
