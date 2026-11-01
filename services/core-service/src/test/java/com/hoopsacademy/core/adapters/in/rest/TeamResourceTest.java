package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
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
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class TeamResourceTest {

    private static final String TEAMS = "/api/core/teams";

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
    void adminCreatesGetsListsAndUpdatesTeams() {
        var created = create("Lions", "U12", "MIXED", "\"alias\":\"L\",").statusCode(201)
                .body("seasonId", equalTo(season.toString()))
                .body("name", equalTo("Lions"))
                .body("alias", equalTo("L"))
                .body("ageCategory.code", equalTo("U12"))
                .body("genderPolicy", equalTo("MIXED"))
                .body("playerCount", equalTo(0))
                .extract();
        String lions = created.path("id");
        assertThat(created.header("Location")).endsWith(TEAMS + "/" + lions);
        String cubs = create("Cubs", "U8", "FEMALE", "").statusCode(201).body("alias", nullValue()).extract().path("id");

        request().get(TEAMS + "/" + lions).then().statusCode(200).body("name", equalTo("Lions"));
        request().get(TEAMS).then().statusCode(200).body("items.name", contains("Cubs", "Lions"))
                .body("page.totalElements", equalTo(2));
        request().queryParam("ageCategoryId", categories.get("U12").toString()).get(TEAMS).then()
                .body("items.id", contains(lions));
        request().queryParam("seasonId", UUID.randomUUID().toString()).get(TEAMS).then().body("items", hasSize(0));
        request().queryParam("size", 1).queryParam("page", 1).get(TEAMS).then().body("items.id", contains(lions))
                .body("page.totalPages", equalTo(2));

        patch(lions, "{\"name\":\"Big Lions\",\"alias\":null,\"ageCategoryId\":\"" + categories.get("U14") + "\"}")
                .statusCode(200).body("name", equalTo("Big Lions")).body("alias", nullValue())
                .body("ageCategory.code", equalTo("U14"));
        patch(cubs, "{\"name\":\"Big Lions\"}").statusCode(409).body("code", equalTo("TEAM_NAME_TAKEN"));
        request().get(TEAMS + "/" + UUID.randomUUID()).then().statusCode(404);
        patch(UUID.randomUUID().toString(), "{\"name\":\"x\"}").statusCode(404);
    }

    @Test
    void teamNamesAreUniquePerSeasonAndReferencesMustExist() {
        create("Lions", "U12", "MIXED", "").statusCode(201);
        create("Lions", "U14", "MALE", "").statusCode(409).body("code", equalTo("TEAM_NAME_TAKEN"));
        UUID next = RosterDb.season(tenant, "Next", RosterDb.TODAY.plusDays(400), RosterDb.TODAY.plusDays(700), RosterDb.YEAR + 1);
        request().contentType(ContentType.JSON).body(body(next, "Lions", categories.get("U12"), "MIXED", "")).post(TEAMS)
                .then().statusCode(201);
        request().contentType(ContentType.JSON).body(body(UUID.randomUUID(), "X", categories.get("U12"), "MIXED", ""))
                .post(TEAMS).then().statusCode(404);
        request().contentType(ContentType.JSON).body(body(season, "X", UUID.randomUUID(), "MIXED", "")).post(TEAMS)
                .then().statusCode(404);
        String lions = request().get(TEAMS).then().extract().path("items[0].id");
        patch(lions, "{\"ageCategoryId\":\"" + UUID.randomUUID() + "\"}").statusCode(404);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body(body(season, "X", categories.get("U12"), "OTHER", "")).post(TEAMS).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"genderPolicy\":\"OTHER\"}").patch(TEAMS + "/" + lions).then().statusCode(400);
    }

    @Test
    void staffIsAttachedIdempotentlyListedAndDetached() {
        String lions = create("Lions", "U12", "MIXED", "").extract().path("id");
        UUID coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        UUID assistant = CoreDb.person(tenant, "Abe", "Assist", null, TenantRole.ASSISTANT_COACH, TenantRole.COACH);
        UUID parent = CoreDb.person(tenant, "Pam", "Parent", null, TenantRole.PARENT);

        putStaff(lions, coach, "COACH").statusCode(200).body("person.personId", equalTo(coach.toString()))
                .body("person.displayName", equalTo("Cora Coach")).body("role", equalTo("COACH"))
                .body("since", equalTo(RosterDb.TODAY.toString()));
        putStaff(lions, coach, "COACH").statusCode(200);
        putStaff(lions, assistant, "ASSISTANT_COACH").statusCode(200);
        putStaff(lions, assistant, "COACH").statusCode(200).body("role", equalTo("COACH"));
        putStaff(lions, parent, "COACH").statusCode(422).body("code", equalTo("STAFF_ROLE_MISSING"));
        putStaff(lions, coach, "ASSISTANT_COACH").statusCode(422);
        putStaff(lions, UUID.randomUUID(), "COACH").statusCode(404);
        putStaff(UUID.randomUUID().toString(), coach, "COACH").statusCode(404);

        request().get(TEAMS + "/" + lions + "/staff").then().statusCode(200)
                .body("person.personId", containsInAnyOrder(coach.toString(), assistant.toString()));
        request().delete(TEAMS + "/" + lions + "/staff/" + assistant).then().statusCode(204);
        request().delete(TEAMS + "/" + lions + "/staff/" + assistant).then().statusCode(404);
        request().get(TEAMS + "/" + lions + "/staff").then().body("person.personId", contains(coach.toString()));
        request().get(TEAMS + "/" + UUID.randomUUID() + "/staff").then().statusCode(404);
    }

    @Test
    void staffedByMeListsOnlyTheCallersTeams() {
        UUID coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        UUID lions = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        RosterDb.team(tenant, season, "Cubs", categories.get("U8"), "MIXED");
        RosterDb.staff(tenant, lions, coach, "COACH");
        Members.signInAs(tenant, coach, EnumSet.of(TenantRole.COACH), Set.of(lions));
        request().queryParam("staffedByMe", true).get(TEAMS).then().statusCode(200).body("items.id", contains(lions.toString()));
        request().get(TEAMS).then().body("items", hasSize(2));
        Members.signIn(tenant, TenantRole.PARENT);
        request().queryParam("staffedByMe", true).get(TEAMS).then().statusCode(200).body("items", hasSize(0));
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void everyMemberReadsOnlyAdminsManageTeamsAndStaff(Set<TenantRole> roles, boolean admin) {
        UUID team = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        UUID coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        RosterDb.staff(tenant, team, coach, "COACH");
        Members.signIn(tenant, roles);
        request().get(TEAMS).then().statusCode(200);
        request().get(TEAMS + "/" + team).then().statusCode(200);
        request().get(TEAMS + "/" + team + "/staff").then().statusCode(200);
        create("New", "U10", "MALE", "").statusCode(admin ? 201 : 403);
        patch(team.toString(), "{\"name\":\"Renamed\"}").statusCode(admin ? 200 : 403);
        putStaff(team.toString(), coach, "COACH").statusCode(admin ? 200 : 403);
        request().delete(TEAMS + "/" + team + "/staff/" + coach).then().statusCode(admin ? 204 : 403);
    }

    @Test
    void staffOfATeamStillCannotManageIt() {
        UUID team = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        UUID coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        RosterDb.staff(tenant, team, coach, "COACH");
        Members.signInAs(tenant, coach, EnumSet.of(TenantRole.COACH), Set.of(team));
        patch(team.toString(), "{\"name\":\"Mine\"}").statusCode(403);
        putStaff(team.toString(), coach, "COACH").statusCode(403);
    }

    @Test
    void anotherTenantsTeamsAreNotFound() {
        UUID foreign = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        UUID coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        String other = Members.newTenant();
        Members.signIn(other, TenantRole.ADMIN);
        RequestSpecification asOther = given().filter(Contract.CORE).header("X-Tenant-Id", other);
        asOther.get(TEAMS + "/" + foreign).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON).body("{\"name\":\"x\"}")
                .patch(TEAMS + "/" + foreign).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(TEAMS + "/" + foreign + "/staff").then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON).body("{\"role\":\"COACH\"}")
                .put(TEAMS + "/" + foreign + "/staff/" + coach).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).contentType(ContentType.JSON)
                .body(body(season, "Steal", categories.get("U12"), "MIXED", "")).post(TEAMS).then().statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(TEAMS).then().statusCode(200).body("items", hasSize(0));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(TEAMS).then().statusCode(404);
    }

    private RequestSpecification request() {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
    }

    private ValidatableResponse create(String name, String category, String policy, String extra) {
        return request().contentType(ContentType.JSON).body(body(season, name, categories.get(category), policy, extra))
                .post(TEAMS).then();
    }

    private ValidatableResponse patch(String id, String json) {
        return request().contentType(ContentType.JSON).body(json).patch(TEAMS + "/" + id).then();
    }

    private ValidatableResponse putStaff(String team, UUID person, String role) {
        return request().contentType(ContentType.JSON).body("{\"role\":\"" + role + "\"}")
                .put(TEAMS + "/" + team + "/staff/" + person).then();
    }

    private static String body(UUID season, String name, UUID category, String policy, String extra) {
        return "{" + extra + "\"seasonId\":\"" + season + "\",\"name\":\"" + name + "\",\"ageCategoryId\":\"" + category
                + "\",\"genderPolicy\":\"" + policy + "\"}";
    }
}
