package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.RealResolverProfile;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** The tenant filter backed by core's own tables: roles from membership_role, tenant status, deactivation. */
@QuarkusTest
@TestProfile(RealResolverProfile.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class RealAuthzResolverTest {

    static final String SUB = "real-resolver-user";
    private static final String PROFILE = "/api/core/tenant";

    private String tenant;
    private UUID personId;

    @BeforeEach
    void memberOfAFreshTenant() {
        tenant = UUID.randomUUID().toString();
        CoreDb.tenant(tenant);
        personId = CoreDb.person(tenant, CoreDb.login(SUB), "Rita", "Real", null, null, null, TenantRole.COACH);
    }

    @Test
    @TestSecurity(user = SUB)
    void activeMemberIsResolvedFromTheDatabase() {
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(PROFILE).then().statusCode(200)
                .body("id", equalTo(tenant));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"name\":\"Coach cannot rename\"}").patch(PROFILE).then().statusCode(403);
    }

    @Test
    @TestSecurity(user = SUB)
    void suspendedAndWithdrawnTenantsAnswerNotFound() {
        setStatus("SUSPENDED");
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(PROFILE).then().statusCode(404);
        setStatus("WITHDRAWN");
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(PROFILE).then().statusCode(404);
        setStatus("ACTIVE");
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(PROFILE).then().statusCode(200);
    }

    @Test
    @TestSecurity(user = SUB)
    void deactivatedMemberIsNotAMember() {
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.person set active = false where id = ?", personId));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(PROFILE).then().statusCode(404);
    }

    @Test
    @TestSecurity(user = "platform-admin", roles = "super_admin")
    void superAdminWithoutMembershipGetsNotFound() {
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(PROFILE).then().statusCode(404);
    }

    @Test
    @TestSecurity(user = SUB)
    void unknownTenantIsNotFound() {
        given().filter(Contract.CORE).header("X-Tenant-Id", UUID.randomUUID().toString()).get(PROFILE)
                .then().statusCode(404);
    }

    private void setStatus(String status) {
        CoreDb.inTenant(null, c -> CoreDb.update(c, "update core.tenant set status = ? where id = ?::uuid", status, tenant));
    }
}
