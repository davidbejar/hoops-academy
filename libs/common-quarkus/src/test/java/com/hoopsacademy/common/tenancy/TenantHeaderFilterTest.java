package com.hoopsacademy.common.tenancy;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class TenantHeaderFilterTest {

    static final String TENANT_A = "0a000000-0000-4000-8000-00000000000a";
    static final String TENANT_B = "0b000000-0000-4000-8000-00000000000b";
    private static final String WHOAMI = "/api/probe/whoami";

    @Test
    @TenantUser(tenant = TENANT_A, roles = {TenantRole.COACH, TenantRole.PARENT})
    void memberGetsContextPopulated() {
        given().header("X-Tenant-Id", TENANT_A).get(WHOAMI).then()
                .statusCode(200)
                .body("tenantId", equalTo(TENANT_A))
                .body("subject", equalTo(TenantUser.SUBJECT))
                .body("roles", containsInAnyOrder("COACH", "PARENT"));
    }

    @Test
    @TenantUser(tenant = TENANT_A, roles = TenantRole.COACH)
    void theBoundTenantIsInTheLoggingMdcOfTheRequest() {
        given().header("X-Tenant-Id", TENANT_A).get("/api/probe/mdc").then()
                .statusCode(200)
                .body(equalTo(TENANT_A));
    }

    @Test
    @TenantUser(tenant = TENANT_A)
    void missingHeaderIsBadRequest() {
        given().get(WHOAMI).then()
                .statusCode(400)
                .contentType("application/problem+json")
                .body("type", equalTo("urn:hoops:problem:bad-request"))
                .body("detail", equalTo("Header X-Tenant-Id is required"))
                .body("instance", equalTo(WHOAMI));
    }

    @Test
    @TenantUser(tenant = TENANT_A)
    void malformedHeaderIsBadRequest() {
        given().header("X-Tenant-Id", "acme' or 1=1").get(WHOAMI).then()
                .statusCode(400)
                .contentType("application/problem+json")
                .body("detail", equalTo("Header X-Tenant-Id must be a UUID"));
    }

    @Test
    @TenantUser(tenant = TENANT_B, roles = TenantRole.ADMIN)
    void nonMemberGetsNotFoundNeverForbidden() {
        given().header("X-Tenant-Id", TENANT_A).get(WHOAMI).then()
                .statusCode(404)
                .contentType("application/problem+json")
                .body("type", equalTo("urn:hoops:problem:not-found"));
    }

    @Test
    @TestSecurity(user = "super-admin", roles = "super_admin")
    void superAdminWithoutMembershipGetsNotFound() {
        given().header("X-Tenant-Id", TENANT_A).get(WHOAMI).then().statusCode(404);
    }

    @Test
    void unauthenticatedIsUnauthorized() {
        given().header("X-Tenant-Id", TENANT_A).get(WHOAMI).then()
                .statusCode(401)
                .contentType("application/problem+json");
    }

    @Test
    @TestSecurity(user = "super-admin", roles = "super_admin")
    void platformPathsAreSkipped() {
        given().get("/platform/probe/ping").then().statusCode(200).body(equalTo("tenant-bound=false"));
    }

    @Test
    void internalPathsAreSkipped() {
        given().get("/internal/probe/ping").then().statusCode(200).body(equalTo("tenant-bound=false"));
    }

    @Test
    void onlyTheApiSegmentIsTenantScoped() {
        given().get("/apiary/probe/ping").then().statusCode(200).body(equalTo("tenant-bound=false"));
    }

    @Test
    @TestSecurity(user = "someone")
    void anExemptApiPathNeedsNoTenantHeader() {
        given().get("/api/probe/me").then().statusCode(200).body(equalTo("tenant-bound=false"));
        given().get("/api/probe/me/").then().statusCode(200).body(equalTo("tenant-bound=false"));
    }

    @Test
    void anExemptApiPathStillRequiresAuthentication() {
        given().get("/api/probe/me").then()
                .statusCode(401)
                .contentType("application/problem+json");
    }

    @Test
    @TestSecurity(user = "someone")
    void theExemptionIsForTheExactPathOnly() {
        given().get("/api/probe/me/details").then()
                .statusCode(400)
                .body("detail", equalTo("Header X-Tenant-Id is required"));
    }

    @Test
    void exemptPathsComeFromConfigurationAndAreNormalised() {
        TenantScopedPaths paths = new TenantScopedPaths(java.util.List.of(" /api/core/me/ ", "api/x"));

        org.assertj.core.api.Assertions.assertThat(paths.isTenantScoped("/api/core/me")).isFalse();
        org.assertj.core.api.Assertions.assertThat(paths.isTenantScoped("api/x/")).isFalse();
        org.assertj.core.api.Assertions.assertThat(paths.isTenantScoped("/api/core/members")).isTrue();
        org.assertj.core.api.Assertions.assertThat(paths.isTenantScoped("/api")).isTrue();
        org.assertj.core.api.Assertions.assertThat(paths.isTenantScoped("/platform/x")).isFalse();
    }
}
