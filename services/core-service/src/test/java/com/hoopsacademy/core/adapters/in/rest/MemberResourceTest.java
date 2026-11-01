package com.hoopsacademy.core.adapters.in.rest;

import static com.hoopsacademy.core.testsupport.KeycloakStubs.anySetupEmail;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.setupEmailSent;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.userCreated;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.userDeleted;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasItems;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class MemberResourceTest {

    private static final String MEMBERS = "/api/core/members";

    @InjectWireMock
    WireMockServer keycloak;

    private String tenant;
    private UUID admin;

    @BeforeEach
    void tenantWithOneAdmin() {
        KeycloakStubs.installDefaults(keycloak);
        tenant = Members.newTenant();
        admin = CoreDb.person(tenant, "Ada", "Admin", "ada@example.com", TenantRole.ADMIN);
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    // ------------------------------------------------------------------ invite

    @Test
    void inviteProvisionsALoginAndSendsTheSetupEmail() {
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);

        var response = invite("""
                {"givenName":"Carla","familyName":"Coach","email":"carla@example.com","locale":"en",
                 "roles":["COACH","PARENT"]}""").statusCode(201)
                .body("roles", contains("COACH", "PARENT"))
                .body("invitationStatus", equalTo("PENDING"))
                .body("userId", notNullValue())
                .body("displayName", equalTo("Carla Coach"))
                .body("active", equalTo(true))
                .body("playerId", nullValue())
                .extract();
        assertThat(response.header("Location")).endsWith(MEMBERS + "/" + response.path("personId"));
        keycloak.verify(1, setupEmailSent(sub));
        assertThat(CoreDb.count(tenant, "select count(*) from core.user_membership_index where keycloak_sub = ?", sub))
                .isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.outbox where event_type = 'member.invited'"))
                .isEqualTo(1);
        var audit = CoreDb.auditRow(tenant, "member.invited");
        String personId = response.path("personId");
        assertThat(audit).containsEntry("actorSub", TenantUser.SUBJECT).containsEntry("targetType", "person")
                .containsEntry("targetId", personId).containsEntry("actorPersonId", Members.callerPersonId(tenant).toString());
        assertThat(audit.get("metadata")).contains("COACH", "PARENT").doesNotContain("carla@example.com", "Carla");
    }

    @Test
    void youngPlayerWithoutLoginNeedsBirthDateAndGender() {
        invite("""
                {"givenName":"Leo","familyName":"Kid","roles":["PLAYER"],"sendInvitation":false}""")
                .statusCode(422)
                .body("code", equalTo("PLAYER_REQUIRES_BIRTH_AND_GENDER"))
                .body("violations.field", containsInAnyOrder("birthDate", "gender"));
        invite("""
                {"givenName":"Leo","familyName":"Kid","birthDate":"2015-02-28","gender":"MALE",
                 "roles":["PLAYER"],"sendInvitation":false}""")
                .statusCode(201)
                .body("playerId", notNullValue())
                .body("invitationStatus", equalTo("NONE"))
                .body("userId", nullValue())
                .body("birthDate", equalTo("2015-02-28"));
        keycloak.verify(0, userCreated());
    }

    @Test
    void invitationNeedsAnEmailAndEmailsAreUniquePerTenant() {
        invite("{\"givenName\":\"No\",\"familyName\":\"Mail\",\"roles\":[\"PARENT\"]}").statusCode(422)
                .body("code", equalTo("INVITATION_REQUIRES_EMAIL"));
        invite("{\"givenName\":\"Dup\",\"familyName\":\"Ada\",\"email\":\"ADA@example.com\",\"roles\":[\"COACH\"]}")
                .statusCode(409).body("code", equalTo("EMAIL_TAKEN"));
        keycloak.verify(0, userCreated());
    }

    @Test
    void keycloakFailuresLeaveNoMemberBehind() {
        KeycloakStubs.createUserFails(keycloak);
        given().filter(Contract.FAILURES).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"givenName\":\"K\",\"familyName\":\"Down\",\"email\":\"kdown@example.com\",\"roles\":[\"COACH\"]}")
                .post(MEMBERS).then().statusCode(502);

        KeycloakStubs.installDefaults(keycloak);
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);
        KeycloakStubs.setupEmailFails(keycloak);
        given().filter(Contract.FAILURES).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"givenName\":\"M\",\"familyName\":\"Fail\",\"email\":\"mfail@example.com\",\"roles\":[\"COACH\"]}")
                .post(MEMBERS).then().statusCode(502);
        keycloak.verify(1, userDeleted(sub));
        assertThat(CoreDb.count(tenant, "select count(*) from core.person where email in ('kdown@example.com', "
                + "'mfail@example.com')")).isZero();
    }

    @Test
    void anExistingLoginJoinsWithoutANewKeycloakUser() {
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.existingUser(keycloak, "known@example.com", sub);
        invite("{\"givenName\":\"Kim\",\"familyName\":\"Known\",\"email\":\"known@example.com\",\"roles\":[\"PARENT\"]}")
                .statusCode(201).body("invitationStatus", equalTo("ACCEPTED"));
        keycloak.verify(0, userCreated());
        keycloak.verify(0, anySetupEmail());
    }

    // ------------------------------------------------------------------ read

    @Test
    void listFiltersAndPages() {
        CoreDb.person(tenant, "Bea", "Coach", "bea@example.com", TenantRole.COACH);
        UUID gone = CoreDb.person(tenant, "Gus", "Gone", null, TenantRole.COACH);
        deactivate(gone).statusCode(200);

        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).queryParam("role", "COACH")
                .get(MEMBERS).then().statusCode(200)
                .body("items.givenName", contains("Bea", "Gus"))
                .body("page.totalElements", equalTo(2));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).queryParam("active", true).queryParam("size", 1)
                .get(MEMBERS).then().statusCode(200)
                .body("items", hasSize(1))
                .body("page.totalElements", equalTo(2))
                .body("page.totalPages", equalTo(2));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).queryParam("q", "BEA@")
                .get(MEMBERS).then().statusCode(200).body("items.givenName", contains("Bea"));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).queryParam("q", "%")
                .get(MEMBERS).then().statusCode(200).body("items", hasSize(0));
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).queryParam("size", 201)
                .get(MEMBERS).then().statusCode(400);
    }

    @Test
    void getMemberAndUnknownIsNotFound() {
        member(admin).statusCode(200).body("roles", contains("ADMIN")).body("email", equalTo("ada@example.com"));
        member(UUID.randomUUID()).statusCode(404);
    }

    // ------------------------------------------------------------------ update

    @Test
    void patchUsesMergeSemanticsAndKeepsInvariants() {
        UUID kid = CoreDb.person(tenant, null, "Leo", "Kid", null, LocalDate.of(2014, 1, 1), "MALE", TenantRole.PLAYER);
        patch(kid, "{\"givenName\":\"Leon\",\"phone\":\"+34 600 000 000\",\"locale\":\"en\"}").statusCode(200)
                .body("givenName", equalTo("Leon")).body("phone", equalTo("+34 600 000 000"))
                .body("locale", equalTo("en"));
        patch(kid, "{\"phone\":null}").statusCode(200).body("phone", nullValue()).body("givenName", equalTo("Leon"));
        assertThat(CoreDb.auditActions(tenant)).filteredOn("member.updated"::equals).hasSize(2);
        assertThat(CoreDb.auditRow(tenant, "member.updated").get("metadata")).contains("phone")
                .doesNotContain("+34 600 000 000");
        patch(kid, "{\"birthDate\":null}").statusCode(422).body("code", equalTo("PLAYER_REQUIRES_BIRTH_AND_GENDER"));
        patch(kid, "{\"email\":\"ada@example.com\"}").statusCode(409).body("code", equalTo("EMAIL_TAKEN"));
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"gender\":\"OTHER\",\"givenName\":\"\"}").patch(MEMBERS + "/" + kid).then().statusCode(400)
                .body("violations.field", hasItems("gender", "givenName"));
        given().filter(Contract.RESPONSES_ONLY).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{}").patch(MEMBERS + "/" + kid).then().statusCode(400);
    }

    @Test
    void replaceRolesValidatesPlayerDataAndProtectsTheLastAdmin() {
        UUID coach = CoreDb.person(tenant, "Cole", "Coach", null, TenantRole.COACH);
        roles(coach, "[\"COACH\",\"PLAYER\"]").statusCode(422);
        patch(coach, "{\"birthDate\":\"2000-01-01\",\"gender\":\"MALE\"}").statusCode(200);
        roles(coach, "[\"COACH\",\"PLAYER\"]").statusCode(200)
                .body("roles", contains("COACH", "PLAYER")).body("playerId", notNullValue());
        roles(admin, "[\"COACH\"]").statusCode(409).body("code", equalTo("LAST_ADMIN"));
        roles(coach, "[\"ADMIN\"]").statusCode(200);
        roles(admin, "[\"COACH\"]").statusCode(200).body("roles", contains("COACH"));
        assertThat(CoreDb.count(tenant, "select count(*) from core.outbox where event_type = 'membership.changed'"))
                .as("three successful role changes; the rejected ones rolled back").isEqualTo(3);
        assertThat(CoreDb.auditActions(tenant)).filteredOn("member.roles_replaced"::equals).hasSize(3);
    }

    @Test
    void deactivationRevokesTheMembershipButKeepsHistory() {
        UUID user = CoreDb.login("deactivate-" + UUID.randomUUID());
        UUID parent = CoreDb.person(tenant, user, "Pam", "Parent", null, null, null, TenantRole.PARENT);
        deactivate(parent).statusCode(200).body("active", equalTo(false));
        deactivate(parent).statusCode(200).body("active", equalTo(false));
        assertThat(CoreDb.count(tenant, "select count(*) from core.user_membership_index where person_id = ?", parent))
                .isZero();
        deactivate(admin).statusCode(409).body("code", equalTo("LAST_ADMIN"));
        member(parent).statusCode(200);
        assertThat(CoreDb.auditActions(tenant)).as("the idempotent repeat is not audited")
                .containsOnlyOnce("member.deactivated");
        assertThat(CoreDb.auditRow(tenant, "member.deactivated")).containsEntry("targetId", parent.toString());
    }

    // ------------------------------------------------------------------ authorization

    @ParameterizedTest
    @MethodSource("com.hoopsacademy.core.testsupport.Members#roleSetsWithAdminFlag")
    void onlyAdminsManageMembers(Set<TenantRole> roles, boolean isAdmin) {
        Members.signIn(tenant, roles);
        int read = isAdmin ? 200 : 403;
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(MEMBERS).then().statusCode(read);
        member(admin).statusCode(read);
        invite("{\"givenName\":\"M\",\"familyName\":\"X\",\"roles\":[\"PARENT\"],\"sendInvitation\":false}")
                .statusCode(isAdmin ? 201 : 403);
        UUID coach = CoreDb.person(tenant, "Mat", "Rix", null, TenantRole.COACH);
        patch(coach, "{\"givenName\":\"Matrix\"}").statusCode(read);
        roles(coach, "[\"ASSISTANT_COACH\"]").statusCode(read);
        deactivate(coach).statusCode(read);
    }

    @Test
    void pendingAndRejectedPlayersAreNotListedAsMembers() {
        java.util.Map<String, UUID> people = new java.util.HashMap<>();
        for (String status : java.util.List.of("ACTIVE", "PENDING_APPROVAL", "REJECTED", "WITHDRAWN")) {
            UUID player = com.hoopsacademy.core.testsupport.RosterDb.playerAged(tenant, "P" + status, 11, "MALE");
            CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.player set status = ? where id = ?", status, player));
            people.put(status, UUID.fromString(com.hoopsacademy.core.testsupport.RosterDb.text(tenant,
                    "select person_id::text from core.player where id = ?", player)));
        }

        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).queryParam("size", 200).get(MEMBERS).then()
                .statusCode(200)
                .body("items.personId", hasItems(people.get("ACTIVE").toString(), people.get("WITHDRAWN").toString()))
                .body("items.personId", everyItem(org.hamcrest.Matchers.not(org.hamcrest.Matchers.oneOf(
                        people.get("PENDING_APPROVAL").toString(), people.get("REJECTED").toString()))))
                .body("page.totalElements", equalTo(3));
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).queryParam("role", "PLAYER").get(MEMBERS).then()
                .body("page.totalElements", equalTo(2));
    }

    @Test
    void anotherTenantsMembersAreNotFound() {
        String other = Members.newTenant();
        UUID stranger = CoreDb.person(other, "Sam", "Stranger", null, TenantRole.ADMIN, TenantRole.COACH);
        member(stranger).statusCode(404);
        patch(stranger, "{\"givenName\":\"Hacked\"}").statusCode(404);
        roles(stranger, "[\"PARENT\"]").statusCode(404);
        deactivate(stranger).statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(MEMBERS).then()
                .body("items.personId", everyItem(org.hamcrest.Matchers.not(stranger.toString())))
                .body("items.personId", hasItem(admin.toString()));
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(MEMBERS).then().statusCode(404);
    }

    private ValidatableResponse invite(String body) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON).body(body)
                .post(MEMBERS).then();
    }

    private ValidatableResponse member(UUID person) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(MEMBERS + "/" + person).then();
    }

    private ValidatableResponse patch(UUID person, String body) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON).body(body)
                .patch(MEMBERS + "/" + person).then();
    }

    private ValidatableResponse roles(UUID person, String roles) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"roles\":" + roles + "}").put(MEMBERS + "/" + person + "/roles").then();
    }

    private ValidatableResponse deactivate(UUID person) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant)
                .post(MEMBERS + "/" + person + "/deactivate").then();
    }
}
