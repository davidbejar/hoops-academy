package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.QuarkusTestProfile;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * E2E finding (WP17): with a realm client lacking the Keycloak 25+ {@code basic} scope, access tokens carry no
 * {@code sub}; /me used to fall back to preferred_username and answered 404 "not provisioned". Such tokens are now a
 * 401 Problem; the realm export adds {@code basic} to every client.
 */
@QuarkusTest
@TestProfile(MeWithoutSubjectTest.RequireSub.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class MeWithoutSubjectTest {

    public static class RequireSub implements QuarkusTestProfile {
        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of("hoops.security.require-sub", "true");
        }
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
