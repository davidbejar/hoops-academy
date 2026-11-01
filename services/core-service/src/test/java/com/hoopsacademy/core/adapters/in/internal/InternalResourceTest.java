package com.hoopsacademy.core.adapters.in.internal;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.empty;
import static org.hamcrest.Matchers.equalTo;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.core.testsupport.Contract;
import com.hoopsacademy.core.testsupport.CoreDb;
import com.hoopsacademy.core.testsupport.RosterDb;
import com.hoopsacademy.core.testsupport.WireMockResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.security.TestSecurity;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "core"))
@WithTestResource(WireMockResource.class)
@TestSecurity(user = "game-service", roles = "service")
class InternalResourceTest {

    private String tenant;
    private String subject;
    private UUID person;
    private UUID ownPlayer;
    private UUID child;

    @BeforeEach
    void parentWhoIsAlsoAPlayer() {
        tenant = UUID.randomUUID().toString();
        subject = "internal-" + UUID.randomUUID();
        CoreDb.tenant(tenant);
        person = CoreDb.person(tenant, CoreDb.login(subject), "Pat", "P", null, LocalDate.of(2001, 5, 5), "MALE",
                TenantRole.PARENT, TenantRole.PLAYER);
        ownPlayer = CoreDb.player(tenant, person);
        child = CoreDb.player(tenant, CoreDb.person(tenant, "Kid", "P", null));
        CoreDb.guardianLink(tenant, person, child);
    }

    @Test
    void authzContextCarriesRolesRelationsAndTenantStatus() {
        given().filter(Contract.CORE).get("/internal/authz/{t}/{s}", tenant, subject).then().statusCode(200)
                .body("sub", equalTo(subject))
                .body("tenantId", equalTo(tenant))
                .body("personId", equalTo(person.toString()))
                .body("tenantStatus", equalTo("ACTIVE"))
                .body("roles", contains("PARENT", "PLAYER"))
                .body("staffTeamIds", empty())
                .body("linkedPlayerIds", contains(child.toString()))
                .body("ownPlayerId", equalTo(ownPlayer.toString()));
    }

    @Test
    void authzContextCarriesTheTenantZoneAndTheTeamsOfOwnAndLinkedPlayers() {
        RosterDb.timezone(tenant, "Asia/Jakarta");
        UUID season = RosterDb.currentSeason(tenant);
        var categories = RosterDb.defaultCategories(tenant);
        UUID ownTeam = RosterDb.team(tenant, season, "Seniors", categories.get("SENIOR"), "MIXED");
        UUID childTeam = RosterDb.team(tenant, season, "U12", categories.get("U12"), "MIXED");
        UUID unrelatedTeam = RosterDb.team(tenant, season, "U14", categories.get("U14"), "MIXED");
        RosterDb.assignment(tenant, ownTeam, ownPlayer, "4");
        RosterDb.assignment(tenant, childTeam, child, "7");
        RosterDb.assignment(tenant, unrelatedTeam, CoreDb.player(tenant, CoreDb.person(tenant, "Other", "O", null)), "9");

        given().filter(Contract.CORE).get("/internal/authz/{t}/{s}", tenant, subject).then().statusCode(200)
                .body("timezone", equalTo("Asia/Jakarta"))
                .body("playerTeamIds", containsInAnyOrder(ownTeam.toString(), childTeam.toString()));
    }

    @Test
    void aMemberWithoutPlayersHasNoPlayerTeams() {
        String coach = "coach-" + UUID.randomUUID();
        CoreDb.person(tenant, CoreDb.login(coach), "Coach", "C", null, null, null, TenantRole.COACH);

        given().filter(Contract.CORE).get("/internal/authz/{t}/{s}", tenant, coach).then().statusCode(200)
                .body("playerTeamIds", empty())
                .body("timezone", equalTo("Europe/Madrid"));
    }

    @Test
    void suspendedTenantIsReportedSoCallersCanDenyAccess() {
        CoreDb.inTenant(null, c -> CoreDb.update(c, "update core.tenant set status = 'SUSPENDED' where id = ?::uuid", tenant));
        given().filter(Contract.CORE).get("/internal/authz/{t}/{s}", tenant, subject).then().statusCode(200)
                .body("tenantStatus", equalTo("SUSPENDED"));
    }

    @Test
    void unknownSubjectOrTenantIsNotFound() {
        given().filter(Contract.CORE).get("/internal/authz/{t}/{s}", tenant, "nobody").then().statusCode(404);
        given().filter(Contract.CORE).get("/internal/authz/{t}/{s}", UUID.randomUUID(), subject).then().statusCode(404);
    }

    @Test
    void usageCountsMembersAndPlayers() {
        given().filter(Contract.CORE).get("/internal/usage/{t}", tenant).then().statusCode(200)
                .body("service", equalTo("core"))
                .body("tenantId", equalTo(tenant))
                .body("counters.members", equalTo(2))
                .body("counters.players", equalTo(2))
                .body("counters.activePlayers", equalTo(2))
                .body("counters.playersRejected", equalTo(0));
    }

    @Test
    void anUnknownTenantHasZeroUsageLikeInEveryOtherService() {
        given().filter(Contract.CORE).get("/internal/usage/{t}", UUID.randomUUID()).then().statusCode(200)
                .body("service", equalTo("core"))
                .body("counters.members", equalTo(0))
                .body("counters.players", equalTo(0));
    }

    @Test
    @TestSecurity(user = "someone", roles = "user")
    void endUsersAreForbidden() {
        given().filter(Contract.CORE).get("/internal/usage/{t}", tenant).then().statusCode(403);
    }

    @Test
    @TestSecurity
    void anonymousIsUnauthorized() {
        given().filter(Contract.CORE).get("/internal/authz/{t}/{s}", tenant, subject).then().statusCode(401);
    }
}
