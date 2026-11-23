package com.hoopsacademy.common.replica;

import com.hoopsacademy.common.replica.DecodedEvent.Invalid;
import com.hoopsacademy.common.replica.DecodedEvent.Valid;
import java.time.Clock;
import java.time.Duration;
import java.util.Optional;
import java.util.function.Supplier;
import org.jboss.logging.Logger;

/**
 * The one consumer loop of the roster replicas of game and athlete (ADR-0037, shared since WP130, ADR-0062); each
 * service's {@code @Incoming("core-roster")} method hands it every record. A tombstone (the null value after a removal)
 * is counted and skipped; a valid event is applied by the service (in the event's tenant) and counted by outcome; a
 * record that breaks the contract is parked and acknowledged, so it never blocks the records behind it. The database
 * work of a record (apply or park) is tried {@link RetryPolicy#maxAttempts()} times with a doubling backoff; after the
 * last attempt the failure is rethrown, which fails the channel (liveness DOWN): the pod restarts from the last
 * committed offset, which is still before the record (at least once, idempotent apply).
 *
 * @param <E> the service's own event type
 */
public final class ReplicaConsumer<E> {

    /** Pauses between attempts; replaced in tests. */
    @FunctionalInterface
    interface Sleeper {
        void sleep(Duration duration) throws InterruptedException;
    }

    private static final Logger LOG = Logger.getLogger(ReplicaConsumer.class);

    private final CoreEventDecoder<E> decoder;
    private final ReplicaApplier<E> applier;
    private final ParkedEvents parked;
    private final ReplicaMetrics metrics;
    private final Clock clock;
    private final RetryPolicy retries;
    private final Sleeper sleeper;

    public ReplicaConsumer(CoreEventDecoder<E> decoder, ReplicaApplier<E> applier, ParkedEvents parked,
            ReplicaMetrics metrics, Clock clock, RetryPolicy retries) {
        this(decoder, applier, parked, metrics, clock, retries, Thread::sleep);
    }

    ReplicaConsumer(CoreEventDecoder<E> decoder, ReplicaApplier<E> applier, ParkedEvents parked, ReplicaMetrics metrics,
            Clock clock, RetryPolicy retries, Sleeper sleeper) {
        this.decoder = decoder;
        this.applier = applier;
        this.parked = parked;
        this.metrics = metrics;
        this.clock = clock;
        this.retries = retries;
        this.sleeper = sleeper;
    }

    /** @throws RuntimeException the last failure when every attempt at the record's database work failed */
    public void consume(ReplicaRecord record) {
        if (record.value() == null) {
            metrics.processed(record.topic(), "tombstone");
            return;
        }
        switch (decoder.decode(record.topic(), record.key(), record.value())) {
            case Valid<E> valid -> apply(record, valid);
            case Invalid<E> invalid -> park(record, invalid);
        }
    }

    private void apply(ReplicaRecord record, Valid<E> valid) {
        ReplicaOutcome outcome = withRetries(record, () -> applier.apply(valid.event()));
        metrics.processed(record.topic(), outcome.label());
        metrics.lag(record.topic(), valid.envelope().occurredAt(), clock.instant());
    }

    private void park(ReplicaRecord record, Invalid<E> invalid) {
        LOG.warnf("Parking %s (event %s): %s", position(record), invalid.eventId().map(Object::toString).orElse("unknown"),
                invalid.reason());
        ParkedEvent event = new ParkedEvent(record.topic(), record.partition(), record.offset(),
                Optional.ofNullable(record.key()), invalid.eventId(), invalid.reason());
        withRetries(record, () -> {
            parked.park(event);
            return event;
        });
        metrics.parked(record.topic());
    }

    private <T> T withRetries(ReplicaRecord record, Supplier<T> work) {
        for (int attempt = 1; ; attempt++) {
            try {
                return work.get();
            } catch (RuntimeException e) {
                if (attempt >= retries.maxAttempts()) {
                    LOG.errorf("Giving up on %s after %d attempts, stopping the consumer: %s", position(record), attempt,
                            e.toString());
                    throw e;
                }
                LOG.warnf("Processing %s failed (attempt %d of %d), retrying: %s", position(record), attempt,
                        retries.maxAttempts(), e.toString());
                pause(retries.backoffAfter(attempt));
            }
        }
    }

    private void pause(Duration duration) {
        try {
            sleeper.sleep(duration);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("interrupted while retrying a roster record", e);
        }
    }

    private static String position(ReplicaRecord record) {
        return record.topic() + "-" + record.partition() + "@" + record.offset();
    }
}
