package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

class HealthDomainTest {

    static final Instant NOW = Instant.parse("2026-11-02T10:00:00Z");
    static final Actor COACH = new Actor(PersonId.random(), "Coach Carter");
    static final LocalDate TODAY = LocalDate.of(2026, 11, 2);
    static final PlayerId PLAYER = PlayerId.random();

    static Injury injury(LocalDate occurred, LocalDate expected) {
        return Injury.report(PLAYER, occurred, "left ankle", null, InjurySeverity.MODERATE, expected, COACH, NOW);
    }

    // ---- injury invariants
    @Test
    void anInjuryStartsOpenWithoutActualReturn() {
        Injury injury = injury(TODAY, TODAY.plusDays(10));

        assertThat(injury.status()).isEqualTo(InjuryStatus.OPEN);
        assertThat(injury.actualReturnOn()).isEmpty();
        assertThat(injury.reportedBy()).isEqualTo(COACH);
    }

    @Test
    void expectedReturnMustNotBeBeforeTheDayOfTheInjury() {
        assertThat(injury(TODAY, TODAY).expectedReturnOn()).contains(TODAY);
        assertThat(injury(TODAY, null).expectedReturnOn()).isEmpty();
        assertThatThrownBy(() -> injury(TODAY, TODAY.minusDays(1))).isInstanceOf(DomainRuleViolation.class)
                .extracting("code").isEqualTo("INJURY_RETURN_BEFORE_OCCURRENCE");
    }

    @Test
    void recoveringNeedsAnActualReturnNotBeforeTheInjury() {
        Injury open = injury(TODAY, TODAY.plusDays(5));

        Injury recovered = open.changedTo(TODAY, "left ankle", null, InjurySeverity.MODERATE, TODAY.plusDays(5),
                TODAY.plusDays(3), InjuryStatus.RECOVERED, NOW);

        assertThat(recovered.status()).isEqualTo(InjuryStatus.RECOVERED);
        assertThatThrownBy(() -> open.changedTo(TODAY, "left ankle", null, InjurySeverity.MODERATE, null, null,
                InjuryStatus.RECOVERED, NOW)).isInstanceOf(DomainRuleViolation.class)
                .extracting("code").isEqualTo("RECOVERY_DATE_REQUIRED");
        assertThatThrownBy(() -> open.changedTo(TODAY, "left ankle", null, InjurySeverity.MODERATE, null,
                TODAY.minusDays(1), InjuryStatus.RECOVERED, NOW)).isInstanceOf(DomainRuleViolation.class)
                .extracting("code").isEqualTo("INJURY_RETURN_BEFORE_OCCURRENCE");
    }

    @Test
    void movingTheInjuryDateAfterTheExpectedReturnIsRejected() {
        Injury open = injury(TODAY, TODAY.plusDays(5));

        assertThatThrownBy(() -> open.changedTo(TODAY.plusDays(6), "left ankle", null, InjurySeverity.MODERATE,
                TODAY.plusDays(5), null, InjuryStatus.OPEN, NOW)).isInstanceOf(DomainRuleViolation.class)
                .extracting("code").isEqualTo("INJURY_RETURN_BEFORE_OCCURRENCE");
    }

    @Test
    void bodyPartIsRequired() {
        assertThatThrownBy(() -> Injury.report(PLAYER, TODAY, " ", null, InjurySeverity.MINOR, null, COACH, NOW))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("INVALID_INJURY");
    }

    // ---- availability around today
    @Test
    void anOpenInjuryWithoutActualReturnMakesThePlayerUnavailableEvenWhenTheExpectedDateHasPassed() {
        Injury overdue = injury(TODAY.minusDays(20), TODAY.minusDays(2));
        Injury noEstimate = injury(TODAY.minusDays(1), null);

        assertThat(overdue.blocksAvailability(TODAY)).isTrue();
        assertThat(noEstimate.blocksAvailability(TODAY)).isTrue();
    }

    @Test
    void aRecoveredInjuryNeverBlocks() {
        Injury recovered = injury(TODAY.minusDays(5), TODAY.plusDays(5)).changedTo(TODAY.minusDays(5), "left ankle", null,
                InjurySeverity.MODERATE, TODAY.plusDays(5), TODAY.minusDays(1), InjuryStatus.RECOVERED, NOW);

        assertThat(recovered.blocksAvailability(TODAY)).isFalse();
    }

