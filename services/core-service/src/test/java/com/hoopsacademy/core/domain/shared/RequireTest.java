package com.hoopsacademy.core.domain.shared;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import org.junit.jupiter.api.Test;

class RequireTest {

    @Test
    void textIsStrippedAndMayUseTheWholeMaximumLength() {
        assertThat(Require.text(" abc ", "name", 3)).isEqualTo("abc");
        assertThatThrownBy(() -> Require.text("abcd", "name", 3))
                .isInstanceOfSatisfying(DomainRuleViolation.class, e -> assertThat(e.code()).isEqualTo("INVALID_NAME"));
    }

    @Test
    void presentReturnsTheValueOrNamesTheMissingField() {
        assertThat(Require.present("x", "startsOn")).isEqualTo("x");
        assertThatThrownBy(() -> Require.present(null, "startsOn"))
                .isInstanceOfSatisfying(DomainRuleViolation.class,
                        e -> assertThat(e.code()).isEqualTo("INVALID_STARTS_ON"));
    }
}
