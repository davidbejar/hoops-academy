package com.hoopsacademy.game.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.SecurityEventCapture;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.game.adapters.out.client.RestRosterPort;
import com.hoopsacademy.game.support.CoreStubs;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * ADR-0043 through game's real endpoints: a caller of another academy and a member refused by the match rules are
 * one {@code hoops.security} event each, counted in {@code hoops_authz_denied_total}.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class SecurityEventsTest {

    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1";
    static final String B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1";
    static final String TEAM = "11111111-0000-4000-8000-0000000000e1";
    static final String SEASON = "22222222-0000-4000-8000-0000000000e1";

    @InjectCoreWireMock
    WireMockServer core;

    @Inject
    RestRosterPort rosterPort;

    @BeforeEach
    void reset() {
        CoreStubs.reset(core);
        rosterPort.clearCache();
        CoreStubs.teamRoster(core, A, TEAM, SEASON);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void aCallerOfAnotherAcademyIsANotMemberEvent() {
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().header("X-Tenant-Id", B).get("/api/game/matches").then().statusCode(404);

            assertThat(events.single())
                    .containsEntry("security.kind", "not_member")
                    .containsEntry("security.outcome", "404")
                    .containsEntry("tenantId", B)
                    .containsEntry("security.subject", TenantUser.SUBJECT)
                    .containsEntry("security.resource", "GET /api/game/matches");
        }
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT)
    void aParentSchedulingAMatchIsAFineGrainedEventAndCounted() {
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().header("X-Tenant-Id", A).contentType(ContentType.JSON)
                    .body("{\"teamId\":\"" + TEAM + "\",\"opponentName\":\"Lakers U14\",\"homeAway\":\"HOME\","
                            + "\"scheduledAt\":\"2026-12-05T09:00:00Z\",\"venue\":\"Main gym\"}")
                    .post("/api/game/matches").then().statusCode(403);

            assertThat(events.single())
                    .containsEntry("security.kind", "fine_grained")
                    .containsEntry("security.outcome", "403")
                    .containsEntry("tenantId", A)
                    .containsEntry("security.roles", "PARENT")
                    .containsEntry("security.resource", "POST /api/game/matches");
        }
        given().get("/q/metrics").then().statusCode(200)
                .body(containsString("hoops_authz_denied_total{kind=\"fine_grained\"}"));
    }
}
