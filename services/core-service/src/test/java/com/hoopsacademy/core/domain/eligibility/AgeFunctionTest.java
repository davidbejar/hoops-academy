package com.hoopsacademy.core.domain.eligibility;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.core.domain.tenant.AgeRule;
import java.time.LocalDate;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

class AgeFunctionTest {

    private static final int REFERENCE_YEAR = 2026;

    @Test
    void strategiesFollowTheTenantAgeRule() {
        assertThat(AgeFunction.of(AgeRule.BIRTH_YEAR)).isEqualTo(AgeFunction.BIRTH_YEAR);
        assertThat(AgeFunction.of(AgeRule.BIRTHDAY)).isEqualTo(AgeFunction.BIRTHDAY);
    }

    @Nested
    class BirthYear {

        @Test
        void dec31AndJan1BirthsAreOneYearApartWhateverTheEvaluationDate() {
            LocalDate dec31 = LocalDate.of(2014, 12, 31);
            LocalDate jan1 = LocalDate.of(2015, 1, 1);
            for (LocalDate asOf : new LocalDate[] {LocalDate.of(2026, 1, 1), LocalDate.of(2026, 12, 31)}) {
                assertThat(AgeFunction.BIRTH_YEAR.ageOf(dec31, REFERENCE_YEAR, asOf)).isEqualTo(12);
                assertThat(AgeFunction.BIRTH_YEAR.ageOf(jan1, REFERENCE_YEAR, asOf)).isEqualTo(11);
            }
        }

        @Test
        void usesTheSeasonReferenceYearNotTheEvaluationYear() {
            assertThat(AgeFunction.BIRTH_YEAR.ageOf(LocalDate.of(2015, 6, 1), 2027, LocalDate.of(2026, 11, 2)))
                    .isEqualTo(12);
        }
    }

    @Nested
    class Birthday {

        @Test
        void dec31BirthdayCountsOnTheDayItself() {
            LocalDate dec31 = LocalDate.of(2014, 12, 31);
            assertThat(AgeFunction.BIRTHDAY.ageOf(dec31, REFERENCE_YEAR, LocalDate.of(2026, 12, 30))).isEqualTo(11);
            assertThat(AgeFunction.BIRTHDAY.ageOf(dec31, REFERENCE_YEAR, LocalDate.of(2026, 12, 31))).isEqualTo(12);
        }

        @Test
        void jan1BirthdayTurnsOverAtNewYear() {
            LocalDate jan1 = LocalDate.of(2015, 1, 1);
            assertThat(AgeFunction.BIRTHDAY.ageOf(jan1, REFERENCE_YEAR, LocalDate.of(2026, 12, 31))).isEqualTo(11);
            assertThat(AgeFunction.BIRTHDAY.ageOf(jan1, REFERENCE_YEAR, LocalDate.of(2027, 1, 1))).isEqualTo(12);
        }

        @Test
        void feb29BirthdayIsCelebratedOnMarch1InNonLeapYears() {
            LocalDate leapDay = LocalDate.of(2016, 2, 29);
            assertThat(AgeFunction.BIRTHDAY.ageOf(leapDay, REFERENCE_YEAR, LocalDate.of(2027, 2, 28))).isEqualTo(10);
            assertThat(AgeFunction.BIRTHDAY.ageOf(leapDay, REFERENCE_YEAR, LocalDate.of(2027, 3, 1))).isEqualTo(11);
        }

        @Test
        void feb29BirthdayIsExactInLeapYears() {
            LocalDate leapDay = LocalDate.of(2016, 2, 29);
            assertThat(AgeFunction.BIRTHDAY.ageOf(leapDay, REFERENCE_YEAR, LocalDate.of(2028, 2, 28))).isEqualTo(11);
            assertThat(AgeFunction.BIRTHDAY.ageOf(leapDay, REFERENCE_YEAR, LocalDate.of(2028, 2, 29))).isEqualTo(12);
        }

        @Test
        void feb29UnderBirthYearIsJustTheYear() {
            assertThat(AgeFunction.BIRTH_YEAR.ageOf(LocalDate.of(2016, 2, 29), 2027, LocalDate.of(2027, 2, 28)))
                    .isEqualTo(11);
        }
    }
}
