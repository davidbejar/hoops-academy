package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.github.tomakehurst.wiremock.WireMockServer;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.common.testing.TenantUserRegistry;
import com.hoopsacademy.core.testsupport.Approvals;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.http.ContentType;
import java.util.EnumSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class PlayerResourceTest {

    @InjectWireMock
    WireMockServer keycloak;

    private String tenant;
    private Approvals api;
    private UUID season;
    private Map<String, UUID> categories;
    private UUID lions;
    private UUID admin;
    private UUID coach;

    @BeforeEach
    void anAcademyWithAnU12TeamAndItsCoach() {
        KeycloakStubs.installDefaults(keycloak);
        tenant = Members.newTenant();
        api = new Approvals(tenant);
        season = RosterDb.currentSeason(tenant);
        categories = RosterDb.defaultCategories(tenant);
        lions = RosterDb.team(tenant, season, "Lions", categories.get("U12"), "MIXED");
        admin = RosterDb.callerPerson(tenant);
        coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        RosterDb.staff(tenant, lions, coach, "COACH");
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    private void signInCoach() {
        Members.signInAs(tenant, coach, EnumSet.of(TenantRole.COACH), Set.of(lions));
    }

    private void signInCoachOfNothing() {
        UUID other = CoreDb.person(tenant, "Otto", "Other", null, TenantRole.COACH);
        Members.signInAs(tenant, other, EnumSet.of(TenantRole.COACH), Set.of());
    }

    private UUID createdPlayer(io.restassured.response.ValidatableResponse response) {
        return UUID.fromString(response.extract().path("player.id"));
    }

    @Test
    void anAdminAddsAPlayerDirectlyWithAnAutoApprovedAuditRow() {
        var response = api.create(Approvals.playerJson("Ann", "FEMALE", 11, ",\"email\":\"ann@example.org\""))
                .statusCode(201)
                .body("player.status", equalTo("ORPHAN"))
                .body("player.givenName", equalTo("Ann")).body("player.familyName", equalTo("Test"))
                .body("player.displayName", equalTo("Ann Test")).body("player.gender", equalTo("FEMALE"))
                .body("player.naturalCategory.code", equalTo("U12")).body("player.teams", empty())
                .body("approvalRequest.status", equalTo("APPROVED")).body("approvalRequest.action", equalTo("ADD_PLAYER"))
                .body("approvalRequest.decidedBy.personId", equalTo(admin.toString()))
                .body("approvalRequest.requestedBy.personId", equalTo(admin.toString()))
                .body("approvalRequest.decidedAt", notNullValue());
        UUID player = createdPlayer(response);
        assertThat(RosterDb.playerStatus(tenant, player)).isEqualTo("ORPHAN");
        assertThat(CoreDb.count(tenant, "select count(*) from core.membership_role r join core.player p "
                + "on p.person_id = r.person_id where p.id = ? and r.role = 'PLAYER'", player)).isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.approval_request where status = 'APPROVED'")).isEqualTo(1);
        assertThat(api.outbox("player.approved")).isEqualTo(1);
        assertThat(CoreDb.auditActions(tenant)).containsExactly("player.approved");
        api.getPlayer(player).statusCode(200).body("status", equalTo("ORPHAN"));
        api.request().queryParam("status", "ORPHAN").get("/api/core/players").then().statusCode(200)
                .body("items.id", contains(player.toString()));
    }

    @Test
    void aPlayerWithAnEmailGetsALoginWithATemporaryPasswordShownOnce() {
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);

        var response = api.create(Approvals.playerJson("Lia", "FEMALE", 11, ",\"email\":\"lia@example.org\""))
                .statusCode(201).header("Cache-Control", "no-store");
        UUID player = createdPlayer(response);
        String password = response.extract().path("temporaryPassword");

        keycloak.verify(1, KeycloakStubs.userCreated());
        keycloak.verify(1, KeycloakStubs.temporaryPasswordSet(sub));
        assertThat(KeycloakStubs.temporaryPasswordSentFor(keycloak, sub)).isEqualTo(password);
        assertThat(CoreDb.tablesContaining(tenant, password)).isEmpty();
        keycloak.verify(0, KeycloakStubs.anySetupEmail());
        assertThat(CoreDb.count(tenant, "select count(*) from core.player p join core.person s on s.id = p.person_id "
                + "join core.app_user u on u.id = s.user_id where p.id = ? and u.keycloak_sub = ? "
                + "and s.invitation_status = 'PENDING'", player, sub)).isEqualTo(1);
        assertThat(CoreDb.count(tenant, "select count(*) from core.user_membership_index where keycloak_sub = ?", sub))
                .isEqualTo(1);
    }

    @Test
    void anExistingKeycloakUserIsLinkedWithoutAnEmail() {
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.existingUser(keycloak, "known@example.org", sub);

        api.create(Approvals.playerJson("Kim", "FEMALE", 11, ",\"email\":\"known@example.org\"")).statusCode(201)
                .body("$", not(org.hamcrest.Matchers.hasKey("temporaryPassword")));

        keycloak.verify(0, KeycloakStubs.userCreated());
        keycloak.verify(0, KeycloakStubs.anyPasswordReset());
        assertThat(CoreDb.count(tenant, "select count(*) from core.person s join core.app_user u on u.id = s.user_id "
                + "where u.keycloak_sub = ? and s.invitation_status = 'ACCEPTED'", sub)).isEqualTo(1);
    }

    @Test
    void aFailingTemporaryPasswordLeavesNoPlayerAndDeletesTheNewLogin() {
        String sub = UUID.randomUUID().toString();
        KeycloakStubs.createdUserGets(keycloak, sub);
        KeycloakStubs.temporaryPasswordFails(keycloak);
        long persons = CoreDb.count(tenant, "select count(*) from core.person");

        api.create(Approvals.playerJson("Lia", "FEMALE", 11, ",\"email\":\"lia2@example.org\"")).statusCode(502)
                .body("code", equalTo("IDENTITY_PROVIDER_UNAVAILABLE"));

        keycloak.verify(1, KeycloakStubs.userDeleted(sub));
        assertThat(CoreDb.count(tenant, "select count(*) from core.person")).isEqualTo(persons);
        assertThat(CoreDb.auditActions(tenant)).isEmpty();
    }

    @Test
    void anEmailTakenInTheTenantFailsBeforeKeycloakIsCalled() {
        api.create(Approvals.playerJson("Ann", "FEMALE", 11, ",\"email\":\"twice@example.org\"")).statusCode(201);
        keycloak.resetRequests();
        api.create(Approvals.playerJson("Bea", "FEMALE", 11, ",\"email\":\"twice@example.org\"")).statusCode(409)
                .body("code", equalTo("EMAIL_TAKEN"));
        keycloak.verify(0, KeycloakStubs.userCreated());
    }

    @Test
    void anAdminMayAssignTheInitialTeamAndIneligibleOnesAreRejectedWithNothingLeftBehind() {
        api.create(Approvals.playerJson("Uma", "FEMALE", 11, ",\"teamId\":\"" + lions + "\",\"jerseyNumber\":\"7\""))
                .statusCode(201)
                .body("player.status", equalTo("ACTIVE"))
                .body("player.teams[0].team.id", equalTo(lions.toString()))
                .body("player.teams[0].team.name", equalTo("Lions"))
                .body("player.teams[0].jerseyNumber", equalTo("7")).body("player.teams[0].valid", equalTo(true))
                .body("approvalRequest.payload.teamId", equalTo(lions.toString()))
                .body("approvalRequest.payload.jerseyNumber", equalTo("7"));

        long persons = CoreDb.count(tenant, "select count(*) from core.person");
        api.create(Approvals.playerJson("Tom", "MALE", 13, ",\"teamId\":\"" + lions + "\"")).statusCode(422)
                .body("code", equalTo("PLAYER_INELIGIBLE")).body("violations.code", contains("CATEGORY_TOO_LOW"));
        api.create(Approvals.playerJson("Ben", "MALE", 11, ",\"teamId\":\"" + lions + "\",\"jerseyNumber\":\"7\""))
                .statusCode(409).body("code", equalTo("JERSEY_NUMBER_TAKEN"));
        assertThat(CoreDb.count(tenant, "select count(*) from core.person")).isEqualTo(persons);
        assertThat(CoreDb.count(tenant, "select count(*) from core.approval_request")).isEqualTo(1);
    }

    @Test
    void invalidRequestsAreRejected() {
        api.create(Approvals.playerJson("Ann", "FEMALE", 11, ",\"teamId\":\"" + UUID.randomUUID() + "\""))
                .statusCode(404);
        api.create(Approvals.playerJson("Ann", "FEMALE", 11, ",\"email\":\"dup@example.org\"")).statusCode(201);
        api.create(Approvals.playerJson("Bea", "FEMALE", 11, ",\"email\":\"dup@example.org\"")).statusCode(409)
                .body("code", equalTo("EMAIL_TAKEN"));
        api.lenientRequest().contentType(ContentType.JSON).body("{\"givenName\":\"X\",\"familyName\":\"Y\"}")
                .post("/api/core/players").then().statusCode(400);
    }

    @Test
    void aCoachRequestsAPlayerWhoStaysPendingAndUnassigned() {
        signInCoach();
        var response = api.create(Approvals.playerJson("Pia", "FEMALE", 11,
                        ",\"teamId\":\"" + lions + "\",\"jerseyNumber\":\"5\",\"note\":\"great shooter\""))
                .statusCode(202)
                .body("player.status", equalTo("PENDING_APPROVAL")).body("player.teams", empty())
                .body("approvalRequest.status", equalTo("PENDING"))
                .body("approvalRequest.requestedBy.personId", equalTo(coach.toString()))
                .body("approvalRequest.payload.note", equalTo("great shooter"))
                .body("approvalRequest.payload.teamId", equalTo(lions.toString()))
                .body("approvalRequest.decidedBy", nullValue());
        UUID player = createdPlayer(response);
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where player_id = ?", player)).isZero();
        assertThat(api.outbox("player.requested")).isEqualTo(1);
        assertThat(api.outbox("player.approved")).isZero();
    }

    @Test
    void aCoachMayOnlyRequestForOwnTeamsAndUnknownTeamsAreNotFound() {
        UUID others = RosterDb.team(tenant, season, "Others", categories.get("U12"), "MIXED");
        signInCoach();
        api.create(Approvals.playerJson("Pia", "FEMALE", 11, ",\"teamId\":\"" + others + "\"")).statusCode(403);
        api.create(Approvals.playerJson("Pia", "FEMALE", 11, ",\"teamId\":\"" + UUID.randomUUID() + "\"")).statusCode(404);
        api.create(Approvals.playerJson("Pia", "FEMALE", 11, "")).statusCode(202);
        assertThat(CoreDb.count(tenant, "select count(*) from core.approval_request")).isEqualTo(1);
    }

    static Stream<Arguments> addCallers() {
        return Stream.of(
                Arguments.of(EnumSet.of(TenantRole.ADMIN), 201),
                Arguments.of(EnumSet.of(TenantRole.COACH), 202),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH), 403),
                Arguments.of(EnumSet.of(TenantRole.PARENT), 403),
                Arguments.of(EnumSet.of(TenantRole.PLAYER), 403),
                Arguments.of(EnumSet.of(TenantRole.ADMIN, TenantRole.COACH), 201),
                Arguments.of(EnumSet.of(TenantRole.COACH, TenantRole.PARENT), 202));
    }

    @ParameterizedTest
    @MethodSource("addCallers")
    void roleMatrixOfAddAndWithdraw(Set<TenantRole> roles, int addStatus) {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        RosterDb.assignment(tenant, lions, ben, "9");
        Members.signInAs(tenant, roles.contains(TenantRole.COACH) && !roles.contains(TenantRole.ADMIN) ? coach : admin,
                roles, Set.of(lions));
        api.create(Approvals.playerJson("Pia", "FEMALE", 11, "")).statusCode(addStatus);
        int withdrawStatus = switch (addStatus) {
            case 201 -> 200;
            default -> addStatus;
        };
        api.withdraw(ben).statusCode(withdrawStatus);
    }

    @Test
    void pendingPlayersAreVisibleToAdminsAndTheirRequesterOnly() {
        signInCoach();
        UUID pia = createdPlayer(api.create(Approvals.playerJson("Pia", "FEMALE", 11, "")).statusCode(202));
        UUID ann = RosterDb.playerAged(tenant, "Ann", 11, "FEMALE");

        api.getPlayer(pia).statusCode(200).body("status", equalTo("PENDING_APPROVAL"));
        api.request().get("/api/core/players").then().statusCode(200).body("items.id", containsInAnyOrder(pia.toString(), ann.toString()));

        signInCoachOfNothing();
        api.getPlayer(pia).statusCode(404);
        api.request().get("/api/core/players").then().statusCode(200).body("items.id", contains(ann.toString()))
                .body("page.totalElements", equalTo(1));
        api.request().queryParam("status", "PENDING_APPROVAL").get("/api/core/players").then().statusCode(200)
                .body("items", empty());
        api.getPlayer(ann).statusCode(200);

        Members.signIn(tenant, TenantRole.ASSISTANT_COACH);
        api.getPlayer(pia).statusCode(404);

        Members.signIn(tenant, TenantRole.ADMIN);
        api.getPlayer(pia).statusCode(200);
        api.request().queryParam("status", "PENDING_APPROVAL").get("/api/core/players").then().body("items.id", contains(pia.toString()));
    }

    @Test
    void parentsAndPlayersSeeOnlyLinkedAndOwnPlayersAndNeverPendingOnes() {
        UUID ann = RosterDb.playerAged(tenant, "Ann", 11, "FEMALE");
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        UUID pending = RosterDb.playerAged(tenant, "Pen", 11, "MALE");
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.player set status = 'PENDING_APPROVAL' where id = ?", pending));

        signInWith(EnumSet.of(TenantRole.PARENT), Set.of(ann, pending), Optional.empty());
        api.request().get("/api/core/players").then().statusCode(200).body("items.id", contains(ann.toString()));
        api.getPlayer(ann).statusCode(200);
        api.getPlayer(ben).statusCode(404);
        api.getPlayer(pending).statusCode(404);

        signInWith(EnumSet.of(TenantRole.PLAYER), Set.of(), Optional.of(ben));
        api.request().get("/api/core/players").then().statusCode(200).body("items.id", contains(ben.toString()));
        api.getPlayer(ben).statusCode(200);
        api.getPlayer(ann).statusCode(404);

        signInWith(EnumSet.of(TenantRole.PARENT), Set.of(), Optional.empty());
        api.request().get("/api/core/players").then().statusCode(200).body("items", empty())
                .body("page.totalElements", equalTo(0));
    }

    private void signInWith(Set<TenantRole> roles, Set<UUID> linked, Optional<UUID> own) {
        TenantUserRegistry.clear();
        TenantUserRegistry.register(new AuthzContext(TenantUser.SUBJECT, Members.callerPersonId(tenant),
                TenantId.parse(tenant), roles, Set.of(), linked, own));
    }

    @Test
    void theListFiltersByStatusTeamAndNameAndPages() {
        UUID ann = RosterDb.playerAged(tenant, "Ann", 11, "FEMALE");
        UUID bea = RosterDb.playerAged(tenant, "Bea", 11, "FEMALE");
        UUID cat = RosterDb.playerAged(tenant, "Cat_50%", 11, "FEMALE");
        RosterDb.assignment(tenant, lions, ann, null);
        CoreDb.inTenant(tenant, c -> CoreDb.update(c, "update core.player set status = 'WITHDRAWN' where id = ?", cat));

        api.request().get("/api/core/players").then().statusCode(200).body("items.id", contains(ann.toString(), bea.toString(), cat.toString()))
                .body("items[0].teams[0].team.name", equalTo("Lions"))
                .body("page.totalElements", equalTo(3));
        api.request().queryParam("teamId", lions).get("/api/core/players").then().body("items.id", contains(ann.toString()));
        api.request().queryParam("status", "WITHDRAWN").get("/api/core/players").then().body("items.id", contains(cat.toString()));
        api.request().queryParam("q", "BE").get("/api/core/players").then().body("items.id", contains(bea.toString()));
        api.request().queryParam("q", "50%").get("/api/core/players").then().body("items.id", contains(cat.toString()));
        api.request().queryParam("q", "%").get("/api/core/players").then().body("items.id", contains(cat.toString()));
        api.request().queryParam("size", 2).queryParam("page", 1).get("/api/core/players").then()
                .body("items", hasSize(1)).body("page.totalPages", equalTo(2));
        api.lenientRequest().queryParam("status", "NOPE").get("/api/core/players").then().statusCode(400);
    }

    @Test
    void anAdminWithdrawsAPlayerAtOnceClosingAssignmentsAndResolvingCases() {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        UUID assignment = RosterDb.assignment(tenant, lions, ben, "9");
        UUID theCase = RosterDb.openCase(tenant, assignment, "CATEGORY_TOO_LOW");

        api.withdraw(ben).statusCode(200)
                .body("player.status", equalTo("WITHDRAWN")).body("player.teams", empty())
                .body("approvalRequest.action", equalTo("WITHDRAW_PLAYER"))
                .body("approvalRequest.status", equalTo("APPROVED"))
                .body("approvalRequest.payload.reason", equalTo("moved away"))
                .body("approvalRequest.decidedBy.personId", equalTo(admin.toString()));

        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where player_id = ? and left_on is null", ben)).isZero();
        assertThat(RosterDb.text(tenant, "select status || ':' || resolution from core.eligibility_case where id = ?", theCase))
                .isEqualTo("RESOLVED:REMOVED_FROM_TEAM");
        assertThat(RosterDb.text(tenant, "select resolved_by_person_id::text from core.eligibility_case where id = ?", theCase))
                .isEqualTo(admin.toString());
        assertThat(api.outbox("player.withdrawn")).isEqualTo(1);

        api.withdraw(ben).statusCode(409).body("code", equalTo("PLAYER_NOT_WITHDRAWABLE"));
        api.withdraw(UUID.randomUUID()).statusCode(404);
    }

    @Test
    void aCoachRequestsAWithdrawalAndThePlayerStaysActive() {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        RosterDb.assignment(tenant, lions, ben, "9");
        signInCoach();

        api.withdraw(ben).statusCode(202)
                .body("player.status", equalTo("ACTIVE")).body("player.teams", hasSize(1))
                .body("approvalRequest.status", equalTo("PENDING"))
                .body("approvalRequest.action", equalTo("WITHDRAW_PLAYER"))
                .body("approvalRequest.payload.reason", equalTo("moved away"));
        assertThat(RosterDb.playerStatus(tenant, ben)).isEqualTo("ACTIVE");
        api.withdraw(ben).statusCode(409).body("code", equalTo("APPROVAL_ALREADY_PENDING"));
        assertThat(api.outbox("player.requested")).isEqualTo(1);
    }

    @Test
    void aCoachCannotWithdrawPlayersOutsideTheirTeamsOrStillPendingOnes() {
        UUID others = RosterDb.team(tenant, season, "Others", categories.get("U12"), "MIXED");
        UUID eve = RosterDb.playerAged(tenant, "Eve", 11, "FEMALE");
        RosterDb.assignment(tenant, others, eve, null);
        UUID orphan = RosterDb.playerAged(tenant, "Ola", 11, "FEMALE");
        signInCoach();
        api.withdraw(eve).statusCode(403);
        api.withdraw(orphan).statusCode(403);
        UUID pia = createdPlayer(api.create(Approvals.playerJson("Pia", "FEMALE", 11, "")).statusCode(202));
        api.withdraw(pia).statusCode(409).body("code", equalTo("PLAYER_NOT_WITHDRAWABLE"));
        Members.signIn(tenant, TenantRole.ADMIN);
        api.withdraw(pia).statusCode(409);
    }

    @Test
    void withdrawalWithoutABodyIsAccepted() {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        api.request().contentType(ContentType.JSON).post("/api/core/players/" + ben + "/withdraw").then().statusCode(200)
                .body("approvalRequest.payload.reason", nullValue());
    }

    @Test
    void anotherTenantsPlayersAreNotFound() {
        UUID mine = RosterDb.playerAged(tenant, "Ann", 11, "FEMALE");
        String other = Members.newTenant();
        UUID theirs = RosterDb.playerAged(other, "Zed", 11, "MALE");
        RosterDb.callerPerson(other);
        Members.signIn(other, TenantRole.ADMIN);
        Approvals asOther = new Approvals(other);

        asOther.getPlayer(mine).statusCode(404);
        asOther.withdraw(mine).statusCode(404);
        asOther.request().get("/api/core/players").then().statusCode(200).body("items.id", contains(theirs.toString()))
                .body("items.id", not(hasItem(mine.toString())));
        assertThat(RosterDb.playerStatus(tenant, mine)).isEqualTo("ACTIVE");
        assertThat(CoreDb.count(tenant, "select count(*) from core.approval_request")).isZero();
    }
}
