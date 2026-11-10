package com.hoopsacademy.athlete.adapters.config;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.testing.ShippedConfig;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * Where athlete reads the roster from as it ships (decision 66, ADR-0037 "Flip of 2026-11-10"): the replica fed by its
 * consumer in production and dev mode, `rest` as the fallback switch (ATHLETE_ROSTER_SOURCE), and `rest` in the test
 * profile, whose tests run no broker (the replica tests switch source and consumer on themselves).
 */
class RosterSourceDefaultsTest {

    @Test
    void productionReadsTheReplicaFedByItsConsumer() {
        ShippedConfig prod = ShippedConfig.load("prod", Map.of());

        assertThat(prod.value("hoops.roster.source")).contains("replica");
        assertThat(prod.value("hoops.roster.consumer.enabled")).contains("true");
        assertThat(prod.value("mp.messaging.incoming.core-roster.enabled")).contains("true");
    }

    @Test
    void restStaysTheFallbackSwitch() {
        ShippedConfig prod = ShippedConfig.load("prod", Map.of("ATHLETE_ROSTER_SOURCE", "rest"));

        assertThat(prod.value("hoops.roster.source")).contains("rest");
    }

    @Test
    void devModeReadsTheReplicaFromKafkaDevServices() {
        ShippedConfig dev = ShippedConfig.load("dev", Map.of());

        assertThat(dev.value("hoops.roster.source")).contains("replica");
        assertThat(dev.value("hoops.roster.consumer.enabled")).contains("true");
        assertThat(dev.value("quarkus.kafka.devservices.enabled")).as("Dev Services start the broker").isEmpty();
        assertThat(dev.value("kafka.bootstrap.servers")).as("Dev Services need it unset").isEmpty();
    }

    @Test
    void theTestProfileRunsNoBrokerAndPinsRest() {
        ShippedConfig test = ShippedConfig.load("test", Map.of());

        assertThat(test.value("hoops.roster.source")).contains("rest");
        assertThat(test.value("hoops.roster.consumer.enabled")).contains("false");
        assertThat(test.value("quarkus.kafka.devservices.enabled")).contains("false");
    }
}
