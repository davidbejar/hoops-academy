package com.hoopsacademy.core.adapters.in.platform;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * WP34: the super admin reads the audit trail of every academy through the platform datasource (core_platform's read
 * policy, ADR-0029). Rows of other tests share the database, so each test works in its own time window.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "platform-admin", roles = "super_admin")
class PlatformAuditEventResourceTest {

    private static final String AUDIT = "/platform/audit-events";

    private Instant t0;
    private String academyA;
    private String academyB;

    @BeforeEach
    void twoAcademies() {
        t0 = Instant.parse("2001-01-01T00:00:00Z").plus(ThreadLocalRandom.current().nextLong(1, 3_000_000),
                ChronoUnit.MINUTES);
        academyA = Members.newTenant();
        academyB = Members.newTenant();
    }

    @Test
    void listsEveryAcademyNewestFirstWithTheAcademysName() {
        UUID a = CoreDb.auditEvent(academyA, t0, "x", null, "tenant.created", "tenant", academyA, "{\"slug\":\"a\"}");
        UUID b = CoreDb.auditEvent(academyB, t0.plusSeconds(1), "platform-admin", null, "tenant.suspended", "tenant",
                academyB, "{\"status\":\"SUSPENDED\",\"reason\":\"Unpaid fees\"}");

        window().statusCode(200)
                .body("items.id", contains(b.toString(), a.toString()))
                .body("items.tenantId", contains(academyB, academyA))
                .body("items[0].tenantName", equalTo(name(academyB)))
                .body("items[0].target.displayName", equalTo(name(academyB)))
                .body("items[0].actor.kind", equalTo("PLATFORM"))
                // the super admin's own view is not masked (WP38)
                .body("items[0].actor.subject", equalTo("platform-admin"))
                .body("items[0].metadata.status", equalTo("SUSPENDED"))
                .body("items[0].metadata.reason", equalTo("Unpaid fees"))
                .body("items[1].tenantName", equalTo(name(academyA)))
                .body("page.totalElements", equalTo(2));
    }

    @Test
    void narrowsToOneAcademyAndFiltersByActionsAndTime() {
        UUID a1 = CoreDb.auditEvent(academyA, t0, "x", null, "member.invited", "person", UUID.randomUUID(), "{}");
        UUID a2 = CoreDb.auditEvent(academyA, t0.plusSeconds(10), "x", null, "member.updated", "person",
                UUID.randomUUID(), "{}");
        CoreDb.auditEvent(academyB, t0.plusSeconds(5), "x", null, "member.invited", "person", UUID.randomUUID(), "{}");

        window("tenantId", academyA).statusCode(200).body("items.id", contains(a2.toString(), a1.toString()));
        window("tenantId", academyA, "action", "member.invited").statusCode(200)
                .body("items.id", contains(a1.toString()));
        window("action", "member.invited").statusCode(200).body("items.tenantId", contains(academyB, academyA));
        given().filter(Contract.CORE).queryParam("from", t0.plusSeconds(1).toString())
                .queryParam("to", t0.plusSeconds(10).toString()).get(AUDIT).then().statusCode(200)
                .body("items.tenantId", contains(academyB));
        window("size", "1", "page", "1").statusCode(200).body("items.size()", equalTo(1))
                .body("page.totalElements", equalTo(3)).body("page.totalPages", equalTo(3));
        window("tenantId", academyA, "action", "tenant.withdrawn").statusCode(200).body("items", empty());
    }

    @Test
    void namesOnlyTheAdministratorsOfAnAcademy() {
        UUID admin = CoreDb.person(academyA, "Ada", "Admin", "ada@example.com", TenantRole.ADMIN);
        UUID coach = CoreDb.person(academyA, "Cora", "Coach", "cora@example.com", TenantRole.COACH);
        UUID player = RosterDb.player(academyA, "Pia", "Player", java.time.LocalDate.of(2014, 5, 1), "FEMALE");
        UUID byAdmin = CoreDb.auditEvent(academyA, t0, "ada", admin, "member.invited", "person", coach, "{}");
        UUID byCoach = CoreDb.auditEvent(academyA, t0.plusSeconds(1), "cora", coach, "player.requested", "player",
                player, "{}");
        UUID onAdmin = CoreDb.auditEvent(academyA, t0.plusSeconds(2), "platform-admin", null, "admin.updated",
                "person", admin, "{\"fields\":[\"givenName\"]}");

        window("tenantId", academyA).statusCode(200)
                .body("items.id", contains(onAdmin.toString(), byCoach.toString(), byAdmin.toString()))
                .body("items[2].actor.displayName", equalTo("Ada Admin"))
                .body("items[2].target.displayName", nullValue())
                .body("items[1].actor.kind", equalTo("PERSON"))
                .body("items[1].actor.personId", equalTo(coach.toString()))
                .body("items[1].actor.displayName", nullValue())
                .body("items[1].target.displayName", nullValue())
                .body("items[0].target.displayName", equalTo("Ada Admin"));
    }

    @Test
    void anAdminOfAnotherAcademyIsNotNamedInThisOne() {
        UUID adminOfB = CoreDb.person(academyB, "Bea", "Boss", "bea@example.com", TenantRole.ADMIN);
        UUID forged = CoreDb.auditEvent(academyA, t0, "bea", adminOfB, "member.updated", "person", adminOfB, "{}");

        window("tenantId", academyA).statusCode(200)
                .body("items.id", contains(forged.toString()))
                .body("items[0].actor.displayName", nullValue())
                .body("items[0].target.displayName", nullValue());
    }

    @Test
    void anUnknownAcademyIsNotFoundAndBadFiltersAreRejected() {
        given().filter(Contract.CORE).queryParam("tenantId", UUID.randomUUID().toString()).get(AUDIT).then()
                .statusCode(404);
        given().filter(Contract.CORE).queryParam("from", t0.toString()).queryParam("to", t0.minusSeconds(1).toString())
                .get(AUDIT).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).queryParam("action", "tenant.hacked").get(AUDIT).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).queryParam("tenantId", "not-a-uuid").get(AUDIT).then().statusCode(400);
    }

    @Test
    void bothAcademiesAppearWithoutATenantFilter() {
        UUID a = CoreDb.auditEvent(academyA, t0, "x", null, "tenant.logo_removed", "tenant", academyA, "{}");
        UUID b = CoreDb.auditEvent(academyB, t0, "x", null, "tenant.logo_removed", "tenant", academyB, "{}");
        window().statusCode(200).body("items.id", containsInAnyOrder(a.toString(), b.toString()));
    }

    @Test
    @TestSecurity(user = "academy-admin", roles = "user")
    void academyUsersAreForbidden() {
        given().filter(Contract.CORE).get(AUDIT).then().statusCode(403);
    }

    @Test
    @TestSecurity
    void anonymousCallersAreUnauthorized() {
        given().filter(Contract.CORE).get(AUDIT).then().statusCode(401);
    }

    /** The list restricted to this test's minute window ({@code from} t0, {@code to} t0 + 1 min). */
    private ValidatableResponse window(String... query) {
        RequestSpecification request = given().filter(Contract.CORE)
                .queryParam("from", t0.toString()).queryParam("to", t0.plus(1, ChronoUnit.MINUTES).toString());
        for (int i = 0; i < query.length; i += 2) {
            request = request.queryParam(query[i], query[i + 1]);
        }
        return request.get(AUDIT).then();
    }

    private static String name(String tenant) {
        return RosterDb.text(tenant, "select name from core.tenant where id = ?::uuid", tenant);
    }
}
