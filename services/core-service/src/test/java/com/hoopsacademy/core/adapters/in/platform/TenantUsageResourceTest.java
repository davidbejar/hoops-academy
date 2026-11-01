package com.hoopsacademy.core.adapters.in.platform;

import static com.github.tomakehurst.wiremock.client.WireMock.equalTo;
import static com.github.tomakehurst.wiremock.client.WireMock.getRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlEqualTo;
import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.notNullValue;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.InjectWireMock;
import com.hoopsacademy.core.testsupport.KeycloakStubs;
import com.hoopsacademy.core.testsupport.Members;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.UsageStubs;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** {@code GET /platform/tenants/{id}/usage}: core counters + game and athlete over client credentials. */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "platform-admin", roles = "super_admin")
class TenantUsageResourceTest {

    @InjectWireMock
    WireMockServer peers;

    private String tenant;

    @BeforeEach
    void aTenantWithMembersPlayersAndAPendingApproval() {
        KeycloakStubs.installDefaults(peers);
        UsageStubs.bothAnswer(peers);
        tenant = Members.newTenant();
        UUID admin = CoreDb.person(tenant, "Ada", "Admin", null, TenantRole.ADMIN);
        CoreDb.person(tenant, "Cora", "Coach", null, TenantRole.COACH);
        CoreDb.person(tenant, "Pat", "Parent", null, TenantRole.PARENT, TenantRole.COACH);
        RosterDb.playerAged(tenant, "Ann", 11, "FEMALE");
        UUID pending = RosterDb.playerAged(tenant, "Pia", 11, "FEMALE");
        UUID withdrawn = RosterDb.playerAged(tenant, "Wil", 11, "MALE");
        CoreDb.inTenant(tenant, c -> {
            CoreDb.update(c, "update core.player set status = 'PENDING_APPROVAL' where id = ?", pending);
            CoreDb.update(c, "update core.player set status = 'WITHDRAWN' where id = ?", withdrawn);
            return CoreDb.update(c, """
                    insert into core.approval_request (id, tenant_id, action, player_id, requested_by_person_id)
                    values (gen_random_uuid(), ?::uuid, 'ADD_PLAYER', ?, ?)""", tenant, pending, admin);
        });
        RosterDb.team(tenant, RosterDb.currentSeason(tenant), "Lions", RosterDb.defaultCategories(tenant).get("U12"), "MIXED");
    }

    private io.restassured.response.ValidatableResponse usage() {
        return given().filter(Contract.CORE).get("/platform/tenants/" + tenant + "/usage").then();
    }

    @Test
    void aggregatesCoreGameAndAthleteWithTheirCounters() {
        usage().statusCode(200)
                .body("tenantId", org.hamcrest.Matchers.equalTo(tenant))
                .body("services.service", containsInAnyOrder("core", "game", "athlete"))
                .body("unavailableServices", empty())
                .body("services.find { it.service == 'core' }.counters.members", org.hamcrest.Matchers.equalTo(6))
                .body("services.find { it.service == 'core' }.counters.membersAdmin", org.hamcrest.Matchers.equalTo(1))
                .body("services.find { it.service == 'core' }.counters.membersCoach", org.hamcrest.Matchers.equalTo(2))
                .body("services.find { it.service == 'core' }.counters.membersAssistantCoach", org.hamcrest.Matchers.equalTo(0))
                .body("services.find { it.service == 'core' }.counters.membersParent", org.hamcrest.Matchers.equalTo(1))
                .body("services.find { it.service == 'core' }.counters.membersPlayer", org.hamcrest.Matchers.equalTo(3))
                .body("services.find { it.service == 'core' }.counters.players", org.hamcrest.Matchers.equalTo(3))
                .body("services.find { it.service == 'core' }.counters.activePlayers", org.hamcrest.Matchers.equalTo(1))
                .body("services.find { it.service == 'core' }.counters.playersPendingApproval", org.hamcrest.Matchers.equalTo(1))
                .body("services.find { it.service == 'core' }.counters.playersWithdrawn", org.hamcrest.Matchers.equalTo(1))
                .body("services.find { it.service == 'core' }.counters.playersOrphan", org.hamcrest.Matchers.equalTo(0))
                .body("services.find { it.service == 'core' }.counters.teams", org.hamcrest.Matchers.equalTo(1))
                .body("services.find { it.service == 'core' }.counters.seasons", org.hamcrest.Matchers.equalTo(1))
                .body("services.find { it.service == 'core' }.counters.pendingApprovals", org.hamcrest.Matchers.equalTo(1))
                .body("services.find { it.service == 'game' }.counters.matches", org.hamcrest.Matchers.equalTo(3))
                .body("services.find { it.service == 'athlete' }.counters.trainingSessions", org.hamcrest.Matchers.equalTo(12))
                .body("services.find { it.service == 'athlete' }.lastActivityAt", notNullValue());
    }

