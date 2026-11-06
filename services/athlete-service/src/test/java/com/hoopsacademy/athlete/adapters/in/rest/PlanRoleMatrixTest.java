package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.ADMIN;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.ADMIN_AND_PLAYER;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.ASSISTANT_OF_TEAM;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.COACH_AND_PARENT;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.COACH_OF_OTHER;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.COACH_OF_TEAM;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.NO_ROLE;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.PARENT_LINKED;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.PARENT_UNLINKED;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.PLAYER_OTHER;
import static com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.PLAYER_SELF;
import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.adapters.in.rest.RoleMatrixTest.Caller;
import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import jakarta.inject.Inject;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * docs/domain/authz-matrix.md for plans: write plans (ADMIN/any staff), assign (ADMIN/staff of the team, or of a team
 * the player is in), mark completion (ADMIN, team staff, linked parent, the player), reads (visibility is 404).
 * 2xx = allowed, 403 = member without the right, 404 = hidden.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class PlanRoleMatrixTest {

    static final String TENANT = "64000000-0000-4000-8000-000000000001";
    // the same ids as RoleMatrixTest's callers, but this tenant has its own team and players
    static final String TEAM = "55000000-0000-4000-8000-0000000000a1";
    static final String CHILD = "55000000-0000-4000-8000-0000000000b1";
    static final String OTHER = "55000000-0000-4000-8000-0000000000b2";
    static final String OTHER_TEAM = "55000000-0000-4000-8000-0000000000a2";
    static final String ASSIGNMENTS = "/api/athlete/plan-assignments";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;
    String plan;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, CHILD).roster(TENANT, OTHER_TEAM, OTHER).knownPlayers(TENANT, CHILD, OTHER);
        act(ADMIN);
        plan = api(TENANT).body(Map.of("name", "Matrix plan")).post("/api/athlete/training-plans")
                .then().statusCode(201).extract().path("id");
    }

    private void act(Caller c) {
        member(TENANT, c.roles(), c.staffTeams(), c.linked(), c.own());
    }

    private String teamAssignment() {
        act(ADMIN);
        return api(TENANT).body(Map.of("planId", plan, "teamId", TEAM, "dueOn", "2028-01-10")).post(ASSIGNMENTS)
                .then().statusCode(201).extract().path("id");
    }

    private String playerAssignment() {
        act(ADMIN);
        return api(TENANT).body(Map.of("planId", plan, "playerId", CHILD, "dueOn", "2028-01-10")).post(ASSIGNMENTS)
                .then().statusCode(201).extract().path("id");
    }

    // ------------------------------------------------------------------ plans
    static Stream<Arguments> planWrite() {
        return Stream.of(
                Arguments.of(ADMIN, 201), Arguments.of(COACH_OF_TEAM, 201), Arguments.of(ASSISTANT_OF_TEAM, 201),
                Arguments.of(COACH_OF_OTHER, 201), Arguments.of(PARENT_LINKED, 403), Arguments.of(PLAYER_SELF, 403),
                Arguments.of(COACH_AND_PARENT, 201), Arguments.of(ADMIN_AND_PLAYER, 201), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "create plan: {0} -> {1}")
    @MethodSource("planWrite")
    void createPlan(Caller caller, int expected) {
        act(caller);

        assertThat(api(TENANT).body(Map.of("name", "P")).post("/api/athlete/training-plans").then().extract().statusCode())
                .isEqualTo(expected);
    }

    @ParameterizedTest(name = "copy template: {0} -> {1}")
    @MethodSource("planWrite")
    void copyTemplate(Caller caller, int expected) {
        act(ADMIN);
        String template = api(TENANT).queryParam("template", true).get("/api/athlete/training-plans").then().extract().path("items[0].id");
        act(caller);

        assertThat(TrainingPlanApiTest.copy(api(TENANT), template, null).then().extract().statusCode()).isEqualTo(expected);
    }

    static Stream<Arguments> planRead() {
        return Stream.of(Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(PARENT_LINKED, 200),
                Arguments.of(PARENT_UNLINKED, 200), Arguments.of(PLAYER_SELF, 200), Arguments.of(PLAYER_OTHER, 200),
                Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "read plan: {0} -> {1}")
    @MethodSource("planRead")
    void readPlan(Caller caller, int expected) {
        act(caller);

        assertThat(api(TENANT).get("/api/athlete/training-plans/" + plan).then().extract().statusCode()).isEqualTo(expected);
    }

    // ------------------------------------------------------------------ assigning
    static Stream<Arguments> assignToTeam() {
        return Stream.of(
                Arguments.of(ADMIN, 201), Arguments.of(COACH_OF_TEAM, 201), Arguments.of(ASSISTANT_OF_TEAM, 201),
                Arguments.of(COACH_OF_OTHER, 403), Arguments.of(PARENT_LINKED, 403), Arguments.of(PLAYER_SELF, 403),
                Arguments.of(COACH_AND_PARENT, 403), Arguments.of(ADMIN_AND_PLAYER, 201), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "assign to team: {0} -> {1}")
    @MethodSource("assignToTeam")
    void assignPlanToTeam(Caller caller, int expected) {
        act(caller);

        assertThat(api(TENANT).body(Map.of("planId", plan, "teamId", TEAM, "dueOn", "2028-01-10")).post(ASSIGNMENTS)
                .then().extract().statusCode()).isEqualTo(expected);
    }

    @ParameterizedTest(name = "assign to player in the team: {0} -> {1}")
    @MethodSource("assignToTeam")
    void assignPlanToPlayer(Caller caller, int expected) {
        act(caller);

        assertThat(api(TENANT).body(Map.of("planId", plan, "playerId", CHILD, "dueOn", "2028-01-10")).post(ASSIGNMENTS)
                .then().extract().statusCode()).isEqualTo(expected);
    }

    @ParameterizedTest(name = "withdraw assignment: {0} -> {1}")
    @MethodSource("withdraw")
    void withdrawAssignment(Caller caller, int expected) {
        String assignment = teamAssignment();
        act(caller);

        assertThat(api(TENANT).delete(ASSIGNMENTS + "/" + assignment).then().extract().statusCode()).isEqualTo(expected);
    }

    static Stream<Arguments> withdraw() {
        return Stream.of(
                Arguments.of(ADMIN, 204), Arguments.of(COACH_OF_TEAM, 204), Arguments.of(COACH_OF_OTHER, 403),
                Arguments.of(PARENT_LINKED, 403), Arguments.of(PLAYER_SELF, 403), Arguments.of(NO_ROLE, 403));
    }

    // ------------------------------------------------------------------ reading assignments
    static Stream<Arguments> readAssignment() {
        return Stream.of(
                Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(COACH_OF_OTHER, 200),
                Arguments.of(PARENT_LINKED, 200), Arguments.of(PARENT_UNLINKED, 404), Arguments.of(PLAYER_SELF, 200),
                Arguments.of(PLAYER_OTHER, 404), Arguments.of(COACH_AND_PARENT, 200), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "read team assignment: {0} -> {1}")
    @MethodSource("readAssignment")
    void readTeamAssignment(Caller caller, int expected) {
        String assignment = teamAssignment();
        act(caller);

        assertThat(api(TENANT).get(ASSIGNMENTS + "/" + assignment).then().extract().statusCode()).isEqualTo(expected);
    }

    @ParameterizedTest(name = "read player assignment: {0} -> {1}")
    @MethodSource("readAssignment")
    void readPlayerAssignment(Caller caller, int expected) {
        String assignment = playerAssignment();
        act(caller);

        assertThat(api(TENANT).get(ASSIGNMENTS + "/" + assignment).then().extract().statusCode()).isEqualTo(expected);
    }

    static Stream<Arguments> listForChild() {
        return Stream.of(
                Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_OTHER, 200), Arguments.of(PARENT_LINKED, 200),
                Arguments.of(PARENT_UNLINKED, 403), Arguments.of(PLAYER_SELF, 200), Arguments.of(PLAYER_OTHER, 403),
                Arguments.of(COACH_AND_PARENT, 200), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "list assignments of CHILD: {0} -> {1}")
    @MethodSource("listForChild")
    void listAssignmentsOfAPlayer(Caller caller, int expected) {
        teamAssignment();
        act(caller);

        assertThat(api(TENANT).queryParam("playerId", CHILD).get(ASSIGNMENTS).then().extract().statusCode()).isEqualTo(expected);
    }

    @ParameterizedTest(name = "list without filter: {0} sees own={1} foreign={2}")
    @MethodSource("ownScopes")
    void listWithoutFilterIsLimitedToTheCallersPlayers(Caller caller, boolean seesOwn, boolean seesForeign) {
        String own = teamAssignment();
        act(ADMIN);
        String foreign = api(TENANT).body(Map.of("planId", plan, "teamId", OTHER_TEAM, "dueOn", "2028-01-11"))
                .post(ASSIGNMENTS).then().statusCode(201).extract().path("id");
        act(caller);

        java.util.List<String> ids = api(TENANT).queryParam("size", 200).get(ASSIGNMENTS).then().statusCode(200)
                .extract().path("items.id");

        assertThat(ids.contains(own)).isEqualTo(seesOwn);
        assertThat(ids.contains(foreign)).isEqualTo(seesForeign);
    }

    static Stream<Arguments> ownScopes() {
        return Stream.of(Arguments.of(PARENT_LINKED, true, false), Arguments.of(PLAYER_SELF, true, false),
                Arguments.of(PARENT_UNLINKED, false, true), Arguments.of(PLAYER_OTHER, false, true),
                Arguments.of(ADMIN, true, true), Arguments.of(COACH_OF_OTHER, true, true),
                Arguments.of(COACH_AND_PARENT, true, true));
    }

    // ------------------------------------------------------------------ marking completions
    static Stream<Arguments> mark() {
        return Stream.of(
                Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(ASSISTANT_OF_TEAM, 200),
                Arguments.of(COACH_OF_OTHER, 403), Arguments.of(PARENT_LINKED, 200), Arguments.of(PARENT_UNLINKED, 404),
                Arguments.of(PLAYER_SELF, 200), Arguments.of(PLAYER_OTHER, 404), Arguments.of(COACH_AND_PARENT, 200),
                Arguments.of(ADMIN_AND_PLAYER, 200), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "mark CHILD on a team assignment: {0} -> {1}")
    @MethodSource("mark")
    void markCompletionOnTeamAssignment(Caller caller, int expected) {
        String assignment = teamAssignment();
        act(caller);

        assertThat(api(TENANT).body(Map.of("status", "DONE")).put(ASSIGNMENTS + "/" + assignment + "/completions/" + CHILD)
                .then().extract().statusCode()).isEqualTo(expected);
    }

    @ParameterizedTest(name = "mark CHILD on a player assignment: {0} -> {1}")
    @MethodSource("mark")
    void markCompletionOnPlayerAssignment(Caller caller, int expected) {
        String assignment = playerAssignment();
        act(caller);

        assertThat(api(TENANT).body(Map.of("status", "DONE")).put(ASSIGNMENTS + "/" + assignment + "/completions/" + CHILD)
                .then().extract().statusCode()).isEqualTo(expected);
    }

    // ------------------------------------------------------------------ quick-add (WP78, ADR-0041)
    private Map<String, Object> templateItem() {
        act(ADMIN);
        String template = api(TENANT).queryParam("template", true).get("/api/athlete/training-plans").then()
                .extract().path("items[0].id");
        String item = api(TENANT).get("/api/athlete/training-plans/" + template).then().extract().path("items[0].id");
        return Map.of("items", java.util.List.of(Map.of("planId", template, "itemId", item)));
    }

    static Stream<Arguments> quickAddToPlan() {
        return Stream.of(
                Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(ASSISTANT_OF_TEAM, 200),
                Arguments.of(COACH_OF_OTHER, 200), Arguments.of(PARENT_LINKED, 403), Arguments.of(PLAYER_SELF, 403),
                Arguments.of(COACH_AND_PARENT, 200), Arguments.of(ADMIN_AND_PLAYER, 200), Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "quick-add to a plan: {0} -> {1}")
    @MethodSource("quickAddToPlan")
    void quickAddToAPlan(Caller caller, int expected) {
        Map<String, Object> body = templateItem();
        act(caller);

        assertThat(api(TENANT).urlEncodingEnabled(false).body(body)
                .post("/api/athlete/training-plans/" + plan + "/items:copy").then().extract().statusCode())
                .isEqualTo(expected);
    }

    static Stream<Arguments> quickAddToSession() {
        return Stream.of(
                Arguments.of(ADMIN, 200), Arguments.of(COACH_OF_TEAM, 200), Arguments.of(ASSISTANT_OF_TEAM, 200),
                Arguments.of(COACH_OF_OTHER, 403), Arguments.of(PARENT_LINKED, 403), Arguments.of(PARENT_UNLINKED, 403),
                Arguments.of(PLAYER_SELF, 403), Arguments.of(COACH_AND_PARENT, 403), Arguments.of(ADMIN_AND_PLAYER, 200),
                Arguments.of(NO_ROLE, 403));
    }

    @ParameterizedTest(name = "quick-add to a session of the team: {0} -> {1}")
    @MethodSource("quickAddToSession")
    void quickAddToASession(Caller caller, int expected) {
        Map<String, Object> body = templateItem();
        String session = api(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2028-01-10T17:00:00Z", "durationMinutes", 60))
                .post("/api/athlete/training-sessions").then().statusCode(201).extract().path("id");
        act(caller);

        assertThat(api(TENANT).body(body).post("/api/athlete/training-sessions/" + session + "/items").then().extract()
                .statusCode()).isEqualTo(expected);
    }
}
