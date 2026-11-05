package com.hoopsacademy.core.domain.roster;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.domain.shared.Patch;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class SeasonTest {

    private final Season season = new Season(SeasonId.random(), " 2026/27 ", LocalDate.of(2026, 9, 1),
            LocalDate.of(2027, 6, 30), 2026);

    @Test
    void validatesNameDatesAndReferenceYear() {
        assertThat(season.name()).isEqualTo("2026/27");
        assertThatThrownBy(() -> new Season(SeasonId.random(), "x", LocalDate.of(2026, 9, 2), LocalDate.of(2026, 9, 1), 2026))
                .isInstanceOf(DomainRuleViolation.class)
                .extracting(e -> ((DomainRuleViolation) e).code()).isEqualTo("INVALID_ENDS_ON");
        assertThatThrownBy(() -> new Season(SeasonId.random(), "x", LocalDate.of(2026, 9, 1), LocalDate.of(2026, 9, 1), 1999))
                .isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new Season(SeasonId.random(), "x", LocalDate.of(2026, 9, 1), LocalDate.of(2026, 9, 1), 2101))
                .isInstanceOf(DomainRuleViolation.class);
        assertThat(new Season(SeasonId.random(), "x", LocalDate.of(2026, 9, 1), LocalDate.of(2026, 9, 1), 2000)
                .referenceYear()).isEqualTo(2000);
        assertThat(new Season(SeasonId.random(), "x", LocalDate.of(2026, 9, 1), LocalDate.of(2026, 9, 1), 2100)
                .referenceYear()).isEqualTo(2100);
        assertThatThrownBy(() -> new Season(SeasonId.random(), "", LocalDate.of(2026, 9, 1), LocalDate.of(2026, 9, 1), 2026))
                .isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new Season(SeasonId.random(), "x", null, LocalDate.of(2026, 9, 1), 2026))
                .isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new Season(null, "x", LocalDate.of(2026, 9, 1), LocalDate.of(2026, 9, 1), 2026))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    void overlapIncludesSharedBoundaryDaysButNotItself() {
        assertThat(season.overlaps(season)).isFalse();
        assertThat(season.overlaps(other(LocalDate.of(2027, 6, 30), LocalDate.of(2028, 6, 30)))).isTrue();
        assertThat(season.overlaps(other(LocalDate.of(2025, 9, 1), LocalDate.of(2026, 9, 1)))).isTrue();
        assertThat(season.overlaps(other(LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 2)))).isTrue();
        assertThat(season.overlaps(other(LocalDate.of(2027, 7, 1), LocalDate.of(2028, 6, 30)))).isFalse();
        assertThat(season.overlaps(other(LocalDate.of(2025, 9, 1), LocalDate.of(2026, 8, 31)))).isFalse();
    }

    @Test
    void currentAndEndedAreInclusiveOfTheBoundaries() {
        assertThat(season.isCurrent(LocalDate.of(2026, 8, 31))).isFalse();
        assertThat(season.isCurrent(LocalDate.of(2026, 9, 1))).isTrue();
        assertThat(season.isCurrent(LocalDate.of(2027, 6, 30))).isTrue();
        assertThat(season.isCurrent(LocalDate.of(2027, 7, 1))).isFalse();
        assertThat(season.hasEnded(LocalDate.of(2027, 6, 30))).isFalse();
        assertThat(season.hasEnded(LocalDate.of(2027, 7, 1))).isTrue();
    }

    @Test
    void changesAreAppliedAndRevalidated() {
        assertThat(new SeasonChanges(Patch.of("Next"), Patch.absent(), Patch.absent(), Patch.absent())
                .changesReferenceYear()).isFalse();
        assertThat(new SeasonChanges(Patch.absent(), Patch.absent(), Patch.absent(), Patch.of(2027))
                .changesReferenceYear()).isTrue();
        Season renamed = season.apply(new SeasonChanges(Patch.of("Next"), Patch.absent(), Patch.absent(), Patch.of(2027)));
        assertThat(renamed.name()).isEqualTo("Next");
        assertThat(renamed.referenceYear()).isEqualTo(2027);
        assertThat(renamed.startsOn()).isEqualTo(season.startsOn());
        assertThat(renamed.id()).isEqualTo(season.id());
        assertThatThrownBy(() -> season.apply(new SeasonChanges(Patch.absent(), Patch.of(LocalDate.of(2028, 1, 1)),
                Patch.absent(), Patch.absent()))).isInstanceOf(DomainRuleViolation.class);
        assertThat(new SeasonChanges(Patch.absent(), Patch.absent(), Patch.absent(), Patch.of(2026)).changesReferenceYear())
                .isTrue();
    }

    private static Season other(LocalDate from, LocalDate to) {
        return new Season(SeasonId.random(), "other", from, to, from.getYear());
    }
}
