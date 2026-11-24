package com.hoopsacademy.athlete.adapters.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.athlete.application.AssignmentRepository.AssignmentQuery;
import com.hoopsacademy.athlete.domain.PlanAssignment;
import com.hoopsacademy.athlete.domain.PlayerId;
import com.hoopsacademy.athlete.domain.TeamId;
import com.hoopsacademy.common.paging.PageResult;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The JPQL filter of an assignment search, without a database (the API tests run it against one). */
class AssignmentSearchClauseTest {

    private static final TeamId TEAM = new TeamId(UUID.randomUUID());
    private static final PlayerId PLAYER = new PlayerId(UUID.randomUUID());
    private static final Optional<LocalDate> NONE = Optional.empty();

    @Test
    void noRestrictionMeansNoWhereClause() {
        assertThat(AssignmentJpaRepository.whereClause(query(null, null, NONE, NONE))).isEmpty();
    }

    @Test
    void teamsAndPlayersAreAlternativesAndTheDueWindowNarrowsThem() {
        String where = AssignmentJpaRepository.whereClause(
                query(List.of(TEAM), List.of(PLAYER), Optional.of(LocalDate.MIN), Optional.of(LocalDate.MAX)));

        assertThat(where).isEqualTo(" where (a.teamId in :teams or a.playerId in :players)"
                + " and a.dueOn >= :dueFrom and a.dueOn <= :dueTo");
    }

    @Test
    void anEmptyTargetListAddsNoCondition() {
        assertThat(AssignmentJpaRepository.whereClause(query(List.of(), List.of(PLAYER), NONE, NONE)))
                .isEqualTo(" where (a.playerId in :players)");
        assertThat(AssignmentJpaRepository.whereClause(query(List.of(TEAM), null, NONE, Optional.of(LocalDate.MAX))))
                .isEqualTo(" where (a.teamId in :teams) and a.dueOn <= :dueTo");
    }

    @Test
    void aScopeWithoutAnyTeamOrPlayerFindsNothingWithoutQuerying() {
        AssignmentJpaRepository withoutDatabase = new AssignmentJpaRepository(null);

        PageResult<PlanAssignment> found = withoutDatabase.search(query(List.of(), null, NONE, NONE));

        assertThat(found.items()).isEmpty();
        assertThat(found.totalElements()).isZero();
    }

    private static AssignmentQuery query(List<TeamId> teams, List<PlayerId> players, Optional<LocalDate> from,
            Optional<LocalDate> to) {
        return new AssignmentQuery(teams, players, from, to, 0, 20);
    }
}
