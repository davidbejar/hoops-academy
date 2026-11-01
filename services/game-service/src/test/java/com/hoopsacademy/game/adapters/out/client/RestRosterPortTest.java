package com.hoopsacademy.game.adapters.out.client;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.equalTo;
import static com.github.tomakehurst.wiremock.client.WireMock.equalToJson;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.getRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.post;
import static com.github.tomakehurst.wiremock.client.WireMock.postRequestedFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.hoopsacademy.common.client.CoreMembership;
import com.hoopsacademy.common.client.CoreRosterClient;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.problem.UpstreamUnavailableException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.game.application.PlayerBrief;
import com.hoopsacademy.game.application.TeamRoster;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.TeamId;
import com.hoopsacademy.game.support.CoreStubs;
import com.hoopsacademy.game.support.CoreWireMockResource;
import com.hoopsacademy.game.support.InjectCoreWireMock;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The RosterPort adapter (over common-quarkus' shared {@link CoreRosterClient}) against a WireMock core-service: real
 * REST client, token filter, JSON mapping and cache.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "game"))
@WithTestResource(CoreWireMockResource.class)
class RestRosterPortTest {

    static final TenantId TENANT = TenantId.parse("11111111-1111-4111-8111-111111111111");
    static final UUID TEAM = UUID.fromString("22222222-2222-4222-8222-222222222222");
    static final UUID SEASON = UUID.fromString("33333333-3333-4333-8333-333333333333");
    static final String ANA = "44444444-4444-4444-8444-444444444444";

    @InjectCoreWireMock
    WireMockServer core;

    @Inject
    RestRosterPort port;

    @Inject
    CoreRosterClient coreClient;

    @BeforeEach
    void reset() {
        CoreStubs.reset(core);
        port.clearCache();
    }

    private void stubRoster() {
        CoreStubs.teamRoster(core, TENANT.toString(), TEAM.toString(), SEASON.toString(), CoreStubs.player(ANA, "Ana Ruiz", "7"));
    }

    @Test
    void teamRosterHappyPathSendsServiceTokenAndTenant() {
        stubRoster();

        TeamRoster roster = port.teamRoster(TENANT, TeamId.of(TEAM));

        assertThat(roster.seasonId().value()).isEqualTo(SEASON);
        assertThat(roster.players()).singleElement().satisfies(p -> {
            assertThat(p.playerId().value()).isEqualTo(UUID.fromString(ANA));
            assertThat(p.displayName()).isEqualTo("Ana Ruiz");
            assertThat(p.jerseyNumber()).isEqualTo("7");
        });
        core.verify(1, getRequestedFor(urlPathEqualTo("/internal/teams/" + TEAM + "/roster"))
                .withQueryParam("tenantId", equalTo(TENANT.toString()))
                .withHeader("Authorization", equalTo("Bearer " + CoreStubs.SERVICE_TOKEN))
                .withoutHeader("X-Tenant-Id"));
    }

    @Test
    void secondIdenticalCallIsServedFromTheCache() {
        stubRoster();

        port.teamRoster(TENANT, TeamId.of(TEAM));
        port.teamRoster(TENANT, TeamId.of(TEAM));

        core.verify(1, getRequestedFor(urlPathEqualTo("/internal/teams/" + TEAM + "/roster")));
    }

    @Test
    void cacheIsKeyedPerCall() {
        stubRoster();
        UUID otherTeam = UUID.randomUUID();
        CoreStubs.teamRoster(core, TENANT.toString(), otherTeam.toString(), SEASON.toString());

        port.teamRoster(TENANT, TeamId.of(TEAM));
        port.teamRoster(TENANT, TeamId.of(otherTeam));

        core.verify(1, getRequestedFor(urlPathEqualTo("/internal/teams/" + TEAM + "/roster")));
        core.verify(1, getRequestedFor(urlPathEqualTo("/internal/teams/" + otherTeam + "/roster")));
    }

    @Test
    void unknownTeamIsNotFoundAndNotCached() {
        core.stubFor(get(urlPathEqualTo("/internal/teams/" + TEAM + "/roster")).willReturn(aResponse().withStatus(404)));

        assertThatThrownBy(() -> port.teamRoster(TENANT, TeamId.of(TEAM))).isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> port.teamRoster(TENANT, TeamId.of(TEAM))).isInstanceOf(NotFoundException.class);

