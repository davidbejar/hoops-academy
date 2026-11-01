package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.application.MaterialiseSessions;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class ScheduleApiTest {

    static final String TENANT = "51000000-0000-4000-8000-000000000001";
    static final String OTHER_TENANT = "51000000-0000-4000-8000-000000000002";
    static final String TEAM = "51000000-0000-4000-8000-0000000000a1";
    static final String OTHER_TEAM = "51000000-0000-4000-8000-0000000000a2";
    static final String PLAYER = "51000000-0000-4000-8000-0000000000b1";
    static final String STRANGER_PLAYER = "51000000-0000-4000-8000-0000000000b2";
    static final ZoneId ZONE = ZoneId.of("Europe/Madrid");

    @Inject MaterialiseSessions materialise;
    @Inject TenantScope tenantScope;
    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, PLAYER).roster(TENANT, OTHER_TEAM, STRANGER_PLAYER);
    }

    static Map<String, Object> schedule(String team, String day, String time) {
        return Map.of("teamId", team, "dayOfWeek", day, "startTime", time, "durationMinutes", 90, "location", "Main court",
                "validFrom", LocalDate.now(ZONE).toString());
    }

    String createSchedule(String tenant, String team, String day, String time) {
        return api(tenant).body(schedule(team, day, time)).post("/api/athlete/training-schedules")
                .then().statusCode(201).extract().path("id");
    }

    int sessionCount(String tenant, String team) {
        LocalDate today = LocalDate.now(ZONE);
        return api(tenant).queryParam("teamId", team).queryParam("from", today.toString())
                .queryParam("to", today.plusDays(100).toString()).queryParam("size", 200)
                .get("/api/athlete/training-sessions").then().statusCode(200).extract().path("page.totalElements");
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffCreatesScheduleAndEightWeeksOfSessionsAreMaterialised() {
        api(TENANT).body(schedule(TEAM, "TUESDAY", "18:30")).post("/api/athlete/training-schedules")
                .then().statusCode(201)
                .body("id", notNullValue())
                .body("teamId", equalTo(TEAM))
                .body("dayOfWeek", equalTo("TUESDAY"))
                .body("startTime", equalTo("18:30"))
                .body("durationMinutes", equalTo(90));

        LocalDate today = LocalDate.now(ZONE);
        api(TENANT).queryParam("teamId", TEAM).queryParam("from", today.toString())
                .queryParam("to", today.plusWeeks(8).minusDays(1).toString()).queryParam("size", 200)
                .get("/api/athlete/training-sessions").then().statusCode(200)
                .body("items", hasSize(8))
                .body("items.status", org.hamcrest.Matchers.everyItem(equalTo("PLANNED")))
                .body("items[0].durationMinutes", equalTo(90))
                .body("items[0].location", equalTo("Main court"))
                .body("page.totalElements", equalTo(8));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void materialisationIsIdempotent() {
        String team = "51000000-0000-4000-8000-0000000000c1";
        core.roster(TENANT, team);
        createSchedule(TENANT, team, "WEDNESDAY", "17:00");
        assertThat(sessionCount(TENANT, team)).isEqualTo(8);

        int created = tenantScope.runAs(TenantId.parse(TENANT), () -> materialise.forAllSchedules());
        int createdAgain = tenantScope.runAs(TenantId.parse(TENANT), () -> materialise.forAllSchedules());

        assertThat(created).isZero();
        assertThat(createdAgain).isZero();
        assertThat(sessionCount(TENANT, team)).isEqualTo(8);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void cancelledSessionsAreNotRecreated() {
        String team = "51000000-0000-4000-8000-0000000000c2";
        core.roster(TENANT, team);
        createSchedule(TENANT, team, "THURSDAY", "17:00");
        LocalDate today = LocalDate.now(ZONE);
        String firstSession = api(TENANT).queryParam("teamId", team).queryParam("from", today.toString())
                .queryParam("to", today.plusDays(20).toString()).get("/api/athlete/training-sessions")
                .then().statusCode(200).extract().path("items[0].id");
        api(TENANT).body(Map.of("reason", "Hall closed")).post("/api/athlete/training-sessions/" + firstSession + "/cancel")
                .then().statusCode(200).body("status", equalTo("CANCELLED")).body("cancelReason", equalTo("Hall closed"));

        int created = tenantScope.runAs(TenantId.parse(TENANT), () -> materialise.forAllSchedules());

        assertThat(created).isZero();
        assertThat(sessionCount(TENANT, team)).isEqualTo(8);
        api(TENANT).get("/api/athlete/training-sessions/" + firstSession).then().body("status", equalTo("CANCELLED"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void changingTheWeekdayMovesUntouchedSessionsButKeepsEditedOnes() {
        String team = "51000000-0000-4000-8000-0000000000c3";
        core.roster(TENANT, team);
        String schedule = createSchedule(TENANT, team, "MONDAY", "17:00");
        LocalDate today = LocalDate.now(ZONE);
        List<String> ids = api(TENANT).queryParam("teamId", team).queryParam("from", today.toString())
                .queryParam("to", today.plusDays(60).toString()).get("/api/athlete/training-sessions")
                .then().extract().path("items.id");
        String edited = ids.get(7);
        api(TENANT).body(Map.of("notes", "Friendly vs Estudiantes")).patch("/api/athlete/training-sessions/" + edited)
                .then().statusCode(200);

        api(TENANT).body(Map.of("dayOfWeek", "FRIDAY")).patch("/api/athlete/training-schedules/" + schedule)
                .then().statusCode(200).body("dayOfWeek", equalTo("FRIDAY"));

        List<String> days = api(TENANT).queryParam("teamId", team).queryParam("from", today.toString())
                .queryParam("to", today.plusDays(60).toString()).queryParam("size", 200)
                .get("/api/athlete/training-sessions").then().extract().path("items.startsAt");
        // 8 new Friday sessions plus the manually edited Monday one that stayed
        assertThat(days).hasSize(9);
        assertThat(ids).contains(edited);
        api(TENANT).get("/api/athlete/training-sessions/" + edited).then().body("notes", equalTo("Friendly vs Estudiantes"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void changingOnlyTheLocationKeepsSessionIdsAndUpdatesThem() {
        String team = "51000000-0000-4000-8000-0000000000c4";
        core.roster(TENANT, team);
        String schedule = createSchedule(TENANT, team, "SATURDAY", "10:00");
        LocalDate today = LocalDate.now(ZONE);
        List<String> before = api(TENANT).queryParam("teamId", team).queryParam("from", today.toString())
                .queryParam("to", today.plusDays(60).toString()).get("/api/athlete/training-sessions")
                .then().extract().path("items.id");

        api(TENANT).body(Map.of("location", "Gym B")).patch("/api/athlete/training-schedules/" + schedule)
                .then().statusCode(200).body("location", equalTo("Gym B"));

        var after = api(TENANT).queryParam("teamId", team).queryParam("from", today.toString())
                .queryParam("to", today.plusDays(60).toString()).get("/api/athlete/training-sessions").then().extract();
        assertThat(after.<List<String>>path("items.id")).containsExactlyElementsOf(before);
        assertThat(after.<List<String>>path("items.location")).containsOnly("Gym B");
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void patchCanClearOptionalFieldsAndRejectsBadValues() {
        String team = "51000000-0000-4000-8000-0000000000c5";
        core.roster(TENANT, team);
        String schedule = createSchedule(TENANT, team, "SUNDAY", "10:00");

        api(TENANT).body(Map.of("validUntil", LocalDate.now(ZONE).plusMonths(6).toString()))
                .patch("/api/athlete/training-schedules/" + schedule).then().statusCode(200)
                .body("validUntil", notNullValue());
        var cleared = new java.util.HashMap<String, Object>();
        cleared.put("validUntil", null);
        cleared.put("location", null);
        api(TENANT).body(cleared).patch("/api/athlete/training-schedules/" + schedule).then().statusCode(200)
                .body("validUntil", nullValue()).body("location", nullValue());

        lenient(TENANT).body(Map.of("durationMinutes", 5)).patch("/api/athlete/training-schedules/" + schedule)
                .then().statusCode(400);
        lenient(TENANT).body(Map.of("startTime", "25:00")).patch("/api/athlete/training-schedules/" + schedule)
                .then().statusCode(400);
        lenient(TENANT).body(Map.of()).patch("/api/athlete/training-schedules/" + schedule).then().statusCode(400);
        lenient(TENANT).body(Map.of("dayOfWeek", "FUNDAY")).patch("/api/athlete/training-schedules/" + schedule)
                .then().statusCode(400);
        lenient(TENANT).body(Map.of("validFrom", "2000-01-01", "validUntil", "1999-01-01"))
                .patch("/api/athlete/training-schedules/" + schedule).then().statusCode(422);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void endingAScheduleRemovesFutureSessionsButKeepsThoseWithAttendance() {
        String team = "51000000-0000-4000-8000-0000000000c6";
        core.roster(TENANT, team, PLAYER);
        String schedule = createSchedule(TENANT, team, "FRIDAY", "19:00");
        LocalDate today = LocalDate.now(ZONE);
        String kept = api(TENANT).queryParam("teamId", team).queryParam("from", today.toString())
                .queryParam("to", today.plusDays(30).toString()).get("/api/athlete/training-sessions")
                .then().extract().path("items[1].id");
        api(TENANT).body(Map.of("entries", List.of(Map.of("playerId", PLAYER, "status", "PRESENT"))))
                .put("/api/athlete/training-sessions/" + kept + "/attendance").then().statusCode(200);

        api(TENANT).delete("/api/athlete/training-schedules/" + schedule).then().statusCode(204);

        assertThat(sessionCount(TENANT, team)).isEqualTo(1);
        api(TENANT).get("/api/athlete/training-schedules/" + schedule).then().statusCode(404);
        api(TENANT).queryParam("teamId", team).get("/api/athlete/training-schedules").then().statusCode(200)
                .body("", hasSize(0));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void listFiltersByTeamAndActiveDate() {
        String team = "51000000-0000-4000-8000-0000000000c7";
        core.roster(TENANT, team);
        api(TENANT).body(Map.of("teamId", team, "dayOfWeek", "MONDAY", "startTime", "09:00", "durationMinutes", 60,
                "validFrom", "2031-01-01", "validUntil", "2031-06-30")).post("/api/athlete/training-schedules")
                .then().statusCode(201);

        api(TENANT).queryParam("teamId", team).queryParam("activeOn", "2031-03-01")
                .get("/api/athlete/training-schedules").then().statusCode(200).body("", hasSize(1));
        api(TENANT).queryParam("teamId", team).queryParam("activeOn", "2031-07-01")
                .get("/api/athlete/training-schedules").then().statusCode(200).body("", hasSize(0));
        lenient(TENANT).queryParam("activeOn", "not-a-date").get("/api/athlete/training-schedules")
                .then().statusCode(400);
        lenient(TENANT).queryParam("teamId", "nope").get("/api/athlete/training-schedules").then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void createValidatesBodyAndTeam() {
        lenient(TENANT).body(Map.of("teamId", TEAM, "dayOfWeek", "MONDAY", "startTime", "10:00", "durationMinutes", 10,
                "validFrom", "2030-01-01")).post("/api/athlete/training-schedules").then().statusCode(400);
        lenient(TENANT).body(Map.of("teamId", TEAM, "dayOfWeek", "MONDAY", "startTime", "10:00", "durationMinutes", 60,
                "validFrom", "2030-02-01", "validUntil", "2030-01-01")).post("/api/athlete/training-schedules")
                .then().statusCode(422).body("code", equalTo("INVALID_VALIDITY_RANGE"));
        lenient(TENANT).body(Map.of("dayOfWeek", "MONDAY")).post("/api/athlete/training-schedules").then().statusCode(400);

        String ghostTeam = "51000000-0000-4000-8000-0000000000ff";
        core.rosterNotFound(TENANT, ghostTeam);
        api(TENANT).body(schedule(ghostTeam, "MONDAY", "10:00")).post("/api/athlete/training-schedules")
                .then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = OTHER_TEAM)
    void coachOfAnotherTeamCannotWrite() {
        api(TENANT).body(schedule(TEAM, "MONDAY", "10:00")).post("/api/athlete/training-schedules")
                .then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT, linkedPlayers = PLAYER)
    void parentCannotWriteButReadsSchedulesOfTheirTeamOnly() {
        api(TENANT).body(schedule(TEAM, "MONDAY", "10:00")).post("/api/athlete/training-schedules")
                .then().statusCode(403);

        api(TENANT).queryParam("teamId", TEAM).get("/api/athlete/training-schedules").then().statusCode(200);
        api(TENANT).queryParam("teamId", OTHER_TEAM).get("/api/athlete/training-schedules").then().statusCode(404);
        lenient(TENANT).get("/api/athlete/training-schedules").then().statusCode(400);
    }

    @Test
    @TenantUser(tenant = OTHER_TENANT, roles = TenantRole.ADMIN)
    void aMemberOfAnotherTenantGetsNotFoundEverywhere() {
        // not a member of TENANT -> 404 on every resource
        api(TENANT).get("/api/athlete/training-schedules").then().statusCode(404);
        api(TENANT).body(schedule(TEAM, "MONDAY", "10:00")).post("/api/athlete/training-schedules").then().statusCode(404);
        api(TENANT).get("/api/athlete/training-sessions").then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = OTHER_TENANT, roles = TenantRole.ADMIN)
    void scheduleIdsOfAnotherTenantAreInvisibleUnderRls() {
        String foreign;
        {
            // create under TENANT with a different identity, then ask for it as OTHER_TENANT's admin
            com.hoopsacademy.athlete.support.ApiSupport.member(TENANT, java.util.Set.of(TenantRole.ADMIN), java.util.Set.of(),
                    java.util.Set.of(), null);
            foreign = createSchedule(TENANT, TEAM, "MONDAY", "08:00");
            com.hoopsacademy.athlete.support.ApiSupport.member(OTHER_TENANT, java.util.Set.of(TenantRole.ADMIN), java.util.Set.of(),
                    java.util.Set.of(), null);
        }

        api(OTHER_TENANT).get("/api/athlete/training-schedules/" + foreign).then().statusCode(404);
        api(OTHER_TENANT).body(Map.of("location", "x")).patch("/api/athlete/training-schedules/" + foreign).then().statusCode(404);
        api(OTHER_TENANT).delete("/api/athlete/training-schedules/" + foreign).then().statusCode(404);
    }

    @Test
    void anonymousIsUnauthorised() {
        lenient(TENANT).get("/api/athlete/training-schedules").then().statusCode(401);
    }
}
