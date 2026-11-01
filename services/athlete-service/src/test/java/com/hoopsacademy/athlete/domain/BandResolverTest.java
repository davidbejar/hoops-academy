package com.hoopsacademy.athlete.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.athlete.domain.BandResolver.Outcome;
import com.hoopsacademy.common.problem.DomainRuleViolation;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.OptionalInt;
import org.junit.jupiter.api.Test;

/** Band lookup: tenant overrides global, ages are inclusive, ranges are [min, max), missing data gives null + flag. */
class BandResolverTest {

    static final TestTypeId TYPE = TestTypeId.random();

    static BigDecimal v(String value) {
        return new BigDecimal(value);
    }

    static PhysicalTestNorm norm(boolean global, Gender gender, int minAge, int maxAge, NormBand band, String min, String max,
            boolean pending) {
        return PhysicalTestNorm.of(NormId.random(), TYPE, gender, minAge, maxAge, band, min == null ? null : v(min),
                max == null ? null : v(max), pending, "src", global);
    }

    /** Five higher-is-better bands for boys 12-13 around 2000 m. */
    static List<PhysicalTestNorm> globalBoys12to13(boolean pending) {
        return List.of(
                norm(true, Gender.MALE, 12, 13, NormBand.POOR, null, "1800", pending),
                norm(true, Gender.MALE, 12, 13, NormBand.BELOW_AVERAGE, "1800", "2000", pending),
                norm(true, Gender.MALE, 12, 13, NormBand.AVERAGE, "2000", "2200", pending),
                norm(true, Gender.MALE, 12, 13, NormBand.ABOVE_AVERAGE, "2200", "2400", pending),
                norm(true, Gender.MALE, 12, 13, NormBand.EXCELLENT, "2400", null, pending));
    }

    static BandResolver.Resolution resolve(List<PhysicalTestNorm> norms, Gender gender, int age, String value) {
        return BandResolver.resolve(norms, Optional.ofNullable(gender), OptionalInt.of(age), v(value));
    }

    @Test
    void picksTheBandWhoseRangeContainsTheValue() {
        var norms = globalBoys12to13(false);

        assertThat(resolve(norms, Gender.MALE, 12, "1500").expectedBand()).contains(NormBand.POOR);
        assertThat(resolve(norms, Gender.MALE, 12, "2100").expectedBand()).contains(NormBand.AVERAGE);
        assertThat(resolve(norms, Gender.MALE, 12, "2300").expectedBand()).contains(NormBand.ABOVE_AVERAGE);
        assertThat(resolve(norms, Gender.MALE, 12, "3500").expectedBand()).contains(NormBand.EXCELLENT);
        assertThat(resolve(norms, Gender.MALE, 12, "2100").outcome()).isEqualTo(Outcome.MATCHED);
    }

    @Test
    void valueRangesAreMinInclusiveMaxExclusive() {
        var norms = globalBoys12to13(false);

        assertThat(resolve(norms, Gender.MALE, 12, "2000").expectedBand()).contains(NormBand.AVERAGE);
        assertThat(resolve(norms, Gender.MALE, 12, "1999.9").expectedBand()).contains(NormBand.BELOW_AVERAGE);
        assertThat(resolve(norms, Gender.MALE, 12, "2400").expectedBand()).contains(NormBand.EXCELLENT);
    }

    @Test
    void ageEdgesAreInclusiveOnBothSides() {
        var norms = globalBoys12to13(false);

        assertThat(resolve(norms, Gender.MALE, 12, "2100").outcome()).isEqualTo(Outcome.MATCHED);
        assertThat(resolve(norms, Gender.MALE, 13, "2100").outcome()).isEqualTo(Outcome.MATCHED);
        assertThat(resolve(norms, Gender.MALE, 11, "2100").outcome()).isEqualTo(Outcome.NO_NORM);
        assertThat(resolve(norms, Gender.MALE, 14, "2100").outcome()).isEqualTo(Outcome.NO_NORM);
    }

    @Test
    void genderMustMatch() {
        var resolution = resolve(globalBoys12to13(false), Gender.FEMALE, 12, "2100");

        assertThat(resolution.expectedBand()).isEmpty();
        assertThat(resolution.outcome()).isEqualTo(Outcome.NO_NORM);
    }

    @Test
    void aTenantOverrideTakesPrecedenceOverTheGlobalRowsOfTheSameTestGenderAndAgeRange() {
        var norms = new ArrayList<>(globalBoys12to13(false));
        // this academy is stricter: 2100 m is only BELOW_AVERAGE for 12-13 year old boys
        PhysicalTestNorm override = norm(false, Gender.MALE, 12, 13, NormBand.BELOW_AVERAGE, "1900", "2300", false);
        norms.add(override);

        var resolution = resolve(norms, Gender.MALE, 13, "2100");

        assertThat(resolution.expectedBand()).contains(NormBand.BELOW_AVERAGE);
        assertThat(resolution.norm()).contains(override);
    }

    @Test
    void whenTheOverrideCoversTheAgeButNotTheValueThereIsNoFallbackToTheGlobalRows() {
        var norms = new ArrayList<>(globalBoys12to13(false));
        norms.add(norm(false, Gender.MALE, 12, 13, NormBand.AVERAGE, "2000", "2200", false));

        assertThat(resolve(norms, Gender.MALE, 12, "2500").outcome()).isEqualTo(Outcome.NO_NORM);
    }

