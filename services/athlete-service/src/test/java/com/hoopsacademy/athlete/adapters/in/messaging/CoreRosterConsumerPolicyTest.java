package com.hoopsacademy.athlete.adapters.in.messaging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent.Outcome;
import com.hoopsacademy.athlete.application.replica.ParkedEvent;
import com.hoopsacademy.athlete.application.replica.ParkedEvents;
import com.hoopsacademy.athlete.application.replica.RosterEvent;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.common.tenancy.TenantId;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.Test;

/**
 * Characterisation (WP130) of athlete's own consumer loop before it moved to common-quarkus: the points where athlete
 * and game differed. athlete tries a record {@code max-attempts} times with a doubling backoff, retries a failed park
 * the same way, and registers the parked counter and the lag gauge of a topic only when it is first used.
 */
class CoreRosterConsumerPolicyTest {

    private final CoreEventDecoder decoder = new CoreEventDecoder(new ObjectMapper());
    private final ApplyRosterEvent apply = mock(ApplyRosterEvent.class);
    private final ParkedEvents parked = mock(ParkedEvents.class);
    private final SimpleMeterRegistry registry = new SimpleMeterRegistry();
    private final TenantId tenant = TenantId.random();

    private CoreRosterConsumer consumer(int attempts) {
        return new CoreRosterConsumer(decoder, apply, parked, registry,
                Clock.fixed(Instant.parse("2026-11-24T10:00:00Z"), ZoneOffset.UTC), attempts, Duration.ofMillis(1));
    }

    @Test
    void aRecordIsTriedMaxAttemptsTimesThenTheFailureStopsTheConsumer() {
        when(apply.apply(any(RosterEvent.class))).thenThrow(new IllegalStateException("database gone"));

        assertThatThrownBy(() -> consumer(3).consume(record(team()))).hasMessage("database gone");

        verify(apply, times(3)).apply(any(RosterEvent.class));
    }

    @Test
    void aFailedApplyIsRetriedAndThenCounted() {
        when(apply.apply(any(RosterEvent.class))).thenThrow(new IllegalStateException("blip")).thenReturn(Outcome.APPLIED);

        consumer(3).consume(record(team()));

        assertThat(registry.find("hoops.roster.replica.events").tag("outcome", "applied").counter().count()).isOne();
    }

    @Test
    void aFailedParkIsRetried() {
        doThrow(new IllegalStateException("database blip")).doNothing().when(parked).park(any(ParkedEvent.class));
        CoreEvents.Record valid = team();

        consumer(3).consume(new ConsumerRecord<>(valid.topic(), 0, 7L, "not-the-key", valid.value()));

        verify(parked, times(2)).park(any(ParkedEvent.class));
        assertThat(registry.find("hoops.roster.replica.parked").tag("topic", "core.team").counter().count()).isOne();
    }

    @Test
    void aTopicsParkedCounterAndLagGaugeAppearOnlyWhenFirstUsed() {
        doNothing().when(parked).park(any(ParkedEvent.class));
        CoreRosterConsumer consumer = consumer(3);

        assertThat(registry.find("hoops.roster.replica.parked").counters()).isEmpty();
        assertThat(registry.find("hoops.roster.replica.lag.seconds").gauges()).isEmpty();

        when(apply.apply(any(RosterEvent.class))).thenReturn(Outcome.APPLIED);
        consumer.consume(record(team()));
        assertThat(registry.find("hoops.roster.replica.lag.seconds").gauges()).hasSize(1);
    }

    @Test
    void aTombstoneIsCountedAndNeverDecodedOrApplied() {
        consumer(3).consume(new ConsumerRecord<>("core.team", 0, 1L, "k", null));

        assertThat(registry.find("hoops.roster.replica.events").tag("outcome", "tombstone").counter().count()).isOne();
        verifyNoInteractions(apply, parked);
    }

    private CoreEvents.Record team() {
        return CoreEvents.team(tenant, UUID.randomUUID(), "U12", LocalDate.parse("2027-06-30"));
    }

    private static ConsumerRecord<String, String> record(CoreEvents.Record record) {
        return new ConsumerRecord<>(record.topic(), 0, 1L, record.key(), record.value());
    }
}
