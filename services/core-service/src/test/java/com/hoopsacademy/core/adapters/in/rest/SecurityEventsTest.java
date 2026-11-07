package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.SecurityEventCapture;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import org.junit.jupiter.api.Test;

/**
 * ADR-0043 through core's real endpoints and its database-backed membership resolver: a caller of another academy
 * and a member without the role are one {@code hoops.security} event each, counted in
 * {@code hoops_authz_denied_total}.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class SecurityEventsTest {

    @Test
    void aCallerOfAnotherAcademyIsANotMemberEvent() {
        Members.signIn(Members.newTenant(), TenantRole.ADMIN);
        String other = Members.newTenant();
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().header("X-Tenant-Id", other).get("/api/core/seasons").then().statusCode(404);

            assertThat(events.single())
                    .containsEntry("security.kind", "not_member")
                    .containsEntry("security.outcome", "404")
                    .containsEntry("tenantId", other)
                    .containsEntry("security.subject", TenantUser.SUBJECT)
                    .containsEntry("security.resource", "GET /api/core/seasons");
        }
    }

    @Test
    void aCoachReadingTheAuditTrailIsARoleEventAndCounted() {
        String tenant = Members.newTenant();
        Members.signIn(tenant, TenantRole.COACH);
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().header("X-Tenant-Id", tenant).get("/api/core/audit-events").then().statusCode(403);

            assertThat(events.single())
                    .containsEntry("security.kind", "role")
                    .containsEntry("security.outcome", "403")
                    .containsEntry("tenantId", tenant)
                    .containsEntry("security.roles", "COACH")
                    .containsEntry("security.resource", "GET /api/core/audit-events")
                    .containsEntry("security.reason", "Requires one of [ADMIN]");
        }
        given().get("/q/metrics").then().statusCode(200).body(containsString("hoops_authz_denied_total{kind=\"role\"}"));
    }
}
