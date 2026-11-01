package com.hoopsacademy.core.domain.eligibility;

import static com.hoopsacademy.core.domain.eligibility.Fixtures.SENIOR;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.U10;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.U12;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.U14;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.U8;
import static com.hoopsacademy.core.domain.eligibility.Fixtures.category;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import com.hoopsacademy.core.domain.roster.AgeCategoryId;
import java.util.List;
import org.junit.jupiter.api.Test;

class CategoryLadderTest {

    @Test
    void ordersByRankWhateverTheInputOrder() {
        CategoryLadder ladder = CategoryLadder.of(List.of(SENIOR, U12, U8, U10));
        assertThat(ladder.categories()).containsExactly(U8, U10, U12, SENIOR);
    }

    @Test
    void naturalCategoryIsTheLowestRankWhoseMaxAgeAdmitsTheAge() {
        CategoryLadder ladder = Fixtures.LADDER;
        assertThat(ladder.naturalFor(5)).contains(U8);
        assertThat(ladder.naturalFor(7)).contains(U8);
        assertThat(ladder.naturalFor(8)).contains(U10);
        assertThat(ladder.naturalFor(11)).contains(U12);
        assertThat(ladder.naturalFor(12)).contains(U14);
        assertThat(ladder.naturalFor(18)).contains(SENIOR);
        assertThat(ladder.naturalFor(45)).contains(SENIOR);
    }

    @Test
    void withoutASeniorCategoryOlderPlayersHaveNoNaturalCategory() {
        CategoryLadder ladder = CategoryLadder.of(List.of(U8, U10));
        assertThat(ladder.naturalFor(10)).isEmpty();
    }

    @Test
    void levelsCountPositionsOnTheLadderNotRankValues() {
        CategoryLadder ladder = CategoryLadder.of(List.of(category("A", 7, 10), category("B", 9, 50),
                category("C", null, 99)));
        AgeCategory a = ladder.categories().get(0);
        AgeCategory c = ladder.categories().get(2);
        assertThat(ladder.levelsBetween(a, c.id())).isEqualTo(2);
        assertThat(ladder.levelsBetween(c, a.id())).isEqualTo(-2);
        assertThat(ladder.find(c.id())).contains(c);
    }

    @Test
    void unknownCategoryIsRejected() {
        assertThat(Fixtures.LADDER.find(AgeCategoryId.random())).isEmpty();
        assertThatThrownBy(() -> Fixtures.LADDER.levelsBetween(U8, AgeCategoryId.random()))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void maxAgeMustGrowWithRank() {
        assertThatThrownBy(() -> CategoryLadder.of(List.of(category("A", 9, 0), category("B", 9, 1))))
                .isInstanceOf(DomainRuleViolation.class)
                .extracting(e -> ((DomainRuleViolation) e).code()).isEqualTo(CategoryLadder.ORDER_VIOLATION);
        assertThatThrownBy(() -> CategoryLadder.of(List.of(category("A", 11, 0), category("B", 9, 1))))
                .isInstanceOf(DomainRuleViolation.class);
    }

    @Test
    void anUnlimitedCategoryMustBeTheTopRank() {
        assertThatThrownBy(() -> CategoryLadder.of(List.of(category("S", null, 0), category("B", 9, 1))))
                .isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> CategoryLadder.of(List.of(category("S", null, 0), category("T", null, 1))))
                .isInstanceOf(DomainRuleViolation.class);
    }

    @Test
    void ranksMustBeDistinct() {
        assertThatThrownBy(() -> CategoryLadder.of(List.of(category("A", 7, 1), category("B", 9, 1))))
                .isInstanceOf(DomainRuleViolation.class);
    }

    @Test
    void anEmptyLadderHasNoNaturalCategory() {
        assertThat(CategoryLadder.of(List.of()).naturalFor(10)).isEmpty();
        assertThat(CategoryLadder.of(List.of(U14)).categories()).containsExactly(U14);
    }
}
