package com.hoopsacademy.common.tenancy;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

/** Internal endpoints get the tenant as a query parameter and use TenantScope.runAs inside the HTTP request. */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class InternalTenantScopeTest {

    private static final String TENANT = "0d000000-0000-4000-8000-00000000000d";

    @Test
    void runAsWorksInsideAnInternalRequestAndLeavesNothingBound() {
        given().queryParam("tenantId", TENANT).get("/internal/probe/tenant-setting").then()
                .statusCode(200)
                .body(equalTo(TENANT + "|bound-after=false"));
    }

    @Test
    void malformedTenantParameterIsBadRequestProblem() {
        given().queryParam("tenantId", "acme").get("/internal/probe/tenant-setting").then()
                .statusCode(400)
                .contentType("application/problem+json")
                .body("type", equalTo("urn:hoops:problem:bad-request"))
                .body("detail", equalTo("Invalid tenant id: not a canonical UUID"));
    }
}
