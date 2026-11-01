package com.hoopsacademy.core.domain.eligibility;

import static com.hoopsacademy.core.domain.eligibility.EligibilityReason.CATEGORY_TOO_LOW;
import static com.hoopsacademy.core.domain.eligibility.EligibilityReason.GENDER_POLICY;
import static com.hoopsacademy.core.domain.eligibility.EligibilityReason.MISSING_BIRTH_DATE;
import static com.hoopsacademy.core.domain.eligibility.EligibilityReason.MISSING_GENDER;
import static com.hoopsacademy.core.domain.eligibility.EligibilityReason.PLAYER_NOT_ACTIVE;
import static com.hoopsacademy.core.domain.eligibility.EligibilityReason.PLAY_UP_LIMIT_EXCEEDED;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.LADDER;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.SEASON;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.SENIOR;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.U12;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.U14;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.U16;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.U8;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.player;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.team;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.core.domain.membership.Gender;
import com.hoopsacademy.core.domain.membership.PlayerId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import com.hoopsacademy.core.domain.roster.GenderPolicy;
import com.hoopsacademy.core.domain.roster.SeasonId;
import com.hoopsacademy.core.domain.roster.Team;
import com.hoopsacademy.core.domain.roster.TeamId;
import com.hoopsacademy.core.domain.tenant.AgeRule;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

class EligibilityEvaluatorTest {

    private static final LocalDate AS_OF = LocalDate.of(2026, 11, 2);
    private static final TenantSettings BIRTH_YEAR = new TenantSettings(AgeRule.BIRTH_YEAR, null, 10);
    private static final TenantSettings BIRTHDAY = new TenantSettings(AgeRule.BIRTHDAY, null, 10);

    private final EligibilityEvaluator birthYear = new EligibilityEvaluator(LADDER, BIRTH_YEAR);

    @Test
    void naturalCategoryIsEligibleAndReportsAgeAndCategory() {
        Evaluation evaluation = birthYear.evaluate(player(LocalDate.of(2015, 5, 5), Gender.MALE),
                team(U12, GenderPolicy.MALE), SEASON, AS_OF);
        assertThat(evaluation.eligibility()).isEqualTo(new Eligibility.Eligible());
        assertThat(evaluation.eligibility().allowed()).isTrue();
        assertThat(evaluation.eligibility().playUpLevels()).isZero();
        assertThat(evaluation.eligibility().reasons()).isEmpty();
        assertThat(evaluation.age()).isEqualTo(11);
        assertThat(evaluation.naturalCategory()).isEqualTo(U12);
    }

    @Test
    void higherCategoryIsAPlayUpByLadderPositions() {
        Evaluation evaluation = birthYear.evaluate(player(LocalDate.of(2015, 5, 5), Gender.FEMALE),
                team(U16, GenderPolicy.MIXED), SEASON, AS_OF);
        assertThat(evaluation.eligibility()).isEqualTo(new Eligibility.PlayUp(2));
        assertThat(evaluation.eligibility().allowed()).isTrue();
        assertThat(evaluation.eligibility().playUpLevels()).isEqualTo(2);
    }

    @Test
    void lowerCategoryIsTooLow() {
        Evaluation evaluation = birthYear.evaluate(player(LocalDate.of(2012, 5, 5), Gender.MALE),
                team(U12, GenderPolicy.MALE), SEASON, AS_OF);
        assertThat(evaluation.eligibility()).isEqualTo(new Eligibility.Ineligible(List.of(CATEGORY_TOO_LOW)));
        assertThat(evaluation.eligibility().allowed()).isFalse();
        assertThat(evaluation.eligibility().playUpLevels()).isZero();
    }

    @Test
    void dec31AndJan1BirthsUnderBothRules() {
        Team u12 = team(U12, GenderPolicy.MIXED);
        var dec31 = player(LocalDate.of(2014, 12, 31), Gender.MALE);
        var jan1 = player(LocalDate.of(2015, 1, 1), Gender.MALE);
        assertThat(birthYear.evaluate(dec31, u12, SEASON, AS_OF).eligibility().reasons()).containsExactly(CATEGORY_TOO_LOW);
        assertThat(birthYear.evaluate(jan1, u12, SEASON, AS_OF).eligibility().allowed()).isTrue();

        EligibilityEvaluator birthday = new EligibilityEvaluator(LADDER, BIRTHDAY);
        assertThat(birthday.evaluate(dec31, u12, SEASON, LocalDate.of(2026, 12, 30)).eligibility().allowed()).isTrue();
        assertThat(birthday.evaluate(dec31, u12, SEASON, LocalDate.of(2026, 12, 31)).eligibility().reasons())
                .containsExactly(CATEGORY_TOO_LOW);
        assertThat(birthday.evaluate(jan1, u12, SEASON, LocalDate.of(2026, 12, 31)).eligibility().allowed()).isTrue();
        assertThat(birthday.evaluate(jan1, u12, SEASON, LocalDate.of(2027, 1, 1)).eligibility().reasons())
                .containsExactly(CATEGORY_TOO_LOW);
    }

    @Test
    void feb29BirthdayUnderBirthdayRuleFlipsOnMarch1OfANonLeapYear() {
        EligibilityEvaluator birthday = new EligibilityEvaluator(LADDER, BIRTHDAY);
        var leapling = player(LocalDate.of(2016, 2, 29), Gender.FEMALE);
        Team u12 = team(U12, GenderPolicy.FEMALE);
        assertThat(birthday.evaluate(leapling, u12, SEASON, LocalDate.of(2027, 2, 28)).age()).isEqualTo(10);
        assertThat(birthday.evaluate(leapling, u12, SEASON, LocalDate.of(2027, 3, 1)).age()).isEqualTo(11);
        assertThat(birthday.evaluate(leapling, team(Fixtures.U10, GenderPolicy.FEMALE), SEASON, LocalDate.of(2027, 3, 1))
                .eligibility().reasons()).containsExactly(CATEGORY_TOO_LOW);
    }