    @Test
    void peersAreCalledForThisTenantWithAServiceToken() {
        usage().statusCode(200);
        for (String service : new String[] {"game", "athlete"}) {
            peers.verify(1, getRequestedFor(urlEqualTo("/" + service + "/internal/usage/" + tenant))
                    .withHeader("Authorization", equalTo("Bearer test-service-token")));
        }
    }

    @Test
    void oneDownPeerIsListedAndTheRestIsStillReturned() {
        UsageStubs.down(peers, "athlete");
        usage().statusCode(200).body("services.service", containsInAnyOrder("core", "game"))
                .body("unavailableServices", contains("athlete"));

        KeycloakStubs.installDefaults(peers);
        UsageStubs.bothAnswer(peers);
        UsageStubs.unreachable(peers, "game");
        usage().statusCode(200).body("services.service", containsInAnyOrder("core", "athlete"))
                .body("unavailableServices", contains("game"));
    }

    @Test
    void bothPeersDownStillAnswersWithCoreAlone() {
        UsageStubs.down(peers, "game");
        UsageStubs.unreachable(peers, "athlete");
        usage().statusCode(200).body("services.service", contains("core"))
                .body("unavailableServices", contains("athlete", "game"))
                .body("services[0].counters.members", org.hamcrest.Matchers.equalTo(6));
    }

    @Test
    void aPeerSlowerThanTheTimeoutCountsAsUnavailable() {
        UsageStubs.slow(peers, "game", 3500);
        long started = System.nanoTime();
        usage().statusCode(200).body("unavailableServices", contains("game"));
        assertThat((System.nanoTime() - started) / 1_000_000).isLessThan(3400);
    }

    @Test
    void theDaysSnapshotIsUpsertedAndAPartialOneNeverReplacesACompleteOne() {
        UsageStubs.down(peers, "athlete");
        usage().statusCode(200);
        assertThat(snapshots()).isEqualTo(1);
        assertThat(completeSnapshots()).isZero();

        KeycloakStubs.installDefaults(peers);
        UsageStubs.bothAnswer(peers);
        usage().statusCode(200);
        assertThat(snapshots()).isEqualTo(1);
        assertThat(completeSnapshots()).isEqualTo(1);

        UsageStubs.down(peers, "game");
        usage().statusCode(200);
        usage().statusCode(200);
        assertThat(snapshots()).isEqualTo(1);
        assertThat(completeSnapshots()).isEqualTo(1);
    }

    @Test
    void unknownTenantsAreNotFound() {
        given().filter(Contract.CORE).get("/platform/tenants/" + UUID.randomUUID() + "/usage").then().statusCode(404);
    }

    @Test
    @TestSecurity(user = "academy-admin", roles = "user")
    void tenantAdminsAreForbidden() {
        given().filter(Contract.CORE).get("/platform/tenants/" + tenant + "/usage").then().statusCode(403);
    }

    @Test
    @TestSecurity(user = "service", roles = "service")
    void serviceAccountsAreForbidden() {
        given().filter(Contract.CORE).get("/platform/tenants/" + tenant + "/usage").then().statusCode(403);
    }

    @Test
    @TestSecurity
    void anonymousCallersAreUnauthorized() {
        given().filter(Contract.CORE).get("/platform/tenants/" + tenant + "/usage").then().statusCode(401);
    }

    private long snapshots() {
        return CoreDb.countAsPlatform("select count(*) from core.usage_snapshot where tenant_id = ?::uuid", tenant);
    }

    private long completeSnapshots() {
        return CoreDb.countAsPlatform("select count(*) from core.usage_snapshot where tenant_id = ?::uuid "
                + "and jsonb_array_length(report -> 'unavailableServices') = 0", tenant);
    }
}