    @Test
    void anOverrideForOtherGenderOrAgesDoesNotHideGlobalRows() {
        var norms = new ArrayList<>(globalBoys12to13(false));
        norms.add(norm(false, Gender.FEMALE, 12, 13, NormBand.AVERAGE, "1000", "2000", false));
        norms.add(norm(false, Gender.MALE, 14, 15, NormBand.AVERAGE, "1000", "2000", false));

        assertThat(resolve(norms, Gender.MALE, 12, "2300").expectedBand()).contains(NormBand.ABOVE_AVERAGE);
    }

    @Test
    void effectiveNormsDropGlobalRowsOverlappedByATenantRowOfTheSameGender() {
        var global = globalBoys12to13(false);
        PhysicalTestNorm girls = norm(true, Gender.FEMALE, 12, 13, NormBand.AVERAGE, "1500", "1900", false);
        PhysicalTestNorm tenant = norm(false, Gender.MALE, 13, 14, NormBand.AVERAGE, "2000", "2200", false);
        var all = new ArrayList<>(global);
        all.add(girls);
        all.add(tenant);

        var effective = BandResolver.effective(all);

        assertThat(effective).containsExactlyInAnyOrder(girls, tenant);
    }

    @Test
    void missingGenderOrBirthDateGivesNoBandAndTheMissingDataFlag() {
        var norms = globalBoys12to13(false);

        var noGender = BandResolver.resolve(norms, Optional.empty(), OptionalInt.of(12), v("2100"));
        var noAge = BandResolver.resolve(norms, Optional.of(Gender.MALE), OptionalInt.empty(), v("2100"));

        assertThat(noGender.expectedBand()).isEmpty();
        assertThat(noGender.outcome()).isEqualTo(Outcome.MISSING_PLAYER_DATA);
        assertThat(noAge.expectedBand()).isEmpty();
        assertThat(noAge.outcome()).isEqualTo(Outcome.MISSING_PLAYER_DATA);
        assertThat(noAge.referencePending()).isFalse();
    }

    @Test
    void noNormsAtAllIsNoNormNotAnError() {
        var resolution = resolve(List.of(), Gender.MALE, 12, "2100");

        assertThat(resolution.expectedBand()).isEmpty();
        assertThat(resolution.norm()).isEmpty();
        assertThat(resolution.outcome()).isEqualTo(Outcome.NO_NORM);
    }

    @Test
    void referencePendingIsPropagatedFromTheAppliedNorm() {
        assertThat(resolve(globalBoys12to13(true), Gender.MALE, 12, "2100").referencePending()).isTrue();
        assertThat(resolve(globalBoys12to13(false), Gender.MALE, 12, "2100").referencePending()).isFalse();
    }

    // ---- ordering (higher / lower is better only matters for checking that a table is sane)
    @Test
    void aHigherIsBetterTableAscendsFromPoorToExcellent() {
        assertThat(BandResolver.bandsAreOrdered(globalBoys12to13(false), true)).isTrue();
        assertThat(BandResolver.bandsAreOrdered(globalBoys12to13(false), false)).isFalse();
    }

    @Test
    void aLowerIsBetterTableDescendsFromPoorToExcellent() {
        var sprint = List.of(
                norm(true, Gender.MALE, 12, 12, NormBand.EXCELLENT, null, "3.6", false),
                norm(true, Gender.MALE, 12, 12, NormBand.ABOVE_AVERAGE, "3.6", "3.8", false),
                norm(true, Gender.MALE, 12, 12, NormBand.AVERAGE, "3.8", "4.0", false),
                norm(true, Gender.MALE, 12, 12, NormBand.BELOW_AVERAGE, "4.0", "4.3", false),
                norm(true, Gender.MALE, 12, 12, NormBand.POOR, "4.3", null, false));

        assertThat(BandResolver.bandsAreOrdered(sprint, false)).isTrue();
        assertThat(BandResolver.bandsAreOrdered(sprint, true)).isFalse();
    }

    // ---- age
    @Test
    void ageIsCountedInFullYearsOnTheMeasurementDate() {
        LocalDate birth = LocalDate.of(2012, 5, 1);

        assertThat(AgeAt.years(birth, LocalDate.of(2026, 4, 30))).isEqualTo(13);
        assertThat(AgeAt.years(birth, LocalDate.of(2026, 5, 1))).isEqualTo(14);
        assertThat(AgeAt.years(birth, LocalDate.of(2011, 1, 1))).isZero();
    }

    // ---- norm invariants
    @Test
    void aNormNeedsAnOrderedAgeAndValueRange() {
        assertThatThrownBy(() -> norm(false, Gender.MALE, 14, 12, NormBand.AVERAGE, "1", "2", false))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("NORM_INVALID_AGE_RANGE");
        assertThatThrownBy(() -> norm(false, Gender.MALE, 12, 14, NormBand.AVERAGE, "2", "2", false))
                .isInstanceOf(DomainRuleViolation.class).extracting("code").isEqualTo("NORM_INVALID_VALUE_RANGE");
        assertThat(norm(false, Gender.MALE, 12, 12, NormBand.AVERAGE, null, null, false).minValue()).isEmpty();
    }

    @Test
    void agesOverlapWhenTheyShareAtLeastOneYear() {
        var a = norm(false, Gender.MALE, 10, 12, NormBand.AVERAGE, null, null, false);

        assertThat(a.overlapsAges(norm(false, Gender.MALE, 12, 14, NormBand.AVERAGE, null, null, false))).isTrue();
        assertThat(a.overlapsAges(norm(false, Gender.MALE, 13, 14, NormBand.AVERAGE, null, null, false))).isFalse();
    }
}
