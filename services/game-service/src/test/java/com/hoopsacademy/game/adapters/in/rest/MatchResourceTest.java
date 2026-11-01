package com.hoopsacademy.game.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
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
import io.restassured.response.ValidatableResponse;
import jakarta.inject.Inject;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class MatchResourceTest {

    static final String A = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
    static final String B = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
    static final String TEAM = "11111111-0000-4000-8000-000000000001";
    static final String OTHER_TEAM = "11111111-0000-4000-8000-000000000002";
    static final String SEASON = "22222222-0000-4000-8000-000000000001";

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
        CoreStubs.teamRoster(core, A, TEAM, SEASON);
        CoreStubs.teamRoster(core, A, OTHER_TEAM, SEASON);
    }

    private static String newMatchBody(String team) {
        return "{\"teamId\":\"" + team + "\",\"opponentName\":\"Lakers U14\",\"homeAway\":\"HOME\","
                + "\"scheduledAt\":\"2026-12-05T09:00:00Z\",\"venue\":\"Main gym\"}";
    }

    private static io.restassured.specification.RequestSpecification asTenantA() {
        return given().filter(Contract.FILTER).header("X-Tenant-Id", A).contentType(ContentType.JSON);
    }

    private ValidatableResponse create(String team) {
        return asTenantA().body(newMatchBody(team)).post("/api/game/matches").then();
    }

    // ---------------------------------------------------------------- create

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void adminCreatesAMatchWithSeasonFromCoreAndDefaults() {
        create(TEAM).statusCode(201)
                .header("Location", org.hamcrest.Matchers.containsString("/api/game/matches/"))
                .body("status", equalTo("SCHEDULED"))
                .body("seasonId", equalTo(SEASON))
                .body("periodCount", equalTo(4))
                .body("periodMinutes", equalTo(10))
                .body("score.team", equalTo(0))
                .body("lastServerSeq", equalTo(0))
                .body("id", notNullValue());
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void coachOfTheTeamCreates() {
        create(TEAM).statusCode(201);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ASSISTANT_COACH, staffTeams = TEAM)
    void assistantCoachOfTheTeamCreates() {
        create(TEAM).statusCode(201);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffOfAnotherTeamCannotCreate() {
        create(OTHER_TEAM).statusCode(403);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT, linkedPlayers = "99999999-0000-4000-8000-000000000001")
    void parentCannotCreateAndCoreIsNotCalled() {
        create(TEAM).statusCode(403);
        core.verify(0, com.github.tomakehurst.wiremock.client.WireMock.getRequestedFor(
                com.github.tomakehurst.wiremock.client.WireMock.urlPathMatching("/internal/teams/.*")));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PLAYER, ownPlayer = "99999999-0000-4000-8000-000000000002")
    void playerCannotCreate() {
        create(TEAM).statusCode(403);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void unknownTeamIsNotFound() {
        String unknown = "11111111-0000-4000-8000-0000000000ff";
        core.stubFor(com.github.tomakehurst.wiremock.client.WireMock
                .get(com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo("/internal/teams/" + unknown + "/roster"))
                .willReturn(com.github.tomakehurst.wiremock.client.WireMock.aResponse().withStatus(404)));

        create(unknown).statusCode(404);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void coreDownMeansProblem503() {
        String team = "11111111-0000-4000-8000-0000000000fe";
        core.stubFor(com.github.tomakehurst.wiremock.client.WireMock
                .get(com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo("/internal/teams/" + team + "/roster"))
                .willReturn(com.github.tomakehurst.wiremock.client.WireMock.aResponse().withStatus(500)));

        given().header("X-Tenant-Id", A).contentType(ContentType.JSON).body(newMatchBody(team)).post("/api/game/matches")
                .then().statusCode(503).contentType("application/problem+json")
                .body("code", equalTo("UPSTREAM_UNAVAILABLE"))
                .body("type", equalTo("urn:hoops:problem:upstream-unavailable"))
                .body("instance", equalTo("/api/game/matches"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void invalidBodyIsABadRequestProblem() {
        given().header("X-Tenant-Id", A).contentType(ContentType.JSON)
                .body("{\"teamId\":\"" + TEAM + "\",\"opponentName\":\"\",\"homeAway\":\"HOME\",\"scheduledAt\":\"2026-12-05T09:00:00Z\"}")
                .post("/api/game/matches").then().statusCode(400).contentType("application/problem+json");
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void memberOfOtherTenantOnlyGetsNotFound() {
        given().header("X-Tenant-Id", B).contentType(ContentType.JSON).body(newMatchBody(TEAM)).post("/api/game/matches")
                .then().statusCode(404);
    }

    // ---------------------------------------------------------------- read

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT)
    void anyMemberCanGetAMatch() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        asTenantA().get("/api/game/matches/" + id).then().statusCode(200).body("id", equalTo(id.toString()));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PLAYER)
    void unknownMatchIsNotFound() {
        asTenantA().get("/api/game/matches/" + UUID.randomUUID()).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void anotherTenantsMatchIsNotFoundEvenForAnAdminOfThatOtherTenant() {
        UUID inB = seed.match(B, TEAM, MatchStatus.SCHEDULED);

        asTenantA().get("/api/game/matches/" + inB).then().statusCode(404);
        asTenantA().body("{\"opponentName\":\"x\"}").patch("/api/game/matches/" + inB).then().statusCode(404);
        asTenantA().post("/api/game/matches/" + inB + "/start").then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT)
    void listFiltersByTeamAndStatusNewestFirst() {
        String team = UUID.randomUUID().toString();
        UUID early = seed.match(A, team, MatchStatus.SCHEDULED, java.time.Instant.parse("2026-12-01T10:00:00Z"));
        UUID late = seed.match(A, team, MatchStatus.SCHEDULED, java.time.Instant.parse("2026-12-20T10:00:00Z"));
        seed.match(A, team, MatchStatus.CANCELLED);
        seed.match(A, UUID.randomUUID().toString(), MatchStatus.SCHEDULED);

        asTenantA().queryParam("teamId", team).queryParam("status", "SCHEDULED").get("/api/game/matches")
                .then().statusCode(200)
                .body("items.id", contains(late.toString(), early.toString()))
                .body("page.totalElements", equalTo(2))
                .body("page.totalPages", equalTo(1));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT)
    void listPagesAndFiltersBySeasonAndRange() {
        String team = UUID.randomUUID().toString();
        seed.match(A, team, MatchStatus.SCHEDULED, java.time.Instant.parse("2027-01-01T10:00:00Z"));
        seed.match(A, team, MatchStatus.SCHEDULED, java.time.Instant.parse("2027-01-02T10:00:00Z"));
        seed.match(A, team, MatchStatus.SCHEDULED, java.time.Instant.parse("2027-01-03T10:00:00Z"));

        asTenantA().queryParam("teamId", team).queryParam("size", 2).queryParam("page", 1).get("/api/game/matches")
                .then().statusCode(200).body("items", hasSize(1)).body("page.totalPages", equalTo(2));
        asTenantA().queryParam("teamId", team).queryParam("scheduledFrom", "2027-01-02T00:00:00Z")
                .queryParam("scheduledTo", "2027-01-02T23:59:59Z").get("/api/game/matches")
                .then().statusCode(200).body("items", hasSize(1));
        asTenantA().queryParam("seasonId", UUID.randomUUID().toString()).get("/api/game/matches")
                .then().statusCode(200).body("items", hasSize(0));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT)
    void listRejectsAnOversizedPage() {
        given().header("X-Tenant-Id", A).queryParam("size", 500).get("/api/game/matches").then().statusCode(400);
    }

    // ---------------------------------------------------------------- patch

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffPatchesAScheduledMatch() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        asTenantA().body("{\"opponentName\":\"Bulls\",\"periodCount\":2,\"venue\":\"Away gym\"}")
                .patch("/api/game/matches/" + id).then().statusCode(200)
                .body("opponentName", equalTo("Bulls")).body("periodCount", equalTo(2)).body("venue", equalTo("Away gym"));
        asTenantA().body("{\"venue\":null}").patch("/api/game/matches/" + id).then().statusCode(200)
                .body("venue", nullValue()).body("opponentName", equalTo("Bulls"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void periodSettingsCannotChangeOnceLive() {
        UUID id = seed.match(A, TEAM, MatchStatus.LIVE);

        asTenantA().body("{\"periodMinutes\":8}").patch("/api/game/matches/" + id).then().statusCode(409);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void emptyPatchIsABadRequest() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        given().header("X-Tenant-Id", A).contentType(ContentType.JSON).body("{}").patch("/api/game/matches/" + id)
                .then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PLAYER)
    void playerCannotPatch() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        asTenantA().body("{\"opponentName\":\"x\"}").patch("/api/game/matches/" + id).then().statusCode(403);
    }

    // ---------------------------------------------------------------- lifecycle

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffStartsFinishesAMatch() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);
        // starter comes with the seeded roster
        asTenantA().post("/api/game/matches/" + id + "/start").then().statusCode(200)
                .body("status", equalTo("LIVE")).body("startedAt", notNullValue());
        asTenantA().post("/api/game/matches/" + id + "/start").then().statusCode(200).body("status", equalTo("LIVE"));
        asTenantA().post("/api/game/matches/" + id + "/finish").then().statusCode(200)
                .body("status", equalTo("FINISHED")).body("finishedAt", notNullValue());
        asTenantA().post("/api/game/matches/" + id + "/start").then().statusCode(409);
        asTenantA().post("/api/game/matches/" + id + "/finish").then().statusCode(409);
        asTenantA().body("{\"reason\":\"too late\"}").post("/api/game/matches/" + id + "/cancel").then().statusCode(409);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void cannotFinishAMatchThatIsNotLive() {
        UUID id = seed.match(A, TEAM, MatchStatus.CANCELLED);

        asTenantA().post("/api/game/matches/" + id + "/finish").then().statusCode(409)
                .body("code", equalTo("INVALID_STATE"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void startWithoutStarterIs422() {
        // created through the API, so it has no roster at all
        String id = create(TEAM).statusCode(201).extract().path("id");

        asTenantA().post("/api/game/matches/" + id + "/start").then().statusCode(422).body("code", equalTo("NO_STARTERS"));
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ASSISTANT_COACH, staffTeams = TEAM)
    void cancelFromLiveRecordsTheReason() {
        UUID id = seed.match(A, TEAM, MatchStatus.LIVE);

        asTenantA().body("{\"reason\":\"Floor flooded\"}").post("/api/game/matches/" + id + "/cancel").then().statusCode(200)
                .body("status", equalTo("CANCELLED")).body("cancelReason", equalTo("Floor flooded"))
                .body("cancelledAt", notNullValue());
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = TEAM)
    void cancelNeedsAReason() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        given().header("X-Tenant-Id", A).contentType(ContentType.JSON).body("{\"reason\":\" \"}")
                .post("/api/game/matches/" + id + "/cancel").then().statusCode(400);
    }

    // ---------------------------------------------------------------- role matrix on lifecycle

    @Test
    @TenantUser(tenant = A, roles = TenantRole.COACH, staffTeams = OTHER_TEAM)
    void staffOfAnotherTeamCannotStartFinishCancelOrPatch() {
        UUID id = seed.match(A, TEAM, MatchStatus.LIVE);

        asTenantA().post("/api/game/matches/" + id + "/start").then().statusCode(403);
        asTenantA().post("/api/game/matches/" + id + "/finish").then().statusCode(403);
        asTenantA().body("{\"reason\":\"x\"}").post("/api/game/matches/" + id + "/cancel").then().statusCode(403);
        asTenantA().body("{\"opponentName\":\"x\"}").patch("/api/game/matches/" + id).then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.PARENT, linkedPlayers = "99999999-0000-4000-8000-000000000001")
    void parentCannotStartFinishOrCancel() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        asTenantA().post("/api/game/matches/" + id + "/start").then().statusCode(403);
        asTenantA().post("/api/game/matches/" + id + "/finish").then().statusCode(403);
        asTenantA().body("{\"reason\":\"x\"}").post("/api/game/matches/" + id + "/cancel").then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = A, roles = {TenantRole.PLAYER, TenantRole.PARENT})
    void aPlayerWhoIsAlsoAParentStillCannotStart() {
        UUID id = seed.match(A, TEAM, MatchStatus.SCHEDULED);

        asTenantA().post("/api/game/matches/" + id + "/start").then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = A, roles = TenantRole.ADMIN)
    void adminManagesAnyTeam() {
        UUID id = seed.match(A, OTHER_TEAM, MatchStatus.SCHEDULED);

        asTenantA().post("/api/game/matches/" + id + "/start").then().statusCode(200).body("id", equalTo(id.toString()));
    }
}
