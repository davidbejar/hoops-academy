package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;
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
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Attaching a plan to a session: the plan must exist, the session counts as edited, deleting the plan detaches it. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class SessionPlanApiTest {

    static final String TENANT = "61000000-0000-4000-8000-000000000001";
    static final String TEAM = "61000000-0000-4000-8000-0000000000a1";
    static final String SESSIONS = "/api/athlete/training-sessions";
    static final String PLANS = "/api/athlete/training-plans";
    static final ZoneId ZONE = ZoneId.of("Europe/Madrid");

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
        core.roster(TENANT, TEAM, "61000000-0000-4000-8000-0000000000b1");
    }

    String plan(String name) {
        return api(TENANT).body(Map.of("name", name)).post(PLANS).then().statusCode(201).extract().path("id");
    }

    String adHoc(Object planId) {
        var body = new java.util.HashMap<String, Object>(
                Map.of("teamId", TEAM, "startsAt", "2027-09-07T17:00:00Z", "durationMinutes", 60));
        if (planId != null) {
            body.put("planId", planId);
        }
        return lenient(TENANT).body(body).post(SESSIONS).then().extract().path("id");
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void aSessionCanCarryAnExistingPlanOrATemplate() {
        String own = plan("Shooting day");
        String template = api(TENANT).queryParam("template", true).queryParam("q", "Form").get(PLANS)
                .then().extract().path("items[0].id");

        api(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2027-09-07T17:00:00Z", "durationMinutes", 60, "planId", own))
                .post(SESSIONS).then().statusCode(201).body("planId", equalTo(own));
        String session = adHoc(null);
        api(TENANT).body(Map.of("planId", template)).patch(SESSIONS + "/" + session).then().statusCode(200)
                .body("planId", equalTo(template));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void anUnknownPlanIsRejected() {
        String ghost = UUID.randomUUID().toString();
        String session = adHoc(null);

        api(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2027-09-08T17:00:00Z", "durationMinutes", 60, "planId", ghost))
                .post(SESSIONS).then().statusCode(404);
        api(TENANT).body(Map.of("planId", ghost)).patch(SESSIONS + "/" + session).then().statusCode(404);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void deletingAPlanDetachesItFromSessions() {
        String doomed = plan("Doomed");
        String session = adHoc(doomed);
        api(TENANT).get(SESSIONS + "/" + session).then().body("planId", equalTo(doomed));

        api(TENANT).delete(PLANS + "/" + doomed).then().statusCode(204);

        api(TENANT).get(SESSIONS + "/" + session).then().statusCode(200).body("planId", nullValue());
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = {TEAM, "61000000-0000-4000-8000-0000000000c1"})
    void aMaterialisedSessionWithAPlanSurvivesAReplan() {
        String team = "61000000-0000-4000-8000-0000000000c1";
        core.roster(TENANT, team);
        String schedule = api(TENANT).body(Map.of("teamId", team, "dayOfWeek", "MONDAY", "startTime", "17:00",
                "durationMinutes", 90, "validFrom", LocalDate.now(ZONE).toString()))
                .post("/api/athlete/training-schedules").then().statusCode(201).extract().path("id");
        LocalDate today = LocalDate.now(ZONE);
        List<String> ids = api(TENANT).queryParam("teamId", team).queryParam("from", today.toString())
                .queryParam("to", today.plusDays(60).toString()).get(SESSIONS).then().extract().path("items.id");
        String withPlan = ids.get(3);
        String plan = plan("Week 4 plan");
        api(TENANT).body(Map.of("planId", plan)).patch(SESSIONS + "/" + withPlan).then().statusCode(200);

        api(TENANT).body(Map.of("dayOfWeek", "FRIDAY")).patch("/api/athlete/training-schedules/" + schedule)
                .then().statusCode(200);

        List<String> after = api(TENANT).queryParam("teamId", team).queryParam("from", today.toString())
                .queryParam("to", today.plusDays(60).toString()).queryParam("size", 200).get(SESSIONS)
                .then().extract().path("items.id");
        assertThat(after).contains(withPlan);
        api(TENANT).get(SESSIONS + "/" + withPlan).then().body("planId", equalTo(plan));
    }
}
