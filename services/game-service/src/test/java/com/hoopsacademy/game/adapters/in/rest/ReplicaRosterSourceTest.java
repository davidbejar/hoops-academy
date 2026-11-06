package com.hoopsacademy.game.adapters.in.rest;

import static com.github.tomakehurst.wiremock.client.WireMock.anyRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathMatching;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.testing.TenantUser;
import com.hoopsacademy.game.adapters.in.messaging.RosterEventDecoder;
import com.hoopsacademy.game.application.replica.ReplicateRoster;
import com.hoopsacademy.game.support.Contract;
import com.hoopsacademy.game.support.CoreEvents;
import com.hoopsacademy.game.support.CoreStubs;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import com.hoopsacademy.game.support.ReplicaFeed;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.QuarkusTestProfile;
import io.quarkus.test.junit.TestProfile;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * {@code hoops.roster.source=replica} (ADR-0037): the tenant filter and the use cases read the local replica, so a
 * request needs no call to core at all; with the production resolver (the test-jar's resolver excluded).
 */
@QuarkusTest
@TestProfile(ReplicaRosterSourceTest.ReplicaSource.class)
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class ReplicaRosterSourceTest {

    public static class ReplicaSource implements QuarkusTestProfile {
        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of("hoops.roster.source", "replica",
                    "quarkus.arc.exclude-types", "com.hoopsacademy.common.testing.TestAuthzContextResolver");
        }
    }

    static final String MEMBER_TENANT = "6a0b5c1e-1111-4111-8111-000000000001";
    static final String COACH_TENANT = "6a0b5c1e-1111-4111-8111-000000000002";
    static final String STRANGER_TENANT = "6a0b5c1e-1111-4111-8111-000000000003";

    @InjectCoreWireMock
    WireMockServer core;

    @Inject
    RosterEventDecoder decoder;

    @Inject
    ReplicateRoster replicate;

    @BeforeEach
    void coreKnowsNothing() {
        CoreStubs.reset(core);
    }

    @Test
    @TenantUser(tenant = MEMBER_TENANT)
    void aMemberOfTheReplicaReachesTheApiWithoutAskingCore() {
        CoreEvents events = CoreEvents.of(TenantId.parse(MEMBER_TENANT));
        ReplicaFeed.apply(decoder, replicate, events.tenant("ACTIVE", "Europe/Madrid"),
                events.person(UUID.randomUUID(), "Paula Parent", TenantUser.SUBJECT, true, TenantRole.PARENT));

        given().filter(Contract.FILTER).header("X-Tenant-Id", MEMBER_TENANT).get("/api/game/matches").then()
                .statusCode(200).body("items.size()", equalTo(0));

        core.verify(0, anyRequestedFor(urlPathMatching("/internal/.*")));
    }

    @Test
    @TenantUser(tenant = COACH_TENANT)
    void aCoachSchedulesAMatchForATeamOfTheReplica() {
        CoreEvents events = CoreEvents.of(TenantId.parse(COACH_TENANT));
        UUID coach = UUID.randomUUID();
        UUID team = UUID.randomUUID();
        UUID season = UUID.randomUUID();
        ReplicaFeed.apply(decoder, replicate, events.tenant("ACTIVE", "Europe/Madrid"),
                events.person(coach, "Cora Coach", TenantUser.SUBJECT, true, TenantRole.COACH),
                events.team(team, season, LocalDate.now().plusMonths(6), "Lions"), events.staff(team, coach, "COACH"));

        given().filter(Contract.FILTER).header("X-Tenant-Id", COACH_TENANT).contentType(ContentType.JSON)
                .body("{\"teamId\":\"" + team + "\",\"opponentName\":\"Tigers\",\"homeAway\":\"HOME\","
                        + "\"scheduledAt\":\"2026-12-05T09:00:00Z\"}")
                .post("/api/game/matches").then().statusCode(201).body("seasonId", equalTo(season.toString()));

        core.verify(0, anyRequestedFor(urlPathMatching("/internal/.*")));
    }

    @Test
    @TenantUser(tenant = STRANGER_TENANT)
    void someoneTheReplicaDoesNotKnowIsNotFound() {
        CoreEvents events = CoreEvents.of(TenantId.parse(STRANGER_TENANT));
        ReplicaFeed.apply(decoder, replicate, events.tenant("ACTIVE", "Europe/Madrid"));

        given().header("X-Tenant-Id", STRANGER_TENANT).get("/api/game/matches").then().statusCode(404);

        core.verify(0, anyRequestedFor(urlPathMatching("/internal/.*")));
    }
}
