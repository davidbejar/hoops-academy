package com.hoopsacademy.athlete.adapters.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

/** hoops.roster.source: rest (default) or replica; the replica needs its consumer. */
class RosterSourceTest {

    @Test
    void restIsTheDefaultAndNeedsNoConsumer() {
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
                .hasMessageContaining("hoops.roster.replica.consume");
    }

    @Test
    void anUnknownSourceFailsAtStartup() {
        assertThatThrownBy(() -> RosterSource.of("cache", true)).isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("hoops.roster.source");
    }
}
