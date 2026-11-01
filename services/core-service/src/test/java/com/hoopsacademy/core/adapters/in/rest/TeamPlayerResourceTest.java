package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import java.time.LocalDate;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class TeamPlayerResourceTest {

    private static final String TEAMS = "/api/core/teams/";

    private String tenant;
    private UUID season;
    private Map<String, UUID> categories;
    private UUID lions;
    private UUID uma;

    @BeforeEach
    void u12TeamAndAnElevenYearOld() {
        tenant = Members.newTenant();
        season = RosterDb.currentSeason(tenant);
        categories = RosterDb.defaultCategories(tenant);
        lions = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        uma = RosterDb.playerAged(tenant, "Uma", 11, "FEMALE");
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void adminAssignsListsRenumbersAndUnassigns() {
        assign(lions, uma, "\"jerseyNumber\":\"7\",").statusCode(201)
                .body("player.id", equalTo(uma.toString()))
                .body("player.displayName", equalTo("Uma Test"))
                .body("teamId", equalTo(lions.toString()))
                .body("jerseyNumber", equalTo("7"))
                .body("joinedOn", equalTo(RosterDb.TODAY.toString()))
                .body("playUpLevels", equalTo(0))
                .body("playerStatus", equalTo("ACTIVE"));
        request().get(TEAMS + lions + "/players").then().statusCode(200).body("player.id", contains(uma.toString()));
        request().get(TEAMS + lions).then().body("playerCount", equalTo(1));

        patchJersey(lions, uma, "\"00\"").statusCode(200).body("jerseyNumber", equalTo("00"));
        patchJersey(lions, uma, "null").statusCode(200).body("jerseyNumber", nullValue());
        request().delete(TEAMS + lions + "/players/" + uma).then().statusCode(204);
        assertThat(RosterDb.playerStatus(tenant, uma)).isEqualTo("ORPHAN");
        request().get(TEAMS + lions + "/players").then().body("", empty());
        request().queryParam("includeLeft", true).get(TEAMS + lions + "/players").then()
                .body("leftOn", contains(RosterDb.TODAY.toString())).body("playerStatus", contains("ORPHAN"));
        request().delete(TEAMS + lions + "/players/" + uma).then().statusCode(404);
        patchJersey(lions, uma, "\"8\"").statusCode(404);

        assign(lions, uma, "\"joinedOn\":\"" + RosterDb.TODAY.plusDays(3) + "\",").statusCode(201)
                .body("joinedOn", equalTo(RosterDb.TODAY.plusDays(3).toString())).body("playerStatus", equalTo("ACTIVE"));
        assertThat(RosterDb.playerStatus(tenant, uma)).isEqualTo("ACTIVE");
    }

    @Test
    void duplicatesAndJerseysConflict() {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        assign(lions, uma, "\"jerseyNumber\":\"7\",").statusCode(201);
        assign(lions, uma, "").statusCode(409).body("code", equalTo("PLAYER_ALREADY_ON_TEAM"));
        assign(lions, ben, "\"jerseyNumber\":\"7\",").statusCode(409).body("code", equalTo("JERSEY_NUMBER_TAKEN"));
        assign(lions, ben, "\"jerseyNumber\":\"07\",").statusCode(201);
        patchJersey(lions, ben, "\"7\"").statusCode(409).body("code", equalTo("JERSEY_NUMBER_TAKEN"));
        patchJersey(lions, uma, "\"7\"").statusCode(200);
        assign(UUID.randomUUID(), uma, "").statusCode(404);
        assign(lions, UUID.randomUUID(), "").statusCode(404);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"playerId\":\"" + ben + "\",\"jerseyNumber\":\"100\"}").post(TEAMS + lions + "/players")
                .then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{}").patch(TEAMS + lions + "/players/" + uma).then().statusCode(400);
    }

    @Test
    void ineligiblePlayersAreRejectedWithTheReasons() {
        UUID teen = RosterDb.playerAged(tenant, "Tom", 13, "MALE");
        UUID girls = RosterDb.team(tenant, season, "Girls U14", categories.get("U14"), "FEMALE");
        assign(lions, teen, "").statusCode(422).body("code", equalTo("PLAYER_INELIGIBLE"))
                .body("violations.code", contains("CATEGORY_TOO_LOW"));
        assign(girls, teen, "").statusCode(422).body("violations.code", contains("GENDER_POLICY"));
        UUID withdrawn = RosterDb.playerAged(tenant, "Wil", 11, "MALE");
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.player set status = 'WITHDRAWN' where id = ?", withdrawn));
        assign(lions, withdrawn, "").statusCode(422).body("violations.code", contains("PLAYER_NOT_ACTIVE"));
        RosterDb.settings(tenant, "BIRTH_YEAR", 0);
        assign(girls, uma, "").statusCode(422).body("violations.code", contains("PLAY_UP_LIMIT_EXCEEDED"));
        RosterDb.settings(tenant, "BIRTH_YEAR", 1);
        assign(girls, uma, "").statusCode(201).body("playUpLevels", equalTo(1));
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where player_id = ?", teen)).isZero();
    }

    @Test
    void eligibilityCheckReportsVerdictAgeAndNaturalCategoryWithoutSideEffects() {
        UUID u16 = RosterDb.team(tenant, season, "U16", categories.get("U16"), "MIXED");
        check(lions, uma, null).statusCode(200)
                .body("playerId", equalTo(uma.toString())).body("teamId", equalTo(lions.toString()))
                .body("asOf", equalTo(RosterDb.TODAY.toString()))
                .body("result", equalTo("ELIGIBLE")).body("reasons", empty())
                .body("age", equalTo(11)).body("naturalCategory.code", equalTo("U12"));
        check(u16, uma, null).statusCode(200).body("result", equalTo("PLAY_UP")).body("playUpLevels", equalTo(2));
        UUID teen = RosterDb.playerAged(tenant, "Tom", 13, "MALE");
        check(lions, teen, "2030-01-01").statusCode(200).body("result", equalTo("INELIGIBLE"))
                .body("asOf", equalTo("2030-01-01")).body("reasons", contains("CATEGORY_TOO_LOW"));
        check(lions, UUID.randomUUID(), null).statusCode(404);
        check(UUID.randomUUID(), uma, null).statusCode(404);
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player")).isZero();
    }

    @Test
    void birthdayRuleUsesTheEvaluationDate() {
        RosterDb.settings(tenant, "BIRTHDAY", null);
        UUID kid = RosterDb.player(tenant, "Kim", "Test", LocalDate.of(2015, 3, 10), "MALE");
        check(lions, kid, "2025-03-09").statusCode(200).body("age", equalTo(9)).body("result", equalTo("PLAY_UP"));
        check(lions, kid, "2025-03-10").statusCode(200).body("age", equalTo(10)).body("result", equalTo("ELIGIBLE"));
        check(lions, kid, "2027-03-09").statusCode(200).body("age", equalTo(11)).body("result", equalTo("ELIGIBLE"));
        check(lions, kid, "2027-03-10").statusCode(200).body("age", equalTo(12)).body("result", equalTo("INELIGIBLE"));
    }

    @Test
    void eligibleTeamsListsOnlyEligibleTeamsInRankOrder() {
        UUID boysU12 = RosterDb.team(tenant, season, "Boys U12", categories.get("U12"), "MALE");
        RosterDb.team(tenant, season, "Minis", categories.get("U10"), "MIXED");
        UUID u14 = RosterDb.team(tenant, season, "U14", categories.get("U14"), "MIXED");
        UUID seniors = RosterDb.team(tenant, season, "Seniors", categories.get("SENIOR"), "MIXED");
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        UUID next = RosterDb.season(tenant, "Next", RosterDb.TODAY.plusDays(400), RosterDb.TODAY.plusDays(700), RosterDb.YEAR + 1);
        RosterDb.team(tenant, next, "Next U12", categories.get("U12"), "MIXED");
        RosterDb.team(tenant, next, "Next U14", categories.get("U14"), "MIXED");

        eligibleTeams(ben, season).statusCode(200)
                .body("team.id", contains(boysU12.toString(), lions.toString(), u14.toString(), seniors.toString()))
                .body("eligibility.result", contains("ELIGIBLE", "ELIGIBLE", "PLAY_UP", "PLAY_UP"))
                .body("eligibility.playUpLevels[2]", equalTo(1))
                .body("eligibility.playUpLevels[3]", equalTo(4));
        RosterDb.settings(tenant, "BIRTH_YEAR", 2);
        eligibleTeams(uma, season).statusCode(200).body("team.id", contains(lions.toString(), u14.toString()));
        eligibleTeams(ben, next).statusCode(200).body("team.name", contains("Next U14"))
                .body("eligibility.result", contains("ELIGIBLE")).body("eligibility.age", contains(12));
        eligibleTeams(UUID.randomUUID(), season).statusCode(404);
        eligibleTeams(ben, UUID.randomUUID()).statusCode(404);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).get("/api/core/players/" + ben + "/eligible-teams")
                .then().statusCode(400);
    }

    /** roles, staff of the team?, may assign/renumber/unassign, may check eligibility, may list eligible teams. */
    static Stream<Arguments> callers() {
        return Stream.of(
                Arguments.of(EnumSet.of(TenantRole.ADMIN), false, true, true, true),
                Arguments.of(EnumSet.of(TenantRole.COACH), true, true, true, true),
                Arguments.of(EnumSet.of(TenantRole.COACH), false, false, false, true),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH), true, false, true, false),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH), false, false, false, false),
                Arguments.of(EnumSet.of(TenantRole.PARENT), false, false, false, false),
                Arguments.of(EnumSet.of(TenantRole.PLAYER), false, false, false, false),
                Arguments.of(EnumSet.of(TenantRole.ADMIN, TenantRole.COACH), false, true, true, true),
                Arguments.of(EnumSet.of(TenantRole.COACH, TenantRole.PARENT), true, true, true, true));
    }

    @ParameterizedTest
    @MethodSource("callers")
    void roleMatrix(Set<TenantRole> roles, boolean staff, boolean mayAssign, boolean mayCheck, boolean mayListEligible) {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        RosterDb.assignment(tenant, lions, ben, "9");
        Members.signInAs(tenant, Members.callerPersonId(tenant), roles, staff ? Set.of(lions) : Set.of());
        request().get(TEAMS + lions + "/players").then().statusCode(200).body("", hasSize(1));
        check(lions, uma, null).statusCode(mayCheck ? 200 : 403);
        eligibleTeams(uma, season).statusCode(mayListEligible ? 200 : 403);
        assign(lions, uma, "").statusCode(mayAssign ? 201 : 403);
        patchJersey(lions, ben, "\"10\"").statusCode(mayAssign ? 200 : 403);
        request().delete(TEAMS + lions + "/players/" + ben).then().statusCode(mayAssign ? 204 : 403);
    }

    @Test
    void aCoachMayOnlyAssignToTheirOwnTeams() {
        UUID other = RosterDb.team(tenant, season, "Others", categories.get("U12"), "MIXED");
        UUID coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        Members.signInAs(tenant, coach, EnumSet.of(TenantRole.COACH), Set.of(lions));
        assign(other, uma, "").statusCode(403);
        assign(lions, uma, "").statusCode(201);
    }

    @Test
    void anotherTenantsAssignmentsAreNotFound() {
        RosterDb.assignment(tenant, lions, uma, "4");
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);
        UUID otherSeason = RosterDb.currentSeason(other);
        RequestSpecification asOther = given().filter(Contract.CORE).header("X-Tenant-Id", other);
        asOther.get(TEAMS + lions + "/players").then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON)
                .body("{\"playerId\":\"" + uma + "\"}").post(TEAMS + lions + "/players").then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON)
                .body("{\"jerseyNumber\":\"1\"}").patch(TEAMS + lions + "/players/" + uma).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).delete(TEAMS + lions + "/players/" + uma).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(TEAMS + lions + "/players/" + uma + "/eligibility")
                .then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).queryParam("seasonId", otherSeason.toString())
                .get("/api/core/players/" + uma + "/eligible-teams").then().statusCode(404);
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where left_on is null")).isEqualTo(1);
    }

    @Test
    void theRosterHidesClosedAssignmentsButCountsOnlyValidOnes() {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        RosterDb.assignment(tenant, lions, uma, "1");
        UUID invalid = RosterDb.assignment(tenant, lions, ben, "2");
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.team_player set invalidated_at = now(), "
                + "invalid_reason = 'CATEGORY_TOO_LOW' where id = ?", invalid));
        request().get(TEAMS + lions + "/players").then().body("player.id", containsInAnyOrder(uma.toString(), ben.toString()))
                .body("find { it.player.id == '" + ben + "' }.invalidReason", equalTo("CATEGORY_TOO_LOW"));
        request().get(TEAMS + lions).then().body("playerCount", equalTo(1));
    }

    private RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }

    private ValidatableResponse assign(UUID team, UUID player, String extra) {
        return request().contentType(ContentType.JSON).body("{" + extra + "\"playerId\":\"" + player + "\"}")
                .post(TEAMS + team + "/players").then();
    }

    /**
     * A {@code null} jersey is valid per contract ({@code allOf: [JerseyNumber], nullable: true}), but the validator
     * loses {@code nullable} when it flattens the {@code allOf}; such requests are therefore validated response-only.
     */
    private ValidatableResponse patchJersey(UUID team, UUID player, String jersey) {
        RequestSpecification spec = "null".equals(jersey)
                ? given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant) : request();
        return spec.contentType(ContentType.JSON).body("{\"jerseyNumber\":" + jersey + "}")
                .patch(TEAMS + team + "/players/" + player).then();
    }

    private ValidatableResponse check(UUID team, UUID player, String asOf) {
        RequestSpecification spec = request();
        if (asOf != null) {
            spec = spec.queryParam("asOf", asOf);
        }
        return spec.get(TEAMS + team + "/players/" + player + "/eligibility").then();
    }

    private ValidatableResponse eligibleTeams(UUID player, UUID seasonId) {
        return request().queryParam("seasonId", seasonId.toString()).get("/api/core/players/" + player + "/eligible-teams")
                .then();
    }
}
