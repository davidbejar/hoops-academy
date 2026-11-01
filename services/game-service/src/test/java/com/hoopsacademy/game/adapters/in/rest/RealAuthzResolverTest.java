package com.hoopsacademy.game.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.game.adapters.out.client.RestRosterPort;
import com.hoopsacademy.game.support.CoreStubs;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.QuarkusTestProfile;
import io.quarkus.test.junit.TestProfile;
import jakarta.inject.Inject;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The tenant filter with the PRODUCTION resolver (RosterAuthzResolver over WireMock core): the common test-jar's
 * TestAuthzContextResolver is excluded for this profile only, via quarkus.arc.exclude-types.
 */
@QuarkusTest
@TestProfile(RealAuthzResolverTest.RealResolverProfile.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class RealAuthzResolverTest {

    public static class RealResolverProfile implements QuarkusTestProfile {
        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of("quarkus.arc.exclude-types", "com.hoopsacademy.common.testing.TestAuthzContextResolver");
        }
    }

    static final String TENANT = "11111111-1111-4111-8111-111111111111";

    @InjectCoreWireMock
    WireMockServer core;

    @Inject
    RestRosterPort port;

    @BeforeEach
    void reset() {
        CoreStubs.reset(core);
        port.clearCache();
    }

    @Test
    @TenantUser(tenant = TENANT)
    void activeMemberReachesTheApi() {
        CoreStubs.authz(core, TENANT, TenantUser.SUBJECT, "ACTIVE", List.of("PARENT"), List.of());

        given().header("X-Tenant-Id", TENANT).get("/api/game/matches").then().statusCode(200).body("items.size()", equalTo(0));
    }

    @Test
    @TenantUser(tenant = TENANT)
    void suspendedTenantIsNotFound() {
        CoreStubs.authz(core, TENANT, TenantUser.SUBJECT, "SUSPENDED", List.of("ADMIN"), List.of());

        given().header("X-Tenant-Id", TENANT).get("/api/game/matches").then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT)
    void coreSaysNotAMemberIsNotFound() {
        core.stubFor(com.github.tomakehurst.wiremock.client.WireMock
                .get(com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo("/internal/authz/" + TENANT + "/" + TenantUser.SUBJECT))
                .willReturn(com.github.tomakehurst.wiremock.client.WireMock.aResponse().withStatus(404)));

        given().header("X-Tenant-Id", TENANT).get("/api/game/matches").then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT)
    void coreDownIsAProblem503() {
        core.stubFor(com.github.tomakehurst.wiremock.client.WireMock
                .get(com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo("/internal/authz/" + TENANT + "/" + TenantUser.SUBJECT))
                .willReturn(com.github.tomakehurst.wiremock.client.WireMock.aResponse().withStatus(500)));

        given().header("X-Tenant-Id", TENANT).get("/api/game/matches").then().statusCode(503)
                .contentType("application/problem+json")
                .body("code", equalTo("UPSTREAM_UNAVAILABLE"))
                .body("status", equalTo(503));
    }
}
