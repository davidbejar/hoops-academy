package com.hoopsacademy.game.adapters.out.roster;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.game.adapters.out.roster.RosterSourceSelection.RosterSource;
import org.junit.jupiter.api.Test;

/**
 * hoops.roster.source with hoops.roster.consumer.enabled (FOLLOW-UPS "game on replica without its consumer", WP117):
 * a replica that no consumer feeds would never change, so game refuses to start with it, as athlete does.
 */
class RosterSourceSelectionTest {

    @Test
    void replicaWithItsConsumerStarts() {
        assertThatCode(() -> new RosterSourceSelection(RosterSource.REPLICA, true)).doesNotThrowAnyException();
    }

    @Test
    void restStartsWithOrWithoutTheConsumer() {
        assertThatCode(() -> new RosterSourceSelection(RosterSource.REST, false)).doesNotThrowAnyException();
        assertThatCode(() -> new RosterSourceSelection(RosterSource.REST, true)).doesNotThrowAnyException();
    }

    @Test
    void replicaWithoutItsConsumerWouldNeverChangeAndFailsTheStart() {
        assertThatThrownBy(() -> new RosterSourceSelection(RosterSource.REPLICA, false))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("hoops.roster.consumer.enabled")
                .hasMessageContaining("GAME_ROSTER_CONSUMER_ENABLED");
    }
}
