package com.hoopsacademy.core.domain.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class TemporaryPasswordTest {

    private static final String FAKE = "Fake-Test-Value-42";

    @Test
    void revealsItsValueOnlyOnPurpose() {
        TemporaryPassword password = TemporaryPassword.of(FAKE);
        assertThat(password.reveal()).isEqualTo(FAKE);
        assertThat(password.toString()).doesNotContain(FAKE).isEqualTo("TemporaryPassword[***]");
        assertThat(String.valueOf(password)).doesNotContain(FAKE);
    }

    @Test
    void enforcesTheRealmLengthPolicy() {
        assertThat(TemporaryPassword.of("x".repeat(TemporaryPassword.MIN_LENGTH)).reveal()).hasSize(12);
        assertThat(TemporaryPassword.of("x".repeat(TemporaryPassword.MAX_LENGTH)).reveal()).hasSize(128);
        assertThatThrownBy(() -> TemporaryPassword.of("x".repeat(11))).isInstanceOf(IllegalArgumentException.class)
                .hasMessageNotContaining("xxxxxxxxxxx");
        assertThatThrownBy(() -> TemporaryPassword.of("x".repeat(129))).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> TemporaryPassword.of(null)).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void canNeverEqualAnEmailUsername() {
        // username = e-mail (ADR-0023); the realm refuses passwords equal to either (notUsername, notEmail)
        assertThatThrownBy(() -> TemporaryPassword.of("someone@example.com"))
                .isInstanceOf(IllegalArgumentException.class).hasMessageNotContaining("someone");
        assertThatThrownBy(() -> TemporaryPassword.of("@starts-with-an-at"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void equalityFollowsTheValueWithoutExposingIt() {
        assertThat(TemporaryPassword.of(FAKE)).isEqualTo(TemporaryPassword.of(FAKE))
                .hasSameHashCodeAs(TemporaryPassword.of(FAKE))
                .isNotEqualTo(TemporaryPassword.of(FAKE + "x"))
                .isNotEqualTo(FAKE);
    }
}
