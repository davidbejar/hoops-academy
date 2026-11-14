package com.hoopsacademy.core.adapters.in.rest;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.equalTo;

import com.fasterxml.jackson.databind.JsonNode;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.RosterEvents;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

/**
 * WP91 (decision 73): {@code PATCH /api/core/me} with {@code givenName} / {@code familyName} and {@code tenantId}
 * renames the caller's own person in that academy, with the side effects of an administrator's {@code updateMember}
 * (audit {@code member.updated}, a {@code core.person} event); the e-mail stays with the administrators.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
class MeOwnNameTest {

    private static final String ME = "/api/core/me";
    private static final java.time.LocalDate BORN = java.time.LocalDate.of(2010, 4, 1);

    @ParameterizedTest
    @EnumSource(TenantRole.class)
    @TestSecurity(user = "me-own-matrix")
    void everyRoleRenamesItsOwnPersonInTheNamedAcademyOnly(TenantRole role) {
        String academy = tenant("ACTIVE");
        String other = tenant("ACTIVE");
        UUID login = CoreDb.login("me-own-matrix");
        // a PLAYER always has a birth date and a gender (Person's invariant, checked again on every edit)
        UUID mine = CoreDb.person(academy, login, "Old", "Name", null, BORN, "FEMALE", role);
        UUID elsewhere = CoreDb.person(other, login, "Old", "Name", null, BORN, "FEMALE", role);

        rename("{\"givenName\": \"Ada\", \"familyName\": \"Lovelace\", \"tenantId\": \"" + academy + "\"}")
                .statusCode(200).body("userId", equalTo(login.toString()))
                .body("memberships.find { it.tenant.id == '" + academy + "' }.givenName", equalTo("Ada"))
                .body("memberships.find { it.tenant.id == '" + academy + "' }.familyName", equalTo("Lovelace"))
                .body("memberships.find { it.tenant.id == '" + other + "' }.givenName", equalTo("Old"));

        assertThat(name(academy, mine)).isEqualTo("Ada Lovelace");
        assertThat(name(other, elsewhere)).as("the other academy keeps its own record").isEqualTo("Old Name");
        var audit = CoreDb.auditRow(academy, "member.updated");
        assertThat(audit).containsEntry("actorSub", "me-own-matrix").containsEntry("actorPersonId", mine.toString())
                .containsEntry("targetType", "person").containsEntry("targetId", mine.toString());
        assertThat(audit.get("metadata")).contains("familyName", "givenName").doesNotContain("Ada", "Lovelace");
        JsonNode event = RosterEvents.last(academy, "core.person", mine);
        assertThat(event.get("type").asText()).isEqualTo("person.changed");
        assertThat(event.get("payload").get("displayName").asText()).isEqualTo("Ada Lovelace");
        RosterEvents.assertValid("core.person", event);
    }

    @Test
    @TestSecurity(user = "me-own-one")
    void oneNameAloneAndTheLocaleInTheSameCall() {
        String academy = tenant("ACTIVE");
        UUID mine = CoreDb.person(academy, CoreDb.login("me-own-one"), "Grace", "Old", null, null, null,
                TenantRole.COACH);

        rename("{\"familyName\": \"Hopper\", \"locale\": \"en\", \"tenantId\": \"" + academy + "\"}").statusCode(200)
                .body("locale", equalTo("en"));

        assertThat(name(academy, mine)).isEqualTo("Grace Hopper");
        assertThat(CoreDb.auditRow(academy, "member.updated").get("metadata")).contains("familyName")
                .doesNotContain("givenName");
    }

    @Test
    @TestSecurity(user = "me-own-same")
    void theSameNameWritesNothing() {
        String academy = tenant("ACTIVE");
        UUID mine = CoreDb.person(academy, CoreDb.login("me-own-same"), "Same", "Name", null, null, null,
                TenantRole.PARENT);
        long events = RosterEvents.count(academy);

        rename("{\"givenName\": \"Same\", \"familyName\": \"Name\", \"tenantId\": \"" + academy + "\"}")
                .statusCode(200);

        assertThat(CoreDb.auditActions(academy)).doesNotContain("member.updated");
        assertThat(RosterEvents.count(academy)).isEqualTo(events);
        assertThat(name(academy, mine)).isEqualTo("Same Name");
    }

    @Test
    @TestSecurity(user = "me-own-email")
    void theEmailAndMalformedBodiesAreRejected() {
        String academy = tenant("ACTIVE");
        UUID mine = CoreDb.person(academy, CoreDb.login("me-own-email"), "Eve", "Mail", "eve@example.com", null, null,
                TenantRole.PLAYER);
        String t = ", \"tenantId\": \"" + academy + "\"";

        invalid("{\"email\": \"new@example.com\"" + t + "}");
        invalid("{\"givenName\": \"Eve\", \"email\": \"new@example.com\"" + t + "}");
        invalid("{\"givenName\": \"Eve\"}");
        invalid("{\"tenantId\": \"" + academy + "\"}");
        invalid("{\"locale\": \"en\"" + t + "}");
        invalid("{\"givenName\": \"  \"" + t + "}");
        invalid("{\"givenName\": null" + t + "}");
        invalid("{\"familyName\": \"" + "x".repeat(81) + "\"" + t + "}");
        invalid("{\"givenName\": \"Eve\", \"tenantId\": \"not-a-uuid\"}");
        invalid("{}");

        assertThat(CoreDb.count(academy, "select count(*) from core.person where id = ? and email = 'eve@example.com' "
                + "and given_name = 'Eve'", mine)).isEqualTo(1);
        assertThat(CoreDb.auditActions(academy)).doesNotContain("member.updated");
    }

    @Test
    @TestSecurity(user = "me-own-outsider")
    void anAcademyWhereTheCallerIsNotAnActiveMemberIsNotFoundAndNothingIsStored() {
        UUID login = CoreDb.login("me-own-outsider");
        String home = tenant("ACTIVE");
        CoreDb.person(home, login, "Out", "Sider", null, null, null, TenantRole.COACH);
        String foreign = tenant("ACTIVE");
        UUID stranger = CoreDb.person(foreign, CoreDb.login("me-own-stranger-" + UUID.randomUUID()), "Str", "Anger",
                null, null, null, TenantRole.ADMIN);
        String left = tenant("ACTIVE");
        UUID gone = CoreDb.person(left, login, "Gone", "Away", null, null, null, TenantRole.PARENT);
        CoreDb.inTenant(left, c -> CoreDb.update(c, "update core.person set active = false where id = ?", gone));
        String suspended = tenant("SUSPENDED");
        UUID paused = CoreDb.person(suspended, login, "Paused", "Member", null, null, null, TenantRole.COACH);

        for (String academy : new String[] {foreign, left, suspended, UUID.randomUUID().toString()}) {
            rename("{\"givenName\": \"Hacked\", \"locale\": \"id\", \"tenantId\": \"" + academy + "\"}")
                    .statusCode(404);
        }

        assertThat(name(foreign, stranger)).isEqualTo("Str Anger");
        assertThat(name(left, gone)).isEqualTo("Gone Away");
        assertThat(name(suspended, paused)).isEqualTo("Paused Member");
        given().filter(Contract.CORE).get(ME).then().statusCode(200).body("locale", equalTo("es"));
    }

    @Test
    @TestSecurity(user = "me-own-root", roles = "super_admin")
    void aSuperAdminWithoutMembershipIsNotFound() {
        String academy = tenant("ACTIVE");

        rename("{\"givenName\": \"Root\", \"tenantId\": \"" + academy + "\"}").statusCode(404);
    }

    @Test
    void anonymousCallersAreUnauthorized() {
        given().filter(Contract.CORE).contentType(ContentType.JSON)
                .body("{\"givenName\": \"Anon\", \"tenantId\": \"" + UUID.randomUUID() + "\"}").patch(ME).then()
                .statusCode(401);
    }

    private static ValidatableResponse rename(String body) {
        return given().filter(Contract.CORE).contentType(ContentType.JSON).body(body).patch(ME).then();
    }

    private static void invalid(String body) {
        given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON).body(body).patch(ME).then()
                .statusCode(400);
    }

    private static String name(String tenant, UUID person) {
        return com.hoopsacademy.core.testsupport.RosterDb.text(tenant,
                "select given_name || ' ' || family_name from core.person where id = ?", person);
    }

    private static String tenant(String status) {
        String id = UUID.randomUUID().toString();
        CoreDb.tenant(id, status);
        return id;
    }
}
