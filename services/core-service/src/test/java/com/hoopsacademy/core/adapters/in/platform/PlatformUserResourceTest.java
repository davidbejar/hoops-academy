package com.hoopsacademy.core.adapters.in.platform;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.LogCapture;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.response.ValidatableResponse;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

/**
 * WP91 (decision 71): {@code GET /platform/users} lists every login with its person in each academy, for the super admin
 * only, read through the platform datasource (V18). Logins of other tests share the database, so every test searches
 * for its own marker.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "platform-admin", roles = "super_admin")
class PlatformUserResourceTest {

    private static final String USERS = "/platform/users";

    private String marker;
    private String academyA;
    private String academyB;

    @BeforeEach
    void twoAcademies() {
        marker = "wp91" + UUID.randomUUID().toString().substring(0, 8);
        academyA = Members.newTenant();
        academyB = Members.newTenant();
        named(academyA, "Alpha " + marker);
        named(academyB, "Beta " + marker);
    }

    @Test
    void listsALoginWithItsPersonInEveryAcademyOrderedByAcademyName() {
        UUID ada = CoreDb.appUser("sub-" + marker, "ada." + marker + "@example.com");
        UUID inB = CoreDb.person(academyB, ada, "Ada", "Byron", null, null, null, TenantRole.PARENT);
        UUID inA = CoreDb.person(academyA, ada, "Ada", "Lovelace", null, null, null, TenantRole.COACH,
                TenantRole.ADMIN);
        CoreDb.inTenant(academyB, c -> CoreDb.update(c, "update core.person set active = false where id = ?", inB));
        CoreDb.inTenant(null, c -> CoreDb.update(c, "update core.tenant set status = 'SUSPENDED' where id = ?::uuid",
                academyB));

        search(marker).statusCode(200)
                .body("items", hasSize(1))
                .body("items[0].id", equalTo(ada.toString()))
                .body("items[0].email", equalTo("ada." + marker + "@example.com"))
                .body("items[0].memberships.tenantId", contains(academyA, academyB))
                .body("items[0].memberships[0].tenantName", equalTo("Alpha " + marker))
                .body("items[0].memberships[0].tenantSlug", equalTo(slug(academyA)))
                .body("items[0].memberships[0].tenantStatus", equalTo("ACTIVE"))
                .body("items[0].memberships[0].personId", equalTo(inA.toString()))
                .body("items[0].memberships[0].givenName", equalTo("Ada"))
                .body("items[0].memberships[0].familyName", equalTo("Lovelace"))
                .body("items[0].memberships[0].roles", contains("ADMIN", "COACH"))
                .body("items[0].memberships[0].active", equalTo(true))
                .body("items[0].memberships[1].tenantStatus", equalTo("SUSPENDED"))
                .body("items[0].memberships[1].familyName", equalTo("Byron"))
                .body("items[0].memberships[1].roles", contains("PARENT"))
                .body("items[0].memberships[1].active", equalTo(false))
                .body("page.totalElements", equalTo(1));
    }

    @Test
    void findsALoginByAnyOfItsNamesCaseInsensitivelyButNeverAPersonWithoutLogin() {
        UUID grace = CoreDb.appUser("sub-g-" + marker, "g." + marker + "@example.com");
        CoreDb.person(academyA, grace, "Grace" + marker, "Hopper", null, null, null, TenantRole.COACH);
        CoreDb.person(academyB, grace, "Amazing", "Admiral" + marker, null, null, null, TenantRole.PARENT);
        CoreDb.person(academyA, "Kid" + marker, "NoLogin", null, TenantRole.PLAYER);

        search("GRACE" + marker.toUpperCase()).statusCode(200).body("items.id", contains(grace.toString()));
        search("admiral" + marker).statusCode(200).body("items.id", contains(grace.toString()))
                .body("items[0].memberships", hasSize(2));
        search("Grace" + marker + " hop").statusCode(200).body("items.id", contains(grace.toString()));
        search("Kid" + marker).statusCode(200).body("items", empty()).body("page.totalElements", equalTo(0));
    }

    @Test
    void aLoginWithoutMembershipsIsListedWithAnEmptyList() {
        UUID admin = CoreDb.appUser("sub-sa-" + marker, "root." + marker + "@example.com");

        search("root." + marker).statusCode(200).body("items.id", contains(admin.toString()))
                .body("items[0].memberships", empty());
    }

    @Test
    void pagesAreOrderedByEmailAndCounted() {
        UUID c = CoreDb.appUser("sub-c-" + marker, "c." + marker + "@example.com");
        UUID a = CoreDb.appUser("sub-a-" + marker, "A." + marker + "@example.com");
        UUID b = CoreDb.appUser("sub-b-" + marker, "b." + marker + "@example.com");

        search(marker, "size", "2").statusCode(200).body("items.id", contains(a.toString(), b.toString()))
                .body("page.totalElements", equalTo(3)).body("page.totalPages", equalTo(2));
        search(marker, "size", "2", "page", "1").statusCode(200).body("items.id", contains(c.toString()));
    }

    @Test
    void likeWildcardsInTheQueryAreLiteral() {
        CoreDb.appUser("sub-w-" + marker, "w." + marker + "@example.com");

        search("%" + marker.substring(1)).statusCode(200).body("items", empty());
        search(marker.substring(0, 2) + "_" + marker.substring(3)).statusCode(200).body("items", empty());
    }

    @Test
    void withoutAQueryEveryLoginIsListed() {
        CoreDb.appUser("sub-all-" + marker, "all." + marker + "@example.com");

        int total = given().filter(Contract.CORE).queryParam("size", "200").get(USERS).then().statusCode(200)
                .extract().path("page.totalElements");
        assertThat(total).isPositive();
    }

    @Test
    void aShortOrOversizedQueryAndABadPageAreRejected() {
        given().filter(Contract.RESPONSES_ONLY).queryParam("q", "a").get(USERS).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).queryParam("q", "x".repeat(101)).get(USERS).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).queryParam("size", "201").get(USERS).then().statusCode(400);
    }

    @Test
    void neverWritesTheEmailOrTheQueryToTheLog() {
        CoreDb.appUser("sub-log-" + marker, "log." + marker + "@example.com");

        try (LogCapture logs = LogCapture.start()) {
            search("log." + marker).statusCode(200).body("items", hasSize(1));
            assertThat(logs.containing(marker)).isEmpty();
        }
    }

    @ParameterizedTest
    @EnumSource(TenantRole.class)
    @TestSecurity(user = TenantUser.SUBJECT, roles = "user")
    void everyTenantRoleIsForbidden(TenantRole role) {
        Members.signIn(academyA, role);

        given().filter(Contract.CORE).get(USERS).then().statusCode(403);
    }

    @Test
    @TestSecurity
    void anonymousCallersAreUnauthorized() {
        given().filter(Contract.CORE).get(USERS).then().statusCode(401);
    }

    private ValidatableResponse search(String query, String... more) {
        var request = given().filter(Contract.CORE).queryParam("q", query);
        for (int i = 0; i < more.length; i += 2) {
            request = request.queryParam(more[i], more[i + 1]);
        }
        return request.get(USERS).then();
    }

    private static void named(String tenant, String name) {
        CoreDb.inTenant(null, c -> CoreDb.update(c, "update core.tenant set name = ? where id = ?::uuid", name, tenant));
    }

    private static String slug(String tenant) {
        return com.hoopsacademy.core.testsupport.RosterDb.text(tenant, "select slug from core.tenant where id = ?::uuid",
                tenant);
    }
}
