package com.hoopsacademy.common.client;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.problem.UpstreamUnavailableException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantRole;
import jakarta.ws.rs.ProcessingException;
import jakarta.ws.rs.WebApplicationException;
import java.time.Duration;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The cached, error-mapping access to core's /internal API shared by game and athlete (ADR-0008). */
class CoreRosterClientTest {

    private static final TenantId TENANT = TenantId.random();
    private static final UUID TEAM = UUID.randomUUID();
    private static final UUID PAST_TEAM = UUID.randomUUID();
    private static final UUID PERSON = UUID.randomUUID();
    private static final UUID PLAYER = UUID.randomUUID();

    /** Scripted fake of the REST client; counts calls so caching is observable. */
    static final class FakeCore implements CoreInternalClient {
        final List<String> calls = new ArrayList<>();
        final Map<String, RuntimeException> failures = new HashMap<>();
        AuthzContextDto authz = authzDto("ACTIVE", "Europe/Madrid");
        TeamRosterDto roster = new TeamRosterDto(TENANT.value(), TEAM, UUID.randomUUID(), "U12 A",
                List.of(new RosterPlayerDto(PLAYER, "Ann", "7", LocalDate.of(2014, 2, 3), "FEMALE", "ACTIVE")),
                List.of(new RosterStaffDto(PERSON, "COACH")), LocalDate.of(2027, 6, 30));
        List<PlayerBriefDto> players = List.of(new PlayerBriefDto(PLAYER, "Ann", LocalDate.of(2014, 2, 3), "FEMALE", "ACTIVE"));

        @Override
        public AuthzContextDto authz(String tenantId, String sub) {
            return answer("authz " + sub, () -> authz);
        }

        @Override
        public TeamRosterDto teamRoster(UUID teamId, String tenantId) {
            return answer("roster " + teamId, () -> roster);
        }

        @Override
        public PlayerBatchResponseDto players(String tenantId, PlayerBatchRequestDto request) {
            return answer("players " + request.playerIds(), () -> new PlayerBatchResponseDto(players));
        }

        private <T> T answer(String call, java.util.function.Supplier<T> value) {
            calls.add(call);
            RuntimeException failure = failures.get(call.substring(0, call.indexOf(' ')));
            if (failure != null) {
                throw failure;
            }
            return value.get();
        }
    }

    static CoreInternalClient.AuthzContextDto authzDto(String status, String zone) {
        return new CoreInternalClient.AuthzContextDto("sub-1", PERSON, TENANT.value(), status, List.of("PARENT", "COACH"),
                List.of(TEAM), List.of(PLAYER), null, List.of(TEAM), zone, List.of(PAST_TEAM));
    }

    private final FakeCore core = new FakeCore();
    private final CoreRosterClient client = new CoreRosterClient(core, Duration.ofSeconds(30));

    @Test
    void mapsTheMembershipIncludingZoneAndPlayerTeams() {
        CoreMembership member = client.membership(TENANT, "sub-1").orElseThrow();

        assertThat(member.tenantActive()).isTrue();
        assertThat(member.context().roles()).containsExactlyInAnyOrder(TenantRole.PARENT, TenantRole.COACH);
        assertThat(member.context().staffTeamIds()).containsExactly(TEAM);
        assertThat(member.context().historicStaffTeamIds()).containsExactly(PAST_TEAM);
        assertThat(member.context().linkedPlayerIds()).containsExactly(PLAYER);
        assertThat(member.context().playerTeamIds()).containsExactly(TEAM);
        assertThat(member.context().timezone()).contains(ZoneId.of("Europe/Madrid"));
        assertThat(member.context().ownPlayerId()).isEmpty();
        assertThat(member.context().tenantId()).isEqualTo(TENANT);
    }

    @Test
    void toleratesAnOlderCoreWithoutZoneOrPlayerTeamsAndIgnoresUnknownZones() {
        core.authz = new CoreInternalClient.AuthzContextDto("sub-1", PERSON, TENANT.value(), "ACTIVE", List.of(), List.of(),
                List.of(), PLAYER, null, "Mars/Olympus", null);

        CoreMembership member = client.membership(TENANT, "sub-1").orElseThrow();

        assertThat(member.context().timezone()).isEmpty();
        assertThat(member.context().playerTeamIds()).isEmpty();
        assertThat(member.context().historicStaffTeamIds()).isEmpty();
        assertThat(member.context().ownPlayerId()).contains(PLAYER);
    }