        core.verify(2, getRequestedFor(urlPathEqualTo("/internal/teams/" + TEAM + "/roster")));
    }

    @Test
    void serverErrorBecomesUpstreamUnavailableAndIsNotCached() {
        core.stubFor(get(urlPathEqualTo("/internal/teams/" + TEAM + "/roster")).willReturn(aResponse().withStatus(500)));

        assertThatThrownBy(() -> port.teamRoster(TENANT, TeamId.of(TEAM)))
                .isInstanceOf(UpstreamUnavailableException.class).extracting("code").isEqualTo("UPSTREAM_UNAVAILABLE");
        stubRoster();
        assertThat(port.teamRoster(TENANT, TeamId.of(TEAM)).players()).hasSize(1);
    }

    @Test
    void rejectedServiceTokenCountsAsUpstreamUnavailable() {
        core.stubFor(get(urlPathEqualTo("/internal/teams/" + TEAM + "/roster")).willReturn(aResponse().withStatus(403)));

        assertThatThrownBy(() -> port.teamRoster(TENANT, TeamId.of(TEAM))).isInstanceOf(UpstreamUnavailableException.class);
    }

    @Test
    void slowCoreTimesOutAfterTwoSecondsAsUpstreamUnavailable() {
        core.stubFor(get(urlPathEqualTo("/internal/teams/" + TEAM + "/roster"))
                .willReturn(aResponse().withFixedDelay(4000).withStatus(200)));

        long start = System.nanoTime();
        assertThatThrownBy(() -> port.teamRoster(TENANT, TeamId.of(TEAM))).isInstanceOf(UpstreamUnavailableException.class);
        long elapsedMillis = (System.nanoTime() - start) / 1_000_000;

        assertThat(elapsedMillis).isBetween(1_500L, 3_800L);
    }

    @Test
    void playersBatchSendsSortedDistinctIdsAndCaches() {
        String other = "00000000-0000-4000-8000-000000000001";
        core.stubFor(post(urlPathEqualTo("/internal/players:batch")).withQueryParam("tenantId", equalTo(TENANT.toString()))
                .willReturn(aResponse().withHeader("Content-Type", "application/json").withBody(
                        "{\"players\":[{\"id\":\"" + ANA + "\",\"displayName\":\"Ana Ruiz\",\"birthDate\":\"2012-05-01\","
                                + "\"gender\":\"MALE\",\"status\":\"ACTIVE\"}]}")));
        List<PlayerId> ids = List.of(PlayerId.of(UUID.fromString(ANA)), PlayerId.of(UUID.fromString(other)),
                PlayerId.of(UUID.fromString(ANA)));

        List<PlayerBrief> first = port.players(TENANT, ids);
        port.players(TENANT, ids);

        assertThat(first).singleElement().extracting(PlayerBrief::displayName).isEqualTo("Ana Ruiz");
        core.verify(1, postRequestedFor(urlPathEqualTo("/internal/players:batch"))
                .withRequestBody(equalToJson("{\"playerIds\":[\"" + other + "\",\"" + ANA + "\"]}")));
        assertThat(port.players(TENANT, List.of())).isEmpty();
    }

    @Test
    void authzContextMapsRolesStatusAndCaches() {
        CoreStubs.authz(core, TENANT.toString(), "alice", "ACTIVE", List.of("COACH", "PLAYER"), List.of(TEAM.toString()));

        Optional<CoreMembership> access = coreClient.membership(TENANT, "alice");
        coreClient.membership(TENANT, "alice");

        assertThat(access).hasValueSatisfying(a -> {
            assertThat(a.context().roles()).containsExactlyInAnyOrder(TenantRole.COACH, TenantRole.PLAYER);
            assertThat(a.context().staffTeamIds()).containsExactly(TEAM);
            assertThat(a.tenantActive()).isTrue();
        });
        core.verify(1, getRequestedFor(urlPathEqualTo("/internal/authz/" + TENANT + "/alice")));
    }

    @Test
    void nonMemberIsAnEmptyAuthzContext() {
        core.stubFor(get(urlPathEqualTo("/internal/authz/" + TENANT + "/mallory")).willReturn(aResponse().withStatus(404)));

        assertThat(coreClient.membership(TENANT, "mallory")).isEmpty();
    }

    @Test
    void authzFailureIsUpstreamUnavailable() {
        core.stubFor(get(urlPathEqualTo("/internal/authz/" + TENANT + "/bob")).willReturn(aResponse().withStatus(503)));

        assertThatThrownBy(() -> coreClient.membership(TENANT, "bob")).isInstanceOf(UpstreamUnavailableException.class);
    }

    @Test
    void authzContextCarriesTheTenantZoneAndThePlayerTeamsOverTheWire() {
        core.stubFor(get(urlPathEqualTo("/internal/authz/" + TENANT + "/pia")).willReturn(aResponse()
                .withHeader("Content-Type", "application/json").withBody("""
                        {"sub":"pia","personId":"%s","tenantId":"%s","tenantStatus":"ACTIVE","roles":["PARENT"],
                         "staffTeamIds":[],"linkedPlayerIds":["%s"],"ownPlayerId":null,"playerTeamIds":["%s"],
                         "timezone":"Asia/Jakarta"}""".formatted(UUID.randomUUID(), TENANT, ANA, TEAM))));

        assertThat(coreClient.membership(TENANT, "pia")).hasValueSatisfying(a -> {
            assertThat(a.context().playerTeamIds()).containsExactly(TEAM);
            assertThat(a.context().timezone()).contains(java.time.ZoneId.of("Asia/Jakarta"));
        });
    }
}
