package com.hoopsacademy.athlete.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.athlete.adapters.in.messaging.CoreEventDecoder;
import com.hoopsacademy.athlete.application.TeamRoster;
import com.hoopsacademy.athlete.application.replica.ApplyRosterEvent;
import com.hoopsacademy.athlete.domain.PersonId;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.athlete.support.CoreEvents;
import com.hoopsacademy.athlete.support.ReplicaFeed;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.testing.PostgresRlsResource;
import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.common.tenancy.TenantScope;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.common.WithTestResource;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * The replica answers what core's /internal API answers (InternalRoster): only open, valid assignments; players
 * without birth date or gender are left out (the contract requires both); a tenant that is not ACTIVE is not found;
 * players ordered by joining date, staff by role, since and person like core.
 */
@QuarkusTest
@WithTestResource(value = PostgresRlsResource.class, initArgs = @ResourceArg(name = "service", value = "athlete"))
class ReplicaRosterRulesTest {

    static final LocalDate SEASON_END = LocalDate.now().plusMonths(6);

    @Inject ReplicaRosterRepository replica;
    @Inject CoreEventDecoder decoder;
    @Inject ApplyRosterEvent apply;
    @Inject TenantScope tenantScope;

    ReplicaFeed feed;
    TenantId tenant;
    UUID team;

    @BeforeEach
    void setUp() {
        feed = new ReplicaFeed(decoder, apply);
        tenant = TenantId.random();
        team = UUID.randomUUID();
        feed.apply(CoreEvents.tenant(tenant, "ACTIVE", "Europe/Madrid"),
                CoreEvents.team(tenant, team, "U12", SEASON_END));
    }

    @Test
    void closedAndInvalidatedAssignmentsAreNotOnTheRoster() {
        UUID current = player("Cara Current", LocalDate.of(2013, 1, 1), "FEMALE");
        UUID left = player("Lena Left", LocalDate.of(2013, 1, 1), "FEMALE");
        UUID invalid = player("Ines Invalid", LocalDate.of(2013, 1, 1), "FEMALE");
        assign(current, LocalDate.of(2026, 9, 1), null, null);
        assign(left, LocalDate.of(2026, 9, 1), LocalDate.of(2026, 10, 1), null);
        assign(invalid, LocalDate.of(2026, 9, 1), null, "CATEGORY_TOO_LOW");

        assertThat(roster().playerIds()).containsExactly(new PlayerId(current));
    }

    @Test
    void anAssignmentClosedLaterLeavesTheRoster() {
        UUID p = player("Cara Current", LocalDate.of(2013, 1, 1), "FEMALE");
        UUID assignment = UUID.randomUUID();
        feed.apply(CoreEvents.teamPlayer(tenant, assignment, team, p, "4", LocalDate.of(2026, 9, 1), null, null));
        feed.apply(CoreEvents.teamPlayer(tenant, assignment, team, p, "4", LocalDate.of(2026, 9, 1),
                LocalDate.of(2026, 11, 1), null));

        assertThat(roster().players()).isEmpty();
    }

    @Test
    void playersWithoutBirthDateOrGenderAreLeftOutLikeCoreDoes() {
        UUID complete = player("Cara Complete", LocalDate.of(2013, 1, 1), "FEMALE");
        UUID noBirth = player("Nora Nobirth", null, "FEMALE");
        UUID noGender = player("Nico Nogender", LocalDate.of(2013, 1, 1), null);
        List.of(complete, noBirth, noGender).forEach(p -> assign(p, LocalDate.of(2026, 9, 1), null, null));

        assertThat(roster().playerIds()).containsExactly(new PlayerId(complete));
        assertThat(tenantScope.runAs(tenant, () -> replica.players(tenant,
                List.of(new PlayerId(complete), new PlayerId(noBirth), new PlayerId(noGender)))))
                .containsOnlyKeys(new PlayerId(complete));
    }

    @Test
    void aPlayerOnTheRosterCarriesTheNameOfItsLatestPlayerEvent() {
        UUID person = UUID.randomUUID();
        UUID p = UUID.randomUUID();
        feed.apply(CoreEvents.player(tenant, p, person, "Old Name", "ACTIVE", LocalDate.of(2013, 1, 1), "MALE"),
                CoreEvents.player(tenant, p, person, "New Name", "ACTIVE", LocalDate.of(2013, 1, 1), "MALE"));
        assign(p, LocalDate.of(2026, 9, 1), null, null);

        assertThat(roster().players()).containsExactly(new TeamRoster.RosterPlayer(new PlayerId(p), "New Name"));
    }

    @Test
    void anAssignmentWhosePlayerHasNotArrivedYetIsNotListed() {
        assign(UUID.randomUUID(), LocalDate.of(2026, 9, 1), null, null);

        assertThat(roster().players()).isEmpty();
    }

    @Test
    void playersAreOrderedByJoiningDate() {
        UUID later = player("Lara Later", LocalDate.of(2013, 1, 1), "FEMALE");
        UUID earlier = player("Erin Earlier", LocalDate.of(2013, 1, 1), "FEMALE");
        assign(later, LocalDate.of(2026, 10, 1), null, null);
        assign(earlier, LocalDate.of(2026, 9, 1), null, null);

        assertThat(roster().playerIds()).containsExactly(new PlayerId(earlier), new PlayerId(later));
    }

