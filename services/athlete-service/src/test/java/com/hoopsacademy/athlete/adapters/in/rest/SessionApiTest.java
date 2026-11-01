package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static org.assertj.core.api.Assertions.assertThat;
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
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class SessionApiTest {

    static final String TENANT = "52000000-0000-4000-8000-000000000001";
    static final String TEAM = "52000000-0000-4000-8000-0000000000a1";
    static final String OTHER_TEAM = "52000000-0000-4000-8000-0000000000a2";
    static final String PLAYER = "52000000-0000-4000-8000-0000000000b1";
    static final String STRANGER_PLAYER = "52000000-0000-4000-8000-0000000000b2";
    static final String SESSIONS = "/api/athlete/training-sessions";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, PLAYER).roster(TENANT, OTHER_TEAM, STRANGER_PLAYER);
    }

    String createSession(String team, String startsAt) {
        return api(TENANT).body(Map.of("teamId", team, "startsAt", startsAt, "durationMinutes", 75, "location", "Court 1"))
                .post(SESSIONS).then().statusCode(201).extract().path("id");
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffCreatesAnAdHocSession() {
        api(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2027-03-02T17:00:00Z", "durationMinutes", 75,
                "location", "Court 1", "notes", "shooting drills")).post(SESSIONS)
                .then().statusCode(201)
                .body("id", notNullValue())
                .body("scheduleId", nullValue())
                .body("status", equalTo("PLANNED"))
                .body("durationMinutes", equalTo(75))
                .body("startsAt", equalTo("2027-03-02T17:00:00Z"))
                .body("notes", equalTo("shooting drills"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void listFiltersByTeamRangeAndStatusAndPages() {
        String a = createSession(TEAM, "2027-04-05T17:00:00Z");
        createSession(TEAM, "2027-04-12T17:00:00Z");
        createSession(TEAM, "2027-04-19T17:00:00Z");
        createSession(OTHER_TEAM, "2027-04-06T17:00:00Z");
        api(TENANT).body(Map.of("reason", "rain")).post(SESSIONS + "/" + a + "/cancel").then().statusCode(200);

        api(TENANT).queryParam("teamId", TEAM).queryParam("from", "2027-04-01").queryParam("to", "2027-04-30")
                .get(SESSIONS).then().statusCode(200).body("items", hasSize(3)).body("page.totalElements", equalTo(3));
        api(TENANT).queryParam("teamId", TEAM).queryParam("from", "2027-04-01").queryParam("to", "2027-04-30")
                .queryParam("status", "CANCELLED").get(SESSIONS).then().body("items", hasSize(1));
        api(TENANT).queryParam("teamId", TEAM).queryParam("from", "2027-04-01").queryParam("to", "2027-04-30")
                .queryParam("size", 2).queryParam("page", 1).get(SESSIONS).then()
                .body("items", hasSize(1)).body("page.totalPages", equalTo(2)).body("page.page", equalTo(1));
        // both teams, no team filter: staff roles see everything in range
        api(TENANT).queryParam("from", "2027-04-01").queryParam("to", "2027-04-30").get(SESSIONS)
                .then().body("page.totalElements", equalTo(4));
        // the range is inclusive of the whole `to` day and excludes the day after
        api(TENANT).queryParam("teamId", TEAM).queryParam("from", "2027-04-05").queryParam("to", "2027-04-05")
                .get(SESSIONS).then().body("items", hasSize(1));
        api(TENANT).queryParam("teamId", TEAM).queryParam("from", "2027-04-06").queryParam("to", "2027-04-11")
                .get(SESSIONS).then().body("items", hasSize(0));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void rangeLongerThan366DaysIsRejectedAndMalformedParametersAre400() {
        lenient(TENANT).queryParam("from", "2027-01-01").queryParam("to", "2028-01-02").get(SESSIONS)
                .then().statusCode(400);
        api(TENANT).queryParam("from", "2027-01-01").queryParam("to", "2027-12-31").get(SESSIONS).then().statusCode(200);
        lenient(TENANT).queryParam("from", "2027-02-01").queryParam("to", "2027-01-01").get(SESSIONS).then().statusCode(400);
        lenient(TENANT).queryParam("status", "WHATEVER").get(SESSIONS).then().statusCode(400);
        lenient(TENANT).queryParam("size", 500).get(SESSIONS).then().statusCode(400);
        lenient(TENANT).queryParam("page", -1).get(SESSIONS).then().statusCode(400);
        lenient(TENANT).queryParam("from", "yesterday").get(SESSIONS).then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void patchChangesTimeLocationPlanNotesAndStatus() {
        String id = createSession(TEAM, "2027-05-04T17:00:00Z");
        String plan = api(TENANT).body(Map.of("name", "Session plan")).post("/api/athlete/training-plans")
                .then().statusCode(201).extract().path("id");

        api(TENANT).body(Map.of("startsAt", "2027-05-04T18:00:00Z", "durationMinutes", 60, "location", "Court 2",
                "planId", plan, "notes", "bring bibs")).patch(SESSIONS + "/" + id)
                .then().statusCode(200)
                .body("startsAt", equalTo("2027-05-04T18:00:00Z"))
                .body("durationMinutes", equalTo(60))
                .body("location", equalTo("Court 2"))
                .body("planId", equalTo(plan))
                .body("notes", equalTo("bring bibs"));
        var clear = new java.util.HashMap<String, Object>();
        clear.put("planId", null);
        clear.put("notes", null);
        api(TENANT).body(clear).patch(SESSIONS + "/" + id).then().statusCode(200)
                .body("planId", nullValue()).body("notes", nullValue()).body("location", equalTo("Court 2"));
        api(TENANT).body(Map.of("status", "DONE")).patch(SESSIONS + "/" + id).then().statusCode(200).body("status", equalTo("DONE"));
        api(TENANT).body(Map.of("status", "PLANNED")).patch(SESSIONS + "/" + id).then().statusCode(200).body("status", equalTo("PLANNED"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void patchRejectsCancellingBadValuesAndEmptyBodies() {
        String id = createSession(TEAM, "2027-05-11T17:00:00Z");

        lenient(TENANT).body(Map.of("status", "CANCELLED")).patch(SESSIONS + "/" + id).then().statusCode(400);
        lenient(TENANT).body(Map.of("startsAt", "tomorrow")).patch(SESSIONS + "/" + id).then().statusCode(400);
        lenient(TENANT).body(Map.of("durationMinutes", 1000)).patch(SESSIONS + "/" + id).then().statusCode(400);
        lenient(TENANT).body(Map.of("planId", "not-a-uuid")).patch(SESSIONS + "/" + id).then().statusCode(400);
        lenient(TENANT).body(Map.of()).patch(SESSIONS + "/" + id).then().statusCode(400);
        lenient(TENANT).body(Map.of("location", 5)).patch(SESSIONS + "/" + id).then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void cancelledSessionsAreFrozen() {
        String id = createSession(TEAM, "2027-05-18T17:00:00Z");
        api(TENANT).body(Map.of("reason", "Holiday")).post(SESSIONS + "/" + id + "/cancel").then().statusCode(200);

        api(TENANT).body(Map.of("notes", "x")).patch(SESSIONS + "/" + id).then().statusCode(409);
        api(TENANT).body(Map.of("reason", "again")).post(SESSIONS + "/" + id + "/cancel").then().statusCode(409);
        lenient(TENANT).body(Map.of("reason", "")).post(SESSIONS + "/" + createSession(TEAM, "2027-05-25T17:00:00Z") + "/cancel")
                .then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void doneSessionCannotBeCancelled() {
        String id = createSession(TEAM, "2027-06-01T17:00:00Z");
        api(TENANT).body(Map.of("status", "DONE")).patch(SESSIONS + "/" + id).then().statusCode(200);

        api(TENANT).body(Map.of("reason", "oops")).post(SESSIONS + "/" + id + "/cancel").then().statusCode(409);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void createValidatesInput() {
        lenient(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2027-06-08T17:00:00Z", "durationMinutes", 5))
                .post(SESSIONS).then().statusCode(400);
        lenient(TENANT).body(Map.of("teamId", TEAM, "durationMinutes", 60)).post(SESSIONS).then().statusCode(400);
        String ghost = "52000000-0000-4000-8000-0000000000ff";
        core.rosterNotFound(TENANT, ghost);
        api(TENANT).body(Map.of("teamId", ghost, "startsAt", "2027-06-08T17:00:00Z", "durationMinutes", 60))
                .post(SESSIONS).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = OTHER_TEAM)
    void coachOfAnotherTeamReadsButCannotChange() {
        String id = createSessionAsAdmin(TEAM, "2027-06-15T17:00:00Z");

        api(TENANT).get(SESSIONS + "/" + id).then().statusCode(200);
        api(TENANT).queryParam("teamId", TEAM).queryParam("from", "2027-06-15").queryParam("to", "2027-06-15")
                .get(SESSIONS).then().statusCode(200).body("items", hasSize(1));
        api(TENANT).body(Map.of("notes", "hijack")).patch(SESSIONS + "/" + id).then().statusCode(403);
        api(TENANT).body(Map.of("reason", "hijack")).post(SESSIONS + "/" + id + "/cancel").then().statusCode(403);
        api(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2027-06-16T17:00:00Z", "durationMinutes", 60))
                .post(SESSIONS).then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT, linkedPlayers = PLAYER)
    void parentSeesOnlyTheirTeamsSessions() {
        String ownTeamSession = createSessionAsAdmin(TEAM, "2027-07-06T17:00:00Z");
        String otherTeamSession = createSessionAsAdmin(OTHER_TEAM, "2027-07-06T17:00:00Z");

        api(TENANT).get(SESSIONS + "/" + ownTeamSession).then().statusCode(200);
        api(TENANT).get(SESSIONS + "/" + otherTeamSession).then().statusCode(404);
        api(TENANT).queryParam("teamId", TEAM).queryParam("from", "2027-07-01").queryParam("to", "2027-07-31")
                .get(SESSIONS).then().statusCode(200).body("items", hasSize(1));
        api(TENANT).queryParam("teamId", OTHER_TEAM).get(SESSIONS).then().statusCode(404);
        lenient(TENANT).get(SESSIONS).then().statusCode(400);
        api(TENANT).body(Map.of("notes", "x")).patch(SESSIONS + "/" + ownTeamSession).then().statusCode(403);
        api(TENANT).body(Map.of("reason", "x")).post(SESSIONS + "/" + ownTeamSession + "/cancel").then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PLAYER, ownPlayer = PLAYER)
    void playerSeesTheirTeamsSessions() {
        String ownTeamSession = createSessionAsAdmin(TEAM, "2027-08-03T17:00:00Z");
        String otherTeamSession = createSessionAsAdmin(OTHER_TEAM, "2027-08-03T17:00:00Z");

        api(TENANT).get(SESSIONS + "/" + ownTeamSession).then().statusCode(200);
        api(TENANT).get(SESSIONS + "/" + otherTeamSession).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void unknownSessionIs404AndMalformedIdIs404() {
        api(TENANT).get(SESSIONS + "/" + UUID.randomUUID()).then().statusCode(404);
        lenient(TENANT).get(SESSIONS + "/not-a-uuid").then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void listsAreOrderedByStart() {
        createSession(TEAM, "2027-09-14T17:00:00Z");
        createSession(TEAM, "2027-09-07T17:00:00Z");
        createSession(TEAM, "2027-09-21T17:00:00Z");

        List<String> starts = api(TENANT).queryParam("teamId", TEAM).queryParam("from", "2027-09-01")
                .queryParam("to", "2027-09-30").get(SESSIONS).then().extract().path("items.startsAt");

        assertThat(starts).containsExactly("2027-09-07T17:00:00Z", "2027-09-14T17:00:00Z", "2027-09-21T17:00:00Z");
    }

    /** Creates a session with the caller temporarily swapped for an admin (the @TenantUser caller may only read). */
    private String createSessionAsAdmin(String team, String startsAt) {
        var original = com.hoopsacademy.common.testing.TenantUserRegistry.find("tenant-user",
                com.hoopsacademy.common.tenancy.TenantId.parse(TENANT)).orElseThrow();
        com.hoopsacademy.athlete.support.ApiSupport.member(TENANT, java.util.Set.of(TenantRole.ADMIN), java.util.Set.of(),
                java.util.Set.of(), null);
        try {
            return createSession(team, startsAt);
        } finally {
            com.hoopsacademy.common.testing.TenantUserRegistry.register(original);
        }
    }
}
