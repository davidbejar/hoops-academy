package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.RosterEvents;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** WP67: the team, team-player and team-staff use cases append their aggregate's state to the outbox. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class TeamEventsTest {

    private static final String TEAMS = "/api/core/teams/";

    private String tenant;
    private UUID season;
    private Map<String, UUID> categories;

    @BeforeEach
    void tenantWithSeasonAndLadder() {
        tenant = Members.newTenant();
        season = RosterDb.currentSeason(tenant);
        categories = RosterDb.defaultCategories(tenant);
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void creatingAndEditingATeamPublishesItsWholeStateWithTheSeasonDates() {
        UUID lions = UUID.fromString(request().contentType(ContentType.JSON).body("{\"alias\":\"L\",\"seasonId\":\""
                + season + "\",\"name\":\"Lions\",\"ageCategoryId\":\"" + categories.get("U12")
                + "\",\"genderPolicy\":\"MIXED\"}").post(TEAMS).then().statusCode(201).extract().path("id"));

        JsonNode created = RosterEvents.last(tenant, "core.team", lions);
        assertThat(created.get("type").asText()).isEqualTo("team.changed");
        assertThat(created.get("tenantId").asText()).isEqualTo(tenant);
        assertThat(created.get("payload").get("name").asText()).isEqualTo("Lions");
        assertThat(created.get("payload").get("alias").asText()).isEqualTo("L");
        assertThat(created.get("payload").get("seasonId").asText()).isEqualTo(season.toString());
        assertThat(created.get("payload").get("seasonStartDate").asText())
                .isEqualTo(RosterDb.text(tenant, "select start_date::text from core.season where id = ?", season));

        request().contentType(ContentType.JSON).body("{\"name\":\"Big Lions\",\"clear\":[\"alias\"]}")
                .patch(TEAMS + lions).then().statusCode(200);
        request().contentType(ContentType.JSON).body("{\"name\":\"Big Lions\"}").patch(TEAMS + lions).then()
                .statusCode(200);

        assertThat(RosterEvents.of(tenant, "core.team", lions)).as("an edit that changes nothing publishes nothing")
                .hasSize(2);
        JsonNode edited = RosterEvents.state(tenant, "core.team", lions);
        assertThat(edited.get("name").asText()).isEqualTo("Big Lions");
        assertThat(edited.get("alias").isNull()).isTrue();
    }

    @Test
    void changingTheSeasonDatesRepublishesEveryTeamOfTheSeason() {
        UUID lions = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        UUID cubs = RosterDb.team(tenant, season, "Cubs", categories.get("U8"), "MIXED");
        LocalDate end = LocalDate.parse(RosterDb.text(tenant, "select end_date::text from core.season where id = ?", season));

        request().contentType(ContentType.JSON).body("{\"endsOn\":\"" + end.plusDays(10) + "\"}")
                .patch("/api/core/seasons/" + season).then().statusCode(200);

        for (UUID team : List.of(lions, cubs)) {
            assertThat(RosterEvents.state(tenant, "core.team", team).get("seasonEndDate").asText())
                    .isEqualTo(end.plusDays(10).toString());
        }
    }

    @Test
    void assigningRenumberingAndRemovingAPlayerPublishTheAssignment() {
        UUID lions = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        UUID uma = RosterDb.playerAged(tenant, "Uma", 11, "FEMALE");

        request().contentType(ContentType.JSON).body("{\"jerseyNumber\":\"7\",\"playerId\":\"" + uma + "\"}")
                .post(TEAMS + lions + "/players").then().statusCode(201);
        UUID assignment = UUID.fromString(RosterDb.text(tenant,
                "select id::text from core.team_player where team_id = ? and player_id = ?", lions, uma));
        JsonNode assigned = RosterEvents.state(tenant, "core.team-player", assignment);
        assertThat(assigned.get("teamId").asText()).isEqualTo(lions.toString());
        assertThat(assigned.get("playerId").asText()).isEqualTo(uma.toString());
        assertThat(assigned.get("jerseyNumber").asText()).isEqualTo("7");
        assertThat(assigned.get("leftOn").isNull()).isTrue();
        assertThat(assigned.get("invalidReason").isNull()).isTrue();

        request().contentType(ContentType.JSON).body("{\"jerseyNumber\":\"9\"}").patch(TEAMS + lions + "/players/" + uma)
                .then().statusCode(200);
        assertThat(RosterEvents.state(tenant, "core.team-player", assignment).get("jerseyNumber").asText()).isEqualTo("9");

        request().delete(TEAMS + lions + "/players/" + uma).then().statusCode(204);
        assertThat(RosterEvents.state(tenant, "core.team-player", assignment).get("leftOn").asText())
                .isEqualTo(RosterDb.TODAY.toString());
        assertThat(RosterEvents.of(tenant, "core.team-player", assignment)).hasSize(3);
    }

    @Test
    void attachingChangingAndDetachingStaffPublishesTheEntryThenItsRemoval() {
        UUID lions = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        UUID coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH, TenantRole.ASSISTANT_COACH);
        UUID entry = RosterEvents.teamStaffId(lions, coach);

        putStaff(lions, coach, "COACH");
        JsonNode attached = RosterEvents.last(tenant, "core.team-staff", entry);
        assertThat(attached.get("type").asText()).isEqualTo("team-staff.changed");
        assertThat(attached.get("payload").get("role").asText()).isEqualTo("COACH");
        assertThat(attached.get("payload").get("since").asText()).isEqualTo(RosterDb.TODAY.toString());
        putStaff(lions, coach, "ASSISTANT_COACH");
        assertThat(RosterEvents.state(tenant, "core.team-staff", entry).get("role").asText()).isEqualTo("ASSISTANT_COACH");

        request().delete(TEAMS + lions + "/staff/" + coach).then().statusCode(204);

        JsonNode removed = RosterEvents.last(tenant, "core.team-staff", entry);
        assertThat(removed.get("type").asText()).isEqualTo("team-staff.removed");
        assertThat(removed.get("payload").get("teamId").asText()).isEqualTo(lions.toString());
        assertThat(removed.get("payload").get("personId").asText()).isEqualTo(coach.toString());
    }

    @Test
    void aRejectedCommandAppendsNothing() {
        UUID lions = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        UUID parent = CoreDb.person(tenant, "Pam", "Parent", null, TenantRole.PARENT);

        request().contentType(ContentType.JSON).body("{\"role\":\"COACH\"}").put(TEAMS + lions + "/staff/" + parent)
                .then().statusCode(422);
        request().contentType(ContentType.JSON).body("{\"name\":\"Lions\",\"seasonId\":\"" + season
                + "\",\"ageCategoryId\":\"" + UUID.randomUUID() + "\",\"genderPolicy\":\"MIXED\"}").post(TEAMS).then()
                .statusCode(404);

        assertThat(RosterEvents.count(tenant)).isZero();
    }

    private void putStaff(UUID team, UUID person, String role) {
        request().contentType(ContentType.JSON).body("{\"role\":\"" + role + "\"}").put(TEAMS + team + "/staff/" + person)
                .then().statusCode(200);
    }

    private RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }
}
