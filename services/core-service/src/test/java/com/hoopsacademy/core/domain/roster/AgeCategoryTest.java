package com.hoopsacademy.core.domain.roster;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import com.hoopsacademy.core.domain.shared.Patch;
import java.util.List;
import org.junit.jupiter.api.Test;

class AgeCategoryTest {

    @Test
    void validatesCodeNameMaxAgeAndRank() {
        AgeCategory u12 = new AgeCategory(AgeCategoryId.random(), "U12", " Under 12 ", 11, 2);
        assertThat(u12.name()).isEqualTo("Under 12");
        assertThat(u12.admitsAge(11)).isTrue();
        assertThat(u12.admitsAge(12)).isFalse();
        assertThat(u12.isUnlimited()).isFalse();
        AgeCategory senior = new AgeCategory(AgeCategoryId.random(), "SENIOR", "Senior", null, 6);
        assertThat(senior.admitsAge(80)).isTrue();
        assertThat(senior.isUnlimited()).isTrue();
        assertThat(new AgeCategory(AgeCategoryId.random(), "U4", "Tiny", 3, 0).maxAge()).isEqualTo(3);
        assertThat(new AgeCategory(AgeCategoryId.random(), "U99", "Veterans", 99, 0).maxAge()).isEqualTo(99);
        for (Runnable invalid : List.<Runnable>of(
                () -> new AgeCategory(AgeCategoryId.random(), "u12", "x", 11, 0),
                () -> new AgeCategory(AgeCategoryId.random(), "U12345678901234567", "x", 11, 0),
                () -> new AgeCategory(AgeCategoryId.random(), null, "x", 11, 0),
                () -> new AgeCategory(AgeCategoryId.random(), "U1", "", 11, 0),
                () -> new AgeCategory(AgeCategoryId.random(), "U1", "x", 2, 0),
                () -> new AgeCategory(AgeCategoryId.random(), "U1", "x", 100, 0),
                () -> new AgeCategory(AgeCategoryId.random(), "U1", "x", 11, -1))) {
            assertThatThrownBy(invalid::run).isInstanceOf(DomainRuleViolation.class);
        }
    }

    @Test
    void changesMayClearTheMaxAge() {
        AgeCategory u18 = new AgeCategory(AgeCategoryId.random(), "U18", "U18", 17, 5);
        AgeCategory open = u18.apply(new AgeCategoryChanges(Patch.of("OPEN"), Patch.absent(), Patch.of(null), Patch.of(9)));
        assertThat(open).isEqualTo(new AgeCategory(u18.id(), "OPEN", "U18", null, 9));
        assertThat(new AgeCategoryChanges(Patch.absent(), Patch.absent(), Patch.of(3), Patch.absent()).changesLadder()).isTrue();
        assertThat(new AgeCategoryChanges(Patch.absent(), Patch.absent(), Patch.absent(), Patch.of(3)).changesLadder()).isTrue();
        assertThat(new AgeCategoryChanges(Patch.of("X"), Patch.of("y"), Patch.absent(), Patch.absent()).changesLadder()).isFalse();
    }

    @Test
    void defaultsAreTheFederationLadder() {
        assertThat(DefaultAgeCategories.create()).extracting(AgeCategory::code, AgeCategory::maxAge, AgeCategory::rank)
                .containsExactly(
                        org.assertj.core.groups.Tuple.tuple("U8", 7, 0),
                        org.assertj.core.groups.Tuple.tuple("U10", 9, 1),
                        org.assertj.core.groups.Tuple.tuple("U12", 11, 2),
                        org.assertj.core.groups.Tuple.tuple("U14", 13, 3),
                        org.assertj.core.groups.Tuple.tuple("U16", 15, 4),
                        org.assertj.core.groups.Tuple.tuple("U18", 17, 5),
                        org.assertj.core.groups.Tuple.tuple("SENIOR", null, 6));
    }
}
