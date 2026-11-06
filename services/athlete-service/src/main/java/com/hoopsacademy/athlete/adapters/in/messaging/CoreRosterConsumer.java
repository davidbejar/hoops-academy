package com.hoopsacademy.athlete.adapters.in.messaging;

import com.hoopsacademy.athlete.adapters.in.messaging.DecodedEvent.Invalid;
import com.hoopsacademy.athlete.adapters.in.messaging.DecodedEvent.Valid;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent.Outcome;
import com.hoopsacademy.athlete.application.replica.ParkedEvent;
import com.hoopsacademy.athlete.application.replica.ParkedEvents;
import com.hoopsacademy.athlete.application.replica.RosterEvent;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;
import io.smallrye.common.annotation.Blocking;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;

/**
 * Consumes core's seven roster topics (channel {@code core-roster}, group {@code athlete-service.roster}, only with
 * hoops.roster.consumer.enabled, on by default) one record at a time, in topic order. A valid event is applied in its own tenant;
 * a record that breaks the contract is parked and skipped; a tombstone (null value after a removal) carries nothing
 * to apply. A failure to apply (the database) is retried with backoff; after the last attempt the channel fails,
 * which turns the liveness check DOWN so the pod restarts from the last committed offset (at least once, idempotent).
 * Metrics (same names as game's): {@code hoops_roster_replica_events_total{topic,outcome}} (applied, duplicate, stale,
 * tombstone, ignored: a removal athlete does not apply yet, WP81), {@code hoops_roster_replica_parked_total{topic}},
 * {@code hoops_roster_replica_lag_seconds{topic}}.
 */
@ApplicationScoped
public class CoreRosterConsumer {

    private static final Logger LOG = Logger.getLogger(CoreRosterConsumer.class);

    private final CoreEventDecoder decoder;
    private final ApplyRosterEvent apply;
    private final ParkedEvents parked;
    private final MeterRegistry metrics;
    private final Clock clock;
    private final int maxAttempts;
    private final Duration firstBackoff;
    private final Map<String, AtomicLong> lagMillis = new ConcurrentHashMap<>();

    public CoreRosterConsumer(CoreEventDecoder decoder, ApplyRosterEvent apply, ParkedEvents parked, MeterRegistry metrics,
            Clock clock,
            @ConfigProperty(name = "hoops.roster.replica.max-attempts", defaultValue = "5") int maxAttempts,
            @ConfigProperty(name = "hoops.roster.replica.first-backoff", defaultValue = "PT0.5S") Duration firstBackoff) {
        this.decoder = decoder;
        this.apply = apply;
        this.parked = parked;
        this.metrics = metrics;
        this.clock = clock;
        this.maxAttempts = maxAttempts;
        this.firstBackoff = firstBackoff;
    }

    @Incoming("core-roster")
    @Blocking
    public void consume(ConsumerRecord<String, String> record) {
        if (record.value() == null) {
            count(record.topic(), "tombstone");
            return;
        }
        switch (decoder.decode(record.topic(), record.key(), record.value())) {
            case Valid valid -> applyWithRetries(record, valid.event());
            case DecodedEvent.Ignored ignored -> {
                count(record.topic(), "ignored");
                recordLag(record.topic(), ignored.occurredAt());
            }
            case Invalid invalid -> park(record, invalid);
        }
    }

    private void applyWithRetries(ConsumerRecord<String, String> record, RosterEvent event) {
        Outcome outcome = withRetries(record, () -> apply.apply(event));
        count(record.topic(), outcome.name().toLowerCase(Locale.ROOT));
        recordLag(record.topic(), event.occurredAt());
    }

    private void park(ConsumerRecord<String, String> record, Invalid invalid) {
        LOG.warnf("Parking %s-%d@%d: %s", record.topic(), record.partition(), record.offset(), invalid.reason());
        ParkedEvent event = new ParkedEvent(record.topic(), record.partition(), record.offset(),
                Optional.ofNullable(record.key()), invalid.eventId(), invalid.reason());
        withRetries(record, () -> {
            parked.park(event);
            return event;
        });
        metrics.counter("hoops.roster.replica.parked", "topic", record.topic()).increment();
    }

    /** Database work for one record: retried with backoff, then the failure fails the channel. */
    private <T> T withRetries(ConsumerRecord<String, String> record, Supplier<T> work) {
        for (int attempt = 1; ; attempt++) {
            try {
                return work.get();
            } catch (RuntimeException e) {
                if (attempt >= maxAttempts) {
                    LOG.errorf("Giving up on %s-%d@%d after %d attempts: %s", record.topic(), record.partition(),
                            record.offset(), attempt, e.toString());
                    throw e;
                }
                LOG.warnf("Processing %s-%d@%d failed (attempt %d of %d), retrying: %s", record.topic(),
                        record.partition(), record.offset(), attempt, maxAttempts, e.toString());
                sleep(firstBackoff.multipliedBy(1L << (attempt - 1)));
            }
        }
    }

    private void count(String topic, String outcome) {
        metrics.counter("hoops.roster.replica.events", "topic", topic, "outcome", outcome).increment();
    }

    /** How old the topic's latest event was when the replica applied it. */
    private void recordLag(String topic, Instant occurredAt) {
        long millis = Math.max(0, clock.millis() - occurredAt.toEpochMilli());
        lagMillis.computeIfAbsent(topic, t -> metrics.gauge("hoops.roster.replica.lag.seconds",
                Tags.of("topic", t), new AtomicLong(), v -> v.get() / 1000.0)).set(millis);
    }

    private static void sleep(Duration duration) {
        try {
            Thread.sleep(duration);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("interrupted while retrying", e);
        }
    }
}
