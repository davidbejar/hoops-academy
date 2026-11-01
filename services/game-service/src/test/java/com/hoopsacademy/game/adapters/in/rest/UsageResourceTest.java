package com.hoopsacademy.game.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.support.Contract;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import jakarta.inject.Inject;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class UsageResourceTest {

    static final String USAGE_TENANT = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
    static final String EMPTY_TENANT = "dddddddd-dddd-4ddd-8ddd-dddddddddddd";
    static final String TEAM = "11111111-0000-4000-8000-000000000021";

    @Inject
    MatchSeed seed;

    @Test
    @TestSecurity(user = "platform", roles = "service")
    void countsMatchesByStatusForThatTenantOnly() {
        seed.match(USAGE_TENANT, TEAM, MatchStatus.SCHEDULED);
        seed.match(USAGE_TENANT, TEAM, MatchStatus.SCHEDULED);
        seed.match(USAGE_TENANT, TEAM, MatchStatus.LIVE);
        seed.match(USAGE_TENANT, TEAM, MatchStatus.FINISHED);
        seed.match(USAGE_TENANT, TEAM, MatchStatus.CANCELLED);
        seed.match(EMPTY_TENANT.replace('d', 'e'), TEAM, MatchStatus.SCHEDULED);

        given().filter(Contract.FILTER).get("/internal/usage/" + USAGE_TENANT).then().statusCode(200)
                .body("tenantId", equalTo(USAGE_TENANT))
                .body("service", equalTo("game"))
                .body("collectedAt", notNullValue())
                .body("lastActivityAt", notNullValue())
                .body("counters.matches", equalTo(5))
                .body("counters.scheduledMatches", equalTo(2))
                .body("counters.liveMatches", equalTo(1))
                .body("counters.finishedMatches", equalTo(1))
                .body("counters.cancelledMatches", equalTo(1))
                .body("counters.matchEvents", equalTo(0));
    }

    @Test
    @TestSecurity(user = "platform", roles = "service")
    void aTenantWithoutMatchesReportsZeros() {
        given().get("/internal/usage/" + EMPTY_TENANT).then().statusCode(200)
                .body("counters.matches", equalTo(0));
    }

    @Test
    @TestSecurity(user = "platform", roles = "service")
    void malformedTenantIsABadRequest() {
        given().get("/internal/usage/not-a-uuid").then().statusCode(400);
    }

    @Test
    @TestSecurity(user = "someone", roles = "ADMIN")
    void callersWithoutTheServiceRoleAreForbidden() {
        given().get("/internal/usage/" + USAGE_TENANT).then().statusCode(403);
    }

    @Test
    void anonymousCallersAreUnauthorized() {
        given().get("/internal/usage/" + USAGE_TENANT).then().statusCode(401);
    }
}
