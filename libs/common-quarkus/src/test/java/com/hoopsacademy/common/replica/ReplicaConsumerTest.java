package com.hoopsacademy.common.replica;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

/**
 * The one consumer loop of game's and athlete's roster replicas (WP130, ADR-0062): tombstones skipped, valid events
 * applied in their tenant (by the service) and counted by outcome, invalid records parked and acknowledged, and every
 * database step (apply or park) tried {@code max-attempts} times with a backoff doubling from {@code first-backoff}
 * before the failure stops the consumer.
 */
class ReplicaConsumerTest {

    private static final Instant NOW = Instant.parse("2026-11-24T10:00:00Z");
    private static final RetryPolicy FOUR_ATTEMPTS = new RetryPolicy(4, Duration.ofMillis(500));

    private final SimpleMeterRegistry registry = new SimpleMeterRegistry();
    private final List<EventEnvelope> applied = new ArrayList<>();
    private final Deque<RuntimeException> applyFailures = new ArrayDeque<>();
    private final List<ParkedEvent> parked = new ArrayList<>();
    private final Deque<RuntimeException> parkFailures = new ArrayDeque<>();
    private final List<Duration> pauses = new ArrayList<>();
    private ReplicaOutcome outcome = ReplicaOutcome.APPLIED;

    private final ReplicaConsumer<EventEnvelope> consumer = new ReplicaConsumer<>(
            new CoreEventDecoder<>(new ObjectMapper(), (topic, envelope, type, payload) -> envelope), this::apply,
            this::park, new ReplicaMetrics(registry), Clock.fixed(NOW, ZoneOffset.UTC), FOUR_ATTEMPTS, pauses::add);

    @AfterEach
    void clearInterruptFlag() {
        Thread.interrupted();
    }

    @Test
    void aTombstoneIsCountedAndNeitherAppliedNorParked() {
        consumer.consume(new ReplicaRecord("core.team", 0, 3, "k", null));

        assertThat(events("core.team", "tombstone")).isOne();
        assertThat(applied).isEmpty();
        assertThat(parked).isEmpty();
    }

    @Test
    void aValidEventIsAppliedCountedByOutcomeAndItsAgeIsTheLag() {
        JsonNode event = CoreEventDecoderTest.example(RosterTopic.TEAM);
        outcome = ReplicaOutcome.STALE;

        consumer.consume(record(event));

        assertThat(applied).singleElement().satisfies(envelope -> assertThat(envelope.eventId().toString())
                .isEqualTo(event.get("eventId").asText()));
        assertThat(events("core.team", "stale")).isOne();
        assertThat(events("core.team", "applied")).isZero();
        double age = Duration.between(Instant.parse(event.get("occurredAt").asText()), NOW).toMillis() / 1000.0;
        assertThat(lag("core.team")).isEqualTo(age);
    }

    @Test
    void anEventFromTheFutureHasNoNegativeLag() {
        SimpleMeterRegistry own = new SimpleMeterRegistry();
        ReplicaMetrics metrics = new ReplicaMetrics(own);

        metrics.lag("core.team", NOW.minusSeconds(3), NOW);
        assertThat(own.get("hoops.roster.replica.lag").tag("topic", "core.team").gauge().value()).isEqualTo(3.0);
        metrics.lag("core.team", NOW.plusSeconds(5), NOW);
        assertThat(own.get("hoops.roster.replica.lag").tag("topic", "core.team").gauge().value()).isZero();
    }

    @Test
    void anInvalidRecordIsParkedWithItsCoordinatesAndNeverApplied() {
        JsonNode event = CoreEventDecoderTest.example(RosterTopic.TEAM);

        consumer.consume(new ReplicaRecord("core.team", 2, 41, "not-the-key", event.toString()));
        consumer.consume(new ReplicaRecord("core.team", 2, 42, null, "not json"));

        assertThat(parked).containsExactly(
                new ParkedEvent("core.team", 2, 41, Optional.of("not-the-key"),
                        Optional.of(UUID.fromString(event.get("eventId").asText())),
                        "key is not <tenantId>:<aggregateId> of the envelope"),
                new ParkedEvent("core.team", 2, 42, Optional.empty(), Optional.empty(), "value is not JSON"));
        assertThat(applied).isEmpty();
        assertThat(parkedCount("core.team")).isEqualTo(2);
        assertThat(events("core.team", "applied")).isZero();
    }

