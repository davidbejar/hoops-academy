package com.hoopsacademy.athlete.adapters.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.athlete.application.PlayerBrief;
import com.hoopsacademy.athlete.application.RosterPort;
import com.hoopsacademy.athlete.application.TeamRoster;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.problem.UpstreamUnavailableException;
import com.hoopsacademy.common.tenancy.TenantId;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.junit.jupiter.api.Test;

/** One roster read per tenant and team for the length of a request; outside a request every call reads (ATH-01). */
class RequestMemoRosterPortTest {

    static final TenantId TENANT = TenantId.random();
    static final TeamId TEAM = new TeamId(UUID.randomUUID());
    static final PlayerId PLAYER = new PlayerId(UUID.randomUUID());

    final CountingSource source = new CountingSource();
    final Map<RequestMemoRosterPort.TeamKey, RequestMemoRosterPort.Answer> request = new ConcurrentHashMap<>();

    @Test
    void aTeamIsReadOncePerRequest() {
        source.known.put(TEAM, roster(TEAM));
        RosterPort port = new RequestMemoRosterPort(source, () -> Optional.of(request));

        TeamRoster first = port.teamRoster(TENANT, TEAM);
        TeamRoster second = port.teamRoster(TENANT, TEAM);

        assertThat(second).isSameAs(first);
        assertThat(source.rosterReads).isEqualTo(1);
    }

    @Test
    void anUnknownTeamIsAlsoReadOncePerRequest() {
        RosterPort port = new RequestMemoRosterPort(source, () -> Optional.of(request));

        assertThatThrownBy(() -> port.teamRoster(TENANT, TEAM)).isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> port.teamRoster(TENANT, TEAM)).isInstanceOf(NotFoundException.class)
                .hasMessage("Team not found");
        assertThat(source.rosterReads).isEqualTo(1);
    }

    @Test
    void anUnavailableSourceIsAskedAgain() {
        source.unavailable = true;
        RosterPort port = new RequestMemoRosterPort(source, () -> Optional.of(request));

        assertThatThrownBy(() -> port.teamRoster(TENANT, TEAM)).isInstanceOf(UpstreamUnavailableException.class);
        assertThatThrownBy(() -> port.teamRoster(TENANT, TEAM)).isInstanceOf(UpstreamUnavailableException.class);
        assertThat(source.rosterReads).isEqualTo(2);
    }

    @Test
    void eachTenantAndTeamHasItsOwnAnswer() {
        TeamId other = new TeamId(UUID.randomUUID());
        source.known.put(TEAM, roster(TEAM));
        source.known.put(other, roster(other));
        RosterPort port = new RequestMemoRosterPort(source, () -> Optional.of(request));

        assertThat(port.teamRoster(TENANT, TEAM).teamId()).isEqualTo(TEAM);
        assertThat(port.teamRoster(TENANT, other).teamId()).isEqualTo(other);
        port.teamRoster(TenantId.random(), TEAM);

        assertThat(source.rosterReads).isEqualTo(3);
    }

    @Test
    void outsideARequestEveryCallReads() {
        source.known.put(TEAM, roster(TEAM));
        RosterPort port = new RequestMemoRosterPort(source, Optional::empty);

        port.teamRoster(TENANT, TEAM);
        port.teamRoster(TENANT, TEAM);

        assertThat(source.rosterReads).isEqualTo(2);
        assertThat(request).isEmpty();
    }

    @Test
    void playersAndTeamsOfGoToTheSource() {
        RosterPort port = new RequestMemoRosterPort(source, () -> Optional.of(request));

        assertThat(port.players(TENANT, List.of(PLAYER))).containsOnlyKeys(PLAYER);
        assertThat(port.teamsOf(TENANT, List.of(PLAYER), List.of(TEAM))).containsExactly(TEAM);
        assertThat(source.rosterReads).isZero();
    }

    private static TeamRoster roster(TeamId team) {
        return new TeamRoster(team, "U12", List.of(new TeamRoster.RosterPlayer(PLAYER, "Ana")), List.of(), null);
    }

    /** A source that counts roster reads; players and teamsOf answer without reading a roster. */
    static final class CountingSource implements RosterPort {

        final Map<TeamId, TeamRoster> known = new HashMap<>();
        boolean unavailable;
        int rosterReads;

        @Override
        public TeamRoster teamRoster(TenantId tenant, TeamId team) {
            rosterReads++;
            if (unavailable) {
                throw new UpstreamUnavailableException("core is down", new IllegalStateException("down"));
            }
            TeamRoster roster = known.get(team);
            if (roster == null) {
                throw new NotFoundException("Team not found");
            }
            return roster;
        }

        @Override
        public Map<PlayerId, PlayerBrief> players(TenantId tenant, Collection<PlayerId> ids) {
            Map<PlayerId, PlayerBrief> found = new HashMap<>();
            ids.forEach(id -> found.put(id, new PlayerBrief(id, "Ana", "ACTIVE", Optional.empty(), Optional.empty())));
            return found;
        }

        @Override
        public Set<TeamId> teamsOf(TenantId tenant, Collection<PlayerId> players, Collection<TeamId> candidates) {
            return Set.copyOf(candidates);
        }
    }
}
