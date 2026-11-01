package com.hoopsacademy.common.http;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

/** Every service gets Prometheus metrics from the library (scraped in-cluster; never routed by nginx/ingress). */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class ObservabilityEndpointsTest {

    @Test
    void prometheusMetricsAreServedOnTheManagementPath() {
        given().get("/probe/problems/not-found");
        given().get("/q/metrics").then()
                .statusCode(200)
                .body(containsString("http_server_requests_seconds_count"))
                .body(containsString("jvm_memory_used_bytes"));
    }
}
