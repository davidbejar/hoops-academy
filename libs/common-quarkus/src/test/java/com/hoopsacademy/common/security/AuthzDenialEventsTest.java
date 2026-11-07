package com.hoopsacademy.common.security;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.AuthzContextResolver;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.SecurityEventCapture;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.testing.TestAuthzContextResolver;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusMock;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import jakarta.inject.Inject;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * ASVS 16.3.2 / ADR-0043: every authorization failure of the tenancy layer writes one structured security event
 * (category {@code hoops.security}) and counts it in {@code hoops_authz_denied_total{kind}}; an allowed call writes none.
 */
@QuarkusTest
@WithTestResource(PostgresRlsResource.class)
class AuthzDenialEventsTest {

    static final String TENANT = "0c000000-0000-4000-8000-00000000000c";
    static final String OTHER_TENANT = "0d000000-0000-4000-8000-00000000000d";
    static final String TEAM = "1e000000-0000-4000-8000-000000000001";
    static final String CHILD = "2e000000-0000-4000-8000-000000000002";

    @Inject
    MeterRegistry registry;

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH)
    void aNonMemberIsLoggedWithTheRequestedTenant() {
        double before = denied("not_member");
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().header("X-Tenant-Id", OTHER_TENANT).get("/api/probe/whoami").then().statusCode(404);

            assertThat(events.single())
                    .containsEntry("level", "WARN")
                    .containsEntry("security.event", "authz_denied")
                    .containsEntry("security.kind", "not_member")
                    .containsEntry("security.outcome", "404")
                    .containsEntry("tenantId", OTHER_TENANT)
                    .containsEntry("security.subject", TenantUser.SUBJECT)
                    .containsEntry("security.roles", "-")
                    .containsEntry("security.resource", "GET /api/probe/whoami");
        }
        assertThat(denied("not_member")).isEqualTo(before + 1);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT)
    void aMissingTenantRoleIsLoggedWithTheCallersRoles() {
        double before = denied("role");
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().header("X-Tenant-Id", TENANT).get("/api/probe/authz/staff-area").then().statusCode(403);

            assertThat(events.single())
                    .containsEntry("security.kind", "role")
                    .containsEntry("security.outcome", "403")
                    .containsEntry("tenantId", TENANT)
                    .containsEntry("security.subject", TenantUser.SUBJECT)
                    .containsEntry("security.roles", "PARENT")
                    .containsEntry("security.resource", "GET /api/probe/authz/staff-area")
                    .containsEntry("security.reason", "Requires one of [COACH, ASSISTANT_COACH]");
        }
        assertThat(denied("role")).isEqualTo(before + 1);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void aFineGrainedDenialIsLoggedWithTheRouteTemplateNotTheIds() {
        double before = denied("fine_grained");
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().header("X-Tenant-Id", TENANT).get("/api/probe/authz/teams/" + CHILD).then().statusCode(403);

            Map<String, String> event = events.single();
            assertThat(event)
                    .containsEntry("security.kind", "fine_grained")
                    .containsEntry("security.outcome", "403")
                    .containsEntry("security.roles", "COACH")
                    .containsEntry("security.resource", "GET /api/probe/authz/teams/{teamId}")
                    .containsEntry("security.reason", "Not staff of this team");
            assertThat(event.get("message")).doesNotContain(CHILD);
        }
        assertThat(denied("fine_grained")).isEqualTo(before + 1);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.COACH, staffTeams = TEAM)
    void anAllowedCallWritesNoEvent() {
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().header("X-Tenant-Id", TENANT).get("/api/probe/authz/teams/" + TEAM).then().statusCode(200);

            assertThat(events.events()).isEmpty();
        }
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.ADMIN)
    void aMembershipOfAnotherTenantIsATenantMismatchAndNeverBound() {
        AuthzContext foreign = new AuthzContext(TenantUser.SUBJECT, UUID.randomUUID(), TenantId.parse(OTHER_TENANT),
                Set.of(TenantRole.ADMIN), Set.of(), Set.of(), Optional.empty());
        QuarkusMock.installMockForType(new TestAuthzContextResolver() {
            @Override
            public Optional<AuthzContext> resolve(String subject, TenantId tenantId) {
                return Optional.of(foreign);
            }
        }, AuthzContextResolver.class);
        double before = denied("tenant_mismatch");
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().header("X-Tenant-Id", TENANT).get("/api/probe/whoami").then()
                    .statusCode(404)
                    .contentType("application/problem+json");

            assertThat(events.single())
                    .containsEntry("security.kind", "tenant_mismatch")
                    .containsEntry("security.outcome", "404")
                    .containsEntry("tenantId", TENANT)
                    .containsEntry("security.roles", "-");
        }
        assertThat(denied("tenant_mismatch")).isEqualTo(before + 1);
    }

    @Test
    void anAnonymousTenantRequestIsLoggedAsUnauthenticated() {
        double before = denied("unauthenticated");
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().header("X-Tenant-Id", TENANT).get("/api/probe/whoami").then().statusCode(401);

            assertThat(events.single())
                    .containsEntry("security.kind", "unauthenticated")
                    .containsEntry("security.outcome", "401")
                    .containsEntry("security.subject", "-")
                    .containsEntry("security.resource", "GET /api/probe/whoami");
        }
        assertThat(denied("unauthenticated")).isEqualTo(before + 1);
    }

    @Test
    void anAnonymousCallOfAnAuthenticatedPlatformPathIsLoggedOnce() {
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().get("/platform/probe/ping").then().statusCode(401);

            assertThat(events.single())
                    .containsEntry("security.kind", "unauthenticated")
                    .containsEntry("security.resource", "GET /platform/probe/ping");
        }
    }

    @Test
    @TestSecurity(user = "someone", roles = "default-roles-academy")
    void aMissingRealmRoleIsLoggedWithTheRealmRoles() {
        double before = denied("realm_role");
        try (SecurityEventCapture events = SecurityEventCapture.open()) {
            given().get("/platform/probe/realm-role").then().statusCode(403);

            assertThat(events.single())
                    .containsEntry("security.kind", "realm_role")
                    .containsEntry("security.outcome", "403")
                    .containsEntry("tenantId", "-")
                    .containsEntry("security.subject", "someone")
                    .containsEntry("security.roles", "default-roles-academy")
                    .containsEntry("security.resource", "GET /platform/probe/realm-role");
        }
        assertThat(denied("realm_role")).isEqualTo(before + 1);
    }

    @Test
    @TenantUser(tenant = TENANT, roles = TenantRole.PARENT)
    void theDenialsAreAPrometheusCounterPerKind() {
        given().header("X-Tenant-Id", TENANT).get("/api/probe/authz/staff-area").then().statusCode(403);

        given().get("/q/metrics").then()
                .statusCode(200)
                .body(containsString("hoops_authz_denied_total{kind=\"role\"}"))
                .body(containsString("hoops_authz_denied_total{kind=\"invalid_token\"} 0.0"));
    }

    private double denied(String kind) {
        var counter = registry.find("hoops.authz.denied").tag("kind", kind).counter();
        return counter == null ? 0 : counter.count();
    }
}
