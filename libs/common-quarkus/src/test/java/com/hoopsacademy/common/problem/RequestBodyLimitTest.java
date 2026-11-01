package com.hoopsacademy.common.problem;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

/**
 * Bodies above {@code quarkus.http.limits.max-body-size} (64K in this module's tests) are rejected by the HTTP layer
 * before any resource runs; the answer must still be a Problem, not Vert.x' empty 413.
 */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class RequestBodyLimitTest {

    private static final String PATH = "/probe/problems/validation";

    @Test
    void aBodyAboveTheLimitIsA413Problem() {
        String body = "{\"name\":\"" + "x".repeat(70 * 1024) + "\"}";
        given().contentType("application/json").body(body).post(PATH).then()
                .statusCode(413)
                .contentType("application/problem+json")
                .header("Connection", "close")
                .body("type", equalTo("urn:hoops:problem:payload-too-large"))
                .body("title", equalTo("Payload Too Large"))
                .body("status", equalTo(413))
                .body("code", equalTo("REQUEST_TOO_LARGE"))
                .body("instance", equalTo(PATH));
    }

    @Test
    void aBodyBelowTheLimitReachesTheResource() {
        String body = "{\"name\":\"" + "x".repeat(60 * 1024) + "\"}";
        given().contentType("application/json").body(body).post(PATH).then().statusCode(200);
    }
}