    @Test
    void anOpenInjuryWithAnActualReturnBlocksOnlyUntilTheExpectedReturnDayIsOver() {
        Injury open = injury(TODAY.minusDays(5), TODAY).changedTo(TODAY.minusDays(5), "left ankle", null,
                InjurySeverity.MINOR, TODAY, TODAY.minusDays(1), InjuryStatus.OPEN, NOW);

        assertThat(open.blocksAvailability(TODAY)).as("expected return is today (>= today)").isTrue();
        assertThat(open.blocksAvailability(TODAY.plusDays(1))).as("expected return was yesterday").isFalse();
        assertThat(open.blocksAvailability(TODAY.minusDays(3))).isTrue();
    }

    @Test
    void availabilityListsTheLatestExpectedReturnOfTheBlockingInjuries() {
        Injury early = injury(TODAY.minusDays(3), TODAY.plusDays(2));
        Injury late = injury(TODAY.minusDays(1), TODAY.plusDays(9));
        Injury recovered = injury(TODAY.minusDays(30), TODAY.minusDays(20)).changedTo(TODAY.minusDays(30), "wrist", null,
                InjurySeverity.MINOR, TODAY.minusDays(20), TODAY.minusDays(21), InjuryStatus.RECOVERED, NOW);

        PlayerAvailability availability = PlayerAvailability.of(PLAYER, List.of(early, late, recovered), TODAY);

        assertThat(availability.available()).isFalse();
        assertThat(availability.expectedReturnOn()).contains(TODAY.plusDays(9));
        assertThat(availability.blockingInjuries()).containsExactlyInAnyOrder(early.id(), late.id());
    }

    @Test
    void withoutBlockingInjuriesThePlayerIsAvailable() {
        PlayerAvailability availability = PlayerAvailability.of(PLAYER, List.of(), TODAY);

        assertThat(availability.available()).isTrue();
        assertThat(availability.expectedReturnOn()).isEmpty();
        assertThat(availability.blockingInjuries()).isEmpty();
    }

    @Test
    void unknownExpectedReturnLeavesTheReturnDateEmptyWhileUnavailable() {
        PlayerAvailability availability = PlayerAvailability.of(PLAYER, List.of(injury(TODAY, null)), TODAY);

        assertThat(availability.available()).isFalse();
        assertThat(availability.expectedReturnOn()).isEmpty();
    }

    // ---- body measurement invariants
    @Test
    void aMeasurementNeedsHeightOrWeightWithinRange() {
        BodyMeasurement both = BodyMeasurement.record(PLAYER, TODAY, new BigDecimal("172.46"), new BigDecimal("61.234"), COACH, NOW);

        assertThat(both.heightCm()).contains(new BigDecimal("172.5"));
        assertThat(both.weightKg()).contains(new BigDecimal("61.23"));
        assertThat(BodyMeasurement.record(PLAYER, TODAY, null, new BigDecimal("40"), COACH, NOW).heightCm()).isEmpty();
        assertThatThrownBy(() -> BodyMeasurement.record(PLAYER, TODAY, null, null, COACH, NOW))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("MEASUREMENT_EMPTY");
        assertThatThrownBy(() -> BodyMeasurement.record(PLAYER, TODAY, new BigDecimal("49.9"), null, COACH, NOW))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("MEASUREMENT_OUT_OF_RANGE");
        assertThatThrownBy(() -> BodyMeasurement.record(PLAYER, TODAY, null, new BigDecimal("250.1"), COACH, NOW))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("MEASUREMENT_OUT_OF_RANGE");
    }

    // ---- test type invariants
    @Test
    void aCustomTestTypeIsNotGlobalAndHasAWellFormedCode() {
        PhysicalTestType type = PhysicalTestType.custom("MY_SHUTTLE", "Shuttle", "s", false, null);

        assertThat(type.global()).isFalse();
        assertThat(type.higherIsBetter()).isFalse();
        assertThatThrownBy(() -> PhysicalTestType.custom("my shuttle", "Shuttle", "s", false, null))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("INVALID_TEST_TYPE");
        assertThatThrownBy(() -> PhysicalTestType.custom("X", "Shuttle", "s", false, null))
                .isInstanceOf(DomainRuleViolation.class);
    }

    @Test
    void aGlobalTestTypeRefusesChanges() {
        PhysicalTestType global = new PhysicalTestType(TestTypeId.random(), "COOPER_12MIN", "Cooper", "m", true, null, true);

        assertThatThrownBy(() -> global.changedTo("x", "m", true, null))
                .isInstanceOf(com.hoopsacademy.common.problem.AccessDeniedException.class)
                .extracting("code").isEqualTo("TEST_TYPE_IS_GLOBAL");
    }
}
