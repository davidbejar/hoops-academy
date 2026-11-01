package com.hoopsacademy.athlete.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** When core-service fails or is slow, the API answers 503 Problem with code UPSTREAM_UNAVAILABLE (not in the contract's response set). */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class UpstreamFailureApiTest {

    static final String TENANT = "58000000-0000-4000-8000-000000000001";
    static final String TEAM = "58000000-0000-4000-8000-0000000000a1";

    @Inject CoreRosterAdapter rosterAdapter;
    CoreStubs core;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        rosterAdapter.clearCache();
    }

    private io.restassured.specification.RequestSpecification request() {
        return given().header("X-Tenant-Id", TENANT).header("Content-Type", "application/json");
    }

    private static final String BODY = """
            {"teamId":"%s","dayOfWeek":"MONDAY","startTime":"18:00","durationMinutes":60,"validFrom":"2030-01-01"}
            """.formatted(TEAM);

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void coreErrorIs503WithProblemJson() {
        core.rosterFails(TENANT, TEAM, 500);

        request().body(BODY).post("/api/athlete/training-schedules").then().statusCode(503)
                .contentType("application/problem+json")
                .body("code", equalTo("UPSTREAM_UNAVAILABLE"))
                .body("status", equalTo(503))
                .body("type", equalTo("urn:hoops:problem:upstream-unavailable"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void coreTimeoutIs503() {
        core.rosterDelayed(TENANT, TEAM, 4_000);

        request().body(BODY).post("/api/athlete/training-schedules").then().statusCode(503)
                .body("code", equalTo("UPSTREAM_UNAVAILABLE"));
    }
}