    @Test
    void aSuspendedTenantIsReportedButNotActive() {
        core.authz = authzDto("SUSPENDED", "Europe/Madrid");

        assertThat(client.membership(TENANT, "sub-1")).hasValueSatisfying(m -> assertThat(m.tenantActive()).isFalse());
    }

    @Test
    void aNonMemberIsEmptyAndNeverCached() {
        core.failures.put("authz", new WebApplicationException(404));

        assertThat(client.membership(TENANT, "sub-1")).isEmpty();
        assertThat(client.membership(TENANT, "sub-1")).isEmpty();
        assertThat(core.calls).hasSize(2);
    }

    @Test
    void answersAreCachedPerArgumentsUntilCleared() {
        CoreMembership fetched = client.membership(TENANT, "sub-1").orElseThrow();
        assertThat(client.membership(TENANT, "sub-1")).containsSame(fetched);
        client.teamRoster(TENANT, TEAM);
        client.teamRoster(TENANT, TEAM);
        client.teamRoster(TenantId.random(), TEAM);
        client.players(TENANT, List.of(PLAYER));
        client.players(TENANT, List.of(PLAYER));

        assertThat(core.calls).hasSize(4);
    }

    @Test
    void clearingTheCacheRefetchesEveryKindOfAnswer() {
        client.membership(TENANT, "sub-1");
        client.teamRoster(TENANT, TEAM);
        client.players(TENANT, List.of(PLAYER));

        client.clearCache();
        client.membership(TENANT, "sub-1");
        client.teamRoster(TENANT, TEAM);
        client.players(TENANT, List.of(PLAYER));

        assertThat(core.calls).containsExactly("authz sub-1", "roster " + TEAM, "players " + List.of(PLAYER),
                "authz sub-1", "roster " + TEAM, "players " + List.of(PLAYER));
    }

    @Test
    void mapsTheRoster() {
        CoreInternalClient.TeamRosterDto roster = client.teamRoster(TENANT, TEAM);

        assertThat(roster.teamName()).isEqualTo("U12 A");
        assertThat(roster.players()).singleElement().satisfies(p -> {
            assertThat(p.playerId()).isEqualTo(PLAYER);
            assertThat(p.jerseyNumber()).isEqualTo("7");
        });
        assertThat(roster.staff()).singleElement().satisfies(s -> assertThat(s.personId()).isEqualTo(PERSON));
    }

    @Test
    void playersAreCachedOneByOneAndUnaskedIdsAreDropped() {
        UUID unknown = UUID.randomUUID();
        core.players = List.of(new CoreInternalClient.PlayerBriefDto(PLAYER, "Ann", null, null, "ACTIVE"),
                new CoreInternalClient.PlayerBriefDto(UUID.randomUUID(), "Not asked", null, null, "ACTIVE"));

        assertThat(client.players(TENANT, List.of(PLAYER, unknown))).containsOnlyKeys(PLAYER);
        assertThat(client.players(TENANT, List.of(PLAYER))).containsOnlyKeys(PLAYER);
        assertThat(client.players(TENANT, List.of())).isEmpty();

        assertThat(core.calls).hasSize(1);
    }

    @Test
    void anUnknownTeamIsNotFoundAndNotCached() {
        core.failures.put("roster", new WebApplicationException(404));

        assertThatThrownBy(() -> client.teamRoster(TENANT, TEAM)).isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> client.teamRoster(TENANT, TEAM)).isInstanceOf(NotFoundException.class);
        assertThat(core.calls).hasSize(2);
    }

    @Test
    void serverErrorsDeniedCallsAndTimeoutsAreUpstreamUnavailable() {
        core.failures.put("roster", new WebApplicationException(500));
        core.failures.put("authz", new WebApplicationException(403));
        core.failures.put("players", new ProcessingException("read timed out"));

        assertThatThrownBy(() -> client.teamRoster(TENANT, TEAM)).isInstanceOf(UpstreamUnavailableException.class)
                .extracting("code").isEqualTo(UpstreamUnavailableException.CODE);
        assertThatThrownBy(() -> client.membership(TENANT, "sub-1")).isInstanceOf(UpstreamUnavailableException.class);
        assertThatThrownBy(() -> client.players(TENANT, List.of(PLAYER))).isInstanceOf(UpstreamUnavailableException.class);
    }
}
