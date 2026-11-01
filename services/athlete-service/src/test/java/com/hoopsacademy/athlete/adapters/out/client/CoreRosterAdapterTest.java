package com.hoopsacademy.athlete.adapters.out.client;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.support.CoreMockResource;
import com.hoopsacademy.athlete.support.CoreStubs;
import com.hoopsacademy.common.client.CoreMembership;
import com.hoopsacademy.common.client.CoreRosterClient;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.problem.UpstreamUnavailableException;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The RosterPort adapter over common-quarkus' shared {@link CoreRosterClient} against a WireMock core-service (happy
 * path, 404, timeout/503, caching, token); membership lookups go through the shared client directly.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
@WithTestResource(CoreMockResource.class)
class CoreRosterAdapterTest {

    static final TenantId TENANT = TenantId.parse("c0000000-0000-4000-8000-000000000001");

    @Inject RosterPort roster;
    @Inject CoreRosterAdapter adapter;
    @Inject CoreRosterClient coreClient;

    CoreStubs core;
    String team;

    @BeforeEach
    void setUp() {
        core = new CoreStubs().reset();
        adapter.clearCache();
        team = UUID.randomUUID().toString();
    }

    @Test
    void teamRosterHappyPathSendsTheServiceToken() {
        String p1 = UUID.randomUUID().toString();
        String p2 = UUID.randomUUID().toString();
        core.roster(TENANT.toString(), team, p1, p2);

        var result = roster.teamRoster(TENANT, new TeamId(UUID.fromString(team)));

        assertThat(result.teamName()).isEqualTo("U12");
        assertThat(result.playerIds()).containsExactlyInAnyOrder(new PlayerId(UUID.fromString(p1)), new PlayerId(UUID.fromString(p2)));
        assertThat(core.sentBearer(team, "athlete-service-token")).isTrue();
    }

