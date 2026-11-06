package com.hoopsacademy.athlete.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.athlete.domain.Gender;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantId;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * What every {@link RosterPort} adapter guarantees, whatever its source (core's REST API or the local replica). A
 * subclass per adapter supplies the port and a fixture that makes core "know" a team or a player (WireMock stubs for
 * REST, core events for the replica).
 */
public abstract class RosterPortContract {

    /** A player as core knows it (every field the contract carries). */
    public record KnownPlayer(PlayerId id, String displayName, String status, LocalDate birthDate, Gender gender) {

        public static KnownPlayer random(String displayName) {
            return new KnownPlayer(new PlayerId(UUID.randomUUID()), displayName, "ACTIVE", LocalDate.of(2013, 4, 2),
                    Gender.FEMALE);
        }
    }

    /** Makes the source know facts about one tenant. */
    public interface CoreFixture {

        /** The team with its current (open, valid) players and its staff. */
        void team(TenantId tenant, TeamId team, String name, List<KnownPlayer> players, List<PersonId> staff);

        /** Players core knows (in no particular team). */
        void players(TenantId tenant, List<KnownPlayer> players);

        /** Nothing is known about this team in the tenant. */
        void unknownTeam(TenantId tenant, TeamId team);
    }

    protected abstract RosterPort port();

    protected abstract CoreFixture core();

    /** Runs a port call as the adapter is called in production (in the tenant's request or job scope). */
    protected abstract <T> T inTenant(TenantId tenant, java.util.function.Supplier<T> call);

    protected TenantId tenant;
    protected TeamId team;

    @BeforeEach
    void freshTenantAndTeam() {
        tenant = TenantId.random();
        team = new TeamId(UUID.randomUUID());
    }

    @Test
    void teamRosterHasTheTeamsNameCurrentPlayersAndStaff() {
        KnownPlayer ana = KnownPlayer.random("Ana Alba");
        KnownPlayer bea = KnownPlayer.random("Bea Baez");
        PersonId coach = new PersonId(UUID.randomUUID());
        core().team(tenant, team, "U12 Lions", List.of(ana, bea), List.of(coach));

        TeamRoster roster = inTenant(tenant, () -> port().teamRoster(tenant, team));

        assertThat(roster.teamId()).isEqualTo(team);
        assertThat(roster.teamName()).isEqualTo("U12 Lions");
        assertThat(roster.players()).containsExactlyInAnyOrder(new TeamRoster.RosterPlayer(ana.id(), "Ana Alba"),
                new TeamRoster.RosterPlayer(bea.id(), "Bea Baez"));
        assertThat(roster.staff()).containsExactly(coach);
        assertThat(roster.hasPlayer(ana.id())).isTrue();
    }

    @Test
    void aTeamWithoutPlayersOrStaffHasEmptyLists() {
        core().team(tenant, team, "Empty", List.of(), List.of());

        TeamRoster roster = inTenant(tenant, () -> port().teamRoster(tenant, team));

        assertThat(roster.players()).isEmpty();
        assertThat(roster.staff()).isEmpty();
    }

    @Test
    void anUnknownTeamIsNotFound() {
        core().unknownTeam(tenant, team);

        assertThatThrownBy(() -> inTenant(tenant, () -> port().teamRoster(tenant, team)))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void knownPlayersAreFoundWithTheirData() {
        KnownPlayer ana = new KnownPlayer(new PlayerId(UUID.randomUUID()), "Ana Alba", "ACTIVE", LocalDate.of(2012, 5, 1),
                Gender.FEMALE);
        KnownPlayer bob = new KnownPlayer(new PlayerId(UUID.randomUUID()), "Bob Bell", "WITHDRAWN", LocalDate.of(2011, 1, 2),
                Gender.MALE);
        core().players(tenant, List.of(ana, bob));

        Map<PlayerId, PlayerBrief> found = inTenant(tenant, () -> port().players(tenant, List.of(ana.id(), bob.id())));

        assertThat(found).containsOnlyKeys(ana.id(), bob.id());
        assertThat(found.get(ana.id())).isEqualTo(new PlayerBrief(ana.id(), "Ana Alba", "ACTIVE",
                Optional.of(LocalDate.of(2012, 5, 1)), Optional.of(Gender.FEMALE)));
        assertThat(found.get(bob.id())).isEqualTo(new PlayerBrief(bob.id(), "Bob Bell", "WITHDRAWN",
                Optional.of(LocalDate.of(2011, 1, 2)), Optional.of(Gender.MALE)));
    }

    @Test
    void unknownPlayersAreAbsent() {
        KnownPlayer ana = KnownPlayer.random("Ana Alba");
        core().players(tenant, List.of(ana));
        PlayerId stranger = new PlayerId(UUID.randomUUID());

        Map<PlayerId, PlayerBrief> found = inTenant(tenant, () -> port().players(tenant, List.of(ana.id(), stranger)));

        assertThat(found).containsOnlyKeys(ana.id());
        assertThat(inTenant(tenant, () -> port().playerExists(tenant, stranger))).isFalse();
        assertThat(inTenant(tenant, () -> port().playerExists(tenant, ana.id()))).isTrue();
    }

    @Test
    void anotherTenantsTeamIsNotFound() {
        TenantId other = TenantId.random();
        core().team(other, team, "Theirs", List.of(KnownPlayer.random("Zoe Zed")), List.of());
        core().unknownTeam(tenant, team);

        assertThatThrownBy(() -> inTenant(tenant, () -> port().teamRoster(tenant, team)))
                .isInstanceOf(NotFoundException.class);
    }
}