    @Test
    void mixedTeamsAcceptBothGendersSingleGenderTeamsOnlyTheirOwn() {
        LocalDate born = LocalDate.of(2015, 3, 3);
        for (Gender gender : Gender.values()) {
            assertThat(birthYear.evaluate(player(born, gender), team(U12, GenderPolicy.MIXED), SEASON, AS_OF)
                    .eligibility().allowed()).isTrue();
        }
        assertThat(birthYear.evaluate(player(born, Gender.FEMALE), team(U12, GenderPolicy.MALE), SEASON, AS_OF)
                .eligibility().reasons()).containsExactly(GENDER_POLICY);
        assertThat(birthYear.evaluate(player(born, Gender.MALE), team(U12, GenderPolicy.FEMALE), SEASON, AS_OF)
                .eligibility().reasons()).containsExactly(GENDER_POLICY);
    }

    @Test
    void playUpLimitIsEnforcedWhenSet() {
        EligibilityEvaluator limited = new EligibilityEvaluator(LADDER, new TenantSettings(AgeRule.BIRTH_YEAR, 1, 10));
        var u12Player = player(LocalDate.of(2015, 5, 5), Gender.MALE);
        assertThat(limited.evaluate(u12Player, team(U14, GenderPolicy.MALE), SEASON, AS_OF).eligibility())
                .isEqualTo(new Eligibility.PlayUp(1));
        assertThat(limited.evaluate(u12Player, team(U16, GenderPolicy.MALE), SEASON, AS_OF).eligibility().reasons())
                .containsExactly(PLAY_UP_LIMIT_EXCEEDED);
        EligibilityEvaluator none = new EligibilityEvaluator(LADDER, new TenantSettings(AgeRule.BIRTH_YEAR, 0, 10));
        assertThat(none.evaluate(u12Player, team(U14, GenderPolicy.MALE), SEASON, AS_OF).eligibility().reasons())
                .containsExactly(PLAY_UP_LIMIT_EXCEEDED);
        assertThat(birthYear.evaluate(u12Player, team(SENIOR, GenderPolicy.MALE), SEASON, AS_OF).eligibility())
                .isEqualTo(new Eligibility.PlayUp(4));
    }

    @Test
    void missingBirthDateAndGenderAreReportedTogetherAndSkipAgeChecks() {
        var unknown = new EligibilityCandidate(PlayerId.random(), PlayerStatus.ACTIVE, null, null);
        Evaluation evaluation = birthYear.evaluate(unknown, team(U8, GenderPolicy.MALE), SEASON, AS_OF);
        assertThat(evaluation.eligibility().reasons()).containsExactly(MISSING_BIRTH_DATE, MISSING_GENDER);
        assertThat(evaluation.age()).isNull();
        assertThat(evaluation.naturalCategory()).isNull();
    }

    @ParameterizedTest
    @EnumSource(value = PlayerStatus.class, names = {"PENDING_APPROVAL", "WITHDRAWN"})
    void onlyActiveOrOrphanPlayersAreEligible(PlayerStatus status) {
        var inactive = new EligibilityCandidate(PlayerId.random(), status, LocalDate.of(2012, 1, 1), Gender.FEMALE);
        assertThat(birthYear.evaluate(inactive, team(U12, GenderPolicy.MALE), SEASON, AS_OF).eligibility().reasons())
                .containsExactly(PLAYER_NOT_ACTIVE, GENDER_POLICY, CATEGORY_TOO_LOW);
        var orphan = new EligibilityCandidate(PlayerId.random(), PlayerStatus.ORPHAN, LocalDate.of(2015, 1, 1), Gender.MALE);
        assertThat(birthYear.evaluate(orphan, team(U12, GenderPolicy.MALE), SEASON, AS_OF).eligibility().allowed()).isTrue();
    }

    @Test
    void playersOlderThanEveryCategoryAreTooLowForAllTeams() {
        EligibilityEvaluator youthOnly = new EligibilityEvaluator(CategoryLadder.of(List.of(U8, U12)), BIRTH_YEAR);
        Evaluation evaluation = youthOnly.evaluate(player(LocalDate.of(2000, 1, 1), Gender.MALE),
                team(U12, GenderPolicy.MALE), SEASON, AS_OF);
        assertThat(evaluation.eligibility().reasons()).containsExactly(CATEGORY_TOO_LOW);
        assertThat(evaluation.naturalCategory()).isNull();
        assertThat(evaluation.age()).isEqualTo(26);
    }

    @Test
    void teamOfAnotherSeasonIsAProgrammingError() {
        Team foreign = new Team(TeamId.random(), SeasonId.random(), "X", null, U12.id(), GenderPolicy.MIXED);
        assertThatThrownBy(() -> birthYear.evaluate(player(LocalDate.of(2015, 1, 1), Gender.MALE), foreign, SEASON, AS_OF))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void ineligibleNeedsAtLeastOneReasonAndPlayUpAtLeastOneLevel() {
        assertThatThrownBy(() -> new Eligibility.Ineligible(List.of())).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> new Eligibility.PlayUp(0)).isInstanceOf(IllegalArgumentException.class);
        assertThat(new Eligibility.Ineligible(List.of(GENDER_POLICY, CATEGORY_TOO_LOW)).primaryReason())
                .isEqualTo(GENDER_POLICY);
    }
}
