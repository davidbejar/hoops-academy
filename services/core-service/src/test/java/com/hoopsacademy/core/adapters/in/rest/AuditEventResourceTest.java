package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasKey;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/** WP34: an academy's ADMIN reads its audit trail (ADR-0017, ADR-0029); nobody reads another academy's trail. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class AuditEventResourceTest {

    private static final String AUDIT = "/api/core/audit-events";
    private static final Instant T0 = Instant.parse("2026-03-01T10:00:00Z");

    private String tenant;
    private UUID admin;
    private UUID coach;

    @BeforeEach
    void academyWithAnAdminAndACoach() {
        tenant = Members.newTenant();
        admin = CoreDb.person(tenant, "Ada", "Admin", "ada@example.com", TenantRole.ADMIN);
        coach = CoreDb.person(tenant, "Cora", "Coach", "cora@example.com", TenantRole.COACH);
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void listsTheActionsNewestFirstWithNamesResolvedAtReadTime() {
        UUID player = RosterDb.player(tenant, "Pia", "Player", java.time.LocalDate.of(2014, 5, 1), "FEMALE");
        UUID gone = UUID.randomUUID();
        UUID invited = event(T0, "admin-sub", admin, "member.invited", "person", coach, "{\"roles\":[\"COACH\"]}");
        UUID approved = event(T0.plusSeconds(60), "admin-sub", admin, "player.approved", "player", player,
                "{\"action\":\"ADD_PLAYER\"}");
        UUID profile = event(T0.plusSeconds(120), "admin-sub", admin, "tenant.profile_changed", "tenant", tenant,
                "{\"fields\":[\"name\"]}");
        UUID expired = event(T0.plusSeconds(180), "system", null, "member.temporary_password_expired", "person", gone,
                "{}");
        UUID added = event(T0.plusSeconds(240), "platform-admin", null, "admin.added", "person", admin,
                "{\"invited\":false}");
        UUID link = event(T0.plusSeconds(300), "admin-sub", admin, "guardian_link.removed", "guardian_link",
                UUID.randomUUID(), "{}");

        list().statusCode(200)
                .body("items.id", contains(link.toString(), added.toString(), expired.toString(), profile.toString(),
                        approved.toString(), invited.toString()))
                .body("page.totalElements", equalTo(6))
                // a member of the academy
                .body("items[5].at", equalTo("2026-03-01T10:00:00Z"))
                .body("items[5].action", equalTo("member.invited"))
                .body("items[5].actor.kind", equalTo("PERSON"))
                .body("items[5].actor.subject", equalTo("admin-sub"))
                .body("items[5].actor.personId", equalTo(admin.toString()))
                .body("items[5].actor.displayName", equalTo("Ada Admin"))
                .body("items[5].target.type", equalTo("person"))
                .body("items[5].target.id", equalTo(coach.toString()))
                .body("items[5].target.displayName", equalTo("Cora Coach"))
                .body("items[5].metadata.roles", contains("COACH"))
                // a player is named after its person; the academy by its name
                .body("items[4].target.displayName", equalTo("Pia Player"))
                .body("items[3].target.displayName", equalTo(RosterDb.text(tenant,
                        "select name from core.tenant where id = ?::uuid", tenant)))
                // a background job, about a person that no longer exists
                .body("items[2].actor.kind", equalTo("SYSTEM"))
                .body("items[2].actor.personId", nullValue())
                .body("items[2].actor.displayName", nullValue())
                .body("items[2].target.displayName", nullValue())
                // the super admin from the platform console, masked for the academy (decision 16, WP38)
                .body("items[1].actor.kind", equalTo("PLATFORM"))
                .body("items[1].actor.subject", nullValue())
                .body("items[1].actor.personId", nullValue())
                .body("items[1].actor.displayName", nullValue())
                .body("items[1].target.displayName", equalTo("Ada Admin"))
                // a target without a name
                .body("items[0].target.type", equalTo("guardian_link"))
                .body("items[0].target.displayName", nullValue());
    }

    @Test
    void theSuperAdminIsMaskedWhileTheSuspensionReasonIsKept() {
        UUID suspended = event(T0, "platform-admin", null, "tenant.suspended", "tenant", tenant,
                "{\"status\":\"SUSPENDED\",\"reason\":\"Unpaid fees since March\"}");
        UUID system = event(T0.plusSeconds(1), "system", null, "member.temporary_password_expired", "person", coach,
                "{}");
        UUID member = event(T0.plusSeconds(2), "admin-sub", admin, "member.updated", "person", coach,
                "{\"fields\":[\"email\"]}");

        list().statusCode(200)
                .body("items.id", contains(member.toString(), system.toString(), suspended.toString()))
                .body("items[2].actor.kind", equalTo("PLATFORM"))
                .body("items[2].actor", hasKey("subject"))
                .body("items[2].actor.subject", nullValue())
                .body("items[2].actor.personId", nullValue())
                .body("items[2].actor.displayName", nullValue())
                .body("items[2].metadata.status", equalTo("SUSPENDED"))
                .body("items[2].metadata.reason", equalTo("Unpaid fees since March"))
                // only platform actors are masked
                .body("items[1].actor.kind", equalTo("SYSTEM"))
                .body("items[1].actor.subject", equalTo("system"))
                .body("items[0].actor.subject", equalTo("admin-sub"))
                .body("items[0].actor.personId", equalTo(admin.toString()))
                .body("items[0].actor.displayName", equalTo("Ada Admin"));
    }

    @Test
    void filtersByTimeRangeAndByOneOrSeveralActions() {
        UUID first = event(T0, "a", admin, "member.invited", "person", coach, "{}");
        UUID second = event(T0.plus(1, ChronoUnit.HOURS), "a", admin, "member.updated", "person", coach, "{}");
        UUID third = event(T0.plus(2, ChronoUnit.HOURS), "a", admin, "member.roles_replaced", "person", coach, "{}");

        list("from", T0.plus(1, ChronoUnit.HOURS).toString(), "to", T0.plus(2, ChronoUnit.HOURS).toString())
                .statusCode(200).body("items.id", contains(second.toString()));
        list("from", T0.plus(1, ChronoUnit.HOURS).toString()).statusCode(200)
                .body("items.id", contains(third.toString(), second.toString()));
        list("to", T0.plus(1, ChronoUnit.HOURS).toString()).statusCode(200)
                .body("items.id", contains(first.toString()));
        list("action", "member.invited").statusCode(200).body("items.id", contains(first.toString()));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant)
                .queryParam("action", "member.invited", "member.roles_replaced").get(AUDIT).then().statusCode(200)
                .body("items.id", contains(third.toString(), first.toString()))
                .body("page.totalElements", equalTo(2));
        list("action", "tenant.suspended").statusCode(200).body("items", empty());
    }

    @Test
    void pagesThroughTheTrail() {
        for (int i = 0; i < 5; i++) {
            event(T0.plusSeconds(i), "a", admin, "member.updated", "person", coach, "{}");
        }
        list("size", "2", "page", "2").statusCode(200)
                .body("items.size()", equalTo(1))
                .body("page.page", equalTo(2))
                .body("page.size", equalTo(2))
                .body("page.totalElements", equalTo(5))
                .body("page.totalPages", equalTo(3));
        list("size", "2", "page", "3").statusCode(200).body("items", empty());
    }

    @Test
    void anotherAcademysTrailIsNeverListedNorReachable() {
        String other = Members.newTenant();
        UUID stranger = CoreDb.person(other, "Sam", "Stranger", null, TenantRole.ADMIN);
        UUID theirs = CoreDb.auditEvent(other, T0, "b", stranger, "member.invited", "person", stranger, "{}");
        UUID ours = event(T0, "a", admin, "member.invited", "person", coach, "{}");
        // a forged row of ours pointing at their person must not leak their name
        UUID forged = event(T0.plusSeconds(1), "a", stranger, "member.updated", "person", stranger, "{}");

        list().statusCode(200)
                .body("items.id", hasItem(ours.toString()))
                .body("items.id", everyItem(not(theirs.toString())))
                .body("items.find { it.id == '" + forged + "' }.actor.displayName", nullValue())
                .body("items.find { it.id == '" + forged + "' }.target.displayName", nullValue());
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(AUDIT).then().statusCode(404);
    }

    @Test
    void writtenActionsAreReadBack() {
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"givenName\":\"Nia\",\"familyName\":\"New\",\"roles\":[\"PARENT\"],\"sendInvitation\":false}")
                .post("/api/core/members").then().statusCode(201);

        list("action", "member.invited").statusCode(200)
                .body("items[0].actor.subject", equalTo(TenantUser.SUBJECT))
                .body("items[0].actor.personId", equalTo(Members.callerPersonId(tenant).toString()))
                .body("items[0].target.displayName", equalTo("Nia New"))
                .body("items[0].metadata.roles", contains("PARENT"));
    }

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void onlyAdminsReadTheTrail(Set<TenantRole> roles, boolean isAdmin) {
        Members.signIn(tenant, roles);
        list().statusCode(isAdmin ? 200 : 403);
    }

    @Test
    void aNonMemberIsNotFound() {
        Members.signIn(Members.newTenant(), TenantRole.ADMIN);
        list().statusCode(404);
    }

    @Test
    @TestSecurity(user = "platform-admin", roles = "super_admin")
    void theSuperAdminWithoutMembershipIsNotFound() {
        list().statusCode(404);
    }

    @Test
    @TestSecurity
    void anonymousCallersAreUnauthorized() {
        list().statusCode(401);
    }

    @Test
    void invalidFiltersAreBadRequests() {
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant)
                .queryParam("from", T0.toString()).queryParam("to", T0.toString()).get(AUDIT).then().statusCode(400);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant)
                .queryParam("from", T0.toString()).queryParam("to", T0.minusSeconds(1).toString()).get(AUDIT).then()
                .statusCode(400);
        invalid().queryParam("action", "member.hacked").get(AUDIT).then().statusCode(400);
        invalid().queryParam("from", "yesterday").get(AUDIT).then().statusCode(400);
        invalid().queryParam("size", 201).get(AUDIT).then().statusCode(400);
        invalid().queryParam("page", -1).get(AUDIT).then().statusCode(400);
    }

    private UUID event(Instant at, String actorSub, UUID actorPerson, String action, String targetType, Object target,
            String metadata) {
        return CoreDb.auditEvent(tenant, at, actorSub, actorPerson, action, targetType, target, metadata);
    }

    private io.restassured.response.ValidatableResponse list(String... query) {
        RequestSpecification request = given().filter(Contract.CORE).header("X-Tenant-Id", tenant);
        for (int i = 0; i < query.length; i += 2) {
            request = request.queryParam(query[i], query[i + 1]);
        }
        return request.get(AUDIT).then();
    }

    private RequestSpecification invalid() {
        return given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant);
    }
}
