package com.hoopsacademy.game.adapters.in.messaging;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.support.CoreWireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.smallrye.reactive.messaging.kafka.KafkaClientService;
import jakarta.inject.Inject;
import org.junit.jupiter.api.Test;

/**
 * {@code GAME_ROSTER_CONSUMER_ENABLED=false} (the escape hatch, ADR-0037): game starts and is ready without the consumer.
 * {@code %test} already switches the consumer off ({@code application.properties}), so this class runs in the shared
 * application of its resources instead of booting its own (GAME-08).
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class RosterConsumerSwitchedOffTest {

    @Inject
    KafkaClientService kafka;

    @Test
    void gameIsReadyWithoutTheConsumer() {
        assertThat(kafka.getConsumer("core-roster")).as("no Kafka consumer for the channel").isNull();
        given().get("/q/health/ready").then().statusCode(200).body("status", equalTo("UP"));
        given().get("/q/health/live").then().statusCode(200);
    }
}
