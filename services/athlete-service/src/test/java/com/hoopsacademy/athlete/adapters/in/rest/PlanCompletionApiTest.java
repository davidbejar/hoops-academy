package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;

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
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class PlanCompletionApiTest {

    static final String TENANT = "63000000-0000-4000-8000-000000000001";
    static final String TEAM = "63000000-0000-4000-8000-0000000000a1";
    static final String TEAM2 = "63000000-0000-4000-8000-0000000000a2";
    static final String P1 = "63000000-0000-4000-8000-0000000000b1";
    static final String P2 = "63000000-0000-4000-8000-0000000000b2";
    static final String P3 = "63000000-0000-4000-8000-0000000000b3";
    static final String ASSIGNMENTS = "/api/athlete/plan-assignments";
    static final String COMPLETIONS = "/api/athlete/plan-completions";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, P1, P2).roster(TENANT, TEAM2, P3).knownPlayers(TENANT, P1, P2, P3);
    }

    /** Creates a plan and assigns it as ADMIN, then switches to the given caller. */
    String assignedTo(String targetKey, String target) {
        member(TENANT, TenantRole.ADMIN);
        String plan = api(TENANT).body(Map.of("name", "Homework")).post("/api/athlete/training-plans")
                .then().statusCode(201).extract().path("id");
        return api(TENANT).body(Map.of("planId", plan, targetKey, target, "dueOn", "2027-10-10")).post(ASSIGNMENTS)
                .then().statusCode(201).extract().path("id");
    }

    String completion(String assignment, String player) {
        return ASSIGNMENTS + "/" + assignment + "/completions/" + player;
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PLAYER, ownPlayer = P1)
    void aPlayerMarksAndChangesTheirOwnCompletion() {
        String assignment = assignedTo("teamId", TEAM);
        member(TENANT, Set.of(TenantRole.PLAYER), Set.of(), Set.of(), P1);

        String id = api(TENANT).body(Map.of("status", "PARTIAL", "comment", "ran out of time")).put(completion(assignment, P1))
                .then().statusCode(200)
                .body("assignmentId", equalTo(assignment)).body("playerId", equalTo(P1)).body("status", equalTo("PARTIAL"))
                .body("comment", equalTo("ran out of time")).body("recordedBy.personId", notNullValue())
                .body("recordedAt", notNullValue()).extract().path("id");

        api(TENANT).body(Map.of("status", "DONE")).put(completion(assignment, P1)).then().statusCode(200)
                .body("id", equalTo(id)).body("status", equalTo("DONE"));
        api(TENANT).queryParam("assignmentId", assignment).get(COMPLETIONS).then().statusCode(200)
                .body("items", hasSize(1)).body("items[0].status", equalTo("DONE"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT, linkedPlayers = P2)
    void aParentMarksOnlyLinkedChildrenAndSeesOnlyTheirCompletions() {
        String assignment = assignedTo("teamId", TEAM);
        member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(P2), null);

        api(TENANT).body(Map.of("status", "DONE")).put(completion(assignment, P2)).then().statusCode(200);
        api(TENANT).body(Map.of("status", "DONE")).put(completion(assignment, P1)).then().statusCode(403);

        member(TENANT, TenantRole.ADMIN);
        api(TENANT).body(Map.of("status", "NOT_DONE")).put(completion(assignment, P1)).then().statusCode(200);
        member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(P2), null);
        api(TENANT).queryParam("size", 200).get(COMPLETIONS).then().statusCode(200)
                .body("items.playerId", org.hamcrest.Matchers.everyItem(equalTo(P2)));
        api(TENANT).queryParam("playerId", P1).get(COMPLETIONS).then().statusCode(403);
        api(TENANT).queryParam("assignmentId", assignment).get(COMPLETIONS).then().body("items", hasSize(1));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffOfTheTeamMarkForAnyPlayerOfIt() {
        String assignment = assignedTo("teamId", TEAM);
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);

        api(TENANT).body(Map.of("status", "DONE")).put(completion(assignment, P1)).then().statusCode(200);
        api(TENANT).body(Map.of("status", "NOT_DONE")).put(completion(assignment, P2)).then().statusCode(200);
        api(TENANT).queryParam("assignmentId", assignment).get(COMPLETIONS).then().body("items", hasSize(2));
        api(TENANT).queryParam("assignmentId", assignment).queryParam("playerId", P2).queryParam("size", 1)
                .get(COMPLETIONS).then().body("items", hasSize(1)).body("page.totalElements", equalTo(1));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void theMarkedPlayerMustBeATargetOfTheAssignment() {
        String teamAssignment = assignedTo("teamId", TEAM);
        String playerAssignment = assignedTo("playerId", P1);

        lenient(TENANT).body(Map.of("status", "DONE")).put(completion(teamAssignment, P3)).then().statusCode(422)
                .body("code", equalTo("PLAYER_NOT_IN_TEAM"));
        lenient(TENANT).body(Map.of("status", "DONE")).put(completion(playerAssignment, P2)).then().statusCode(422)
                .body("code", equalTo("PLAYER_NOT_TARGETED"));
        api(TENANT).body(Map.of("status", "DONE")).put(completion(playerAssignment, P1)).then().statusCode(200);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void completionInputIsValidated() {
        String assignment = assignedTo("teamId", TEAM);

        lenient(TENANT).body(Map.of("status", "MAYBE")).put(completion(assignment, P1)).then().statusCode(400);
        lenient(TENANT).body(Map.of("comment", "x")).put(completion(assignment, P1)).then().statusCode(400);
        lenient(TENANT).body(Map.of("status", "DONE")).put(completion(java.util.UUID.randomUUID().toString(), P1))
                .then().statusCode(404);
        lenient(TENANT).queryParam("assignmentId", "x").get(COMPLETIONS).then().statusCode(400);
    }
}
