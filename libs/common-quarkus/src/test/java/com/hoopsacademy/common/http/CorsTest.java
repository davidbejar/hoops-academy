package com.hoopsacademy.common.http;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

/** CORS is an allow-list from {@code hoops.cors.origins} (default: the Flutter dev server on :5173). */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class CorsTest {

    private static final String DEV_SERVER = "http://localhost:5173";

    @Test
    void thePreflightOfAnAllowedOriginIsAnswered() {
        given().header("Origin", DEV_SERVER)
                .header("Access-Control-Request-Method", "PATCH")
                .header("Access-Control-Request-Headers", "authorization,content-type,x-tenant-id")
                .options("/api/probe/whoami").then()
                .statusCode(200)
                .header("Access-Control-Allow-Origin", equalTo(DEV_SERVER))
                .header("Access-Control-Allow-Methods", containsString("PATCH"))
                .header("Access-Control-Allow-Headers", containsString("x-tenant-id"))
                .header("Access-Control-Allow-Credentials", not(equalTo("true")));
    }

    @Test
    void anOriginOutsideTheAllowListGetsNoCorsHeaders() {
        given().header("Origin", "https://evil.example")
                .header("Access-Control-Request-Method", "GET")
                .options("/api/probe/whoami").then()
                .header("Access-Control-Allow-Origin", nullValue());
        given().header("Origin", "https://evil.example").get("/probe/problems/not-found").then()
                .header("Access-Control-Allow-Origin", nullValue());
    }

    @Test
    void anAllowedOriginSeesTheExposedHeaders() {
        given().header("Origin", DEV_SERVER).get("/probe/problems/not-found").then()
                .header("Access-Control-Allow-Origin", equalTo(DEV_SERVER))
                .header("Access-Control-Expose-Headers", containsString("ETag"));
    }
}
