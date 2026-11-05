package com.hoopsacademy.core.adapters.in.platform;

import static com.hoopsacademy.core.testsupport.KeycloakStubs.anyLoginUpdate;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.anyPasswordReset;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.anySetupEmail;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.temporaryPasswordSentFor;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.temporaryPasswordSet;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.userCreated;
import static com.hoopsacademy.core.testsupport.KeycloakStubs.userDeleted;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasKey;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;

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
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** The super admin manages a tenant's administrators (WP22, ADR-0023). */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "platform-admin", roles = "super_admin")
class PlatformAdminResourceTest {

    @InjectWireMock
    WireMockServer keycloak;

    private String tenant;
    private String adminSub;
    private UUID admin;

    @BeforeEach
    void tenantWithOneAdmin() {
        KeycloakStubs.installDefaults(keycloak);
        tenant = Members.newTenant();
        adminSub = UUID.randomUUID().toString();
        admin = withLogin(adminSub, "Ada", "Zeta", "ada." + tenant + "@example.com", "ACCEPTED", TenantRole.ADMIN);
    }

    // ------------------------------------------------------------------ list

    @Test
    void listShowsTheActiveAdminsWithTheirOtherRoles() {
        UUID both = CoreDb.person(tenant, "Bo", "Alpha", "bo@example.com", TenantRole.ADMIN, TenantRole.COACH);
        CoreDb.person(tenant, "Cy", "Coach", "cy@example.com", TenantRole.COACH);
        UUID gone = CoreDb.person(tenant, "Di", "Gone", null, TenantRole.ADMIN);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.person set active = false where id = ?", gone));

        given().filter(Contract.CORE).get(admins()).then().statusCode(200)
                .body("items.personId", contains(both.toString(), admin.toString()))
                .body("items[0].otherRoles", contains("COACH"))
                .body("items[0].email", equalTo("bo@example.com"))
                .body("items[0].invitationStatus", equalTo("NONE"))
                .body("items[1].otherRoles", empty())
                .body("items[1].givenName", equalTo("Ada"))
                .body("items[1].invitationStatus", equalTo("ACCEPTED"))
                .body("page.totalElements", equalTo(2));
        given().filter(Contract.CORE).queryParam("size", 1).get(admins()).then().statusCode(200)
                .body("items.personId", contains(both.toString())).body("page.totalPages", equalTo(2));
    }

    // ------------------------------------------------------------------ add

    @Test
    void addInvitesANewAdminThroughTheOnboardingSaga() {
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);

        var response = add("new.admin@example.com", "Nia", "New").statusCode(201)
                .header("Cache-Control", "no-store")
                .body("temporaryPassword", notNullValue())
                .body("givenName", equalTo("Nia"))
                .body("email", equalTo("new.admin@example.com"))
                .body("invitationStatus", equalTo("PENDING"))
                .body("otherRoles", empty())
                .extract();
        String personId = response.path("personId");
        assertThat(response.header("Location")).endsWith(admins() + "/" + personId);

