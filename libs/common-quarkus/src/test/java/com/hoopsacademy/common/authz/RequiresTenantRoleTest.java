package com.hoopsacademy.common.authz;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.specification.RequestSpecification;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class RequiresTenantRoleTest {

    static final String TENANT = "0c000000-0000-4000-8000-00000000000c";
    static final String TEAM = "1e000000-0000-4000-8000-000000000001";
    static final String CHILD = "2e000000-0000-4000-8000-000000000002";
    static final String SELF = "3e000000-0000-4000-8000-000000000003";
    private static final String BASE = "/api/probe/authz/";

    private static RequestSpecification inTenant() {
        return given().header("X-Tenant-Id", TENANT);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ASSISTANT_COACH)
    void classLevelRolesUseAnyOfSemantics() {
        inTenant().get(BASE + "staff-area").then().statusCode(200);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT)
    void missingRoleIsForbiddenProblem() {
        inTenant().get(BASE + "staff-area").then()
                .statusCode(403)
                .contentType("application/problem+json")
                .body("type", equalTo("urn:hoops:problem:forbidden"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void methodLevelRolesOverrideClassLevel() {
        inTenant().get(BASE + "admin-only").then().statusCode(403);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = {TenantRole.ADMIN, TenantRole.COACH})
    void unionOfRolesGrantsAccess() {
        inTenant().get(BASE + "admin-only").then().statusCode(200);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffOfTeamPassesFineGrainedCheck() {
        inTenant().get(BASE + "teams/" + TEAM).then().statusCode(200);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void staffOfAnotherTeamIsForbidden() {
        inTenant().get(BASE + "teams/" + CHILD).then()
                .statusCode(403)
                .body("detail", equalTo("Not staff of this team"));
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT, linkedPlayers = CHILD)
    void guardianPassesForLinkedPlayer() {
        inTenant().get(BASE + "players/" + CHILD).then().statusCode(200);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PLAYER, ownPlayer = SELF)
    void playerPassesForSelfOnly() {
        inTenant().get(BASE + "players/" + SELF).then().statusCode(200);
        inTenant().get(BASE + "players/" + CHILD).then().statusCode(403);
    }
}
