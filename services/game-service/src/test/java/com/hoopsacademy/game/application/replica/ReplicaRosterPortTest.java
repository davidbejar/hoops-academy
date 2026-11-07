package com.hoopsacademy.game.application.replica;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.game.application.PlayerBrief;
import com.hoopsacademy.game.application.TeamRoster;
import com.hoopsacademy.game.domain.PlayerId;
import com.hoopsacademy.game.domain.SeasonId;
import com.hoopsacademy.game.domain.TeamId;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The replica's roster rules (the same as core's {@code /internal} roster endpoints), on an in-memory replica. */
class ReplicaRosterPortTest {

    private static final TenantId TENANT = TenantId.random();
    private static final LocalDate BORN = LocalDate.parse("2012-05-01");

    private final FakeRosterQueries replica = new FakeRosterQueries();
    private final ReplicaRosterPort port = new ReplicaRosterPort(replica);

    private final TeamId lions = TeamId.of(UUID.randomUUID());
    private final SeasonId season = SeasonId.of(UUID.randomUUID());
    private final ReplicaPlayer ana = player("Ana Ruiz", Optional.of(BORN), Optional.of("FEMALE"));
    private final ReplicaPlayer noBirth = player("No Birth", Optional.empty(), Optional.of("FEMALE"));
    private final ReplicaPlayer noGender = player("No Gender", Optional.of(BORN), Optional.empty());

    @Test
    void theRosterKeepsTheLinesOfCompletePlayersInOrder() {
        active();
        replica.teams.put(lions, new ReplicaTeam(lions, season, "Lions", LocalDate.parse("2027-06-30")));
        ReplicaPlayer bea = player("Bea Gil", Optional.of(BORN), Optional.of("MALE"));
        replica.rosters.put(lions, List.of(new RosterLine(bea, Optional.empty()), new RosterLine(noBirth, Optional.of("5")),
                new RosterLine(ana, Optional.of("7")), new RosterLine(noGender, Optional.of("8"))));

        TeamRoster roster = port.teamRoster(TENANT, lions);

        assertThat(roster).isEqualTo(new TeamRoster(lions, season, "Lions", List.of(
                new TeamRoster.Player(bea.id(), "Bea Gil", null), new TeamRoster.Player(ana.id(), "Ana Ruiz", "7")),
                LocalDate.parse("2027-06-30")));
    }

    @Test
    void anUnknownTeamIsNotFound() {
        active();

        assertThatThrownBy(() -> port.teamRoster(TENANT, lions)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void onlyAnActiveTenantHasRostersAndPlayers() {
        replica.teams.put(lions, new ReplicaTeam(lions, season, "Lions", LocalDate.parse("2027-06-30")));
        replica.players.put(ana.id(), ana);

        for (Optional<TenantStatus> status : List.of(Optional.<TenantStatus>empty(), Optional.of(TenantStatus.SUSPENDED),
                Optional.of(TenantStatus.WITHDRAWN))) {
            status.ifPresentOrElse(s -> replica.tenants.put(TENANT, new ReplicaTenant(s, ZoneId.of("UTC"))),
                    () -> replica.tenants.remove(TENANT));
            assertThatThrownBy(() -> port.teamRoster(TENANT, lions)).as(status.toString())
                    .isInstanceOf(NotFoundException.class);
            assertThatThrownBy(() -> port.players(TENANT, List.of(ana.id()))).as(status.toString())
                    .isInstanceOf(NotFoundException.class);
        }
    }

    @Test
    void playersAreTheKnownCompleteOnesAskedOnceEach() {
        active();
        replica.players.put(ana.id(), ana);
        replica.players.put(noBirth.id(), noBirth);
        replica.players.put(noGender.id(), noGender);

        List<PlayerBrief> found = port.players(TENANT,
                List.of(ana.id(), noBirth.id(), noGender.id(), PlayerId.of(UUID.randomUUID()), ana.id()));

        assertThat(found).containsExactly(new PlayerBrief(ana.id(), "Ana Ruiz"));
        assertThat(replica.playerQueries).singleElement().satisfies(ids -> assertThat(ids).hasSize(4));
    }

    @Test
    void noIdsAskNothing() {
        assertThat(port.players(TENANT, List.of())).isEmpty();
        assertThat(replica.playerQueries).isEmpty();
    }

    private void active() {
        replica.tenants.put(TENANT, new ReplicaTenant(TenantStatus.ACTIVE, ZoneId.of("Europe/Madrid")));
    }

    private static ReplicaPlayer player(String name, Optional<LocalDate> birthDate, Optional<String> gender) {
        return new ReplicaPlayer(PlayerId.of(UUID.randomUUID()), name, birthDate, gender);
    }
}