        keycloak.verify(1, userCreated());
        keycloak.verify(1, temporaryPasswordSet(sub));
        assertThat(temporaryPasswordSentFor(keycloak, sub)).isEqualTo(response.path("temporaryPassword"));
        keycloak.verify(0, anySetupEmail());
        assertThat(CoreDb.count(tenant, """
                select count(*) from core.person p join core.membership_role r on r.person_id = p.id and r.role = 'ADMIN'
                 where p.id = ?::uuid and p.active""", personId)).isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.user_membership_index where keycloak_sub = ?", sub))
                .isEqualTo(1);
        assertThat(CoreDb.auditActions(tenant)).endsWith("member.invited", "member.temporary_password_issued",
                "admin.added");
        var audit = CoreDb.auditRow(tenant, "admin.added");
        assertThat(audit).containsEntry("actorSub", "platform-admin").containsEntry("targetId", personId)
                .containsEntry("actorPersonId", null);
        assertThat(audit.get("metadata")).doesNotContain("new.admin@example.com", "Nia");
    }

    @Test
    void addPromotesAnActiveMemberWithThatEmail() {
        UUID coach = withLogin(UUID.randomUUID().toString(), "Cora", "Coach", "cora@example.com", "ACCEPTED",
                TenantRole.COACH);

        add("CORA@example.com", "Ignored", "Names").statusCode(200)
                .body("$", not(hasKey("temporaryPassword")))
                .body("personId", equalTo(coach.toString()))
                .body("givenName", equalTo("Cora"))
                .body("otherRoles", contains("COACH"))
                .body("invitationStatus", equalTo("ACCEPTED"));

        keycloak.verify(0, userCreated());
        keycloak.verify(0, anyPasswordReset());
        assertThat(CoreDb.count(tenant, "select count(*) from core.membership_role where person_id = ? and role = 'ADMIN'",
                coach)).isEqualTo(1);
        assertThat(CoreDb.auditRow(tenant, "admin.added")).containsEntry("targetId", coach.toString());
        add("cora@example.com", "Again", "Same").statusCode(200).body("otherRoles", contains("COACH"));
        assertThat(CoreDb.auditActions(tenant)).as("the repeat changes nothing").containsOnlyOnce("admin.added");
    }

    @Test
    void aPromotedMemberWithoutLoginIsGivenOne() {
        UUID parent = CoreDb.person(tenant, "Pam", "Parent", "pam@example.com", TenantRole.PARENT);
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);

        String password = add("pam@example.com", "Pam", "Parent").statusCode(200)
                .header("Cache-Control", "no-store")
                .body("personId", equalTo(parent.toString()))
                .body("invitationStatus", equalTo("PENDING"))
                .body("otherRoles", contains("PARENT"))
                .extract().path("temporaryPassword");

        keycloak.verify(1, temporaryPasswordSet(sub));
        assertThat(temporaryPasswordSentFor(keycloak, sub)).isEqualTo(password);
        assertThat(CoreDb.count(tenant, "select count(*) from core.user_membership_index where person_id = ?", parent))
                .isEqualTo(1);
    }

    @Test
    void addConflictsAndFailuresLeaveNothingBehind() {
        UUID gone = CoreDb.person(tenant, "Old", "Member", "old@example.com", TenantRole.COACH);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.person set active = false where id = ?", gone));
        add("old@example.com", "Old", "Member").statusCode(409).body("code", equalTo("EMAIL_TAKEN"));
        keycloak.verify(0, userCreated());

        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);
        KeycloakStubs.temporaryPasswordFails(keycloak);
        given().filter(Contract.CORE).contentType(ContentType.JSON)
                .body(addBody("mailfail@example.com", "Mai", "Lfail")).post(admins()).then()
                .statusCode(502).body("code", equalTo("IDENTITY_PROVIDER_UNAVAILABLE"));
        keycloak.verify(1, userDeleted(sub));
        assertThat(CoreDb.count(tenant, "select count(*) from core.person where email = 'mailfail@example.com'")).isZero();
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("admin.added");
    }

    @Test
    void anExistingLoginOfAnotherMemberIsAlreadyAMember() {
        KeycloakStubs.existingUser(keycloak, "alias@example.com", adminSub);
        add("alias@example.com", "Ali", "As").statusCode(409).body("code", equalTo("LOGIN_ALREADY_MEMBER"));
    }

    @Test
    void invalidAddRequestsAreRejected() {
        given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON)
                .body("{\"givenName\":\"No\",\"familyName\":\"Mail\"}").post(admins()).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON)
                .body(addBody("not-an-email", "A", "B")).post(admins()).then().statusCode(400);
        keycloak.verify(0, userCreated());
    }

    // ------------------------------------------------------------------ edit

    @Test
    void editNamesAndEmailMovesTheLogin() {
        patch(admin, "{\"givenName\":\"Adah\",\"email\":\"adah@example.com\"}").statusCode(200)
                .body("givenName", equalTo("Adah"))
                .body("familyName", equalTo("Zeta"))
                .body("email", equalTo("adah@example.com"));

        keycloak.verify(1, KeycloakStubs.loginMoved(adminSub, "adah@example.com"));
        keycloak.verify(0, anySetupEmail());
        keycloak.verify(0, anyPasswordReset());
        assertThat(CoreDb.count(null, "select count(*) from core.app_user where keycloak_sub = ? and email = ?",
                adminSub, "adah@example.com")).isEqualTo(1);
        assertThat(CoreDb.auditActions(tenant)).endsWith("admin.updated", "member.updated",
                "member.login_email_changed");
        assertThat(CoreDb.auditRow(tenant, "admin.updated")).containsEntry("actorSub", "platform-admin");
        assertThat(CoreDb.auditRow(tenant, "admin.updated").get("metadata")).contains("givenName", "email")
                .doesNotContain("adah@example.com", "Adah");
    }

    // ------------------------------------------------------------------ edit: a login shared by several academies (WP31)

    @Test
    void theSuperAdminMovesASharedLoginInEveryAcademyThatUsesIt() {
        String other = Members.newTenant();
        UUID parent = sharedWith(other);
        String left = Members.newTenant();
        UUID former = sharedWith(left);
        CoreDb.inTenant(left, c -> {
            CoreDb.update(c, "update core.person set active = false where id = ?", former);
            return CoreDb.update(c, "delete from core.user_membership_index where person_id = ?", former);
        });

        patch(admin, "{\"email\":\"moved@example.com\"}").statusCode(200).body("email", equalTo("moved@example.com"));

        keycloak.verify(1, KeycloakStubs.loginMoved(adminSub, "moved@example.com"));
        assertThat(emailOf(tenant, admin)).isEqualTo("moved@example.com");
        assertThat(emailOf(other, parent)).as("the other academy's member is the same person").isEqualTo("moved@example.com");
        assertThat(CoreDb.auditActions(other)).containsExactly("member.login_email_changed");
        assertThat(CoreDb.auditRow(other, "member.login_email_changed"))
                .containsEntry("actorSub", "platform-admin")
                .containsEntry("actorPersonId", null)
                .containsEntry("targetType", "person")
                .containsEntry("targetId", parent.toString())
                .containsEntry("metadata", "{}");
        assertThat(CoreDb.auditActions(tenant)).containsOnlyOnce("member.login_email_changed");
        assertThat(emailOf(left, former)).as("an academy the person left keeps its record").isEqualTo(oldEmail());
        assertThat(CoreDb.auditActions(left)).isEmpty();
    }

    @Test
    void anEmailUsedByAnotherMemberOfAnAcademySharingTheLoginIsTaken() {
        String other = Members.newTenant();
        UUID parent = sharedWith(other);
        CoreDb.person(other, "Some", "One", "taken.there@example.com", TenantRole.COACH);

        given().filter(Contract.CORE).contentType(ContentType.JSON).body("{\"email\":\"Taken.There@example.com\"}")
                .patch(admins() + "/" + admin).then().statusCode(409).contentType("application/problem+json")
                .body("code", equalTo("EMAIL_TAKEN"));

        keycloak.verify(0, anyLoginUpdate());
        assertThat(emailOf(tenant, admin)).isEqualTo(oldEmail());
        assertThat(emailOf(other, parent)).isEqualTo(oldEmail());
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("admin.updated", "member.login_email_changed");
        assertThat(CoreDb.auditActions(other)).isEmpty();
    }

    @Test
    void aKeycloakFailureLeavesEveryAcademyOfASharedLoginUnchanged() {
        String other = Members.newTenant();
        UUID parent = sharedWith(other);
        KeycloakStubs.loginUpdateFails(keycloak);

        given().filter(Contract.CORE).contentType(ContentType.JSON).body("{\"email\":\"lost@example.com\"}")
                .patch(admins() + "/" + admin).then().statusCode(502);

        assertThat(emailOf(tenant, admin)).isEqualTo(oldEmail());
        assertThat(emailOf(other, parent)).isEqualTo(oldEmail());
        assertThat(CoreDb.auditActions(other)).isEmpty();
    }

    @Test
    @TestSecurity(user = TenantUser.SUBJECT)
    void anAcademyAdminStillCannotMoveASharedLogin() {
        String other = Members.newTenant();
        UUID parent = sharedWith(other);
        Members.signIn(tenant, TenantRole.ADMIN);

        given().filter(Contract.CORE).header("X-Tenant-Id", tenant).contentType(ContentType.JSON)
                .body("{\"email\":\"takeover@example.com\"}").patch("/api/core/members/" + admin).then()
                .statusCode(409).body("code", equalTo("LOGIN_SHARED"));

        keycloak.verify(0, anyLoginUpdate());
        assertThat(emailOf(tenant, admin)).isEqualTo(oldEmail());
        assertThat(emailOf(other, parent)).isEqualTo(oldEmail());
        assertThat(CoreDb.auditActions(other)).isEmpty();
    }

    @Test
    void aPendingAdminWithACorrectedEmailKeepsTheTemporaryPasswordAndGetsNoMail() {
        String sub = UUID.randomUUID().toString();
        UUID pending = withLogin(sub, "Typo", "Admin", "tpyo@example.com", "PENDING", TenantRole.ADMIN);
        patch(pending, "{\"email\":\"typo@example.com\"}").statusCode(200).body("invitationStatus", equalTo("PENDING"))
                .body("$", not(hasKey("temporaryPassword")));
        keycloak.verify(1, KeycloakStubs.loginMoved(sub, "typo@example.com"));
        keycloak.verify(0, anyPasswordReset());
        keycloak.verify(0, anySetupEmail());
    }

    @Test
    void keycloakFailureOnEditChangesNothing() {
        KeycloakStubs.loginUpdateFails(keycloak);
        given().filter(Contract.CORE).contentType(ContentType.JSON).body("{\"email\":\"lost@example.com\"}")
                .patch(admins() + "/" + admin).then().statusCode(502)
                .body("code", equalTo("IDENTITY_PROVIDER_UNAVAILABLE"));
        given().filter(Contract.CORE).get(admins()).then().body("items[0].email", equalTo("ada." + tenant + "@example.com"));
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("admin.updated");
    }

    @Test
    void onlyActiveAdminsOfTheTenantCanBeEdited() {
        UUID coach = CoreDb.person(tenant, "Cy", "Coach", null, TenantRole.COACH);
        String other = Members.newTenant();
        UUID foreign = CoreDb.person(other, "Fo", "Reign", null, TenantRole.ADMIN);
        patch(coach, "{\"givenName\":\"Hacked\"}").statusCode(404);
        patch(foreign, "{\"givenName\":\"Hacked\"}").statusCode(404);
        patch(UUID.randomUUID(), "{\"givenName\":\"Nobody\"}").statusCode(404);
        given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON).body("{\"phone\":\"+34 600\"}")
                .patch(admins() + "/" + admin).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON).body("{\"email\":null}")
                .patch(admins() + "/" + admin).then().statusCode(400);
        given().filter(Contract.RESPONSES_ONLY).contentType(ContentType.JSON).body("{}")
                .patch(admins() + "/" + admin).then().statusCode(400);
        keycloak.verify(0, anyLoginUpdate());
    }

    // ------------------------------------------------------------------ remove

    @Test
    void removeDropsTheRoleOrDeactivatesButNeverTheLastAdmin() {
        UUID both = CoreDb.person(tenant, "Bo", "Both", null, TenantRole.ADMIN, TenantRole.COACH);

        remove(both).statusCode(204);
        assertThat(CoreDb.count(tenant, "select count(*) from core.person where id = ? and active", both)).isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.membership_role where person_id = ?", both))
                .isEqualTo(1);

        remove(admin).statusCode(409).contentType("application/problem+json")
                .body("code", equalTo("LAST_ADMIN"))
                .body("detail", containsString("at least one active administrator"));

        UUID second = withLogin(UUID.randomUUID().toString(), "Sec", "Ond", "second@example.com", "ACCEPTED",
                TenantRole.ADMIN);
        remove(admin).statusCode(204);
        assertThat(CoreDb.count(tenant, "select count(*) from core.person where id = ? and not active", admin))
                .isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.user_membership_index where person_id = ?", admin))
                .isZero();
        keycloak.verify(0, KeycloakStubs.anyUserDeleted());
        remove(admin).statusCode(404);
        given().filter(Contract.CORE).get(admins()).then().body("items.personId", contains(second.toString()));
        assertThat(CoreDb.auditActions(tenant)).filteredOn("admin.removed"::equals).hasSize(2);
        assertThat(CoreDb.auditRow(tenant, "admin.removed").get("metadata")).contains("membershipDeactivated");
    }

    // ------------------------------------------------------------------ temporary password (ADR-0024)

    @Test
    void aPendingAdminWithoutAnyPasswordGetsATemporaryOneShownOnce() {
        String sub = UUID.randomUUID().toString();
        UUID pending = withLogin(sub, "Pen", "Ding", "pen@example.com", "PENDING", TenantRole.ADMIN);

        try (LogCapture logs = LogCapture.start()) {
            String password = issue(pending).statusCode(200).header("Cache-Control", "no-store")
                    .body("personId", equalTo(pending.toString())).body("invitationStatus", equalTo("PENDING"))
                    .extract().path("temporaryPassword");

            keycloak.verify(1, temporaryPasswordSet(sub));
            assertThat(temporaryPasswordSentFor(keycloak, sub)).isEqualTo(password);
            PasswordLeaks.assertNeverStoredOrLogged(tenant, password, logs);
        }
        assertThat(CoreDb.auditActions(tenant)).endsWith("admin.temporary_password_issued",
                "member.temporary_password_issued");
        assertThat(CoreDb.auditRow(tenant, "admin.temporary_password_issued")).containsEntry("targetId",
                pending.toString()).containsEntry("actorSub", "platform-admin");
        keycloak.verify(0, anySetupEmail());
    }

    @Test
    void aNewTemporaryPasswordReplacesAnUnusedOne() {
        String sub = UUID.randomUUID().toString();
        UUID pending = withLogin(sub, "Re", "Issue", "reissue@example.com", "PENDING", TenantRole.ADMIN);
        KeycloakStubs.temporaryPassword(keycloak, sub);
        String first = issue(pending).statusCode(200).extract().path("temporaryPassword");
        String second = issue(pending).statusCode(200).extract().path("temporaryPassword");
        assertThat(second).isNotEqualTo(first);
        keycloak.verify(2, temporaryPasswordSet(sub));
    }

    @Test
    void onlyAPendingInvitationWithoutAChosenPasswordGetsATemporaryPassword() {
        issue(admin).statusCode(409).body("code", equalTo("INVITATION_NOT_PENDING"));

        UUID noLogin = CoreDb.person(tenant, "No", "Login", "nologin@example.com", TenantRole.ADMIN);
        issue(noLogin).statusCode(409).body("code", equalTo("INVITATION_NOT_PENDING"));

        String sub = UUID.randomUUID().toString();
        UUID signedInElsewhere = withLogin(sub, "Else", "Where", "elsewhere@example.com", "PENDING", TenantRole.ADMIN);
        KeycloakStubs.ownPassword(keycloak, sub);
        issue(signedInElsewhere).statusCode(409).body("code", equalTo("INVITATION_NOT_PENDING"));

        keycloak.verify(0, anyPasswordReset());
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("admin.temporary_password_issued");
    }

    @Test
    void onlyActiveAdminsOfAManagedTenantGetATemporaryPassword() {
        UUID coach = withLogin(UUID.randomUUID().toString(), "Co", "Ach", "co@example.com", "PENDING",
                TenantRole.COACH);
        UUID foreign = CoreDb.person(Members.newTenant(), "Fo", "Reign", null, TenantRole.ADMIN);
        issue(coach).statusCode(404);
        issue(foreign).statusCode(404);
        issue(UUID.randomUUID()).statusCode(404);

        String withdrawn = UUID.randomUUID().toString();
        CoreDb.tenant(withdrawn, "WITHDRAWN");
        given().filter(Contract.CORE).post(admins(withdrawn) + "/" + UUID.randomUUID() + "/temporary-password").then()
                .statusCode(409).body("code", equalTo("TENANT_WITHDRAWN"));
        keycloak.verify(0, anyPasswordReset());
    }

    @Test
    void theSuperAdminAlsoResetsALoginSharedWithAnotherTenant() {
        String sub = UUID.randomUUID().toString();
        UUID pending = withLogin(sub, "Sha", "Red", "shared.pending@example.com", "PENDING", TenantRole.ADMIN);
        CoreDb.person(Members.newTenant(), CoreDb.login(sub), "Sha", "Red", null, null, null, TenantRole.PARENT);
        issue(pending).statusCode(200).body("temporaryPassword", notNullValue());
    }

    @Test
    void aKeycloakFailureChangesNothing() {
        UUID pending = withLogin(UUID.randomUUID().toString(), "Kc", "Down", "kcdown@example.com", "PENDING",
                TenantRole.ADMIN);
        KeycloakStubs.temporaryPasswordFails(keycloak);
        given().filter(Contract.CORE).post(admins() + "/" + pending + "/temporary-password").then()
                .statusCode(502).body("code", equalTo("IDENTITY_PROVIDER_UNAVAILABLE"));
        assertThat(CoreDb.auditActions(tenant)).doesNotContain("admin.temporary_password_issued",
                "member.temporary_password_issued");
    }

    @Test
    void theDeprecatedResendInvitationIsAnAliasOfTheReissue() {
        String sub = UUID.randomUUID().toString();
        UUID pending = withLogin(sub, "Old", "Client", "old.client@example.com", "PENDING", TenantRole.ADMIN);
        given().filter(Contract.CORE).post(admins() + "/" + pending + "/resend-invitation").then().statusCode(202)
                .header("Cache-Control", "no-store")
                .body("personId", equalTo(pending.toString())).body("temporaryPassword", notNullValue());
        keycloak.verify(1, temporaryPasswordSet(sub));
        given().filter(Contract.CORE).post(admins() + "/" + admin + "/resend-invitation").then().statusCode(409)
                .body("code", equalTo("INVITATION_NOT_PENDING"));
    }

    // ------------------------------------------------------------------ tenant state and authorization

    @Test
    void aWithdrawnTenantsAdminsCannotBeManagedButASuspendedOnesCan() {
        String withdrawn = UUID.randomUUID().toString();
        CoreDb.tenant(withdrawn, "WITHDRAWN");
        given().filter(Contract.CORE).get(admins(withdrawn)).then().statusCode(409)
                .body("code", equalTo("TENANT_WITHDRAWN"));
        given().filter(Contract.CORE).contentType(ContentType.JSON).body(addBody("x@example.com", "X", "Y"))
                .post(admins(withdrawn)).then().statusCode(409).body("code", equalTo("TENANT_WITHDRAWN"));
        given().filter(Contract.CORE).delete(admins(withdrawn) + "/" + UUID.randomUUID()).then().statusCode(409);

        String suspended = UUID.randomUUID().toString();
        CoreDb.tenant(suspended, "SUSPENDED");
        given().filter(Contract.CORE).get(admins(suspended)).then().statusCode(200).body("items", empty());
        keycloak.verify(0, userCreated());
    }

    @Test
    void anUnknownTenantIsNotFound() {
        String unknown = UUID.randomUUID().toString();
        given().filter(Contract.CORE).get(admins(unknown)).then().statusCode(404);
        given().filter(Contract.CORE).contentType(ContentType.JSON).body(addBody("x@example.com", "X", "Y"))
                .post(admins(unknown)).then().statusCode(404);
        keycloak.verify(0, userCreated());
    }

    @Test
    @TestSecurity(user = "academy-admin", roles = "user")
    void nonSuperAdminIsForbidden() {
        given().filter(Contract.CORE).get(admins()).then().statusCode(403);
        given().filter(Contract.CORE).contentType(ContentType.JSON).body(addBody("x@example.com", "X", "Y"))
                .post(admins()).then().statusCode(403);
        given().filter(Contract.CORE).delete(admins() + "/" + admin).then().statusCode(403);
        issue(admin).statusCode(403);
        keycloak.verify(0, anyPasswordReset());
    }

    @Test
    @TestSecurity
    void anonymousIsUnauthorized() {
        given().filter(Contract.CORE).get(admins()).then().statusCode(401).contentType("application/problem+json");
    }

    // ------------------------------------------------------------------ helpers

    private UUID withLogin(String sub, String given, String family, String email, String invitation,
            TenantRole... roles) {
        UUID user = CoreDb.appUser(sub, email);
        UUID person = CoreDb.person(tenant, user, given, family, email, null, null, roles);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.person set invitation_status = ? where id = ?",
                invitation, person));
        KeycloakStubs.login(keycloak, sub, email);
        return person;
    }

    /** The tenant admin's login also used by an active PARENT of {@code other}, with the same e-mail there. */
    private UUID sharedWith(String other) {
        return CoreDb.person(other, CoreDb.login(adminSub), "Ada", "Zeta", oldEmail(), null, null, TenantRole.PARENT);
    }

    private String oldEmail() {
        return "ada." + tenant + "@example.com";
    }

    private static String emailOf(String tenantId, UUID person) {
        return RosterDb.text(tenantId, "select email from core.person where id = ?", person);
    }

    private String admins() {
        return admins(tenant);
    }

    private static String admins(String tenantId) {
        return "/platform/tenants/" + tenantId + "/admins";
    }

    private ValidatableResponse add(String email, String given, String family) {
        return given().filter(Contract.CORE).contentType(ContentType.JSON).body(addBody(email, given, family))
                .post(admins()).then();
    }

    private ValidatableResponse patch(UUID person, String body) {
        return given().filter(Contract.CORE).contentType(ContentType.JSON).body(body)
                .patch(admins() + "/" + person).then();
    }

    private ValidatableResponse issue(UUID person) {
        return given().filter(Contract.CORE).post(admins() + "/" + person + "/temporary-password").then();
    }

    private ValidatableResponse remove(UUID person) {
        return given().filter(Contract.CORE).delete(admins() + "/" + person).then();
    }

    private static String addBody(String email, String given, String family) {
        return """
                {"email":"%s","givenName":"%s","familyName":"%s","locale":"en"}""".formatted(email, given, family);
    }
}
