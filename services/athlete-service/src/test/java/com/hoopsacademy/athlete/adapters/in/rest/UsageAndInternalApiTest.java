package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.lenient;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.notNullValue;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUserRegistry;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import jakarta.inject.Inject;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class UsageAndInternalApiTest {

    static final String TENANT = "57000000-0000-4000-8000-000000000001";
    static final String EMPTY_TENANT = "57000000-0000-4000-8000-000000000002";
    static final String TEAM = "57000000-0000-4000-8000-0000000000a1";
    static final String PLAYER = "57000000-0000-4000-8000-0000000000b1";

    @Inject CoreRosterAdapter rosterAdapter;

    @BeforeEach
    void setUp() {
        new CoreStubs().reset().roster(TENANT, TEAM, PLAYER).knownPlayers(TENANT, PLAYER);
        rosterAdapter.clearCache();
    }

    @Test
    @TestSecurity(user = "tenant-user", roles = "service")
    @OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
    void usageCountsTheTenantsDataOnly() {
        com.hoopsacademy.athlete.support.ApiSupport.member(TENANT, TenantRole.ADMIN);
        String session = api(TENANT).body(Map.of("teamId", TEAM, "startsAt", "2029-01-02T17:00:00Z", "durationMinutes", 60))
                .post("/api/athlete/training-sessions").then().statusCode(201).extract().path("id");
        api(TENANT).body(Map.of("entries", List.of(Map.of("playerId", PLAYER, "status", "PRESENT"))))
                .put("/api/athlete/training-sessions/" + session + "/attendance").then().statusCode(200);
        api(TENANT).body(Map.of("playerId", PLAYER, "fromDate", "2029-01-02", "toDate", "2029-01-03"))
                .post("/api/athlete/planned-absences").then().statusCode(201);
        String plan = api(TENANT).body(Map.of("name", "Usage plan")).post("/api/athlete/training-plans")
                .then().statusCode(201).extract().path("id");
        api(TENANT).body(Map.of("planId", plan, "teamId", TEAM, "dueOn", "2029-02-01")).post("/api/athlete/plan-assignments")
                .then().statusCode(201);
        api(TENANT).body(Map.of("playerId", PLAYER, "occurredOn", "2029-01-02", "bodyPart", "knee", "severity", "MINOR"))
                .post("/api/athlete/injuries").then().statusCode(201);
        api(TENANT).body(Map.of("playerId", PLAYER, "measuredOn", "2029-01-02", "heightCm", 150.0))
                .post("/api/athlete/body-measurements").then().statusCode(201);
        api(TENANT).body(Map.of("playerId", PLAYER, "measuredOn", "2029-01-02", "heightCm", 151.0))
                .post("/api/athlete/body-measurements").then().statusCode(409);
        String cooper = api(TENANT).get("/api/athlete/physical-test-types").then().extract().path("find { it.code == 'COOPER_12MIN' }.id");
        api(TENANT).body(Map.of("playerId", PLAYER, "testTypeId", cooper, "measuredOn", "2029-01-02", "value", 2000.0))
                .post("/api/athlete/physical-test-results").then().statusCode(201);
        TenantUserRegistry.clear();

        api(TENANT).get("/internal/usage/" + TENANT).then().statusCode(200)
                .body("tenantId", equalTo(TENANT))
                .body("service", equalTo("athlete"))
                .body("collectedAt", notNullValue())
                .body("counters.trainingSessions", greaterThanOrEqualTo(1))
                .body("counters.attendanceRecords", equalTo(1))
                .body("counters.plannedAbsences", equalTo(1))
                .body("counters.trainingPlans", equalTo(1))
                .body("counters.planAssignments", equalTo(1))
                .body("counters.injuries", equalTo(1))
                .body("counters.bodyMeasurements", equalTo(1))
                .body("counters.physicalTestResults", equalTo(1));
        api(EMPTY_TENANT).get("/internal/usage/" + EMPTY_TENANT).then().statusCode(200)
                .body("counters.trainingSessions", equalTo(0))
                .body("counters.attendanceRecords", equalTo(0))
                .body("counters.trainingPlans", equalTo(0))
                .body("counters.injuries", equalTo(0))
                .body("counters.bodyMeasurements", equalTo(0))
                .body("counters.physicalTestResults", equalTo(0));
    }

    @Test
    @TestSecurity(user = "svc", roles = "service")
    void serviceRoleMayCallAndMalformedTenantIsA400() {
        lenient(TENANT).get("/internal/usage/not-a-uuid").then().statusCode(400);
        api(TENANT).get("/internal/usage/" + EMPTY_TENANT).then().statusCode(200);
    }

    @Test
    @TestSecurity(user = "someone", roles = "ADMIN")
    void withoutTheServiceRoleItIs403() {
        lenient(TENANT).get("/internal/usage/" + TENANT).then().statusCode(403);
    }

    @Test
    void anonymousIs401() {
        lenient(TENANT).get("/internal/usage/" + TENANT).then().statusCode(401);
    }
}
