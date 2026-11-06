package com.hoopsacademy.core.application.events;

import jakarta.enterprise.context.ApplicationScoped;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

/** What the last publisher run saw, for the health check and the metrics (this replica only). */
@ApplicationScoped
public class OutboxPublisherStatus {

    /** {@code lastError}: the exception type of the broker failure, never its message (it may name hosts). */
    public record Snapshot(Optional<Instant> lastRun, boolean brokerAvailable, long pending, Duration lag,
            Optional<String> lastError) {

        public boolean degraded() {
            return !brokerAvailable;
        }
    }

    private volatile Snapshot snapshot = new Snapshot(Optional.empty(), true, 0, Duration.ZERO, Optional.empty());

    public Snapshot snapshot() {
        return snapshot;
    }

    void record(Instant at, boolean brokerAvailable, long pending, Duration lag, Optional<String> lastError) {
        snapshot = new Snapshot(Optional.of(at), brokerAvailable, pending, lag, lastError);
    }
}