    @Test
    void unknownTeamIsNotFound() {
        core.rosterNotFound(TENANT.toString(), team);

        assertThatThrownBy(() -> roster.teamRoster(TENANT, new TeamId(UUID.fromString(team))))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void slowCoreBecomesUpstreamUnavailableWithinTheTimeout() {
        core.rosterDelayed(TENANT.toString(), team, 4_000);
        long started = System.nanoTime();

        assertThatThrownBy(() -> roster.teamRoster(TENANT, new TeamId(UUID.fromString(team))))
                .isInstanceOf(UpstreamUnavailableException.class);

        assertThat((System.nanoTime() - started) / 1_000_000).isLessThan(3_500);
    }

    @Test
    void serverErrorBecomesUpstreamUnavailableAndIsNotCached() {
        core.rosterFails(TENANT.toString(), team, 500);
        var id = new TeamId(UUID.fromString(team));

        assertThatThrownBy(() -> roster.teamRoster(TENANT, id)).isInstanceOf(UpstreamUnavailableException.class);
        assertThatThrownBy(() -> roster.teamRoster(TENANT, id)).isInstanceOf(UpstreamUnavailableException.class);

        assertThat(core.rosterCalls(team)).isEqualTo(2);
    }

    @Test
    void secondRosterReadIsServedFromTheCache() {
        core.roster(TENANT.toString(), team, UUID.randomUUID().toString());
        var id = new TeamId(UUID.fromString(team));

        roster.teamRoster(TENANT, id);
        roster.teamRoster(TENANT, id);

        assertThat(core.rosterCalls(team)).isEqualTo(1);
    }

    @Test
    void cacheIsPerTenant() {
        TenantId other = TenantId.parse("c0000000-0000-4000-8000-000000000002");
        core.roster(TENANT.toString(), team).roster(other.toString(), team);
        var id = new TeamId(UUID.fromString(team));

        roster.teamRoster(TENANT, id);
        roster.teamRoster(other, id);

        assertThat(core.rosterCalls(team)).isEqualTo(2);
    }

    @Test
    void clearCacheForcesANewCall() {
        core.roster(TENANT.toString(), team);
        var id = new TeamId(UUID.fromString(team));
        roster.teamRoster(TENANT, id);

        adapter.clearCache();
        roster.teamRoster(TENANT, id);

        assertThat(core.rosterCalls(team)).isEqualTo(2);
    }

    @Test
    void playersAreFetchedInOneBatchAndCachedIndividually() {
        String known = UUID.randomUUID().toString();
        core.knownPlayers(TENANT.toString(), known);
        var knownId = new PlayerId(UUID.fromString(known));

        var first = roster.players(TENANT, List.of(knownId));
        var second = roster.players(TENANT, List.of(knownId));

        assertThat(first).containsOnlyKeys(knownId);
        assertThat(first.get(knownId).displayName()).startsWith("Player ");
        assertThat(second).isEqualTo(first);
        assertThat(core.batchCalls()).isEqualTo(1);
        assertThat(roster.playerExists(TENANT, knownId)).isTrue();
    }

    @Test
    void unknownPlayersAreOmitted() {
        core.knownPlayers(TENANT.toString(), UUID.randomUUID().toString());
        var stranger = new PlayerId(UUID.randomUUID());

        assertThat(roster.players(TENANT, List.of(stranger))).isEmpty();
        assertThat(roster.playerExists(TENANT, stranger)).isFalse();
    }

    @Test
    void authzContextMapsRolesRelationsStatusAndZone() {
        String staffTeam = UUID.randomUUID().toString();
        core.member(TENANT.toString(), "kc-sub-1", "ACTIVE", "Asia/Jakarta", "[\"COACH\",\"PARENT\"]",
                CoreStubs.json(List.of(staffTeam)), "[]", "null");

        CoreMembership member = coreClient.membership(TENANT, "kc-sub-1").orElseThrow();

        assertThat(member.tenantStatus()).isEqualTo(CoreMembership.TenantStatus.ACTIVE);
        assertThat(member.context().timezone()).contains(ZoneId.of("Asia/Jakarta"));
        assertThat(member.context().roles()).containsExactlyInAnyOrder(TenantRole.COACH, TenantRole.PARENT);
        assertThat(member.context().isStaffOf(UUID.fromString(staffTeam))).isTrue();
        assertThat(member.context().tenantId()).isEqualTo(TENANT);
    }

    @Test
    void authzContextWithoutTimezoneFieldHasNoZone() {
        core.member(TENANT.toString(), "kc-sub-2", "ACTIVE", null, "[\"ADMIN\"]", "[]", "[]", "null");

        assertThat(coreClient.membership(TENANT, "kc-sub-2").orElseThrow().context().timezone()).isEmpty();
    }

    @Test
    void authzContextOfANonMemberIsEmptyAndNotCached() {
        core.notAMember(TENANT.toString(), "stranger");

        assertThat(coreClient.membership(TENANT, "stranger")).isEmpty();
        assertThat(coreClient.membership(TENANT, "stranger")).isEmpty();

        assertThat(core.authzCalls(TENANT.toString(), "stranger")).isEqualTo(2);
    }

    @Test
    void authzContextIsCachedForAMember() {
        core.member(TENANT.toString(), "kc-sub-3", "ACTIVE", null, "[\"ADMIN\"]", "[]", "[]", "null");

        coreClient.membership(TENANT, "kc-sub-3");
        coreClient.membership(TENANT, "kc-sub-3");

        assertThat(core.authzCalls(TENANT.toString(), "kc-sub-3")).isEqualTo(1);
    }

    @Test
    void authzContextPropagatesUpstreamFailure() {
        // nothing stubbed for this subject: WireMock answers 404 -> not a member; an unreachable core is covered above
        assertThat(coreClient.membership(TENANT, "unknown-sub")).isEmpty();
    }

    @Test
    void theServiceTokenIsFetchedOnceAndReused() {
        core.roster(TENANT.toString(), team);
        String other = UUID.randomUUID().toString();
        core.roster(TENANT.toString(), other);

        roster.teamRoster(TENANT, new TeamId(UUID.fromString(team)));
        roster.teamRoster(TENANT, new TeamId(UUID.fromString(other)));

        assertThat(core.tokenCalls()).isLessThanOrEqualTo(1);
    }
}
