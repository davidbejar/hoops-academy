package com.hoopsacademy.game.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;

/** When a season closes (ADR-0042; extracted from PastSeasons in WP88). */
class SeasonCloseTest {

    private static final LocalDate LAST_DAY = LocalDate.of(2026, 6, 30);
    private static final ZoneId JAKARTA = ZoneId.of("Asia/Jakarta");

    @Test
    void aSeasonClosesAtTheStartOfTheDayAfterItsLastDayInTheAcademysZone() {
        assertThat(SeasonClose.after(LAST_DAY, JAKARTA).at()).isEqualTo(Instant.parse("2026-06-30T17:00:00Z"));
    }

    @Test
    void itHasPassedFromThatInstantOn() {
        SeasonClose close = SeasonClose.after(LAST_DAY, JAKARTA);

        assertThat(close.hasPassed(Instant.parse("2026-06-30T16:59:59Z"))).isFalse();
        assertThat(close.hasPassed(Instant.parse("2026-06-30T17:00:00Z"))).isTrue();
        assertThat(close.hasPassed(Instant.parse("2026-07-01T00:00:00Z"))).isTrue();
    }
}
