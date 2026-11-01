package com.hoopsacademy.core.domain.tenant;

import com.hoopsacademy.core.domain.shared.Require;
import java.util.Objects;

/**
 * Roster rules and defaults of a tenant.
 *
 * @param maxPlayUpLevels categories a player may play up; {@code null} = unlimited
 */
public record TenantSettings(AgeRule ageRule, Integer maxPlayUpLevels, int attendanceLateThresholdMinutes) {

    public static final int DEFAULT_LATE_THRESHOLD_MINUTES = 10;
    private static final int MAX_LATE_THRESHOLD_MINUTES = 120;

    public TenantSettings {
        Require.present(ageRule, "ageRule");
        if (maxPlayUpLevels != null && maxPlayUpLevels < 0) {
            throw Require.violation("maxPlayUpLevels", "maxPlayUpLevels must be >= 0 or null");
        }
        if (attendanceLateThresholdMinutes < 0 || attendanceLateThresholdMinutes > MAX_LATE_THRESHOLD_MINUTES) {
            throw Require.violation("attendanceLateThresholdMinutes", "attendanceLateThresholdMinutes must be 0..120");
        }
    }

    public static TenantSettings defaults() {
        return new TenantSettings(AgeRule.BIRTH_YEAR, null, DEFAULT_LATE_THRESHOLD_MINUTES);
    }

    /** Changing these requires re-evaluating eligibility (WP4). */
    public boolean eligibilityRulesDifferFrom(TenantSettings other) {
        return ageRule != other.ageRule || !Objects.equals(maxPlayUpLevels, other.maxPlayUpLevels);
    }
}
