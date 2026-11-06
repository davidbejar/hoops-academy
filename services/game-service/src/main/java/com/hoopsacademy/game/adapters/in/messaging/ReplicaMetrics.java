package com.hoopsacademy.game.adapters.in.messaging;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * The replica consumer's meters on /q/metrics (ADR-0037): {@code hoops_roster_replica_events_total{topic,outcome}},
 * {@code hoops_roster_replica_parked_total{topic}} and {@code hoops_roster_replica_lag_seconds{topic}} (the age of the
 * last processed event when it was processed). Parked counters and lag gauges exist for every topic from the start,
 * so "parked = 0" is visible before anything was parked.
 */
@ApplicationScoped
class ReplicaMetrics {

    private final MeterRegistry registry;
    private final Map<String, AtomicLong> lagMillis = new ConcurrentHashMap<>();

    ReplicaMetrics(MeterRegistry registry) {
        this.registry = registry;
        RosterEventDecoder.TOPICS.forEach(topic -> {
            parkedCounter(topic);
            lagOf(topic);
        });
    }

    /** @param outcome applied, duplicate, stale, tombstone or ignored (a removal game does not apply yet, WP81) */
    void processed(String topic, String outcome) {
        Counter.builder("hoops.roster.replica.events").description("Roster events processed by the replica consumer")
                .tag("topic", topic).tag("outcome", outcome).register(registry).increment();
    }

    void parked(String topic) {
        parkedCounter(topic).increment();
    }

    void lag(String topic, Instant occurredAt, Instant processedAt) {
        lagOf(topic).set(Math.max(0, Duration.between(occurredAt, processedAt).toMillis()));
    }

    private Counter parkedCounter(String topic) {
        return Counter.builder("hoops.roster.replica.parked").description("Roster records parked as invalid")
                .tag("topic", topic).register(registry);
    }

    private AtomicLong lagOf(String topic) {
        return lagMillis.computeIfAbsent(topic, key -> {
            AtomicLong millis = new AtomicLong();
            Gauge.builder("hoops.roster.replica.lag", millis, value -> value.get() / 1000.0).baseUnit("seconds")
                    .description("Age of the last processed roster event when it was processed")
                    .tag("topic", key).register(registry);
            return millis;
        });
    }
}
