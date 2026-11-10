package com.hoopsacademy.game.adapters.in.messaging;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;
import static org.hamcrest.Matchers.equalTo;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.atLeast;
import static org.mockito.Mockito.doCallRealMethod;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.RosterBrokerResource;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.application.replica.RosterEvent;
import com.hoopsacademy.game.support.CoreEvents;
import com.hoopsacademy.game.support.CoreTopics;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.ReplicaDb;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.QuarkusTestProfile;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.junit.mockito.InjectSpy;
import java.time.Duration;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

/**
 * Failures that are not contract violations (ADR-0037): a failed apply is retried in place; when every attempt fails
 * the channel fails and nothing is lost: the messaging health checks turn DOWN (liveness: the pod is restarted and
 * resumes from the committed offset, which is still before the event). Own profile: the failed channel must not stop
 * the consumer of the other test classes.
 */
@QuarkusTest
@TestProfile(RosterConsumerFailureTest.TwoAttempts.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
@WithTestResource(RosterBrokerResource.class)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class RosterConsumerFailureTest {

    public static class TwoAttempts implements QuarkusTestProfile {
        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of("hoops.roster.replica.apply-attempts", "2");
        }
    }

    private static final Duration WAIT = Duration.ofSeconds(30);
    private static final LocalDate SEASON_END = LocalDate.parse("2027-06-30");

    @InjectSpy
    ReplicateRoster replicate;

    private final TenantId tenant = TenantId.random();

    @Test
    @Order(1)
    void aFailedApplyIsRetried() {
        UUID team = UUID.randomUUID();
        doThrow(new IllegalStateException("database blip")).doCallRealMethod().when(replicate).apply(argThat(about(team)));

        CoreTopics.publish(CoreEvents.of(tenant).team(team, UUID.randomUUID(), SEASON_END, "Lions"));

        await().atMost(WAIT).untilAsserted(() -> assertThat(teamName(team)).isEqualTo("Lions"));
        verify(replicate, times(2)).apply(argThat(about(team)));
        given().get("/q/health/live").then().statusCode(200);
    }

    @Test
    @Order(2)
    void whenEveryAttemptFailsTheConsumerStopsAndTheHealthChecksSaySo() {
        UUID team = UUID.randomUUID();
        doThrow(new IllegalStateException("database gone")).when(replicate).apply(argThat(about(team)));

        CoreTopics.publish(CoreEvents.of(tenant).team(team, UUID.randomUUID(), SEASON_END, "Lions"));

        await().atMost(WAIT).untilAsserted(() -> given().get("/q/health/live").then().statusCode(503));
        verify(replicate, atLeast(2)).apply(argThat(about(team)));
        assertThat(teamName(team)).isNull();
        given().get("/q/health/ready").then().statusCode(503)
                .body("checks.find { it.name == 'Database connections health check' }.status", equalTo("UP"));
    }

    private static org.mockito.ArgumentMatcher<RosterEvent> about(UUID aggregate) {
        return event -> event != null && event.envelope().aggregateId().equals(aggregate);
    }

    private Object teamName(UUID team) {
        return ReplicaDb.value(tenant, "select name from game.team_ref where id = '" + team + "'");
    }
}
