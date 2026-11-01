package com.hoopsacademy.core.adapters.health;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;

import com.hoopsacademy.common.client.CoreReachabilityCheck;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

/**
 * core-service probes: readiness includes the database, and the shared {@link CoreReachabilityCheck} of
 * common-quarkus (meant for game/athlete) is switched off at build time, so core never probes itself.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class CoreHealthEndpointsTest {

    @Test
    void readinessIncludesTheDatabaseButNoSelfProbe() {
        given().get("/q/health/ready").then()
                .statusCode(200)
                .body("status", equalTo("UP"))
                .body("checks.name", hasItem(containsString("Database")))
                .body("checks.name", not(hasItem(CoreReachabilityCheck.NAME)));
    }

    @Test
    void livenessIsUp() {
        given().get("/q/health/live").then().statusCode(200).body("status", equalTo("UP"));
    }
}
