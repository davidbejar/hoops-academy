package com.hoopsacademy.game.adapters.in.messaging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.application.replica.ParkedRecord;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.application.replica.ReplicateRoster.Outcome;
import com.hoopsacademy.game.application.replica.RosterEvent;
import com.hoopsacademy.game.support.CoreEvents;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

/**
 * Characterisation (WP130) of game's own consumer loop before it moved to common-quarkus: the points where game and
 * athlete differed. game tries an event {@code apply-attempts} times with linear pauses (1 s, 2 s, ...), does not retry
 * a failed park, and registers the parked counter and the lag gauge of every topic up front.
 */
class RosterEventConsumerPolicyTest {

    private final RosterEventDecoder decoder = new RosterEventDecoder();
    private final ReplicateRoster replicate = mock(ReplicateRoster.class);
    private final SimpleMeterRegistry registry = new SimpleMeterRegistry();
    private final CoreEvents core = CoreEvents.of(TenantId.random());

    private RosterEventConsumer consumer(int attempts) {
        return new RosterEventConsumer(decoder, replicate, new ReplicaMetrics(registry),
                Clock.fixed(Instant.parse("2026-11-24T10:00:00Z"), ZoneOffset.UTC), attempts);
    }

    @Test
    void anEventIsTriedApplyAttemptsTimesThenTheFailureStopsTheConsumer() {
        when(replicate.apply(any(RosterEvent.class))).thenThrow(new IllegalStateException("database gone"));

        assertThatThrownBy(() -> consumer(2).consume(record(team()))).hasMessage("database gone");

        verify(replicate, times(2)).apply(any(RosterEvent.class));
    }

    @Test
    void aFailedApplyIsRetriedAndThenCounted() {
        when(replicate.apply(any(RosterEvent.class))).thenThrow(new IllegalStateException("blip"))
                .thenReturn(Outcome.APPLIED);

        consumer(2).consume(record(team()));

        assertThat(registry.find("hoops.roster.replica.events").tag("outcome", "applied").counter().count()).isOne();
    }

    @Test
    void aFailedParkIsNotRetried() {
        Mockito.doThrow(new IllegalStateException("database blip")).when(replicate).park(any(ParkedRecord.class));
        CoreEvents.Record valid = team();

        assertThatThrownBy(() -> consumer(3).consume(new ConsumerRecord<>(valid.topic(), 0, 7L, "not-the-key",
                valid.value()))).hasMessage("database blip");

        verify(replicate, times(1)).park(any(ParkedRecord.class));
    }

    @Test
    void everyTopicHasItsParkedCounterAndLagGaugeBeforeAnythingHappened() {
        consumer(3);

        for (String topic : RosterEventDecoder.TOPICS) {
            assertThat(registry.find("hoops.roster.replica.parked").tag("topic", topic).counter()).as(topic).isNotNull();
            assertThat(registry.find("hoops.roster.replica.lag").tag("topic", topic).gauge()).as(topic).isNotNull();
        }
    }

    @Test
    void aTombstoneIsCountedAndNeverDecodedOrApplied() {
        consumer(3).consume(new ConsumerRecord<>("core.team", 0, 1L, "k", null));

        assertThat(registry.find("hoops.roster.replica.events").tag("outcome", "tombstone").counter().count()).isOne();
        verifyNoInteractions(replicate);
    }

    private CoreEvents.Record team() {
        return core.team(UUID.randomUUID(), UUID.randomUUID(), LocalDate.parse("2027-06-30"), "Lions");
    }

    private static ConsumerRecord<String, String> record(CoreEvents.Record record) {
        return new ConsumerRecord<>(record.topic(), 0, 1L, record.key(), record.value());
    }
}
