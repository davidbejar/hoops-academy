package com.hoopsacademy.athlete.adapters.out.client;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.lessThan;

import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Probes for Kubernetes: readiness includes the database; core-service reachability is reported as data only, so a
 * core outage never takes athlete-service out of rotation (requests answer 503 Problems instead).
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class HealthEndpointsTest {

    private static final String CORE_CHECK = "checks.find { it.name == 'core-service' }";

    private CoreStubs core;

    @BeforeEach
    void resetCore() {
        core = new CoreStubs().reset();
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
        core.coreLiveness(200, 0);

        given().get("/q/health/ready").then()
                .statusCode(200)
                .body(CORE_CHECK + ".status", equalTo("UP"))
                .body(CORE_CHECK + ".data.core", equalTo("reachable"));
    }

    @Test
    void aFailingCoreIsReportedButReadinessStaysUp() {
        core.coreLiveness(503, 0);

        given().get("/q/health/ready").then()
                .statusCode(200)
                .body("status", equalTo("UP"))
                .body(CORE_CHECK + ".data.core", equalTo("unreachable"));
    }

    @Test
    void aSlowCoreIsReportedUnreachableWithinTheProbeTimeout() {
        core.coreLiveness(200, 3000);

        given().get("/q/health/ready").then()
                .statusCode(200)
                .time(lessThan(2500L))
                .body(CORE_CHECK + ".data.core", equalTo("unreachable"));
    }

    @Test
    void prometheusMetricsAreServed() {
        given().get("/q/metrics").then().statusCode(200).body(containsString("jvm_memory_used_bytes"));
    }
}
