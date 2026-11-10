package com.hoopsacademy.athlete.adapters.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

/** hoops.roster.source: replica (default, RosterSourceDefaultsTest) or rest; the replica needs its consumer. */
class RosterSourceTest {

    @Test
    void restNeedsNoConsumer() {
        assertThat(RosterSource.of("rest", false)).isEqualTo(RosterSource.REST);
        assertThat(RosterSource.of("REST", true)).isEqualTo(RosterSource.REST);
    }

    @Test
    void replicaWithItsConsumerIsAccepted() {
        assertThat(RosterSource.of("replica", true)).isEqualTo(RosterSource.REPLICA);
    }

    @Test
    void replicaWithoutTheConsumerWouldNeverChangeAndFailsAtStartup() {
        assertThatThrownBy(() -> RosterSource.of("replica", false)).isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("hoops.roster.consumer.enabled");
    }

    @Test
    void anUnknownSourceFailsAtStartup() {
        assertThatThrownBy(() -> RosterSource.of("cache", true)).isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("hoops.roster.source");
    }
}
