package com.hoopsacademy.common.http;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.response.ValidatableResponse;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.junit.jupiter.api.Test;

/** Defense in depth: API responses carry security headers even when no proxy adds them (library defaults). */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class SecurityHeadersTest {

    @ParameterizedTest
    @ValueSource(strings = {"/probe/problems/not-found", "/api/probe/whoami", "/platform/probe/ping", "/internal/x"})
    void everyApiResponseCarriesTheSecurityHeaders(String path) {
        assertSecurityHeaders(given().get(path).then());
    }

    @Test
    void theHeadersAreNotAddedToNonApiPaths() {
        // /q/** (health, metrics) and anything else are left alone: the dev UI would break under default-src 'none'.
        given().get("/q/metrics").then().header("Content-Security-Policy", nullValue());
    }

    static ValidatableResponse assertSecurityHeaders(ValidatableResponse response) {
        return response
                .header("X-Content-Type-Options", equalTo("nosniff"))
                .header("X-Frame-Options", equalTo("DENY"))
                .header("Referrer-Policy", equalTo("no-referrer"))
                .header("Content-Security-Policy", equalTo("default-src 'none'; frame-ancestors 'none'"))
                .header("Cross-Origin-Resource-Policy", equalTo("same-origin"));
    }
}
