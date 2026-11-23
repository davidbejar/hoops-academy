package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.CoreTestResources;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * E2E finding (WP17): with a realm client lacking the Keycloak 25+ {@code basic} scope, access tokens carry no
 * {@code sub}; /me used to fall back to preferred_username and answered 404 "not provisioned". Such tokens are now a
 * 401 Problem; the realm export adds {@code basic} to every client.
 */
@QuarkusTest
@CoreTestResources
class MeWithoutSubjectTest {

    /**
     * {@code CallerSubject} reads {@code hoops.security.require-sub} on every call, so a system property (above the
     * {@code %test} value of application.properties) turns it on for these tests without a profile of their own, which
     * would cost a Quarkus restart with a new database (CORET-01).
     */
    private static final String REQUIRE_SUB = "hoops.security.require-sub";

    @BeforeEach
    void requireSub() {
        System.setProperty(REQUIRE_SUB, "true");
    }

    @AfterEach
    void defaultRequireSub() {
        System.clearProperty(REQUIRE_SUB);
    }

    @Test
    @TestSecurity(user = "nosub-alice")
    @OidcSecurity(claims = @Claim(key = "preferred_username", value = "nosub-alice"))
    void aTokenWithoutSubIsUnauthorized() {
        CoreDb.login("nosub-alice");
        given().get("/api/core/me").then()
                .statusCode(401)
                .contentType("application/problem+json")
                .body("type", equalTo("urn:hoops:problem:unauthorized"));
    }

    @Test
    @TestSecurity(user = "with-sub")
    @OidcSecurity(claims = {@Claim(key = "sub", value = "real-sub-1"), @Claim(key = "preferred_username", value = "with-sub")})
    void aTokenWithSubIsIdentifiedBySubNotByUsername() {
        CoreDb.login("with-sub");
        given().get("/api/core/me").then().statusCode(404);
    }
}
