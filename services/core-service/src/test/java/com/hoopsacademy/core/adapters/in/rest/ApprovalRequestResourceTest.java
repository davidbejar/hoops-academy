package com.hoopsacademy.core.adapters.in.rest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

import com.hoopsacademy.common.problem.ConflictException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.tenancy.TenantScope;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.application.port.ApprovalRepository;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.approvals.ApprovalRequestId;
import com.hoopsacademy.core.domain.membership.PersonId;
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
import jakarta.inject.Inject;
import java.time.Instant;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
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
class ApprovalRequestResourceTest {

    @Inject
    TenantScope tenantScope;

    @Inject
    ApprovalRepository repository;

    private String tenant;
    private Approvals api;
    private UUID season;
    private Map<String, UUID> categories;
    private UUID lions;
    private UUID admin;
    private UUID coach;

    @BeforeEach
    void anAcademyWithAnU12TeamAndItsCoach() {
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

    private void signInAdmin() {
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    /** The coach asks to add a player (optionally to the Lions); returns {playerId, requestId}. */
    private UUID[] coachAdds(String name, int age, boolean toLions) {
        signInCoach();
        var response = api.create(Approvals.playerJson(name, "FEMALE", age, toLions
                ? ",\"teamId\":\"" + lions + "\",\"jerseyNumber\":\"4\"" : "")).statusCode(202);
        signInAdmin();
        return new UUID[] {UUID.fromString(response.extract().path("player.id")),
                UUID.fromString(response.extract().path("approvalRequest.id"))};
    }

    private UUID coachWithdraws(UUID player) {
        signInCoach();
        UUID request = UUID.fromString(api.withdraw(player).statusCode(202).extract().path("approvalRequest.id"));
        signInAdmin();
        return request;
    }

    @Test
    void approvingAnAddActivatesThePlayerAndAppliesTheInitialAssignment() {
        UUID[] ids = coachAdds("Pia", 11, true);

        api.decide(ids[1], "approve", "welcome").statusCode(200)
                .body("status", equalTo("APPROVED")).body("decisionNote", equalTo("welcome"))
                .body("decidedBy.personId", equalTo(admin.toString())).body("decidedAt", notNullValue())
                .body("requestedBy.personId", equalTo(coach.toString()))
                .body("requestedBy.displayName", equalTo("Cora Coach")).body("player.displayName", equalTo("Pia Test"));

        api.getPlayer(ids[0]).body("status", equalTo("ACTIVE")).body("teams[0].team.id", equalTo(lions.toString()))
                .body("teams[0].jerseyNumber", equalTo("4"));
        assertThat(api.outbox("player.approved")).isEqualTo(1);
        api.getRequest(ids[1]).statusCode(200).body("status", equalTo("APPROVED"));
    }

    @Test
    void approvingWithoutATeamLeavesAnActiveOrphan() {
        UUID[] ids = coachAdds("Pia", 11, false);
        api.decide(ids[1], "approve", null).statusCode(200).body("decisionNote", nullValue());
        api.getPlayer(ids[0]).body("status", equalTo("ORPHAN")).body("teams", empty());
    }

    @Test
    void anIneligibleAssignmentFailsWith422AndTheRequestStaysPending() {
        UUID[] ids = coachAdds("Tom", 13, true);

        api.decide(ids[1], "approve", null).statusCode(422).body("code", equalTo("PLAYER_INELIGIBLE"))
                .body("violations.code", contains("CATEGORY_TOO_LOW"));

        api.getRequest(ids[1]).body("status", equalTo("PENDING")).body("decidedBy", nullValue());
        api.getPlayer(ids[0]).body("status", equalTo("PENDING_APPROVAL")).body("teams", empty());
        assertThat(api.outbox("player.approved")).isZero();

        api.decide(ids[1], "reject", "too old for U12").statusCode(200).body("status", equalTo("REJECTED"));
    }

    @Test
    void rejectingAnAddLeavesThePlayerWithdrawnAndNeedsANote() {
        UUID[] ids = coachAdds("Pia", 11, true);
        api.lenientRequest().contentType(ContentType.JSON).body("{}").post("/api/core/approval-requests/" + ids[1] + "/reject")
                .then().statusCode(400);
        api.lenientRequest().contentType(ContentType.JSON).body("{\"note\":\"  \"}")
                .post("/api/core/approval-requests/" + ids[1] + "/reject").then().statusCode(400);
        api.getRequest(ids[1]).body("status", equalTo("PENDING"));

        api.decide(ids[1], "reject", "no capacity").statusCode(200)
                .body("status", equalTo("REJECTED")).body("decisionNote", equalTo("no capacity"))
                .body("decidedBy.personId", equalTo(admin.toString()));
        api.getPlayer(ids[0]).body("status", equalTo("WITHDRAWN")).body("teams", empty());
        assertThat(api.outbox("player.rejected")).isEqualTo(1);
    }

    @Test
    void approvingAWithdrawalClosesAssignmentsAndResolvesCases() {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        UUID assignment = RosterDb.assignment(tenant, lions, ben, "9");
        UUID theCase = RosterDb.openCase(tenant, assignment, "CATEGORY_TOO_LOW");
        UUID request = coachWithdraws(ben);
        api.getPlayer(ben).body("status", equalTo("ACTIVE"));

        api.decide(request, "approve", null).statusCode(200).body("status", equalTo("APPROVED"));

        api.getPlayer(ben).body("status", equalTo("WITHDRAWN")).body("teams", empty());
        assertThat(CoreDb.count(tenant, "select count(*) from core.team_player where player_id = ? and left_on is null", ben)).isZero();
        assertThat(RosterDb.text(tenant, "select resolution from core.eligibility_case where id = ?", theCase))
                .isEqualTo("REMOVED_FROM_TEAM");
        assertThat(api.outbox("player.withdrawn")).isEqualTo(1);
    }

    @Test
    void rejectingAWithdrawalKeepsThePlayerAsIs() {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        RosterDb.assignment(tenant, lions, ben, "9");
        UUID request = coachWithdraws(ben);

        api.decide(request, "reject", "still needed").statusCode(200).body("status", equalTo("REJECTED"));

        api.getPlayer(ben).body("status", equalTo("ACTIVE")).body("teams", hasSize(1));
        assertThat(api.outbox("player.rejected")).isEqualTo(1);
        signInCoach();
        api.withdraw(ben).statusCode(202);
    }

    @Test
    void aDecidedRequestCannotBeDecidedAgain() {
        UUID[] ids = coachAdds("Pia", 11, false);
        api.decide(ids[1], "approve", null).statusCode(200);
        for (String verb : List.of("approve", "reject")) {
            api.decide(ids[1], verb, "again").statusCode(409).body("code", equalTo("NOT_PENDING"));
        }
        signInCoach();
        api.cancel(ids[1]).statusCode(409).body("code", equalTo("NOT_PENDING"));
        assertThat(api.outbox("player.approved")).isEqualTo(1);
        assertThat(api.outbox("player.rejected")).isZero();
    }

    @Test
    void theRequesterCancelsAPendingRequest() {
        UUID[] ids = coachAdds("Pia", 11, true);
        signInCoach();

        api.cancel(ids[1]).statusCode(200).body("status", equalTo("CANCELLED"))
                .body("decidedBy.personId", equalTo(coach.toString()));

        api.getPlayer(ids[0]).body("status", equalTo("WITHDRAWN"));
        signInAdmin();
        api.decide(ids[1], "approve", null).statusCode(409).body("code", equalTo("NOT_PENDING"));
        signInCoach();
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        RosterDb.assignment(tenant, lions, ben, null);
        UUID second = UUID.fromString(api.withdraw(ben).statusCode(202).extract().path("approvalRequest.id"));
        api.cancel(second).statusCode(200);
        api.getPlayer(ben).body("status", equalTo("ACTIVE"));
        api.withdraw(ben).statusCode(202);
    }

    @Test
    void nobodyElseCancelsARequest() {
        UUID[] ids = coachAdds("Pia", 11, false);
        UUID rival = CoreDb.person(tenant, "Rick", "Rival", null, TenantRole.COACH);
        Members.signInAs(tenant, rival, EnumSet.of(TenantRole.COACH), Set.of());
        api.cancel(ids[1]).statusCode(404);
        Members.signIn(tenant, TenantRole.ASSISTANT_COACH);
        api.cancel(ids[1]).statusCode(403);
        signInAdmin();
        api.cancel(ids[1]).statusCode(403);
        api.getRequest(ids[1]).body("status", equalTo("PENDING"));
    }

    static Stream<Arguments> deciders() {
        return Stream.of(
                Arguments.of(EnumSet.of(TenantRole.ADMIN), 200),
                Arguments.of(EnumSet.of(TenantRole.COACH), 403),
                Arguments.of(EnumSet.of(TenantRole.ASSISTANT_COACH), 403),
                Arguments.of(EnumSet.of(TenantRole.PARENT), 403),
                Arguments.of(EnumSet.of(TenantRole.PLAYER), 403),
                Arguments.of(EnumSet.of(TenantRole.ADMIN, TenantRole.COACH), 200),
                Arguments.of(EnumSet.of(TenantRole.COACH, TenantRole.PARENT), 403));
    }

    @ParameterizedTest
    @MethodSource("deciders")
    void onlyAnAdminApprovesAndRejects(Set<TenantRole> roles, int status) {
        UUID[] first = coachAdds("Pia", 11, false);
        UUID[] second = coachAdds("Pat", 11, false);
        Members.signInAs(tenant, coach, roles, Set.of(lions));
        api.decide(first[1], "approve", null).statusCode(status);
        api.decide(second[1], "reject", "no").statusCode(status);
    }

    @Test
    void aCoachCannotApproveTheirOwnRequest() {
        UUID[] ids = coachAdds("Pia", 11, false);
        signInCoach();
        api.decide(ids[1], "approve", null).statusCode(403);
        api.getRequest(ids[1]).body("status", equalTo("PENDING"));
    }

    @Test
    void adminsSeeEveryRequestAndCoachesTheirOwn() {
        UUID[] pia = coachAdds("Pia", 11, false);
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        RosterDb.assignment(tenant, lions, ben, null);
        UUID withdrawal = coachWithdraws(ben);
        UUID cat = UUID.fromString(api.create(Approvals.playerJson("Cat", "FEMALE", 11, "")).statusCode(201)
                .extract().path("approvalRequest.id"));
        UUID rival = CoreDb.person(tenant, "Rick", "Rival", null, TenantRole.COACH);
        api.decide(pia[1], "reject", "no");

        api.request().get("/api/core/approval-requests").then().statusCode(200).body("page.totalElements", equalTo(3))
                .body("items.id", containsInAnyOrder(pia[1].toString(), withdrawal.toString(), cat.toString()));
        api.request().queryParam("status", "PENDING").get("/api/core/approval-requests").then()
                .body("items.id", contains(withdrawal.toString()));
        api.request().queryParam("action", "ADD_PLAYER").get("/api/core/approval-requests").then()
                .body("items.id", containsInAnyOrder(pia[1].toString(), cat.toString()));
        api.request().queryParam("playerId", ben).get("/api/core/approval-requests").then()
                .body("items.id", contains(withdrawal.toString()));
        api.request().queryParam("size", 1).queryParam("page", 2).get("/api/core/approval-requests").then()
                .body("items", hasSize(1)).body("page.totalPages", equalTo(3));
        api.getRequest(cat).statusCode(200).body("status", equalTo("APPROVED"));

        signInCoach();
        api.request().get("/api/core/approval-requests").then().statusCode(200)
                .body("items.id", containsInAnyOrder(pia[1].toString(), withdrawal.toString()));
        api.getRequest(cat).statusCode(404);
        api.getRequest(withdrawal).statusCode(200);

        Members.signInAs(tenant, rival, EnumSet.of(TenantRole.COACH), Set.of());
        api.request().get("/api/core/approval-requests").then().body("items", empty());
        api.getRequest(withdrawal).statusCode(404);

        for (TenantRole role : List.of(TenantRole.ASSISTANT_COACH, TenantRole.PARENT, TenantRole.PLAYER)) {
            Members.signIn(tenant, role);
            api.request().get("/api/core/approval-requests").then().statusCode(403);
            api.getRequest(withdrawal).statusCode(403);
        }
    }

    @Test
    void unknownAndForeignRequestsAreNotFound() {
        UUID[] ids = coachAdds("Pia", 11, false);
        api.decide(UUID.randomUUID(), "approve", null).statusCode(404);
        api.decide(UUID.randomUUID(), "reject", "x").statusCode(404);
        api.cancel(UUID.randomUUID()).statusCode(404);
        api.getRequest(UUID.randomUUID()).statusCode(404);

        String other = Members.newTenant();
        RosterDb.callerPerson(other);
        Members.signIn(other, TenantRole.ADMIN);
        Approvals asOther = new Approvals(other);
        asOther.getRequest(ids[1]).statusCode(404);
        asOther.decide(ids[1], "approve", null).statusCode(404);
        asOther.decide(ids[1], "reject", "x").statusCode(404);
        asOther.cancel(ids[1]).statusCode(404);
        asOther.request().get("/api/core/approval-requests").then().statusCode(200).body("items", empty());
        assertThat(RosterDb.text(tenant, "select status from core.approval_request where id = ?", ids[1])).isEqualTo("PENDING");
    }

    @Test
    void twoConcurrentDecisionsHaveExactlyOneWinner() throws Exception {
        UUID[] ids = coachAdds("Pia", 11, false);
        ApprovalRequestId id = new ApprovalRequestId(ids[1]);
        TenantId tenantId = TenantId.parse(tenant);
        CountDownLatch bothRead = new CountDownLatch(2);
        Callable<String> decision = () -> tenantScope.runAs(tenantId, () -> {
            ApprovalRequest read = repository.find(id).orElseThrow();
            bothRead.countDown();
            await(bothRead);
            repository.update(read.approve(new PersonId(admin), null, Instant.now()));
            return "WON";
        });
        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            List<Future<String>> results = new ArrayList<>(List.of(pool.submit(decision), pool.submit(decision)));
            List<String> outcomes = new ArrayList<>();
            for (Future<String> result : results) {
                outcomes.add(outcome(result));
            }
            assertThat(outcomes).containsExactlyInAnyOrder("WON", "CONCURRENT_DECISION");
        } finally {
            pool.shutdownNow();
        }
        assertThat(RosterDb.text(tenant, "select status from core.approval_request where id = ?", ids[1])).isEqualTo("APPROVED");
    }

    private static void await(CountDownLatch latch) {
        try {
            latch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }

    /** "WON", or the code of the ConflictException the loser's transaction died with. */
    private static String outcome(Future<String> future) throws InterruptedException, ExecutionException {
        try {
            return future.get();
        } catch (ExecutionException e) {
            if (e.getCause() instanceof ConflictException conflict) {
                return conflict.code();
            }
            throw e;
        }
    }
}
