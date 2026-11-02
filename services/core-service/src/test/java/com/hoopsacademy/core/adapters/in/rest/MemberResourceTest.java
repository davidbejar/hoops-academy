package com.hoopsacademy.core.adapters.in.rest;

import static com.hoopsacademy.core.testsupport.KeycloakStubs.anyPasswordReset;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.anySetupEmail;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.temporaryPasswordSentFor;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.temporaryPasswordSet;
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
import static org.hamcrest.Matchers.hasKey;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
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
import com.hoopsacademy.core.testsupport.LogCapture;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.PasswordLeaks;
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
    void inviteProvisionsALoginWithATemporaryPasswordShownOnce() {
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);

        var response = invite("""
                {"givenName":"Carla","familyName":"Coach","email":"carla@example.com","locale":"en",
                 "roles":["COACH","PARENT"]}""").statusCode(201)
                .header("Cache-Control", "no-store")
                .body("temporaryPassword", notNullValue())
                .body("roles", contains("COACH", "PARENT"))
                .body("invitationStatus", equalTo("PENDING"))
                .body("userId", notNullValue())
                .body("displayName", equalTo("Carla Coach"))
                .body("active", equalTo(true))
                .body("playerId", nullValue())
                .extract();
        assertThat(response.header("Location")).endsWith(MEMBERS + "/" + response.path("personId"));
        keycloak.verify(1, temporaryPasswordSet(sub));
        assertThat(temporaryPasswordSentFor(keycloak, sub)).isEqualTo(response.path("temporaryPassword"));
        keycloak.verify(0, anySetupEmail());
        assertThat(CoreDb.count(tenant, "select count(*) from core.user_membership_index where keycloak_sub = ?", sub))
                .isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.outbox where event_type = 'member.invited'"))
                .isEqualTo(1);
        var audit = CoreDb.auditRow(tenant, "member.invited");
        String personId = response.path("personId");
        assertThat(audit).containsEntry("actorSub", TenantUser.SUBJECT).containsEntry("targetType", "person")
                .containsEntry("targetId", personId).containsEntry("actorPersonId", Members.callerPersonId(tenant).toString());
        assertThat(audit.get("metadata")).contains("COACH", "PARENT").doesNotContain("carla@example.com", "Carla");
        assertThat(CoreDb.auditActions(tenant)).endsWith("member.invited", "member.temporary_password_issued");
    }

    @Test
    void theTemporaryPasswordOfAnInvitationIsNeverStoredOrLogged() {
        try (LogCapture logs = LogCapture.start()) {
            String password = invite("""
                    {"givenName":"Sec","familyName":"Ret","email":"secret@example.com","roles":["PARENT"]}""")
                    .statusCode(201).extract().path("temporaryPassword");
            PasswordLeaks.assertNeverStoredOrLogged(tenant, password, logs);
        }
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
                .body("$", not(hasKey("temporaryPassword")))
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
        KeycloakStubs.temporaryPasswordFails(keycloak);
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
                .statusCode(201).body("invitationStatus", equalTo("ACCEPTED"))
                .body("$", not(hasKey("temporaryPassword")));
        keycloak.verify(0, userCreated());
        keycloak.verify(0, anyPasswordReset());
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

    // ------------------------------------------------------------------ e-mail of a member with a login (ADR-0023)

    @Test
    void emailChangeMovesTheLoginInKeycloakAndCore() {
        String sub = UUID.randomUUID().toString();
        UUID coach = coachWithLogin(sub, "old.coach@example.com");

        patch(coach, "{\"email\":\"new.coach@example.com\"}").statusCode(200)
                .body("email", equalTo("new.coach@example.com"));

        keycloak.verify(1, KeycloakStubs.loginMoved(sub, "new.coach@example.com"));
        keycloak.verify(0, anySetupEmail());
        keycloak.verify(0, anyPasswordReset());
        assertThat(CoreDb.count(null, "select count(*) from core.app_user where keycloak_sub = ? and email = ?",
                sub, "new.coach@example.com")).isEqualTo(1);
        assertThat(CoreDb.auditActions(tenant)).endsWith("member.updated", "member.login_email_changed");
        assertThat(CoreDb.auditRow(tenant, "member.login_email_changed")).containsEntry("targetId", coach.toString());
        assertThat(CoreDb.auditRow(tenant, "member.login_email_changed").get("metadata"))
                .doesNotContain("coach@example.com");
    }

    @Test
    void namesOnlyAndMembersWithoutLoginDoNotTouchKeycloak() {
        UUID coach = coachWithLogin(UUID.randomUUID().toString(), "names@example.com");
        UUID kid = CoreDb.person(tenant, "No", "Login", "nologin@example.com", TenantRole.PARENT);
        patch(coach, "{\"givenName\":\"Renamed\",\"email\":\"NAMES@example.com\"}").statusCode(200);
        patch(kid, "{\"email\":\"still.nologin@example.com\"}").statusCode(200);
        keycloak.verify(0, KeycloakStubs.anyLoginUpdate());
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("member.login_email_changed");
    }

    @Test
    void keycloakFailureKeepsTheOldEmailEverywhere() {
        String sub = UUID.randomUUID().toString();
        UUID coach = coachWithLogin(sub, "kept.coach@example.com");
        KeycloakStubs.loginUpdateFails(keycloak);

        given().filter(Contract.FAILURES).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"email\":\"lost.coach@example.com\"}").patch(MEMBERS + "/" + coach).then()
                .statusCode(502).contentType("application/problem+json")
                .body("code", equalTo("IDENTITY_PROVIDER_UNAVAILABLE"));

        member(coach).statusCode(200).body("email", equalTo("kept.coach@example.com"));
        assertThat(CoreDb.count(null, "select count(*) from core.app_user where keycloak_sub = ? and email = ?",
                sub, "kept.coach@example.com")).isEqualTo(1);
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("member.updated", "member.login_email_changed");
    }

    @Test
    void anEmailOfAnotherKeycloakLoginIsTaken() {
        String sub = UUID.randomUUID().toString();
        UUID coach = coachWithLogin(sub, "mine@example.com");
        KeycloakStubs.loginUpdateConflicts(keycloak);
        patch(coach, "{\"email\":\"someone.else@example.com\"}").statusCode(409).body("code", equalTo("EMAIL_TAKEN"));
        member(coach).statusCode(200).body("email", equalTo("mine@example.com"));
    }

    @Test
    void aLoginUsedInAnotherTenantCannotBeMovedByAnAcademyAdmin() {
        String sub = UUID.randomUUID().toString();
        UUID coach = coachWithLogin(sub, "shared@example.com");
        UUID user = CoreDb.login(sub);
        CoreDb.person(Members.newTenant(), user, "Sha", "Red", "shared@example.com", null, null, TenantRole.PARENT);

        patch(coach, "{\"email\":\"takeover@example.com\"}").statusCode(409).contentType("application/problem+json")
                .body("code", equalTo("LOGIN_SHARED"))
                .body("detail", org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("shared@example.com")));

        keycloak.verify(0, KeycloakStubs.anyLoginUpdate());
        member(coach).statusCode(200).body("email", equalTo("shared@example.com"));
        patch(coach, "{\"familyName\":\"Still Editable\"}").statusCode(200);
    }

    @Test
    void aDeactivatedMembershipElsewhereDoesNotShareTheLogin() {
        String sub = UUID.randomUUID().toString();
        UUID coach = coachWithLogin(sub, "was.shared@example.com");
        String other = Members.newTenant();
        UUID gone = CoreDb.person(other, CoreDb.login(sub), "Gone", "Away", null, null, null, TenantRole.PARENT);
        CoreDb.inTenant(other, c -> {
            CoreDb.update(c, "update core.person set active = false where id = ?", gone);
            return CoreDb.update(c, "delete from core.user_membership_index where person_id = ?", gone);
        });
        patch(coach, "{\"email\":\"free.now@example.com\"}").statusCode(200);
        keycloak.verify(1, KeycloakStubs.loginMoved(sub, "free.now@example.com"));
    }

    @Test
    void aMemberWithALoginKeepsAnEmail() {
        UUID coach = coachWithLogin(UUID.randomUUID().toString(), "needed@example.com");
        patch(coach, "{\"email\":null}").statusCode(422).body("code", equalTo("LOGIN_REQUIRES_EMAIL"));
        keycloak.verify(0, KeycloakStubs.anyLoginUpdate());
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

    // ------------------------------------------------------------------ temporary password (ADR-0024)

    @Test
    void aPendingMemberGetsANewTemporaryPasswordShownOnce() {
        String sub = UUID.randomUUID().toString();
        UUID coach = coachWithLogin(sub, "pending.coach@example.com", "PENDING");

        try (LogCapture logs = LogCapture.start()) {
            String password = issue(coach).statusCode(200).header("Cache-Control", "no-store")
                    .body("personId", equalTo(coach.toString())).body("invitationStatus", equalTo("PENDING"))
                    .extract().path("temporaryPassword");

            keycloak.verify(1, temporaryPasswordSet(sub));
            assertThat(temporaryPasswordSentFor(keycloak, sub)).isEqualTo(password);
            PasswordLeaks.assertNeverStoredOrLogged(tenant, password, logs);
        }
        var audit = CoreDb.auditRow(tenant, "member.temporary_password_issued");
        assertThat(audit).containsEntry("targetId", coach.toString()).containsEntry("actorSub", TenantUser.SUBJECT);
        keycloak.verify(0, anySetupEmail());
    }

    @Test
    void onlyAnActivePendingMemberWithoutAChosenPasswordGetsOne() {
        issue(admin).statusCode(409).body("code", equalTo("INVITATION_NOT_PENDING"));
        issue(coachWithLogin(UUID.randomUUID().toString(), "accepted@example.com", "ACCEPTED")).statusCode(409)
                .body("code", equalTo("INVITATION_NOT_PENDING"));

        String sub = UUID.randomUUID().toString();
        UUID signedIn = coachWithLogin(sub, "chosen@example.com", "PENDING");
        KeycloakStubs.ownPassword(keycloak, sub);
        issue(signedIn).statusCode(409).body("code", equalTo("INVITATION_NOT_PENDING"));

        UUID gone = coachWithLogin(UUID.randomUUID().toString(), "gone@example.com", "PENDING");
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.person set active = false where id = ?", gone));
        issue(gone).statusCode(409).body("code", equalTo("INVITATION_NOT_PENDING"));

        issue(UUID.randomUUID()).statusCode(404);
        keycloak.verify(0, anyPasswordReset());
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("member.temporary_password_issued");
    }

    @Test
    void aLoginUsedInAnotherTenantCannotBeResetByAnAcademyAdmin() {
        String sub = UUID.randomUUID().toString();
        UUID coach = coachWithLogin(sub, "shared.pending@example.com", "PENDING");
        CoreDb.person(Members.newTenant(), CoreDb.login(sub), "Sha", "Red", null, null, null, TenantRole.PARENT);

        issue(coach).statusCode(409).body("code", equalTo("LOGIN_SHARED"))
                .body("detail", not(org.hamcrest.Matchers.containsString("shared.pending@example.com")));
        keycloak.verify(0, anyPasswordReset());
    }

    @Test
    void aKeycloakFailureLeavesNoAuditRow() {
        UUID coach = coachWithLogin(UUID.randomUUID().toString(), "kc.down@example.com", "PENDING");
        KeycloakStubs.temporaryPasswordFails(keycloak);
        given().filter(Contract.FAILURES).header("X-Tenant-Id", tenant).post(MEMBERS + "/" + coach + "/temporary-password")
                .then().statusCode(502).body("code", equalTo("IDENTITY_PROVIDER_UNAVAILABLE"));
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("member.temporary_password_issued");
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
        UUID pending = coachWithLogin(UUID.randomUUID().toString(), "matrix." + UUID.randomUUID() + "@example.com",
                "PENDING");
        issue(pending).statusCode(isAdmin ? 200 : 403);
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
        issue(stranger).statusCode(404);
        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).get(MEMBERS).then()
                .body("items.personId", everyItem(org.hamcrest.Matchers.not(stranger.toString())))
                .body("items.personId", hasItem(admin.toString()));
        given().filter(Contract.CORE).header("X-Tenant-Id", other).get(MEMBERS).then().statusCode(404);
    }

    /** An ACCEPTED coach whose login (core.app_user + Keycloak user) uses {@code email}. */
    private UUID coachWithLogin(String sub, String email) {
        return coachWithLogin(sub, email, "ACCEPTED");
    }

    private UUID coachWithLogin(String sub, String email, String invitationStatus) {
        UUID user = CoreDb.appUser(sub, email);
        UUID coach = CoreDb.person(tenant, user, "Cora", "Coach", email, null, null, TenantRole.COACH);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c,
                "update core.person set invitation_status = ? where id = ?", invitationStatus, coach));
        KeycloakStubs.login(keycloak, sub, email);
        return coach;
    }

    private ValidatableResponse issue(UUID person) {
        return given().filter(Contract.CORE).header("X-Tenant-Id", tenant)
                .post(MEMBERS + "/" + person + "/temporary-password").then();
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
