package com.hoopsacademy.core.domain.tenant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.hoopsacademy.common.problem.DomainRuleViolation;
import org.junit.jupiter.api.Test;

class TenantSettingsTest {

    @Test
    void defaultsUseBirthYearUnlimitedPlayUpAndTenMinutes() {
        assertThat(TenantSettings.defaults())
                .isEqualTo(new TenantSettings(AgeRule.BIRTH_YEAR, null, 10));
    }

    @Test
    void validatesRanges() {
        assertThatThrownBy(() -> new TenantSettings(AgeRule.BIRTHDAY, -1, 10)).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new TenantSettings(AgeRule.BIRTHDAY, 1, 121)).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new TenantSettings(AgeRule.BIRTHDAY, 1, -1)).isInstanceOf(DomainRuleViolation.class);
        assertThatThrownBy(() -> new TenantSettings(null, 1, 1)).isInstanceOf(DomainRuleViolation.class);
        assertThat(new TenantSettings(AgeRule.BIRTHDAY, 0, 120).maxPlayUpLevels()).isZero();
        assertThat(new TenantSettings(AgeRule.BIRTHDAY, null, 0).attendanceLateThresholdMinutes()).isZero();
    }

    @Test
    void reportsWhetherEligibilityRulesChanged() {
        TenantSettings base = TenantSettings.defaults();
        assertThat(base.eligibilityRulesDifferFrom(new TenantSettings(AgeRule.BIRTH_YEAR, null, 30))).isFalse();
        assertThat(base.eligibilityRulesDifferFrom(new TenantSettings(AgeRule.BIRTHDAY, null, 10))).isTrue();
        assertThat(base.eligibilityRulesDifferFrom(new TenantSettings(AgeRule.BIRTH_YEAR, 1, 10))).isTrue();
    }
}