    @Test
    void staffIsOrderedByRoleThenPersonAndRemovedEntriesAreGone() {
        UUID coach = UUID.fromString("00000000-0000-4000-8000-000000000001");
        UUID assistant = UUID.fromString("00000000-0000-4000-8000-000000000002");
        UUID gone = UUID.fromString("00000000-0000-4000-8000-000000000003");
        feed.apply(CoreEvents.teamStaff(tenant, team, coach, "COACH"),
                CoreEvents.teamStaff(tenant, team, assistant, "ASSISTANT_COACH"),
                CoreEvents.teamStaff(tenant, team, gone, "COACH"),
                CoreEvents.teamStaffRemoved(tenant, team, gone));

        assertThat(roster().staff()).containsExactly(new PersonId(assistant), new PersonId(coach));
    }

    @Test
    void aSuspendedTenantIsNotFoundLikeCoreAnswers() {
        UUID p = player("Cara Current", LocalDate.of(2013, 1, 1), "FEMALE");
        feed.apply(CoreEvents.tenant(tenant, "SUSPENDED", "Europe/Madrid"));

        assertThatThrownBy(this::roster).isInstanceOf(NotFoundException.class);
        assertThat(tenantScope.runAs(tenant, () -> replica.players(tenant, List.of(new PlayerId(p))))).isEmpty();
    }

    @Test
    void aTenantTheReplicaHasNotSeenIsNotFound() {
        TenantId unseen = TenantId.random();

        assertThatThrownBy(() -> tenantScope.runAs(unseen, () -> replica.teamRoster(unseen, new TeamId(team))))
                .isInstanceOf(NotFoundException.class);
        assertThat(tenantScope.runAs(unseen, () -> replica.players(unseen, List.of(new PlayerId(UUID.randomUUID())))))
                .isEmpty();
    }

    @Test
    void noIdsAskedIsAnEmptyAnswer() {
        assertThat(tenantScope.runAs(tenant, () -> replica.players(tenant, List.of()))).isEmpty();
    }

    /** WP82: removed players, assignments and staff persons leave the roster; a removed team is not found. */
    @Test
    void removedPlayersAssignmentsAndPersonsLeaveTheRoster() {
        UUID kept = player("Cara Current", LocalDate.of(2013, 1, 1), "FEMALE");
        UUID removedPlayer = player("Gina Gone", LocalDate.of(2013, 1, 1), "FEMALE");
        UUID unassigned = player("Una Unassigned", LocalDate.of(2013, 1, 1), "FEMALE");
        UUID assignment = UUID.randomUUID();
        UUID coach = UUID.randomUUID();
        UUID removedCoach = UUID.randomUUID();
        assign(kept, LocalDate.of(2026, 9, 1), null, null);
        assign(removedPlayer, LocalDate.of(2026, 9, 1), null, null);
        feed.apply(CoreEvents.teamPlayer(tenant, assignment, team, unassigned, null, LocalDate.of(2026, 9, 1), null, null),
                CoreEvents.person(tenant, coach, "Cole Coach", null, List.of("COACH"), true),
                CoreEvents.person(tenant, removedCoach, "Gus Gone", null, List.of("COACH"), true),
                CoreEvents.teamStaff(tenant, team, coach, "COACH"), CoreEvents.teamStaff(tenant, team, removedCoach, "COACH"),
                CoreEvents.removed(tenant, "player", removedPlayer), CoreEvents.removed(tenant, "team-player", assignment),
                CoreEvents.removed(tenant, "person", removedCoach));

        assertThat(roster().playerIds()).containsExactly(new PlayerId(kept));
        assertThat(roster().staff()).containsExactly(new PersonId(coach));
        assertThat(tenantScope.runAs(tenant, () -> replica.players(tenant,
                List.of(new PlayerId(kept), new PlayerId(removedPlayer))))).containsOnlyKeys(new PlayerId(kept));
    }

    @Test
    void aRemovedTeamOrTenantIsNotFound() {
        UUID p = player("Cara Current", LocalDate.of(2013, 1, 1), "FEMALE");
        feed.apply(CoreEvents.removed(tenant, "team", team));
        assertThatThrownBy(this::roster).isInstanceOf(NotFoundException.class);

        feed.apply(CoreEvents.tenantRemoved(tenant));
        assertThat(tenantScope.runAs(tenant, () -> replica.players(tenant, List.of(new PlayerId(p))))).isEmpty();
    }

    private TeamRoster roster() {
        return tenantScope.runAs(tenant, () -> replica.teamRoster(tenant, new TeamId(team)));
    }

    private UUID player(String name, LocalDate birthDate, String gender) {
        UUID person = UUID.randomUUID();
        UUID player = UUID.randomUUID();
        feed.apply(CoreEvents.person(tenant, person, name, null, List.of("PLAYER"), true),
                CoreEvents.player(tenant, player, person, name, "ACTIVE", birthDate, gender));
        return player;
    }

    private void assign(UUID player, LocalDate joinedOn, LocalDate leftOn, String invalidReason) {
        feed.apply(CoreEvents.teamPlayer(tenant, UUID.randomUUID(), team, player, null, joinedOn, leftOn, invalidReason));
    }
}
