package com.hoopsacademy.game.adapters.in.messaging;

import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder.Decoded;
import com.hoopsacademy.game.application.replica.ParkedRecord;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.application.replica.ReplicateRoster.Outcome;
import com.hoopsacademy.game.application.replica.RosterEvent;
import io.smallrye.reactive.messaging.annotations.Blocking;
import jakarta.enterprise.context.ApplicationScoped;
import java.time.Clock;
import java.time.Duration;
import java.util.Locale;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;

/**
 * Feeds the roster replica from core's roster topics (channel {@code core-roster}, ADR-0037), one record at a time in
 * partition order. Tombstones are skipped (removals are soft); a record that breaks its contract is parked and
 * acknowledged, so it never blocks the records behind it; a valid event is applied in its own tenant, retried a few
 * times, and when it still fails the exception fails the channel (liveness DOWN) and the offset stays uncommitted.
 */
@ApplicationScoped
public class RosterEventConsumer {

    private static final Logger LOG = Logger.getLogger(RosterEventConsumer.class);

    private final RosterEventDecoder decoder;
    private final ReplicateRoster replicate;
    private final ReplicaMetrics metrics;
    private final Clock clock;
    private final int applyAttempts;

    RosterEventConsumer(RosterEventDecoder decoder, ReplicateRoster replicate, ReplicaMetrics metrics, Clock clock,
            @ConfigProperty(name = "hoops.roster.replica.apply-attempts", defaultValue = "3") int applyAttempts) {
        this.decoder = decoder;
        this.replicate = replicate;
        this.metrics = metrics;
        this.clock = clock;
        this.applyAttempts = applyAttempts;
    }

    @Incoming("core-roster")
    @Blocking
    public void consume(ConsumerRecord<String, String> record) {
        if (record.value() == null) {
            metrics.processed(record.topic(), "tombstone");
            return;
        }
        switch (decoder.decode(record.topic(), record.key(), record.value())) {
            case Decoded.Valid valid -> apply(record.topic(), valid.event());
            case Decoded.Invalid invalid -> park(record, invalid);
        }
    }

    private void apply(String topic, RosterEvent event) {
        Outcome outcome = applyWithRetries(event);
        metrics.processed(topic, outcome.name().toLowerCase(Locale.ROOT));
        metrics.lag(topic, event.envelope().occurredAt(), clock.instant());
    }

    private Outcome applyWithRetries(RosterEvent event) {
        for (int attempt = 1; ; attempt++) {
            try {
                return replicate.apply(event);
            } catch (RuntimeException e) {
                if (attempt >= applyAttempts) {
                    LOG.errorf("Applying event %s of %s failed %d times, stopping the consumer: %s",
                            event.envelope().eventId(), event.topic(), attempt, e.toString());
                    throw e;
                }
                LOG.warnf("Applying event %s of %s failed (attempt %d of %d), retrying: %s",
                        event.envelope().eventId(), event.topic(), attempt, applyAttempts, e.toString());
                pause(Duration.ofSeconds(attempt));
            }
        }
    }

    private void park(ConsumerRecord<String, String> record, Decoded.Invalid invalid) {
        LOG.warnf("Parking %s-%d@%d (event %s): %s", record.topic(), record.partition(), record.offset(),
                invalid.eventId().map(Object::toString).orElse("unknown"), invalid.reason());
        replicate.park(new ParkedRecord(record.topic(), record.partition(), record.offset(), record.key(),
                invalid.eventId(), invalid.reason()));
        metrics.parked(record.topic());
    }

    private static void pause(Duration duration) {
        try {
            Thread.sleep(duration);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted while retrying a roster event", e);
        }
    }
}
