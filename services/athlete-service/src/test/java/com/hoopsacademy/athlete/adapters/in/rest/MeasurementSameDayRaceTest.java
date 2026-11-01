package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.api;
import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static org.hamcrest.Matchers.equalTo;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doReturn;

import com.hoopsacademy.athlete.adapters.out.client.CoreRosterAdapter;
import com.hoopsacademy.athlete.application.MeasurementRepository;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.mockito.InjectSpy;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import jakarta.inject.Inject;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Two simultaneous creates for the same player and day both pass the "free day" check; the loser then hits the
 * {@code unique (tenant_id, player_id, measured_on)} constraint. The race is made deterministic by letting the
 * existence check always answer "free": the database constraint must still produce the 409 Problem, not a 500.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class MeasurementSameDayRaceTest {

    static final String TENANT = "67000000-0000-4000-8000-000000000071";
    static final String TEAM = "67000000-0000-4000-8000-0000000000a7";
    static final String PLAYER = "67000000-0000-4000-8000-0000000000b7";
    static final String M = "/api/athlete/body-measurements";

    @Inject CoreRosterAdapter rosterAdapter;
    @InjectSpy MeasurementRepository measurements;

    @BeforeEach
    void setUp() {
        new CoreStubs().reset().roster(TENANT, TEAM, PLAYER).knownPlayers(TENANT, PLAYER);
        rosterAdapter.clearCache();
        member(TENANT, TenantRole.ADMIN);
        doReturn(false).when(measurements).existsOn(any(), any(), any());
    }

    @Test
    void theLoserOfASameDayRaceGetsTheConflictProblem() {
        String body = "{\"playerId\":\"%s\",\"measuredOn\":\"2027-05-02\",\"heightCm\":150.0}".formatted(PLAYER);
        api(TENANT).body(body).post(M).then().statusCode(201);

        api(TENANT).body(body).post(M).then()
                .statusCode(409)
                .contentType("application/problem+json")
                .body("type", equalTo("urn:hoops:problem:conflict"))
                .body("code", equalTo("MEASUREMENT_EXISTS_FOR_DATE"));
    }

    @Test
    void theLoserOfASameDayRaceOnACorrectionGetsTheConflictProblemToo() {
        api(TENANT).body("{\"playerId\":\"%s\",\"measuredOn\":\"2027-06-01\",\"weightKg\":40.0}".formatted(PLAYER))
                .post(M).then().statusCode(201);
        String second = api(TENANT)
                .body("{\"playerId\":\"%s\",\"measuredOn\":\"2027-06-02\",\"weightKg\":40.5}".formatted(PLAYER))
                .post(M).then().statusCode(201).extract().path("id");

        api(TENANT).body("{\"measuredOn\":\"2027-06-01\"}").patch(M + "/" + second).then()
                .statusCode(409)
                .body("code", equalTo("MEASUREMENT_EXISTS_FOR_DATE"));
    }
}
