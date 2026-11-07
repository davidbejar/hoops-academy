package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.formerStaff;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasItems;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import io.restassured.response.ValidatableResponse;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Season history in athlete (WP80, ADR-0042): the training data of a team whose season has ended is read-only; its
 * former staff see the whole attendance sheet and the health records of its players up to the season's last day.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class SeasonHistoryApiTest {

    static final String TENANT = "80000000-0000-4000-8000-000000000001";
    static final String PAST_TEAM = "80000000-0000-4000-8000-0000000000a1";
    static final String TEAM = "80000000-0000-4000-8000-0000000000a2";
    static final String P1 = "80000000-0000-4000-8000-0000000000b1";
    static final String P2 = "80000000-0000-4000-8000-0000000000b2";
    static final String SESSIONS = "/api/athlete/training-sessions";
    static final String ASSIGNMENTS = "/api/athlete/plan-assignments";
    static final String INJURIES = "/api/athlete/injuries";
    static final LocalDate TODAY = LocalDate.now(ZoneId.of("Europe/Madrid"));
    static final LocalDate LAST_DAY = TODAY.minusDays(30);

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        seasonOfThePastTeamEndsOn(null);
        core.roster(TENANT, TEAM, P2).knownPlayers(TENANT, P1, P2);
    }

    /** {@code null}: core sends no end (an open season, as an older core); otherwise the season's last day. */
    void seasonOfThePastTeamEndsOn(LocalDate lastDay) {
        rosterAdapter.clearCache();
        core.rosterOf(TENANT, PAST_TEAM, "Lions", List.<String[]>of(new String[] {P1, "Ana", "2012-05-01", "FEMALE",
                "ACTIVE"}), List.of(), lastDay);
    }

    String session() {
        member(TENANT, TenantRole.ADMIN);
        return api(TENANT).body(Map.of("teamId", PAST_TEAM, "startsAt", LAST_DAY.minusDays(7) + "T17:00:00Z",
                "durationMinutes", 90)).post(SESSIONS).then().statusCode(201).extract().path("id");
    }

    String teamAssignment() {
        member(TENANT, TenantRole.ADMIN);
        String plan = api(TENANT).body(Map.of("name", "Week 1", "items", List.of(Map.of("title", "Drill",
                "durationMinutes", 10)))).post("/api/athlete/training-plans").then().statusCode(201).extract().path("id");
        return api(TENANT).body(Map.of("planId", plan, "teamId", PAST_TEAM, "dueOn", LAST_DAY.toString()))
                .post(ASSIGNMENTS).then().statusCode(201).extract().path("id");
    }

    String injury(String player, LocalDate occurredOn) {
        member(TENANT, TenantRole.ADMIN);
        return api(TENANT).body(Map.of("playerId", player, "occurredOn", occurredOn.toString(), "bodyPart", "knee",
                "severity", "MINOR")).post(INJURIES).then().statusCode(201).extract().path("id");
    }

    static void seasonEnded(ValidatableResponse response) {
        response.statusCode(409).contentType("application/problem+json").body("code", equalTo("SEASON_ENDED"));
    }

    @Test
    void anAdminCannotChangeTheTrainingDataOfAnEndedSeason() {
        String session = session();
        String assignment = teamAssignment();
        seasonOfThePastTeamEndsOn(LAST_DAY);
        member(TENANT, TenantRole.ADMIN);

        seasonEnded(api(TENANT).body(Map.of("teamId", PAST_TEAM, "startsAt", TODAY + "T17:00:00Z",
                "durationMinutes", 60)).post(SESSIONS).then());
        seasonEnded(api(TENANT).body(Map.of("location", "Gym 2")).patch(SESSIONS + "/" + session).then());
        seasonEnded(api(TENANT).body(Map.of("reason", "rain")).post(SESSIONS + "/" + session + "/cancel").then());
        seasonEnded(api(TENANT).body(Map.of("entries", List.of(Map.of("playerId", P1, "status", "PRESENT"))))
                .put(SESSIONS + "/" + session + "/attendance").then());
        seasonEnded(api(TENANT).body(Map.of("teamId", PAST_TEAM, "dayOfWeek", "MONDAY", "startTime", "17:00",
                "durationMinutes", 60, "validFrom", TODAY.toString())).post("/api/athlete/training-schedules").then());
        seasonEnded(api(TENANT).delete(ASSIGNMENTS + "/" + assignment).then());
        seasonEnded(api(TENANT).body(Map.of("status", "DONE")).put(ASSIGNMENTS + "/" + assignment + "/completions/" + P1)
                .then());

        api(TENANT).get(SESSIONS + "/" + session).then().statusCode(200).body("status", equalTo("PLANNED"));
        api(TENANT).get(SESSIONS + "/" + session + "/attendance").then().statusCode(200).body("entries", hasSize(1));
    }

    @Test
    void theFormerCoachSeesTheWholeSheetButGetsTheConflictOnWrites() {
        String session = session();
        seasonOfThePastTeamEndsOn(LAST_DAY);
        formerStaff(TENANT, TenantRole.COACH, Set.of(TEAM), Set.of(PAST_TEAM));

        api(TENANT).get(SESSIONS + "/" + session + "/attendance").then().statusCode(200)
                .body("entries.playerId", contains(P1));
        seasonEnded(api(TENANT).body(Map.of("entries", List.of(Map.of("playerId", P1, "status", "PRESENT"))))
                .put(SESSIONS + "/" + session + "/attendance").then());
        seasonEnded(api(TENANT).body(Map.of("location", "Gym 2")).patch(SESSIONS + "/" + session).then());
    }

    @Test
    void aCoachNeverOnTheTeamKeepsTodaysAnswers() {
        String session = session();
        seasonOfThePastTeamEndsOn(LAST_DAY);
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);

        api(TENANT).get(SESSIONS + "/" + session + "/attendance").then().statusCode(403);
        api(TENANT).body(Map.of("entries", List.of(Map.of("playerId", P1, "status", "PRESENT"))))
                .put(SESSIONS + "/" + session + "/attendance").then().statusCode(403);
    }

    @Test
    void theFormerCoachReadsThePlayersHealthRecordsUpToTheSeasonsLastDayOnly() {
        String during = injury(P1, LAST_DAY.minusDays(10));
        String onLastDay = injury(P1, LAST_DAY);
        String after = injury(P1, LAST_DAY.plusDays(1));
        seasonOfThePastTeamEndsOn(LAST_DAY);
        formerStaff(TENANT, TenantRole.COACH, Set.of(TEAM), Set.of(PAST_TEAM));

        api(TENANT).get(INJURIES + "/" + during).then().statusCode(200);
        api(TENANT).get(INJURIES + "/" + onLastDay).then().statusCode(200);
        api(TENANT).get(INJURIES + "/" + after).then().statusCode(404);
        api(TENANT).queryParam("teamId", PAST_TEAM).get(INJURIES).then().statusCode(200)
                .body("items.id", hasItems(during, onLastDay)).body("items.id", not(hasItem(after)));
        api(TENANT).get(INJURIES).then().statusCode(200).body("items", hasSize(0));
        api(TENANT).queryParam("playerId", P1).queryParam("from", LAST_DAY.minusDays(60).toString())
                .get("/api/athlete/body-measurements").then().statusCode(200);
        seasonEnded(api(TENANT).body(Map.of("bodyPart", "ankle")).patch(INJURIES + "/" + during).then());
        seasonEnded(api(TENANT).body(Map.of("playerId", P1, "occurredOn", TODAY.toString(), "bodyPart", "knee",
                "severity", "MINOR")).post(INJURIES).then());
    }

    @Test
    void theFormerCoachSeesTheMeasurementsUpToTheSeasonsLastDay() {
        member(TENANT, TenantRole.ADMIN);
        for (LocalDate day : List.of(LAST_DAY.minusDays(5), LAST_DAY.plusDays(5))) {
            api(TENANT).body(Map.of("playerId", P1, "measuredOn", day.toString(), "heightCm", 150))
                    .post("/api/athlete/body-measurements").then().statusCode(201);
        }
        seasonOfThePastTeamEndsOn(LAST_DAY);
        formerStaff(TENANT, TenantRole.ASSISTANT_COACH, Set.of(), Set.of(PAST_TEAM));

        api(TENANT).queryParam("playerId", P1).get("/api/athlete/body-measurements").then().statusCode(200)
                .body("measuredOn", contains(LAST_DAY.minusDays(5).toString()));
    }

    @Test
    void aCoachNeverOnTheTeamCannotReadThePlayersHealthRecords() {
        String during = injury(P1, LAST_DAY.minusDays(10));
        seasonOfThePastTeamEndsOn(LAST_DAY);
        member(TENANT, Set.of(TenantRole.COACH), Set.of(TEAM), Set.of(), null);

        api(TENANT).get(INJURIES + "/" + during).then().statusCode(404);
        api(TENANT).queryParam("teamId", PAST_TEAM).get(INJURIES).then().statusCode(200).body("items", hasSize(0));
    }
}
