package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.quarkus.test.security.oidc.Claim;
import io.quarkus.test.security.oidc.OidcSecurity;
import io.restassured.http.ContentType;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** GET/PATCH /api/core/me: memberships across tenants through the subject-scoped index, never anyone else's. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class MeResourceTest {

    private static final String ME = "/api/core/me";

    @Test
    @TestSecurity(user = "me-alice")
    void listsOwnMembershipsInActiveTenantsOnly() {
        String a = tenant("ACTIVE");
        String b = tenant("ACTIVE");
        String suspended = tenant("SUSPENDED");
        String leftTenant = tenant("ACTIVE");
        UUID alice = CoreDb.login("me-alice");
        UUID bob = CoreDb.login("me-bob-" + UUID.randomUUID());
        UUID aliceInA = CoreDb.person(a, alice, "Alice", "A", null, null, null, TenantRole.ADMIN, TenantRole.COACH);
        UUID aliceInB = CoreDb.person(b, alice, "Alice", "A", null, LocalDate.of(1990, 1, 1), "FEMALE",
                TenantRole.PARENT, TenantRole.PLAYER);
        UUID ownPlayer = CoreDb.player(b, aliceInB);
        UUID child = CoreDb.player(b, CoreDb.person(b, "Kid", "A", null));
        CoreDb.guardianLink(b, aliceInB, child);
        CoreDb.person(suspended, alice, "Alice", "A", null, null, null, TenantRole.ADMIN);
        UUID gone = CoreDb.person(leftTenant, alice, "Alice", "A", null, null, null, TenantRole.COACH);
        CoreDb.inTenant(leftTenant, c -> CoreDb.update(c, "update core.person set active = false where id = ?", gone));
        CoreDb.person(a, bob, "Bob", "B", null, null, null, TenantRole.ADMIN);
        CoreDb.person(tenant("ACTIVE"), bob, "Bob", "B", null, null, null, TenantRole.COACH);

        given().filter(Contract.CORE).get(ME).then().statusCode(200)
                .body("sub", equalTo("me-alice"))
                .body("userId", equalTo(alice.toString()))
                .body("superAdmin", equalTo(false))
                .body("memberships", hasSize(2))
                .body("memberships.tenant.id", containsInAnyOrder(a, b))
                .body("memberships.find { it.tenant.id == '" + a + "' }.personId", equalTo(aliceInA.toString()))
                .body("memberships.find { it.tenant.id == '" + a + "' }.roles", contains("ADMIN", "COACH"))
                .body("memberships.find { it.tenant.id == '" + b + "' }.authz.linkedPlayerIds",
                        contains(child.toString()))
                .body("memberships.find { it.tenant.id == '" + b + "' }.authz.ownPlayerId",
                        equalTo(ownPlayer.toString()))
                .body("memberships.find { it.tenant.id == '" + b + "' }.tenant.hasLogo", equalTo(false))
                .body("locale", equalTo("es"));
    }

    @Test
    @TestSecurity(user = "me-coach")
    void reportsTheTeamsTheCallerIsStaffOf() {
        String t = tenant("ACTIVE");
        UUID coach = CoreDb.person(t, CoreDb.login("me-coach"), "Cora", "C", null, null, null, TenantRole.COACH);
        java.util.Map<String, UUID> categories = com.hoopsacademy.core.testsupport.RosterDb.defaultCategories(t);
        UUID season = com.hoopsacademy.core.testsupport.RosterDb.currentSeason(t);
        UUID lions = com.hoopsacademy.core.testsupport.RosterDb.team(t, season, "Lions", categories.get("U12"), "MIXED");
        com.hoopsacademy.core.testsupport.RosterDb.team(t, season, "Other", categories.get("U10"), "MIXED");
        com.hoopsacademy.core.testsupport.RosterDb.staff(t, lions, coach, "COACH");

        given().filter(Contract.CORE).get(ME).then().statusCode(200)
                .body("memberships.find { it.tenant.id == '" + t + "' }.authz.staffTeamIds", contains(lions.toString()));
    }

    @Test
    @TestSecurity(user = "me-parent")
    void reportsTheTenantZoneAndTheTeamsOfOwnAndLinkedPlayers() {
        String t = tenant("ACTIVE");
        com.hoopsacademy.core.testsupport.RosterDb.timezone(t, "Asia/Jakarta");
        UUID parent = CoreDb.person(t, CoreDb.login("me-parent"), "Pia", "P", null, null, null, TenantRole.PARENT);
        UUID child = CoreDb.player(t, CoreDb.person(t, "Kid", "P", null));
        CoreDb.guardianLink(t, parent, child);
        java.util.Map<String, UUID> categories = com.hoopsacademy.core.testsupport.RosterDb.defaultCategories(t);
        UUID season = com.hoopsacademy.core.testsupport.RosterDb.currentSeason(t);
        UUID kidsTeam = com.hoopsacademy.core.testsupport.RosterDb.team(t, season, "Kids", categories.get("U12"), "MIXED");
        com.hoopsacademy.core.testsupport.RosterDb.team(t, season, "Other", categories.get("U10"), "MIXED");
        com.hoopsacademy.core.testsupport.RosterDb.assignment(t, kidsTeam, child, "5");

        given().filter(Contract.CORE).get(ME).then().statusCode(200)
                .body("memberships.find { it.tenant.id == '" + t + "' }.authz.timezone", equalTo("Asia/Jakarta"))
                .body("memberships.find { it.tenant.id == '" + t + "' }.authz.playerTeamIds", contains(kidsTeam.toString()))
                .body("memberships.find { it.tenant.id == '" + t + "' }.authz.ownPlayerId", org.hamcrest.Matchers.nullValue());
    }

    @Test
    @TestSecurity(user = "me-pending")
    void firstMeCallAcceptsAPendingInvitation() {
        String t = tenant("ACTIVE");
        UUID person = CoreDb.person(t, CoreDb.login("me-pending"), "Pia", "P", null, null, null, TenantRole.COACH);
        CoreDb.inTenant(t, c -> CoreDb.update(c, "update core.person set invitation_status = 'PENDING' where id = ?", person));

        given().filter(Contract.CORE).get(ME).then().statusCode(200).body("memberships", hasSize(1));
        assertThat(CoreDb.count(t, "select count(*) from core.person where id = ? and invitation_status = 'ACCEPTED'",
                person)).isEqualTo(1);
    }

    @Test
    @TestSecurity(user = "me-never-provisioned")
    void unprovisionedUserIsNotFound() {
        given().filter(Contract.CORE).get(ME).then().statusCode(404).contentType("application/problem+json");
    }

    @Test
    @TestSecurity(user = "me-root", roles = "super_admin")
    @OidcSecurity(claims = {@Claim(key = "sub", value = "me-root"), @Claim(key = "name", value = "Root Admin"),
            @Claim(key = "email", value = "root@example.com")})
    void superAdminIsRegisteredOnFirstSightWithoutMemberships() {
        given().filter(Contract.CORE).get(ME).then().statusCode(200)
                .body("superAdmin", equalTo(true))
                .body("displayName", equalTo("Root Admin"))
                .body("email", equalTo("root@example.com"))
                .body("userId", notNullValue())
                .body("memberships", empty());
    }

    @Test
    @TestSecurity(user = "me-locale")
    void patchStoresTheLocalePreference() {
        String t = tenant("ACTIVE");
        CoreDb.person(t, CoreDb.login("me-locale"), "Lu", "L", null, null, null, TenantRole.PARENT);

        given().filter(Contract.CORE).contentType(ContentType.JSON).body("{\"locale\":\"id\"}").patch(ME)
                .then().statusCode(200).body("locale", equalTo("id"));
        given().filter(Contract.CORE).get(ME).then().statusCode(200).body("locale", equalTo("id"));
        given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON).body("{\"locale\":\"fr\"}").patch(ME)
                .then().statusCode(400);
    }

    @Test
    @TestSecurity(user = "me-no-header")
    void meNeedsNoTenantHeaderButAuthentication() {
        CoreDb.login("me-no-header");
        given().filter(Contract.CORE).get(ME).then().statusCode(200).body("memberships", empty());
    }

    @Test
    @TestSecurity(user = "me-no-header")
    void meIsServedOnItsPublicPathOnly() {
        CoreDb.login("me-no-header");
        given().get("/account/me").then().statusCode(404);
    }

    @Test
    void anonymousIsUnauthorized() {
        given().filter(Contract.CORE).get(ME).then().statusCode(401);
    }

    private static String tenant(String status) {
        String id = UUID.randomUUID().toString();
        CoreDb.tenant(id, status);
        return id;
    }
}
