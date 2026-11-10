package com.hoopsacademy.core.domain.roster;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.core.domain.membership.PlayerId;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** WP96 (decision 70, ADR-0048): which number a new assignment gets when the request gives none. */
class JerseyCarryOverTest {

    private static final PlayerId PLAYER = PlayerId.random();
    private static final LocalDate SEPTEMBER = LocalDate.of(2025, 9, 1);
    private static final JerseyNumber SEVEN = JerseyNumber.of("7");
    private static final JerseyNumber NINE = JerseyNumber.of("9");

    @Test
    void aRequestedNumberIsUsedAsRequested() {
        JerseyChoice choice = JerseyCarryOver.choose(Optional.of(NINE), Optional.of(SEVEN),
                List.of(numbered("4", SEPTEMBER, null)), Set.of());

        assertThat(choice).isEqualTo(new JerseyChoice(NINE, JerseySource.REQUESTED));
    }

    @Test
    void withoutARequestThePreferredNumberWinsWhenFree() {
        JerseyChoice choice = JerseyCarryOver.choose(Optional.empty(), Optional.of(SEVEN),
                List.of(numbered("4", SEPTEMBER, null)), Set.of(JerseyNumber.of("07"), JerseyNumber.of("70")));

        assertThat(choice).isEqualTo(new JerseyChoice(SEVEN, JerseySource.PREFERRED));
    }

    @Test
    void aTakenPreferredNumberFallsBackToThePreviousOne() {
        JerseyChoice choice = JerseyCarryOver.choose(Optional.empty(), Optional.of(SEVEN),
                List.of(numbered("4", SEPTEMBER, null)), Set.of(SEVEN));

        assertThat(choice).isEqualTo(new JerseyChoice(JerseyNumber.of("4"), JerseySource.PREVIOUS));
    }

    @Test
    void withoutAPreferenceThePreviousNumberIsUsedWhenFree() {
        JerseyChoice choice = JerseyCarryOver.choose(Optional.empty(), Optional.empty(),
                List.of(numbered("4", SEPTEMBER, SEPTEMBER.plusMonths(9))), Set.of(NINE));

        assertThat(choice).isEqualTo(new JerseyChoice(JerseyNumber.of("4"), JerseySource.PREVIOUS));
    }

    @Test
    void whenBothAreTakenTheAssignmentGetsNoNumber() {
        JerseyChoice choice = JerseyCarryOver.choose(Optional.empty(), Optional.of(SEVEN),
                List.of(numbered("4", SEPTEMBER, null)), Set.of(SEVEN, JerseyNumber.of("4")));

        assertThat(choice).isEqualTo(JerseyChoice.NONE);
        assertThat(choice.number()).isNull();
        assertThat(choice.source()).isEqualTo(JerseySource.NONE);
    }

    @Test
    void aPlayerWithoutPreferenceOrHistoryGetsNoNumber() {
        assertThat(JerseyCarryOver.choose(Optional.empty(), Optional.empty(), List.of(), Set.of()))
                .isEqualTo(JerseyChoice.NONE);
    }

    @Test
    void thePreviousNumberIsTheOneOfTheMostRecentNumberedAssignment() {
        List<TeamPlayer> history = List.of(
                numbered("4", SEPTEMBER.minusYears(1), SEPTEMBER.minusMonths(3)),
                numbered("12", SEPTEMBER, SEPTEMBER.plusMonths(9)),
                numbered(null, SEPTEMBER.plusYears(1), null),
                numbered("23", SEPTEMBER.minusYears(2), null));

        assertThat(JerseyCarryOver.previous(history)).contains(JerseyNumber.of("12"));
    }

    @Test
    void onTheSameJoiningDayTheOpenAssignmentIsMoreRecentThanAClosedOne() {
        List<TeamPlayer> openLast = List.of(numbered("5", SEPTEMBER, SEPTEMBER.plusDays(1)),
                numbered("6", SEPTEMBER, null));
        List<TeamPlayer> openFirst = List.of(numbered("6", SEPTEMBER, null),
                numbered("5", SEPTEMBER, SEPTEMBER.plusDays(1)));

        assertThat(JerseyCarryOver.previous(openLast)).contains(JerseyNumber.of("6"));
        assertThat(JerseyCarryOver.previous(openFirst)).contains(JerseyNumber.of("6"));
    }

    @Test
    void onTheSameJoiningDayTheLaterLeftAssignmentIsMoreRecent() {
        List<TeamPlayer> history = List.of(numbered("5", SEPTEMBER, SEPTEMBER.plusDays(9)),
                numbered("6", SEPTEMBER, SEPTEMBER.plusDays(1)));

        assertThat(JerseyCarryOver.previous(history)).contains(JerseyNumber.of("5"));
        assertThat(JerseyCarryOver.previous(history.reversed())).contains(JerseyNumber.of("5"));
    }

    @Test
    void unnumberedAssignmentsHaveNoPreviousNumber() {
        assertThat(JerseyCarryOver.previous(List.of(numbered(null, SEPTEMBER, null)))).isEmpty();
        assertThat(JerseyCarryOver.previous(List.of())).isEmpty();
    }

    private static TeamPlayer numbered(String jersey, LocalDate joined, LocalDate left) {
        TeamPlayer open = TeamPlayer.assign(TeamId.random(), PLAYER, JerseyNumber.ofNullable(jersey), joined, 0);
        return left == null ? open : open.close(left);
    }
}
