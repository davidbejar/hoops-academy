package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
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
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class AttendanceApiTest {

    static final String TENANT = "53000000-0000-4000-8000-000000000001";
    static final String TEAM = "53000000-0000-4000-8000-0000000000a1";
    static final String OTHER_TEAM = "53000000-0000-4000-8000-0000000000a2";
    static final String P1 = "53000000-0000-4000-8000-0000000000b1";
    static final String P2 = "53000000-0000-4000-8000-0000000000b2";
    static final String P3 = "53000000-0000-4000-8000-0000000000b3";
    static final String STRANGER = "53000000-0000-4000-8000-0000000000b9";
    static final String SESSIONS = "/api/athlete/training-sessions/";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, P1, P2, P3).roster(TENANT, OTHER_TEAM, STRANGER).knownPlayers(TENANT, P1, P2, P3, STRANGER);
    }

    /** An ad-hoc session created as an administrator; leaves the registry holding the admin membership. */
    String session(String team, String startsAt) {
        member(TENANT, TenantRole.ADMIN);
        return api(TENANT).body(Map.of("teamId", team, "startsAt", startsAt, "durationMinutes", 90))
                .post("/api/athlete/training-sessions").then().statusCode(201).extract().path("id");
    }

    static Map<String, Object> mark(String player, String status) {
        return Map.of("playerId", player, "status", status);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void sheetListsTheWholeRosterWithEmptyStatuses() {
        String id = session(TEAM, "2027-03-02T17:00:00Z");
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);

        api(TENANT).get(SESSIONS + id + "/attendance").then().statusCode(200)
                .body("sessionId", equalTo(id))
                .body("entries", hasSize(3))
                .body("entries.status", org.hamcrest.Matchers.everyItem(nullValue()))
                .body("entries.expectedAbsent", org.hamcrest.Matchers.everyItem(equalTo(false)));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffRecordsAttendanceAndItIsUpserted() {
        String id = session(TEAM, "2027-03-09T17:00:00Z");
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);

        api(TENANT).body(Map.of("entries", List.of(
                        mark(P1, "PRESENT"),
                        Map.of("playerId", P2, "status", "LATE", "minutesLate", 12, "note", "bus"))))
                .put(SESSIONS + id + "/attendance").then().statusCode(200)
                .body("entries.find { it.playerId == '%s' }.status".formatted(P1), equalTo("PRESENT"))
                .body("entries.find { it.playerId == '%s' }.minutesLate".formatted(P2), equalTo(12))
                .body("entries.find { it.playerId == '%s' }.note".formatted(P2), equalTo("bus"))
                .body("entries.find { it.playerId == '%s' }.recordedBy.personId".formatted(P1), notNullValue())
                .body("entries.find { it.playerId == '%s' }.status".formatted(P3), nullValue());

        // second PUT only touches the listed players
        api(TENANT).body(Map.of("entries", List.of(mark(P2, "ABSENT")))).put(SESSIONS + id + "/attendance")
                .then().statusCode(200)
                .body("entries.find { it.playerId == '%s' }.status".formatted(P2), equalTo("ABSENT"))
                .body("entries.find { it.playerId == '%s' }.minutesLate".formatted(P2), nullValue())
                .body("entries.find { it.playerId == '%s' }.status".formatted(P1), equalTo("PRESENT"));
        api(TENANT).get(SESSIONS + id + "/attendance").then().body("entries.status.findAll { it != null }", hasSize(2));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void plannedAbsencesOverlayTheSheetAsExpectedAbsent() {
        String id = session(TEAM, "2027-03-16T17:00:00Z");
        member(TENANT, Set.of(TenantRole.ADMIN), Set.of(), Set.of(), null);
        String absenceId = api(TENANT).body(Map.of("playerId", P3, "fromDate", "2027-03-15", "toDate", "2027-03-17",
                "reason", "exams")).post("/api/athlete/planned-absences").then().statusCode(201).extract().path("id");
        api(TENANT).body(Map.of("playerId", P1, "fromDate", "2027-03-17", "toDate", "2027-03-18"))
                .post("/api/athlete/planned-absences").then().statusCode(201);
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);

        api(TENANT).get(SESSIONS + id + "/attendance").then().statusCode(200)
                .body("entries.find { it.playerId == '%s' }.expectedAbsent".formatted(P3), equalTo(true))
                .body("entries.find { it.playerId == '%s' }.plannedAbsenceId".formatted(P3), equalTo(absenceId))
                .body("entries.find { it.playerId == '%s' }.expectedAbsent".formatted(P1), equalTo(false))
                .body("entries.find { it.playerId == '%s' }.expectedAbsent".formatted(P2), equalTo(false));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void minutesLateRulesAndRosterMembershipAreEnforced() {
        String id = session(TEAM, "2027-03-23T17:00:00Z");
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);

        api(TENANT).body(Map.of("entries", List.of(mark(P1, "LATE")))).put(SESSIONS + id + "/attendance")
                .then().statusCode(422).body("code", equalTo("MINUTES_LATE_REQUIRED"));
        api(TENANT).body(Map.of("entries", List.of(Map.of("playerId", P1, "status", "PRESENT", "minutesLate", 5))))
                .put(SESSIONS + id + "/attendance").then().statusCode(422).body("code", equalTo("MINUTES_LATE_NOT_ALLOWED"));
        api(TENANT).body(Map.of("entries", List.of(mark(STRANGER, "PRESENT")))).put(SESSIONS + id + "/attendance")
                .then().statusCode(422).body("code", equalTo("PLAYER_NOT_IN_TEAM"));
        lenient(TENANT).body(Map.of("entries", List.of())).put(SESSIONS + id + "/attendance").then().statusCode(400);
        lenient(TENANT).body(Map.of("entries", List.of(mark(P1, "SICK")))).put(SESSIONS + id + "/attendance").then().statusCode(400);
        // nothing was stored by the failed calls
        api(TENANT).get(SESSIONS + id + "/attendance").then().body("entries.status.findAll { it != null }", hasSize(0));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void cancelledSessionsRefuseAttendance() {
        String id = session(TEAM, "2027-03-30T17:00:00Z");
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);
        api(TENANT).body(Map.of("reason", "snow")).post(SESSIONS + id + "/cancel").then().statusCode(200);

        api(TENANT).body(Map.of("entries", List.of(mark(P1, "PRESENT")))).put(SESSIONS + id + "/attendance")
                .then().statusCode(409);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = OTHER_TEAM)
    void staffOfAnotherTeamCannotRecordOrSeeTheSheet() {
        String id = session(TEAM, "2027-04-06T17:00:00Z");
        member(TENANT, Set.of(TenantRole.COACH), Set.of(OTHER_TEAM), Set.of(), null);

        api(TENANT).body(Map.of("entries", List.of(mark(P1, "PRESENT")))).put(SESSIONS + id + "/attendance")
                .then().statusCode(403);
        api(TENANT).get(SESSIONS + id + "/attendance").then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT, linkedPlayers = P1)
    void parentSeesOnlyTheEntryOfTheirChildAndCannotRecord() {
        String id = session(TEAM, "2027-04-13T17:00:00Z");
        member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(P1), null);

        api(TENANT).get(SESSIONS + id + "/attendance").then().statusCode(200)
                .body("entries", hasSize(1)).body("entries[0].playerId", equalTo(P1));
        api(TENANT).body(Map.of("entries", List.of(mark(P1, "PRESENT")))).put(SESSIONS + id + "/attendance")
                .then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT, linkedPlayers = STRANGER)
    void parentOfAPlayerFromAnotherTeamGetsNotFound() {
        String id = session(TEAM, "2027-04-20T17:00:00Z");
        member(TENANT, Set.of(TenantRole.PARENT), Set.of(), Set.of(STRANGER), null);

        api(TENANT).get(SESSIONS + id + "/attendance").then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PLAYER, ownPlayer = P2)
    void playerSeesOnlyTheirOwnEntry() {
        String id = session(TEAM, "2027-04-27T17:00:00Z");
        member(TENANT, Set.of(TenantRole.PLAYER), Set.of(), Set.of(), P2);

        api(TENANT).get(SESSIONS + id + "/attendance").then().statusCode(200)
                .body("entries", hasSize(1)).body("entries[0].playerId", equalTo(P2));
        api(TENANT).body(Map.of("entries", List.of(mark(P2, "PRESENT")))).put(SESSIONS + id + "/attendance")
                .then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void unknownSessionIsNotFound() {
        api(TENANT).get(SESSIONS + UUID.randomUUID() + "/attendance").then().statusCode(404);
        api(TENANT).body(Map.of("entries", List.of(mark(P1, "PRESENT")))).put(SESSIONS + UUID.randomUUID() + "/attendance")
                .then().statusCode(404);
    }
}
