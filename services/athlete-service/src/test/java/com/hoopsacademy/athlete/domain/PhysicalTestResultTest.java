package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class PhysicalTestResultTest {

    static final Instant NOW = Instant.parse("2026-11-02T10:00:00Z");
    static final LocalDate TODAY = LocalDate.of(2026, 11, 2);
    static final Actor COACH = new Actor(PersonId.random(), "Coach Carter");
    static final PlayerId PLAYER = PlayerId.random();
    static final TestTypeId COOPER = TestTypeId.random();

    static PhysicalTestResult result(String value, String notes) {
        return PhysicalTestResult.record(PLAYER, COOPER, TODAY, new BigDecimal(value), notes, COACH, NOW);
    }

    @Test
    void aRecordedValueIsKeptWithThreeDecimals() {
        PhysicalTestResult result = result("2150.12345", "windy");

        assertThat(result.value()).isEqualTo(new BigDecimal("2150.123"));
        assertThat(result.playerId()).isEqualTo(PLAYER);
        assertThat(result.testTypeId()).isEqualTo(COOPER);
        assertThat(result.recordedBy()).isEqualTo(COACH);
        assertThat(result.id()).isNotEqualTo(result("1", null).id());
    }

    @Test
    void valuesRangeFromZeroToBelowOneBillionAndNotesUpTo1000Characters() {
        assertThat(result("0", null).value()).isZero();
        assertThat(result("999999999.999", "n".repeat(1000)).notes()).hasSize(1000);
        assertThatThrownBy(() -> result("-0.001", null))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("RESULT_VALUE_NEGATIVE");
        assertThatThrownBy(() -> result("1000000000", null))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("RESULT_OUT_OF_RANGE");
        assertThatThrownBy(() -> result("1", "n".repeat(1001)))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("RESULT_OUT_OF_RANGE");
    }

    @Test
    void aChangedResultKeepsItsIdentityAndCreationTime() {
        PhysicalTestResult first = result("2000", null);

        PhysicalTestResult changed = first.changedTo(TODAY.minusDays(1), new BigDecimal("2100.0004"), "re-run",
                NOW.plusSeconds(60));

        assertThat(changed.id()).isEqualTo(first.id());
        assertThat(changed.createdAt()).isEqualTo(NOW);
        assertThat(changed.updatedAt()).isEqualTo(NOW.plusSeconds(60));
        assertThat(changed.measuredOn()).isEqualTo(TODAY.minusDays(1));
        assertThat(changed.value()).isEqualTo(new BigDecimal("2100.000"));
        assertThat(changed.notes()).isEqualTo("re-run");
    }
}
