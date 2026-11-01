package com.hoopsacademy.core.domain.eligibility;

import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.tenant.AgeRule;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import java.time.LocalDate;
import net.jqwik.api.Arbitraries;
import net.jqwik.api.Arbitrary;
import net.jqwik.api.ForAll;
import net.jqwik.api.Property;
import net.jqwik.api.Provide;
import net.jqwik.api.constraints.IntRange;
import net.jqwik.time.api.Dates;

/** Invariants of plan §2: team rank ≥ natural rank; gender policy; play-up ≤ limit (null = unlimited). */
class EligibilityPropertiesTest {

    @Property
    void neverAssignsToACategoryBelowTheNaturalOne(@ForAll("birthDates") LocalDate birthDate,
            @ForAll("asOfDates") LocalDate asOf, @ForAll AgeRule rule, @ForAll Gender gender,
            @ForAll("categories") AgeCategory category) {
        EligibilityEvaluator evaluator = new EligibilityEvaluator(Fixtures.LADDER, new TenantSettings(rule, null, 10));
        Evaluation evaluation = evaluator.evaluate(Fixtures.player(birthDate, gender),
                Fixtures.team(category, GenderPolicy.MIXED), Fixtures.SEASON, asOf);
        if (evaluation.eligibility().allowed()) {
            assertThat(evaluation.naturalCategory()).isNotNull();
            assertThat(category.rank()).isGreaterThanOrEqualTo(evaluation.naturalCategory().rank());
            assertThat(category.admitsAge(evaluation.age())).isTrue();
        } else {
            assertThat(evaluation.eligibility().reasons()).containsExactly(EligibilityReason.CATEGORY_TOO_LOW);
        }
    }

    @Property
    void mixedAdmitsBothGendersSingleGenderPoliciesRejectTheOther(@ForAll Gender gender,
            @ForAll GenderPolicy policy, @ForAll("youthBirthDates") LocalDate birthDate) {
        EligibilityEvaluator evaluator = new EligibilityEvaluator(Fixtures.LADDER, TenantSettings.defaults());
        Evaluation evaluation = evaluator.evaluate(Fixtures.player(birthDate, gender),
                Fixtures.team(Fixtures.SENIOR, policy), Fixtures.SEASON, LocalDate.of(2026, 11, 2));
        boolean admitted = policy == GenderPolicy.MIXED || policy.name().equals(gender.name());
        assertThat(evaluation.eligibility().reasons().contains(EligibilityReason.GENDER_POLICY)).isEqualTo(!admitted);
        assertThat(policy.admits(gender)).isEqualTo(admitted);
    }

    @Property
    void playUpLimitIsRespectedWhenSetAndUnlimitedWhenNull(@ForAll("youthBirthDates") LocalDate birthDate,
            @ForAll("categories") AgeCategory category, @ForAll @IntRange(min = 0, max = 7) int limit) {
        Team team = Fixtures.team(category, GenderPolicy.MIXED);
        LocalDate asOf = LocalDate.of(2026, 11, 2);
        Evaluation unlimited = new EligibilityEvaluator(Fixtures.LADDER, TenantSettings.defaults())
                .evaluate(Fixtures.player(birthDate, Gender.MALE), team, Fixtures.SEASON, asOf);
        Evaluation limited = new EligibilityEvaluator(Fixtures.LADDER, new TenantSettings(AgeRule.BIRTH_YEAR, limit, 10))
                .evaluate(Fixtures.player(birthDate, Gender.MALE), team, Fixtures.SEASON, asOf);

        assertThat(unlimited.eligibility().reasons()).doesNotContain(EligibilityReason.PLAY_UP_LIMIT_EXCEEDED);
        if (limited.eligibility().allowed()) {
            assertThat(limited.eligibility().playUpLevels()).isLessThanOrEqualTo(limit);
        }
        if (unlimited.eligibility().allowed()) {
            boolean withinLimit = unlimited.eligibility().playUpLevels() <= limit;
            assertThat(limited.eligibility().allowed()).isEqualTo(withinLimit);
            if (!withinLimit) {
                assertThat(limited.eligibility().reasons()).containsExactly(EligibilityReason.PLAY_UP_LIMIT_EXCEEDED);
            }
        }
    }

    @Property
    void statusDerivationIsIdempotentAndConsistentWithAssignments(@ForAll PlayerStatus status,
            @ForAll boolean hasValidOpenAssignment) {
        PlayerStatus once = PlayerStatusDerivation.derive(status, hasValidOpenAssignment);
        assertThat(PlayerStatusDerivation.derive(once, hasValidOpenAssignment)).isEqualTo(once);
        switch (status) {
            case ACTIVE, ORPHAN -> assertThat(once)
                    .isEqualTo(hasValidOpenAssignment ? PlayerStatus.ACTIVE : PlayerStatus.ORPHAN);
            case PENDING_APPROVAL, WITHDRAWN -> assertThat(once).isEqualTo(status);
        }
    }

    @Provide
    Arbitrary<LocalDate> birthDates() {
        return Dates.dates().between(LocalDate.of(1970, 1, 1), LocalDate.of(2024, 12, 31));
    }

    @Provide
    Arbitrary<LocalDate> youthBirthDates() {
        return Dates.dates().between(LocalDate.of(2009, 1, 1), LocalDate.of(2020, 12, 31));
    }

    @Provide
    Arbitrary<LocalDate> asOfDates() {
        return Dates.dates().between(LocalDate.of(2026, 9, 1), LocalDate.of(2027, 6, 30));
    }

    @Provide
    Arbitrary<AgeCategory> categories() {
        return Arbitraries.of(Fixtures.DEFAULTS);
    }
}
