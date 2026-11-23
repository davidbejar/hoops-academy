package com.hoopsacademy.common.replica;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.tenancy.TenantId;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** The small parts of the shared replica pipeline (WP130): topics, envelope, outcomes, retry policy, meters, schema. */
class ReplicaPartsTest {

    @Test
    void theSevenRosterTopicsAreCoresCompactedTopics() {
        assertThat(RosterTopic.topicNames()).containsExactly("core.person", "core.player", "core.team",
                "core.team-player", "core.team-staff", "core.guardian-link", "core.tenant");
        assertThat(Arrays.stream(RosterTopic.values()).map(RosterTopic::topicName)).isEqualTo(RosterTopic.topicNames());
        assertThat(RosterTopic.of("core.team-player")).contains(RosterTopic.TEAM_PLAYER);
        assertThat(RosterTopic.of("core.unknown")).isEmpty();
        assertThat(RosterTopic.of(null)).isEmpty();
    }

    @Test
    void anEnvelopeHasEveryField() {
        UUID id = UUID.randomUUID();
        TenantId tenant = TenantId.random();
        Instant at = Instant.now();

        assertThatThrownBy(() -> new EventEnvelope(null, tenant, id, at)).hasMessage("eventId");
        assertThatThrownBy(() -> new EventEnvelope(id, null, id, at)).hasMessage("tenantId");
        assertThatThrownBy(() -> new EventEnvelope(id, tenant, null, at)).hasMessage("aggregateId");
        assertThatThrownBy(() -> new EventEnvelope(id, tenant, id, null)).hasMessage("occurredAt");
    }

    @Test
    void anOutcomeIsCountedUnderItsLowerCaseName() {
        assertThat(ReplicaOutcome.APPLIED.label()).isEqualTo("applied");
        assertThat(ReplicaOutcome.DUPLICATE.label()).isEqualTo("duplicate");
        assertThat(ReplicaOutcome.STALE.label()).isEqualTo("stale");
    }

    @Test
    void theBackoffDoublesFromTheFirstOne() {
        RetryPolicy policy = new RetryPolicy(5, Duration.ofMillis(500));

        assertThat(policy.backoffAfter(1)).isEqualTo(Duration.ofMillis(500));
        assertThat(policy.backoffAfter(2)).isEqualTo(Duration.ofSeconds(1));
        assertThat(policy.backoffAfter(4)).isEqualTo(Duration.ofSeconds(4));
    }

    @Test
    void aRetryPolicyNeedsOneAttemptAndNoNegativeBackoff() {
        assertThatThrownBy(() -> new RetryPolicy(0, Duration.ZERO)).isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("hoops.roster.replica.max-attempts");
        assertThatThrownBy(() -> new RetryPolicy(1, Duration.ofMillis(-1))).isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("hoops.roster.replica.first-backoff");
        assertThatCode(() -> new RetryPolicy(1, Duration.ZERO)).doesNotThrowAnyException();
    }

    @Test
    void everyTopicHasItsParkedCounterAndLagGaugeFromTheStart() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();

        new ReplicaMetrics(registry);

        for (String topic : RosterTopic.topicNames()) {
            assertThat(registry.get("hoops.roster.replica.parked").tag("topic", topic).counter().count()).isZero();
            assertThat(registry.get("hoops.roster.replica.lag").tag("topic", topic).gauge().value()).isZero();
        }
        assertThat(registry.get("hoops.roster.replica.lag").gauge().getId().getBaseUnit()).isEqualTo("seconds");
    }

    @Test
    void aRecordOfAnUnknownTopicIsCountedUnderItsTopic() {
        SimpleMeterRegistry registry = new SimpleMeterRegistry();
        ReplicaMetrics metrics = new ReplicaMetrics(registry);

        metrics.parked("core.unknown");
        metrics.processed("core.team", "tombstone");

        assertThat(registry.get("hoops.roster.replica.parked").tag("topic", "core.unknown").counter().count()).isOne();
        assertThat(registry.get("hoops.roster.replica.events").tag("topic", "core.team").tag("outcome", "tombstone")
                .counter().count()).isOne();
    }

    @ParameterizedTest
    @ValueSource(strings = {"game", "athlete", "finance_x"})
    void aSchemaNamesItsTables(String name) {
        assertThat(new ReplicaSchema(name).table("parked_event")).isEqualTo(name + ".parked_event");
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "Game", "game;drop", "game.x", "1game", "_game"})
    void aSchemaIsAPlainLowerCaseIdentifier(String name) {
        assertThatThrownBy(() -> new ReplicaSchema(name)).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void aSchemaNeedsAName() {
        assertThatThrownBy(() -> new ReplicaSchema(null)).isInstanceOf(NullPointerException.class);
    }
}
