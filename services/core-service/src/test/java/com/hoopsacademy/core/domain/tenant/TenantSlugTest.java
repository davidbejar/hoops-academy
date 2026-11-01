package com.hoopsacademy.core.domain.tenant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class TenantSlugTest {

    @ParameterizedTest
    @ValueSource(strings = {"abc", "acme-hoops", "a1b", "club-2026-u18"})
    void acceptsLowercaseSlugs(String raw) {
        assertThat(TenantSlug.of(raw).value()).isEqualTo(raw);
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "ab", "Acme", "-abc", "abc-", "a b c", "abc_d", "ünï"})
    void rejectsInvalidSlugs(String raw) {
        assertThatThrownBy(() -> TenantSlug.of(raw)).isInstanceOf(DomainRuleViolation.class)
                .extracting(e -> ((DomainRuleViolation) e).code()).isEqualTo("INVALID_SLUG");
    }

    @org.junit.jupiter.api.Test
    void rejectsNullAndTooLong() {
        assertThatThrownBy(() -> TenantSlug.of(null)).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> TenantSlug.of("a".repeat(51))).isInstanceOf(DomainRuleViolation.class);
        assertThat(TenantSlug.of("a".repeat(50)).toString()).hasSize(50);
    }
}
