package com.hoopsacademy.common.testing;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * The broker fixture game and athlete share (WP98): the pinned Redpanda image, the seven {@code core.*} roster topics
 * with one partition each (as compose and the chart create them), and the replica consumer switched on.
 */
class RosterBrokerResourceTest {

    @Test
    void startsTheBrokerWithTheSevenRosterTopicsAndSwitchesTheConsumerOn() {
        RosterBrokerResource resource = new RosterBrokerResource();
        try {
            Map<String, String> config = resource.start();

            assertThat(config).containsEntry("hoops.roster.consumer.enabled", "true")
                    .hasEntrySatisfying("kafka.bootstrap.servers", servers -> assertThat(servers).isNotBlank());
            String topics = resource.rpk("rpk", "topic", "list");
            assertThat(RosterBrokerResource.TOPICS).hasSize(7).allSatisfy(topic ->
                    assertThat(topics).containsPattern("(?m)^" + topic.replace(".", "\\.") + "\\s+1\\s"));
        } finally {
            resource.stop();
        }
    }

    @Test
    void stoppingBeforeStartingDoesNothing() {
        new RosterBrokerResource().stop();
    }
}
