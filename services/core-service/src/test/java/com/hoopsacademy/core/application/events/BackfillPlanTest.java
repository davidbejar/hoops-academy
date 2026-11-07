package com.hoopsacademy.core.application.events;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.tenancy.TenantId;
import com.hoopsacademy.core.domain.membership.GuardianLinkId;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.roster.TeamPlayerId;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The pure rules of the events backfill (WP81, extracted in WP88 for PIT): order, candidates, aggregate ids, chunks. */
class BackfillPlanTest {

    private static final TenantId TENANT = TenantId.random();

    @Test
    void theTenantComesFirstThenTheMembersThenWhatRefersToThem() {
        assertThat(BackfillPlan.ORDER).containsExactly(EventTopic.TENANT, EventTopic.PERSON, EventTopic.PLAYER,
                EventTopic.TEAM, EventTopic.TEAM_PLAYER, EventTopic.TEAM_STAFF, EventTopic.GUARDIAN_LINK);
    }

    @Test
    void eachChangeIsKeyedByTheIdItsEventCarries() {
        UUID id = UUID.randomUUID();
        UUID other = UUID.randomUUID();

        assertThat(BackfillPlan.aggregateId(TENANT, new RosterChange.Person(new PersonId(id)))).isEqualTo(id);
        assertThat(BackfillPlan.aggregateId(TENANT, new RosterChange.Player(new PlayerId(id)))).isEqualTo(id);
        assertThat(BackfillPlan.aggregateId(TENANT, new RosterChange.Team(new TeamId(id)))).isEqualTo(id);
        assertThat(BackfillPlan.aggregateId(TENANT, new RosterChange.TeamPlayer(new TeamPlayerId(id)))).isEqualTo(id);
        assertThat(BackfillPlan.aggregateId(TENANT, new RosterChange.GuardianLink(new GuardianLinkId(id),
                new PersonId(other), new PlayerId(other)))).isEqualTo(id);
        assertThat(BackfillPlan.aggregateId(TENANT, new RosterChange.Tenant())).isEqualTo(TENANT.value());
        assertThat(BackfillPlan.aggregateId(TENANT, new RosterChange.TeamStaff(new TeamId(id), new PersonId(other))))
                .isEqualTo(EventTopic.teamStaffId(id, other));
    }

    @Test
    void aSeasonHasNoEventOfItsOwn() {
        RosterChange season = new RosterChange.Season(new SeasonId(UUID.randomUUID()));

        assertThatThrownBy(() -> BackfillPlan.aggregateId(TENANT, season)).isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("season");
    }

    @Test
    void theCandidatesAreTheLiveAggregatesWithoutAPublishedEventInTheirOrder() {
        RosterChange.Person ana = person();
        RosterChange.Person bea = person();
        RosterChange.Person carl = person();

        List<RosterChange> missing = BackfillPlan.missing(TENANT, List.of(carl, ana, bea),
                Set.of(ana.id().value().toString()));

        assertThat(missing).containsExactly(carl, bea);
        assertThat(BackfillPlan.missing(TENANT, List.of(ana), Set.of())).containsExactly(ana);
        assertThat(BackfillPlan.missing(TENANT, List.of(), Set.of("x"))).isEmpty();
    }

    @Test
    void candidatesAreAppendedInChunksOfTheConfiguredSize() {
        List<Integer> five = List.of(1, 2, 3, 4, 5);

        assertThat(BackfillPlan.chunks(five, 2)).containsExactly(List.of(1, 2), List.of(3, 4), List.of(5));
        assertThat(BackfillPlan.chunks(five, 5)).containsExactly(five);
        assertThat(BackfillPlan.chunks(five, 6)).containsExactly(five);
        assertThat(BackfillPlan.chunks(List.of(1, 2, 3, 4), 2)).containsExactly(List.of(1, 2), List.of(3, 4));
        assertThat(BackfillPlan.chunks(List.of(), 2)).isEmpty();
    }

    private static RosterChange.Person person() {
        return new RosterChange.Person(new PersonId(UUID.randomUUID()));
    }
}
