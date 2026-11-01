package com.hoopsacademy.athlete.adapters.out.client;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import jakarta.inject.Inject;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * End to end through the PRODUCTION AuthzContextResolver: membership comes from WireMock core's /internal/authz.
 * (The other API tests use the test-jar's registry-backed resolver.)
 */
@QuarkusTest
@TestProfile(RealResolverProfile.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class RealResolverApiTest {

    static final String TENANT = "59000000-0000-4000-8000-000000000001";
    static final String TEAM = "59000000-0000-4000-8000-0000000000a1";
    static final String URL = "/api/athlete/training-schedules";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
    }

    @Test
    void activeMemberPassesWithRolesFromCore() {
        core.member(TENANT, "tenant-user", "ACTIVE", null, "[\"COACH\"]", CoreStubs.json(List.of(TEAM)), "[]", "null");

        given().header("X-Tenant-Id", TENANT).get(URL).then().statusCode(200);
    }

    @Test
    void rolesFromCoreDecideAuthorisation() {
        core.member(TENANT, "tenant-user", "ACTIVE", null, "[\"PARENT\"]", "[]", CoreStubs.json(List.of(UUID.randomUUID().toString())), "null");
        core.roster(TENANT, TEAM);

        given().header("X-Tenant-Id", TENANT).contentType("application/json")
                .body("{\"teamId\":\"%s\",\"dayOfWeek\":\"MONDAY\",\"startTime\":\"18:00\",\"durationMinutes\":60,\"validFrom\":\"2030-01-01\"}".formatted(TEAM))
                .post(URL).then().statusCode(403);
    }

    @Test
    void nonMemberIs404() {
        core.notAMember(TENANT, "tenant-user");

        given().header("X-Tenant-Id", TENANT).get(URL).then().statusCode(404);
    }

    @Test
    void suspendedTenantIs404() {
        core.member(TENANT, "tenant-user", "SUSPENDED", null, "[\"ADMIN\"]", "[]", "[]", "null");

        given().header("X-Tenant-Id", TENANT).get(URL).then().statusCode(404);
    }

    @Test
    void coreDownIs503() {
        // no stub for the subject and an unreachable authz endpoint: reset leaves WireMock answering 404 for unknown
        // routes, so simulate failure with a 500 for the authz call
        new com.github.tomakehurst.wiremock.client.WireMock("localhost",
                org.eclipse.microprofile.config.ConfigProvider.getConfig().getValue("wiremock.port", Integer.class))
                .register(com.github.tomakehurst.wiremock.client.WireMock
                        .get(com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo("/internal/authz/" + TENANT + "/tenant-user"))
                        .willReturn(com.github.tomakehurst.wiremock.client.WireMock.aResponse().withStatus(500)));

        given().header("X-Tenant-Id", TENANT).get(URL).then().statusCode(503).body("code", equalTo("UPSTREAM_UNAVAILABLE"));
    }
}
