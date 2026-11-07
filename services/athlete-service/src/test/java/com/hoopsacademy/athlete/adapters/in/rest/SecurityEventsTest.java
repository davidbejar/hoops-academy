package com.hoopsacademy.athlete.adapters.in.rest;

import static com.hoopsacademy.athlete.support.ApiSupport.member;
import static com.hoopsacademy.athlete.support.ApiSupport.unvalidated;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;

import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.SecurityEventCapture;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import org.junit.jupiter.api.Test;

/**
 * ADR-0043 through athlete's real endpoints: a caller of another academy and a member without any tenant role are one
 * {@code hoops.security} event each, counted in {@code hoops_authz_denied_total}.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
@TestSecurity(user = "tenant-user")
@OidcSecurity(claims = @Claim(key = "sub", value = "tenant-user"))
class SecurityEventsTest {

    static final String TENANT = "55000000-0000-4000-8000-0000000000e1";
    static final String OTHER = "55000000-0000-4000-8000-0000000000e2";

    @Test
    void aCallerOfAnotherAcademyIsANotMemberEvent() {
        member(TENANT, TenantRole.ADMIN);
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            unvalidated(OTHER).get("/api/athlete/training-schedules").then().statusCode(404);

            assertThat(events.single())
                    .containsEntry("security.kind", "not_member")
                    .containsEntry("security.outcome", "404")
                    .containsEntry("tenantId", OTHER)
                    .containsEntry("security.subject", "tenant-user")
                    .containsEntry("security.resource", "GET /api/athlete/training-schedules");
        }
    }

    @Test
    void aMemberWithoutARoleIsARoleEventAndCounted() {
        member(TENANT);
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            unvalidated(TENANT).get("/api/athlete/training-schedules").then().statusCode(403);

            assertThat(events.single())
                    .containsEntry("security.kind", "role")
                    .containsEntry("security.outcome", "403")
                    .containsEntry("tenantId", TENANT)
                    .containsEntry("security.roles", "-")
                    .containsEntry("security.resource", "GET /api/athlete/training-schedules");
        }
        given().get("/q/metrics").then().statusCode(200).body(containsString("hoops_authz_denied_total{kind=\"role\"}"));
    }
}
