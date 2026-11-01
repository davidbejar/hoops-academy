package com.hoopsacademy.game.adapters.out.client;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

/**
 * Probes for Kubernetes: readiness includes the database; core-service reachability is reported as data only, so a
 * core outage never takes game-service out of rotation (requests answer 503 Problems instead).
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class HealthEndpointsTest {

    private static final String CORE_CHECK = "checks.find { it.name == 'core-service' }";

    @InjectCoreWireMock
    WireMockServer core;

    @AfterEach
    void removeHealthStubs() {
        core.resetMappings();
        com.hoopsacademy.game.support.CoreStubs.tokenEndpoint(core);
    }

    @Test
    void livenessIsUp() {
        given().get("/q/health/live").then().statusCode(200).body("status", equalTo("UP"));
    }

    @Test
    void readinessIncludesTheDatabase() {
        given().get("/q/health/ready").then()
                .statusCode(200)
                .body("status", equalTo("UP"))
                .body("checks.name", hasItem(containsString("Database")));
    }

    @Test
    void aReachableCoreIsReported() {
        core.stubFor(get(urlPathEqualTo("/q/health/live")).willReturn(aResponse().withStatus(200)));

        given().get("/q/health/ready").then()
                .statusCode(200)
                .body(CORE_CHECK + ".status", equalTo("UP"))
                .body(CORE_CHECK + ".data.core", equalTo("reachable"));
    }

    @Test
    void aFailingCoreIsReportedButReadinessStaysUp() {
        core.stubFor(get(urlPathEqualTo("/q/health/live")).willReturn(aResponse().withStatus(500)));

        given().get("/q/health/ready").then()
                .statusCode(200)
                .body("status", equalTo("UP"))
                .body(CORE_CHECK + ".status", equalTo("UP"))
                .body(CORE_CHECK + ".data.core", equalTo("unreachable"));
    }

    @Test
    void aSlowCoreIsReportedUnreachableWithinTheProbeTimeout() {
        core.stubFor(get(urlPathEqualTo("/q/health/live")).willReturn(aResponse().withStatus(200).withFixedDelay(3000)));

        given().get("/q/health/ready").then()
                .statusCode(200)
                .time(org.hamcrest.Matchers.lessThan(2500L))
                .body(CORE_CHECK + ".data.core", equalTo("unreachable"));
    }

    @Test
    void prometheusMetricsAreServed() {
        given().get("/q/metrics").then().statusCode(200).body(containsString("jvm_memory_used_bytes"));
    }
}
