package com.hoopsacademy.core.adapters.in.internal;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
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
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "game-service", roles = "service")
class InternalRosterResourceTest {

    private String tenant;
    private UUID season;
    private UUID lions;
    private UUID coach;
    private String coachSub;
    private UUID ann;
    private UUID bob;
    private UUID gone;
    private Map<String, UUID> categories;

    @BeforeEach
    void teamWithPlayersAndStaff() {
        tenant = Members.newTenant();
        categories = RosterDb.defaultCategories(tenant);
        season = RosterDb.currentSeason(tenant);
        lions = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        coachSub = "coach-" + UUID.randomUUID();
        coach = CoreDb.person(tenant, CoreDb.login(coachSub), "Cora", "Coach", null, null, null, TenantRole.COACH);
        RosterDb.staff(tenant, lions, coach, "COACH");
        ann = RosterDb.player(tenant, "Ann", "A", LocalDate.of(RosterDb.YEAR - 11, 2, 3), "FEMALE");
        bob = RosterDb.player(tenant, "Bob", "B", LocalDate.of(RosterDb.YEAR - 11, 4, 5), "MALE");
        gone = RosterDb.player(tenant, "Gil", "G", LocalDate.of(RosterDb.YEAR - 11, 4, 5), "MALE");
        RosterDb.assignment(tenant, lions, ann, "7");
        RosterDb.assignment(tenant, lions, bob, null);
        UUID invalid = RosterDb.assignment(tenant, lions, gone, "9");
        RosterDb.openCase(tenant, invalid, "CATEGORY_TOO_LOW");
    }

    @Test
    void rosterListsOpenValidAssignmentsAndStaff() {
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", tenant).get("/internal/teams/{t}/roster", lions)
                .then().statusCode(200)
                .body("tenantId", equalTo(tenant))
                .body("teamId", equalTo(lions.toString()))
                .body("seasonId", equalTo(season.toString()))
                .body("seasonEndDate", equalTo(RosterDb.TODAY.plusDays(240).toString()))
                .body("teamName", equalTo("Lions"))
                .body("players.playerId", containsInAnyOrder(ann.toString(), bob.toString()))
                .body("players.find { it.playerId == '" + ann + "' }.displayName", equalTo("Ann A"))
                .body("players.find { it.playerId == '" + ann + "' }.jerseyNumber", equalTo("7"))
                .body("players.find { it.playerId == '" + ann + "' }.birthDate",
                        equalTo(LocalDate.of(RosterDb.YEAR - 11, 2, 3).toString()))
                .body("players.find { it.playerId == '" + ann + "' }.gender", equalTo("FEMALE"))
                .body("players.find { it.playerId == '" + ann + "' }.status", equalTo("ACTIVE"))
                .body("staff.personId", contains(coach.toString()))
                .body("staff.role", contains("COACH"));
    }

    @Test
    void playersBatchAnswersKnownIdsOnly() {
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", tenant).contentType(ContentType.JSON)
                .body("{\"playerIds\":[\"" + ann + "\",\"" + UUID.randomUUID() + "\",\"" + gone + "\"]}")
                .post("/internal/players:batch").then().statusCode(200)
                .body("players.id", containsInAnyOrder(ann.toString(), gone.toString()))
                .body("players.find { it.id == '" + ann + "' }.displayName", equalTo("Ann A"))
                .body("players.find { it.id == '" + ann + "' }.gender", equalTo("FEMALE"))
                .body("players.find { it.id == '" + ann + "' }.status", equalTo("ACTIVE"));
        given().urlEncodingEnabled(false).filter(Contract.RESPONSES_ONLY).queryParam("tenantId", tenant).contentType(ContentType.JSON)
                .body("{\"playerIds\":[]}").post("/internal/players:batch").then().statusCode(400);
    }

    @Test
    void unknownSuspendedOrForeignTenantsAndTeamsAreNotFound() {
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", UUID.randomUUID().toString())
                .get("/internal/teams/{t}/roster", lions).then().statusCode(404);
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", tenant).get("/internal/teams/{t}/roster", UUID.randomUUID())
                .then().statusCode(404);
        String other = Members.newTenant();
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", other).get("/internal/teams/{t}/roster", lions)
                .then().statusCode(404);
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", other).contentType(ContentType.JSON)
                .body("{\"playerIds\":[\"" + ann + "\"]}").post("/internal/players:batch").then().statusCode(200)
                .body("players", empty());
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", UUID.randomUUID().toString()).contentType(ContentType.JSON)
                .body("{\"playerIds\":[\"" + ann + "\"]}").post("/internal/players:batch").then().statusCode(404);
        CoreDb.inTenant(null, c -> CoreDb.update(c, "update core.tenant set status = 'SUSPENDED' where id = ?::uuid", tenant));
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", tenant).get("/internal/teams/{t}/roster", lions)
                .then().statusCode(404);
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", tenant).contentType(ContentType.JSON)
                .body("{\"playerIds\":[\"" + ann + "\"]}").post("/internal/players:batch").then().statusCode(404);
        given().filter(Contract.RESPONSES_ONLY).get("/internal/teams/{t}/roster", lions).then().statusCode(400);
    }

    @Test
    void authzContextReportsStaffTeamsAndUsageCountsSeasonsAndTeams() {
        given().filter(Contract.CORE).get("/internal/authz/{t}/{s}", tenant, coachSub).then().statusCode(200)
                .body("staffTeamIds", contains(lions.toString()));
        given().filter(Contract.CORE).get("/internal/usage/{t}", tenant).then().statusCode(200)
                .body("counters.seasons", equalTo(1))
                .body("counters.teams", equalTo(1));
    }

    @Test
    @TestSecurity(user = "someone", roles = "user")
    void endUsersAreForbidden() {
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", tenant).get("/internal/teams/{t}/roster", lions)
                .then().statusCode(403);
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", tenant).contentType(ContentType.JSON)
                .body("{\"playerIds\":[\"" + ann + "\"]}").post("/internal/players:batch").then().statusCode(403);
    }

    @Test
    void anEmptyTeamHasAnEmptyRoster() {
        UUID empty = RosterDb.team(tenant, season, "Empty", categories.get("U8"), "MIXED");
        given().urlEncodingEnabled(false).filter(Contract.CORE).queryParam("tenantId", tenant).get("/internal/teams/{t}/roster", empty)
                .then().statusCode(200).body("players", hasSize(0)).body("staff", hasSize(0));
    }
}
