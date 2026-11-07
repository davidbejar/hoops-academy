package com.hoopsacademy.common.tenancy;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.SecurityEventCapture;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.QuarkusTestProfile;
import io.quarkus.test.junit.TestProfile;
import java.util.Map;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import org.junit.jupiter.api.Test;

/**
 * A Keycloak access token without {@code sub} (realm client missing the {@code basic} scope, Keycloak 25+) must be
 * rejected with a 401 Problem — never identified by {@code preferred_username}, which is mutable and not unique
 * across realms/clients.
 */
@QuarkusTest
@TestProfile(MissingSubjectTest.RequireSub.class)
@WithTestResource(PostgresRlsResource.class)
class MissingSubjectTest {

    /** The production default (the module's test config relaxes it for plain {@code @TestSecurity}). */
    public static class RequireSub implements QuarkusTestProfile {
        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of("hoops.security.require-sub", "true");
        }
    }

    @Test
    @TestSecurity(user = "alice")
    @OidcSecurity(claims = @Claim(key = "preferred_username", value = "alice"))
    void aTokenWithoutSubIsUnauthorizedOnTenantPaths() {
        given().header("X-Tenant-Id", TenantHeaderFilterTest.TENANT_A).get("/api/probe/whoami").then()
                .statusCode(401)
                .contentType("application/problem+json")
                .header("WWW-Authenticate", "Bearer")
                .body("type", equalTo("urn:hoops:problem:unauthorized"));
    }

    @Test
    @TestSecurity(user = "alice")
    @OidcSecurity(claims = @Claim(key = "preferred_username", value = "alice"))
    void aTokenWithoutSubIsUnauthorizedOnExemptPaths() {
        given().get("/api/probe/me/subject").then()
                .statusCode(401)
                .contentType("application/problem+json");
    }

    @Test
    @TestSecurity(user = "alice")
    @OidcSecurity(claims = @Claim(key = "preferred_username", value = "alice"))
    void aTokenWithoutSubIsOneInvalidTokenEventWithoutTheUsername() {
        for (String path : new String[] {"/api/probe/whoami", "/api/probe/me/subject"}) {
            try (SecurityEventCapture events = SecurityEventCapture.open()) {
                given().header("X-Tenant-Id", TenantHeaderFilterTest.TENANT_A).get(path).then().statusCode(401);

                assertThat(events.single())
                        .containsEntry("security.kind", "invalid_token")
                        .containsEntry("security.reason", "no_sub")
                        .containsEntry("security.subject", "-");
            }
        }
    }

    @Test
    @TestSecurity(user = "bob")
    @OidcSecurity(claims = @Claim(key = "sub", value = "bob-sub"))
    void aTokenWithSubIsIdentifiedBySub() {
        given().get("/api/probe/me/subject").then().statusCode(200).body(equalTo("bob-sub"));
    }
}
