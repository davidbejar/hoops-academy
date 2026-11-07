package com.hoopsacademy.core.domain.roster;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Which of some seasons are read-only history on a day (ADR-0042; extracted from PastSeasons in WP88). */
class EndedSeasonsTest {

    private static final LocalDate TODAY = LocalDate.of(2026, 11, 7);
    private static final Season PAST = season(LocalDate.of(2025, 9, 1), TODAY.minusDays(1));
    private static final Season LAST_DAY = season(LocalDate.of(2026, 9, 1), TODAY);
    private static final Season NEXT = season(TODAY.plusDays(1), TODAY.plusYears(1));

    @Test
    void onlyTheNamedSeasonsThatEndedBeforeTodayAreHistory() {
        assertThat(EndedSeasons.among(List.of(PAST.id(), LAST_DAY.id(), NEXT.id()), List.of(PAST, LAST_DAY, NEXT),
                TODAY)).containsExactly(PAST.id());
    }

    @Test
    void aSeasonThatIsNotNamedOrNotKnownIsNot() {
        SeasonId unknown = new SeasonId(UUID.randomUUID());

        assertThat(EndedSeasons.among(List.of(LAST_DAY.id(), unknown), List.of(PAST, LAST_DAY), TODAY)).isEmpty();
        assertThat(EndedSeasons.among(List.of(), List.of(PAST), TODAY)).isEmpty();
    }

    private static Season season(LocalDate start, LocalDate end) {
        return new Season(new SeasonId(UUID.randomUUID()), "S " + start, start, end, start.getYear());
    }
}