    @Test
    void aFailedApplyIsRetriedWithADoublingBackoffAndCountedOnce() {
        applyFailures.add(new IllegalStateException("blip"));
        applyFailures.add(new IllegalStateException("blip"));

        consumer.consume(record(CoreEventDecoderTest.example(RosterTopic.PERSON)));

        assertThat(applied).hasSize(1);
        assertThat(pauses).containsExactly(Duration.ofMillis(500), Duration.ofSeconds(1));
        assertThat(events("core.person", "applied")).isOne();
    }

    @Test
    void whenEveryAttemptToApplyFailsTheFailureStopsTheConsumerAndNothingIsCounted() {
        for (int i = 0; i < FOUR_ATTEMPTS.maxAttempts(); i++) {
            applyFailures.add(new IllegalStateException("database gone " + i));
        }

        assertThatThrownBy(() -> consumer.consume(record(CoreEventDecoderTest.example(RosterTopic.PERSON))))
                .hasMessage("database gone 3");

        assertThat(pauses).containsExactly(Duration.ofMillis(500), Duration.ofSeconds(1), Duration.ofSeconds(2));
        assertThat(applied).isEmpty();
        assertThat(events("core.person", "applied")).isZero();
        assertThat(lag("core.person")).isZero();
    }

    @Test
    void aFailedParkIsRetriedLikeAnApply() {
        parkFailures.add(new IllegalStateException("blip"));

        consumer.consume(new ReplicaRecord("core.team", 0, 7, "k", "not json"));

        assertThat(parked).hasSize(1);
        assertThat(pauses).containsExactly(Duration.ofMillis(500));
        assertThat(parkedCount("core.team")).isOne();
    }

    @Test
    void whenEveryAttemptToParkFailsTheFailureStopsTheConsumerAndNothingIsCounted() {
        for (int i = 0; i < FOUR_ATTEMPTS.maxAttempts(); i++) {
            parkFailures.add(new IllegalStateException("database gone " + i));
        }

        assertThatThrownBy(() -> consumer.consume(new ReplicaRecord("core.team", 0, 7, "k", "not json")))
                .hasMessage("database gone 3");

        assertThat(pauses).hasSize(3);
        assertThat(parkedCount("core.team")).isZero();
    }

    @Test
    void anInterruptedPauseStopsTheConsumerAndKeepsTheInterrupt() {
        ReplicaConsumer<EventEnvelope> sleeping = new ReplicaConsumer<>(
                new CoreEventDecoder<>(new ObjectMapper(), (topic, envelope, type, payload) -> envelope), this::apply,
                this::park, new ReplicaMetrics(registry), Clock.fixed(NOW, ZoneOffset.UTC), FOUR_ATTEMPTS);
        applyFailures.add(new IllegalStateException("blip"));
        Thread.currentThread().interrupt();

        assertThatThrownBy(() -> sleeping.consume(record(CoreEventDecoderTest.example(RosterTopic.PERSON))))
                .isInstanceOf(IllegalStateException.class).hasMessageContaining("interrupted")
                .hasCauseInstanceOf(InterruptedException.class);

        assertThat(Thread.currentThread().isInterrupted()).isTrue();
        assertThat(applied).isEmpty();
    }

    private ReplicaOutcome apply(EventEnvelope envelope) {
        RuntimeException failure = applyFailures.poll();
        if (failure != null) {
            throw failure;
        }
        applied.add(envelope);
        return outcome;
    }

    private void park(ParkedEvent event) {
        RuntimeException failure = parkFailures.poll();
        if (failure != null) {
            throw failure;
        }
        parked.add(event);
    }

    private static ReplicaRecord record(JsonNode event) {
        String type = event.get("type").asText();
        return new ReplicaRecord("core." + type.substring(0, type.indexOf('.')), 0, 1,
                event.get("tenantId").asText() + ":" + event.get("aggregateId").asText(), event.toString());
    }

    private double events(String topic, String outcome) {
        Counter counter = registry.find("hoops.roster.replica.events").tag("topic", topic).tag("outcome", outcome)
                .counter();
        return counter == null ? 0 : counter.count();
    }

    private double parkedCount(String topic) {
        return registry.get("hoops.roster.replica.parked").tag("topic", topic).counter().count();
    }

    private double lag(String topic) {
        Gauge gauge = registry.get("hoops.roster.replica.lag").tag("topic", topic).gauge();
        return gauge.value();
    }
}
