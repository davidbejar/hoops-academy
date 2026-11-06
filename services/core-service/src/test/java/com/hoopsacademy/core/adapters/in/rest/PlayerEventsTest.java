package com.hoopsacademy.core.adapters.in.rest;

import static org.assertj.core.api.Assertions.assertThat;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.core.testsupport.Approvals;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.RosterEvents;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import io.restassured.response.ValidatableResponse;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** WP67: the player lifecycle (add, request, approve, reject, withdraw) publishes the player's state. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = TenantUser.SUBJECT)
class PlayerEventsTest {

    @InjectWireMock
    WireMockServer keycloak;

    private String tenant;
    private Approvals api;
    private UUID lions;
    private UUID coach;

    @BeforeEach
    void anAcademyWithAnU12TeamAndItsCoach() {
        KeycloakStubs.installDefaults(keycloak);
        tenant = Members.newTenant();
        api = new Approvals(tenant);
        UUID season = RosterDb.currentSeason(tenant);
        lions = RosterDb.team(tenant, season, "Lions", RosterDb.defaultCategories(tenant).get("U12"), "MIXED");
        coach = CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        RosterDb.staff(tenant, lions, coach, "COACH");
        Members.signIn(tenant, TenantRole.ADMIN);
    }

    @Test
    void anAdminsNewPlayerIsPublishedWithItsFinalStatusAndPerson() {
        UUID player = playerOf(api.create(Approvals.playerJson("Ann", "FEMALE", 11, "")).statusCode(201));

        var state = RosterEvents.state(tenant, "core.player", player);
        assertThat(state.get("status").asText()).isEqualTo("ORPHAN");
        assertThat(state.get("displayName").asText()).isEqualTo("Ann Test");
        assertThat(state.get("gender").asText()).isEqualTo("FEMALE");
        UUID person = UUID.fromString(state.get("personId").asText());
        assertThat(RosterEvents.state(tenant, "core.person", person).get("roles").get(0).asText()).isEqualTo("PLAYER");
    }

    @Test
    void aRequestedPlayerIsPublishedPendingThenApproved() {
        signInCoach();
        ValidatableResponse requested = api.create(Approvals.playerJson("Pia", "FEMALE", 11,
                ",\"teamId\":\"" + lions + "\",\"jerseyNumber\":\"5\"")).statusCode(202);
        UUID player = playerOf(requested);
        UUID request = UUID.fromString(requested.extract().path("approvalRequest.id"));
        assertThat(RosterEvents.state(tenant, "core.player", player).get("status").asText()).isEqualTo("PENDING_APPROVAL");

        Members.signIn(tenant, TenantRole.ADMIN);
        api.decide(request, "approve", null).statusCode(200);

        assertThat(RosterEvents.state(tenant, "core.player", player).get("status").asText()).isEqualTo("ACTIVE");
        UUID assignment = UUID.fromString(RosterDb.text(tenant,
                "select id::text from core.team_player where player_id = ?", player));
        assertThat(RosterEvents.state(tenant, "core.team-player", assignment).get("jerseyNumber").asText()).isEqualTo("5");
    }

    @Test
    void aRejectedRequestPublishesThePlayerRejected() {
        signInCoach();
        ValidatableResponse requested = api.create(Approvals.playerJson("Pia", "FEMALE", 11, "")).statusCode(202);
        Members.signIn(tenant, TenantRole.ADMIN);

        api.decide(UUID.fromString(requested.extract().path("approvalRequest.id")), "reject", "no").statusCode(200);

        assertThat(RosterEvents.state(tenant, "core.player", playerOf(requested)).get("status").asText())
                .isEqualTo("REJECTED");
    }

    @Test
    void withdrawingAPlayerPublishesThePlayerAndItsClosedAssignment() {
        UUID ben = RosterDb.playerAged(tenant, "Ben", 11, "MALE");
        UUID assignment = RosterDb.assignment(tenant, lions, ben, "9");

        api.withdraw(ben).statusCode(200);

        assertThat(RosterEvents.state(tenant, "core.player", ben).get("status").asText()).isEqualTo("WITHDRAWN");
        assertThat(RosterEvents.state(tenant, "core.team-player", assignment).get("leftOn").asText())
                .isEqualTo(RosterDb.TODAY.toString());
    }

    private void signInCoach() {
        Members.signInAs(tenant, coach, EnumSet.of(TenantRole.COACH), Set.of(lions));
    }

    private static UUID playerOf(ValidatableResponse response) {
        return UUID.fromString(response.extract().path("player.id"));
    }
}
