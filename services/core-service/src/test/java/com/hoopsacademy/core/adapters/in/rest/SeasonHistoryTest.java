package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.equalTo;

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
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Season history in core (WP80, ADR-0042): a team whose season has ended is listed for its former staff on request,
 * marked {@code seasonEnded}, and every write on it answers 409 {@code SEASON_ENDED}.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class SeasonHistoryTest {

    private static final String TEAMS = "/api/core/teams/";

    private String tenant;
    private UUID pastSeason;
    private UUID pastLions;
    private UUID lions;
    private UUID coach;
    private UUID ann;
    private Map<String, UUID> categories;

    @BeforeEach
    void aCoachWhoseLastSeasonEndedYesterday() {
        tenant = Members.newTenant();
        categories = RosterDb.defaultCategories(tenant);
        pastSeason = RosterDb.season(tenant, "Past", RosterDb.TODAY.minusDays(300), RosterDb.TODAY.minusDays(1),
                RosterDb.YEAR - 1);
        UUID current = RosterDb.season(tenant, "Next", RosterDb.TODAY.plusDays(1), RosterDb.TODAY.plusDays(300),
                RosterDb.YEAR);
        pastLions = RosterDb.team(tenant, pastSeason, "Lions", categories.get("SENIOR"), "MIXED");
        lions = RosterDb.team(tenant, current, "Lions", categories.get("SENIOR"), "MIXED");
        coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        RosterDb.staff(tenant, pastLions, coach, "COACH");
        RosterDb.staff(tenant, lions, coach, "COACH");
        ann = RosterDb.playerAged(tenant, "Ann", 20, "FEMALE");
        RosterDb.assignment(tenant, pastLions, ann, "7");
    }

    @Test
    void theFormerStaffFindTheirPastTeamsOnlyWhenTheyAskForThem() {
        formerCoach();

        request().queryParam("staffedByMe", true).get(TEAMS).then().statusCode(200)
                .body("items.id", contains(lions.toString()));
        request().queryParam("staffedByMe", true).queryParam("includeEnded", true).get(TEAMS).then().statusCode(200)
                .body("items.id", containsInAnyOrder(lions.toString(), pastLions.toString()))
                .body("items.find { it.id == '" + pastLions + "' }.seasonEnded", equalTo(true))
                .body("items.find { it.id == '" + lions + "' }.seasonEnded", equalTo(false));
        request().queryParam("includeEnded", true).get(TEAMS).then().statusCode(200)
                .body("items.id", containsInAnyOrder(lions.toString(), pastLions.toString()));
    }

    @Test
    void everyMemberSeesThatATeamIsHistory() {
        Members.signIn(tenant, TenantRole.PARENT);

        request().get(TEAMS + pastLions).then().statusCode(200).body("seasonEnded", equalTo(true));
        request().get(TEAMS + lions).then().statusCode(200).body("seasonEnded", equalTo(false));
        request().get(TEAMS + pastLions + "/players").then().statusCode(200).body("player.id", contains(ann.toString()));
    }

    @Test
    void anAdminCannotChangeAPastTeamItsStaffOrItsRoster() {
        Members.signIn(tenant, TenantRole.ADMIN);
        UUID bea = RosterDb.playerAged(tenant, "Bea", 20, "FEMALE");

        seasonEnded(request().contentType(ContentType.JSON).body("{\"name\":\"Old Lions\"}").patch(TEAMS + pastLions).then());
        seasonEnded(request().contentType(ContentType.JSON).body("{\"role\":\"COACH\"}")
                .put(TEAMS + pastLions + "/staff/" + coach).then());
        seasonEnded(request().delete(TEAMS + pastLions + "/staff/" + coach).then());
        seasonEnded(assign(pastLions, bea));
        seasonEnded(request().contentType(ContentType.JSON).body("{\"jerseyNumber\":\"8\"}")
                .patch(TEAMS + pastLions + "/players/" + ann).then());
        seasonEnded(request().delete(TEAMS + pastLions + "/players/" + ann).then());

        request().get(TEAMS + pastLions).then().body("name", equalTo("Lions"));
        request().get(TEAMS + pastLions + "/staff").then().body("person.personId", contains(coach.toString()));
        request().get(TEAMS + pastLions + "/players").then().body("player.id", contains(ann.toString()))
                .body("jerseyNumber", contains("7"));
    }

    @Test
    void theFormerCoachGetsTheConflictAndACoachNeverOnTheTeamIsForbidden() {
        UUID bea = RosterDb.playerAged(tenant, "Bea", 20, "FEMALE");
        formerCoach();
        seasonEnded(assign(pastLions, bea));
        seasonEnded(request().delete(TEAMS + pastLions + "/players/" + ann).then());

        UUID stranger = CoreDb.person(tenant, "Sam", "Stranger", null, TenantRole.COACH);
        Members.signInAs(tenant, stranger, EnumSet.of(TenantRole.COACH), Set.of(lions), Set.of());
        assign(pastLions, bea).statusCode(403);
        request().delete(TEAMS + pastLions + "/players/" + ann).then().statusCode(403);
    }

    @Test
    void todaysTeamStaysWritableAndReopeningTheSeasonMakesThePastTeamWritableAgain() {
        Members.signIn(tenant, TenantRole.ADMIN);
        request().contentType(ContentType.JSON).body("{\"name\":\"Lionesses\"}").patch(TEAMS + lions).then()
                .statusCode(200);

        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.season set end_date = ? where id = ?",
                RosterDb.TODAY, pastSeason));
        request().contentType(ContentType.JSON).body("{\"name\":\"Old Lions\"}").patch(TEAMS + pastLions).then()
                .statusCode(200).body("seasonEnded", equalTo(false));
    }

    private void formerCoach() {
        Members.signInAs(tenant, coach, EnumSet.of(TenantRole.COACH), Set.of(lions), Set.of(pastLions));
    }

    private static void seasonEnded(ValidatableResponse response) {
        response.statusCode(409).contentType("application/problem+json").body("code", equalTo("SEASON_ENDED"));
    }

    private ValidatableResponse assign(UUID team, UUID player) {
        return request().contentType(ContentType.JSON).body("{\"playerId\":\"" + player + "\"}")
                .post(TEAMS + team + "/players").then();
    }

    private RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }
}
