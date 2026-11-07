package com.hoopsacademy.core.domain.signup;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class AcademyNameTest {

    @Test
    void trimsAndCollapsesInnerWhitespaceButKeepsTheCase() {
        assertThat(AcademyName.of("  Club \t Baloncesto   Norte ").value()).isEqualTo("Club Baloncesto Norte");
    }

    @Test
    void equalNamesCompareByTheirNormalisedValue() {
        assertThat(AcademyName.of(" Norte  Club")).isEqualTo(AcademyName.of("Norte Club"));
        assertThat(AcademyName.of("Norte Club").toString()).isEqualTo("Norte Club");
    }

    @Test
    void acceptsExactly120Characters() {
        assertThat(AcademyName.of("a".repeat(120)).value()).hasSize(120);
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "   ", "\t"})
    void blankIsRejected(String raw) {
        assertThatThrownBy(() -> AcademyName.of(raw)).isInstanceOf(DomainRuleViolation.class)
                .hasFieldOrPropertyWithValue("code", "INVALID_ACADEMY_NAME");
    }

    @Test
    void nullIsRejected() {
        assertThatThrownBy(() -> AcademyName.of(null)).isInstanceOf(DomainRuleViolation.class);
    }

    @Test
    void moreThan120CharactersAreRejected() {
        assertThatThrownBy(() -> AcademyName.of("a".repeat(121))).isInstanceOf(DomainRuleViolation.class)
                .hasFieldOrPropertyWithValue("code", "INVALID_ACADEMY_NAME");
    }

    @ParameterizedTest
    @ValueSource(strings = {"Norte\u0000Club", "Norte\u0007", "Norte\u007F", "Nor‮te"})
    void controlAndFormatCharactersAreRejected(String raw) {
        assertThatThrownBy(() -> AcademyName.of(raw)).isInstanceOf(DomainRuleViolation.class)
                .hasFieldOrPropertyWithValue("code", "INVALID_ACADEMY_NAME");
    }
}
