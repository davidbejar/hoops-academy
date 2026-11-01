package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class PlanAssignmentApiTest {

    static final String TENANT = "62000000-0000-4000-8000-000000000001";
    static final String OTHER_TENANT = "62000000-0000-4000-8000-000000000002";
    static final String TEAM = "62000000-0000-4000-8000-0000000000a1";
    static final String TEAM2 = "62000000-0000-4000-8000-0000000000a2";
    static final String P1 = "62000000-0000-4000-8000-0000000000b1";
    static final String P2 = "62000000-0000-4000-8000-0000000000b2";
    static final String P3 = "62000000-0000-4000-8000-0000000000b3";
    static final String PLANS = "/api/athlete/training-plans";
    static final String ASSIGNMENTS = "/api/athlete/plan-assignments";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, P1, P2).roster(TENANT, TEAM2, P3).knownPlayers(TENANT, P1, P2, P3);
    }

    String plan(String name) {
        return api(TENANT).body(Map.of("name", name, "items", java.util.List.of(Map.of("title", "Drill", "durationMinutes", 10))))
                .post(PLANS).then().statusCode(201).extract().path("id");
    }

    String assignToTeam(String plan, String team, String due) {
        return api(TENANT).body(Map.of("planId", plan, "teamId", team, "dueOn", due)).post(ASSIGNMENTS)
                .then().statusCode(201).extract().path("id");
    }

    String assignToPlayer(String plan, String player, String due) {
        return api(TENANT).body(Map.of("planId", plan, "playerId", player, "dueOn", due)).post(ASSIGNMENTS)
                .then().statusCode(201).extract().path("id");
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffAssignsAPlanToTheirTeam() {
        String plan = plan("Week 1");

        String id = api(TENANT).body(Map.of("planId", plan, "teamId", TEAM, "dueOn", "2027-10-01", "notes", "bring water"))
                .post(ASSIGNMENTS).then().statusCode(201)
                .body("plan.id", equalTo(plan)).body("plan.name", equalTo("Week 1")).body("plan.itemCount", equalTo(1))
                .body("teamId", equalTo(TEAM)).body("playerId", nullValue()).body("dueOn", equalTo("2027-10-01"))
                .body("notes", equalTo("bring water")).body("recordedBy.displayName", notNullValue())
                .body("recordedAt", notNullValue()).extract().path("id");

        api(TENANT).get(ASSIGNMENTS + "/" + id).then().statusCode(200).body("id", equalTo(id));
        api(TENANT).delete(ASSIGNMENTS + "/" + id).then().statusCode(204);
        api(TENANT).get(ASSIGNMENTS + "/" + id).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffAssignToPlayersOfTheirTeamsOnly() {
        String plan = plan("Individual");

        api(TENANT).body(Map.of("planId", plan, "playerId", P1, "dueOn", "2027-10-02")).post(ASSIGNMENTS).then().statusCode(201)
                .body("playerId", equalTo(P1)).body("teamId", nullValue());
        api(TENANT).body(Map.of("planId", plan, "playerId", P3, "dueOn", "2027-10-02")).post(ASSIGNMENTS).then().statusCode(403);
        api(TENANT).body(Map.of("planId", plan, "teamId", TEAM2, "dueOn", "2027-10-02")).post(ASSIGNMENTS).then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void adminAssignsToAnyPlayerThatExists() {
        String plan = plan("Admin plan");
        assignToPlayer(plan, P3, "2027-10-03");

        api(TENANT).body(Map.of("planId", plan, "playerId", UUID.randomUUID().toString(), "dueOn", "2027-10-03"))
                .post(ASSIGNMENTS).then().statusCode(404);
        api(TENANT).body(Map.of("planId", plan, "teamId", UUID.randomUUID().toString(), "dueOn", "2027-10-03"))
                .post(ASSIGNMENTS).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void exactlyOneTargetAndAnOwnedLivePlanAreRequired() {
        String plan = plan("Rules");
        String template = api(TENANT).queryParam("template", true).queryParam("q", "Form").get(PLANS)
                .then().extract().path("items[0].id");

        lenient(TENANT).body(Map.of("planId", plan, "dueOn", "2027-10-04")).post(ASSIGNMENTS).then().statusCode(422)
                .body("code", equalTo("ASSIGNMENT_TARGET_REQUIRED"));
        lenient(TENANT).body(Map.of("planId", plan, "teamId", TEAM, "playerId", P1, "dueOn", "2027-10-04")).post(ASSIGNMENTS)
                .then().statusCode(422).body("code", equalTo("ASSIGNMENT_TARGET_AMBIGUOUS"));
        lenient(TENANT).body(Map.of("planId", template, "teamId", TEAM, "dueOn", "2027-10-04")).post(ASSIGNMENTS)
                .then().statusCode(422).body("code", equalTo("PLAN_IS_TEMPLATE"));
        lenient(TENANT).body(Map.of("planId", UUID.randomUUID().toString(), "teamId", TEAM, "dueOn", "2027-10-04"))
                .post(ASSIGNMENTS).then().statusCode(404);
        lenient(TENANT).body(Map.of("planId", plan, "teamId", TEAM)).post(ASSIGNMENTS).then().statusCode(400);
        lenient(TENANT).body(Map.of("planId", plan, "teamId", TEAM, "dueOn", "soon")).post(ASSIGNMENTS).then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void teamAssignmentsFanOutToThePlayersOfTheTeamWhenListedByPlayer() {
        // own teams and players, so assignments of the other tests do not show up
        String teamA = UUID.randomUUID().toString();
        String teamB = UUID.randomUUID().toString();
        String a1 = UUID.randomUUID().toString();
        String a2 = UUID.randomUUID().toString();
        String b1 = UUID.randomUUID().toString();
        core.roster(TENANT, teamA, a1, a2).roster(TENANT, teamB, b1).knownPlayers(TENANT, a1, a2, b1);
        String plan = plan("Fan out");
        String forTeam = assignToTeam(plan, teamA, "2027-11-01");
        String forPlayer = assignToPlayer(plan, a1, "2027-11-05");
        String otherTeam = assignToTeam(plan, teamB, "2027-11-03");

        api(TENANT).queryParam("playerId", a1).get(ASSIGNMENTS).then().statusCode(200)
                .body("items.id", containsInAnyOrder(forTeam, forPlayer));
        api(TENANT).queryParam("playerId", a2).get(ASSIGNMENTS).then().body("items.id", containsInAnyOrder(forTeam));
        api(TENANT).queryParam("playerId", b1).get(ASSIGNMENTS).then().body("items.id", containsInAnyOrder(otherTeam));
        api(TENANT).queryParam("teamId", teamA).get(ASSIGNMENTS).then().body("items.id", containsInAnyOrder(forTeam));
        api(TENANT).queryParam("playerId", a1).queryParam("dueFrom", "2027-11-02").get(ASSIGNMENTS).then()
                .body("items.id", containsInAnyOrder(forPlayer));
        api(TENANT).queryParam("playerId", a1).queryParam("dueTo", "2027-11-04").get(ASSIGNMENTS).then()
                .body("items.id", containsInAnyOrder(forTeam));
        api(TENANT).queryParam("teamId", teamA).queryParam("playerId", b1).get(ASSIGNMENTS).then().body("items", hasSize(0));
        api(TENANT).queryParam("playerId", a1).queryParam("size", 1).get(ASSIGNMENTS).then()
                .body("items", hasSize(1)).body("page.size", equalTo(1)).body("page.totalElements", equalTo(2));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void listValidatesItsParameters() {
        lenient(TENANT).queryParam("dueFrom", "never").get(ASSIGNMENTS).then().statusCode(400);
        lenient(TENANT).queryParam("playerId", "x").get(ASSIGNMENTS).then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void aPlanWithAssignmentsCannotBeDeletedAndDeletingTheAssignmentFreesIt() {
        String plan = plan("Pinned");
        String assignment = assignToTeam(plan, TEAM, "2027-12-01");

        lenient(TENANT).delete(PLANS + "/" + plan).then().statusCode(409).body("code", equalTo("PLAN_HAS_ASSIGNMENTS"));
        api(TENANT).delete(ASSIGNMENTS + "/" + assignment).then().statusCode(204);
        api(TENANT).delete(PLANS + "/" + plan).then().statusCode(204);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void withdrawingAnAssignmentDeletesItsCompletions() {
        String assignment = assignToTeam(plan("With answers"), TEAM, "2027-12-02");
        api(TENANT).body(Map.of("status", "DONE")).put(ASSIGNMENTS + "/" + assignment + "/completions/" + P1)
                .then().statusCode(200);
        api(TENANT).queryParam("assignmentId", assignment).get("/api/athlete/plan-completions").then().body("items", hasSize(1));

        api(TENANT).delete(ASSIGNMENTS + "/" + assignment).then().statusCode(204);

        api(TENANT).queryParam("assignmentId", assignment).get("/api/athlete/plan-completions").then().statusCode(404);
        api(TENANT).queryParam("playerId", P1).get("/api/athlete/plan-completions").then().body("items", hasSize(0));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void anotherTenantNeverSeesOrTouchesAssignments() {
        String assignment = assignToTeam(plan("Mine"), TEAM, "2027-12-03");
        member(OTHER_TENANT, TenantRole.ADMIN);

        lenient(OTHER_TENANT).get(ASSIGNMENTS + "/" + assignment).then().statusCode(404);
        lenient(OTHER_TENANT).delete(ASSIGNMENTS + "/" + assignment).then().statusCode(404);
        lenient(OTHER_TENANT).body(Map.of("status", "DONE")).put(ASSIGNMENTS + "/" + assignment + "/completions/" + P1)
                .then().statusCode(404);
        api(OTHER_TENANT).get(ASSIGNMENTS).then().statusCode(200).body("items", hasSize(0));
    }
}
