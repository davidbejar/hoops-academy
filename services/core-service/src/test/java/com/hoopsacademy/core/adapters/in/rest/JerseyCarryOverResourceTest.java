package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
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
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * WP96 (decision 70, ADR-0048): an assignment without a number takes the preferred number or the previous one when
 * free, says which rule applied, and the team's taken numbers are listed for the jersey dialog.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class JerseyCarryOverResourceTest {

    private static final String TEAMS = "/api/core/teams/";

    private String tenant;
    private UUID season;
    private Map<String, UUID> categories;
    private UUID lions;
    private UUID tigers;
    private UUID uma;
    private UUID ben;

    @BeforeEach
    void twoU12TeamsAndTwoPlayers() {
        tenant = Members.newTenant();
        season = RosterDb.currentSeason(tenant);
        categories = RosterDb.defaultCategories(tenant);
        lions = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        tigers = RosterDb.team(tenant, season, "Tigers", categories.get("U12"), "MIXED");
        uma = RosterDb.playerAged(tenant, "Uma", 11, "FEMALE");
        ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void aRequestedNumberIsUsedAsRequested() {
        prefer(uma, "7");

        assign(lions, uma, "\"jerseyNumber\":\"9\",").statusCode(201).body("jerseyNumber", equalTo("9"))
                .body("jerseySource", equalTo("REQUESTED"));
    }

    @Test
    void withoutANumberTheFreePreferredNumberIsTaken() {
        prefer(uma, "7");
        RosterDb.assignment(tenant, lions, ben, "07");

        assign(lions, uma, "").statusCode(201).body("jerseyNumber", equalTo("7"))
                .body("jerseySource", equalTo("PREFERRED"));
        assertThat(RosterDb.text(tenant, "select jersey_number from core.team_player where team_id = ? "
                + "and player_id = ?", lions, uma)).isEqualTo("7");
    }

    @Test
    void aTakenPreferredNumberFallsBackToTheMostRecentNumberedAssignment() {
        prefer(uma, "7");
        RosterDb.assignment(tenant, lions, ben, "7");
        RosterDb.assignment(tenant, tigers, uma, "12");

        assign(lions, uma, "").statusCode(201).body("jerseyNumber", equalTo("12"))
                .body("jerseySource", equalTo("PREVIOUS"));
    }

    @Test
    void aClosedAssignmentStillGivesThePreviousNumber() {
        RosterDb.assignment(tenant, tigers, uma, "4");
        request().delete(TEAMS + tigers + "/players/" + uma).then().statusCode(204);

        assign(lions, uma, "").statusCode(201).body("jerseyNumber", equalTo("4"))
                .body("jerseySource", equalTo("PREVIOUS"));
    }

    @Test
    void whenNeitherNumberIsFreeTheAssignmentGetsNone() {
        prefer(uma, "7");
        RosterDb.assignment(tenant, tigers, uma, "12");
        RosterDb.assignment(tenant, lions, ben, "7");
        UUID cat = RosterDb.playerAged(tenant, "Cat", 11, "FEMALE");
        RosterDb.assignment(tenant, lions, cat, "12");

        assign(lions, uma, "").statusCode(201).body("jerseyNumber", nullValue())
                .body("jerseySource", equalTo("NONE"));
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where team_id = ? and left_on is null "
                + "and jersey_number in ('7', '12')", lions)).as("nobody lost a number").isEqualTo(2);
    }

    @Test
    void aPlayerWithoutPreferenceOrHistoryGetsNone() {
        assign(lions, uma, "").statusCode(201).body("jerseyNumber", nullValue()).body("jerseySource", equalTo("NONE"));
    }

    @Test
    void anExplicitClashIsStillAConflict() {
        prefer(uma, "7");
        RosterDb.assignment(tenant, lions, ben, "7");

        assign(lions, uma, "\"jerseyNumber\":\"7\",").statusCode(409).body("code", equalTo("JERSEY_NUMBER_TAKEN"));
    }

    @Test
    void theTakenNumbersAreListedByValueWithTheirPlayers() {
        UUID cat = RosterDb.playerAged(tenant, "Cat", 11, "FEMALE");
        UUID dan = RosterDb.playerAged(tenant, "Dan", 11, "MALE");
        RosterDb.assignment(tenant, lions, uma, "07");
        RosterDb.assignment(tenant, lions, ben, "7");
        RosterDb.assignment(tenant, lions, cat, null);
        UUID closed = RosterDb.assignment(tenant, lions, dan, "0");
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.team_player set left_on = joined_on where id = ?",
                closed));
        RosterDb.assignment(tenant, tigers, dan, "1");

        request().get(TEAMS + lions + "/jersey-numbers").then().statusCode(200)
                .body("jerseyNumber", contains("7", "07"))
                .body("player.id", contains(ben.toString(), uma.toString()))
                .body("player.displayName", contains("Ben Test", "Uma Test"));
        UUID empty = RosterDb.team(tenant, season, "Empty", categories.get("U12"), "MIXED");
        request().get(TEAMS + empty + "/jersey-numbers").then().statusCode(200).body("", empty());
        request().get(TEAMS + UUID.randomUUID() + "/jersey-numbers").then().statusCode(404);
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void everyMemberReadsTheTakenNumbers(Set<TenantRole> roles, boolean admin) {
        RosterDb.assignment(tenant, lions, uma, "5");
        Members.signIn(tenant, roles);

        request().get(TEAMS + lions + "/jersey-numbers").then().statusCode(200).body("jerseyNumber", contains("5"));
    }

    @Test
    void anotherTenantsTeamIsNotFound() {
        RosterDb.assignment(tenant, lions, uma, "5");
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);

        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(TEAMS + lions + "/jersey-numbers").then()
                .statusCode(404);
    }

    private void prefer(UUID player, String number) {
        request().contentType(ContentType.JSON).body("{\"preferredJerseyNumber\":\"" + number + "\"}")
                .patch("/api/core/players/" + player).then().statusCode(200);
    }

    private RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }

    private ValidatableResponse assign(UUID team, UUID player, String extra) {
        return request().contentType(ContentType.JSON).body("{" + extra + "\"playerId\":\"" + player + "\"}")
                .post(TEAMS + team + "/players").then();
    }
}
