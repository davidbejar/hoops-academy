package com.hoopsacademy.game.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.game.adapters.out.client.RestRosterPort;
import com.hoopsacademy.game.domain.MatchStatus;
import com.hoopsacademy.game.support.Contract;
import com.hoopsacademy.game.support.CoreStubs;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import com.hoopsacademy.game.support.MatchSeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import jakarta.inject.Inject;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class MatchRosterResourceTest {

    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
    static final String TEAM = "11111111-0000-4000-8000-000000000011";
    static final String OTHER_TEAM = "11111111-0000-4000-8000-000000000012";
    static final String SEASON = "22222222-0000-4000-8000-000000000001";
    static final String ANA = "55555555-0000-4000-8000-000000000001";
    static final String BO = "55555555-0000-4000-8000-000000000002";
    static final String STRANGER = "55555555-0000-4000-8000-0000000000ff";

    @InjectCoreWireMock
    WireMockServer core;

    @Inject
    RestRosterPort rosterPort;

    @Inject
    MatchSeed seed;

    @BeforeEach
    void reset() {
        CoreStubs.reset(core);
        rosterPort.clearCache();
        CoreStubs.teamRoster(core, A, TEAM, SEASON, CoreStubs.player(ANA, "Ana Ruiz", "7"), CoreStubs.player(BO, "Bo Chen", null));
    }

    private static RequestSpecification asTenantA() {
        return given().filter(Contract.FILTER).header("X-Tenant-Id", A).contentType(ContentType.JSON);
    }

    private static String body(String... entries) {
        return "{\"entries\":[" + String.join(",", entries) + "]}";
    }

    private static String entry(String player, String jersey, boolean starter) {
        return "{\"playerId\":\"" + player + "\"," + (jersey == null ? "" : "\"jerseyNumber\":\"" + jersey + "\",")
                + "\"isStarter\":" + starter + "}";
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffReplacesTheRosterAndNamesAreSnapshotted() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        asTenantA().body(body(entry(ANA, null, true), entry(BO, "12", false))).put("/api/game/matches/" + id + "/roster")
                .then().statusCode(200)
                .body("matchId", equalTo(id.toString()))
                .body("entries", hasSize(2))
                .body("entries.displayName", containsInAnyOrder("Ana Ruiz", "Bo Chen"))
                .body("entries.find { it.playerId == '" + ANA + "' }.jerseyNumber", equalTo("7"))
                .body("entries.find { it.playerId == '" + BO + "' }.jerseyNumber", equalTo("12"))
                .body("entries.find { it.playerId == '" + ANA + "' }.isStarter", equalTo(true));

        asTenantA().get("/api/game/matches/" + id + "/roster").then().statusCode(200).body("entries", hasSize(2));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void aSecondPutReplacesTheFirstAndMayEmptyTheRoster() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);
        asTenantA().body(body(entry(ANA, null, true))).put("/api/game/matches/" + id + "/roster").then().statusCode(200);

        asTenantA().body(body(entry(BO, null, false))).put("/api/game/matches/" + id + "/roster").then().statusCode(200)
                .body("entries", hasSize(1)).body("entries[0].playerId", equalTo(BO)).body("entries[0].jerseyNumber", nullValue());
        asTenantA().body(body()).put("/api/game/matches/" + id + "/roster").then().statusCode(200).body("entries", hasSize(0));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void playerOutsideTheTeamIs422AndNothingIsStored() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        given().header("X-Tenant-Id", A).contentType(ContentType.JSON)
                .body(body(entry(ANA, null, true), entry(STRANGER, null, false))).put("/api/game/matches/" + id + "/roster")
                .then().statusCode(422).contentType("application/problem+json")
                .body("code", equalTo("PLAYER_NOT_IN_TEAM"))
                .body("violations[0].field", equalTo("entries"))
                .body("violations[0].code", equalTo("PLAYER_NOT_IN_TEAM"));
        // the seeded starter is still there
        asTenantA().get("/api/game/matches/" + id + "/roster").then().body("entries.displayName", containsInAnyOrder("Seed Starter"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void duplicatePlayerIs422() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        given().header("X-Tenant-Id", A).contentType(ContentType.JSON).body(body(entry(ANA, null, true), entry(ANA, null, false)))
                .put("/api/game/matches/" + id + "/roster").then().statusCode(422).body("code", equalTo("DUPLICATE_PLAYER"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void malformedJerseyIsABadRequest() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        given().header("X-Tenant-Id", A).contentType(ContentType.JSON).body(body(entry(ANA, "123", true)))
                .put("/api/game/matches/" + id + "/roster").then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void finishedAndCancelledMatchesKeepTheirRoster() {
        UUID finished = seed.match(A, TEAM, MatchStatus.FINISHED);
        UUID cancelled = seed.match(A, TEAM, MatchStatus.CANCELLED);

        asTenantA().body(body(entry(ANA, null, true))).put("/api/game/matches/" + finished + "/roster").then().statusCode(409);
        asTenantA().body(body(entry(ANA, null, true))).put("/api/game/matches/" + cancelled + "/roster").then().statusCode(409);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT, linkedPlayers = ANA)
    void parentReadsButCannotWriteTheRoster() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        asTenantA().get("/api/game/matches/" + id + "/roster").then().statusCode(200);
        asTenantA().body(body(entry(ANA, null, true))).put("/api/game/matches/" + id + "/roster").then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PLAYER, ownPlayer = ANA)
    void playerCannotWriteTheRoster() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        asTenantA().body(body(entry(ANA, null, true))).put("/api/game/matches/" + id + "/roster").then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = OTHER_TEAM)
    void staffOfAnotherTeamCannotWriteTheRoster() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        asTenantA().body(body(entry(ANA, null, true))).put("/api/game/matches/" + id + "/roster").then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void rosterOfAnotherTenantsMatchIsNotFound() {
        UUID inB = seed.match(B, TEAM, MatchStatus.SCHEDULED);

        asTenantA().get("/api/game/matches/" + inB + "/roster").then().statusCode(404);
        asTenantA().body(body()).put("/api/game/matches/" + inB + "/roster").then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void coreDownMeansProblem503() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);
        rosterPort.clearCache();
        core.stubFor(com.github.tomakehurst.wiremock.client.WireMock
                .get(com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo("/internal/teams/" + TEAM + "/roster"))
                .willReturn(com.github.tomakehurst.wiremock.client.WireMock.aResponse().withStatus(502)));

        given().header("X-Tenant-Id", A).contentType(ContentType.JSON).body(body(entry(ANA, null, true)))
                .put("/api/game/matches/" + id + "/roster").then().statusCode(503).body("code", equalTo("UPSTREAM_UNAVAILABLE"));
    }
}
