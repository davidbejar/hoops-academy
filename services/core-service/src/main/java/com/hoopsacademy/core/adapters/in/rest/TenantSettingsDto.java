package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.core.domain.tenant.AgeRule;
import com.hoopsacademy.core.domain.tenant.TenantSettings;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

/** Contract {@code TenantSettings} (request and response). {@code maxPlayUpLevels} is required but nullable. */
public record TenantSettingsDto(
        @NotNull @Pattern(regexp = "BIRTH_YEAR|BIRTHDAY") String ageRule,
        @JsonInclude(JsonInclude.Include.ALWAYS) @Min(0) Integer maxPlayUpLevels,
        @Min(0) @Max(120) Integer attendanceLateThresholdMinutes) {

    static TenantSettingsDto of(TenantSettings settings) {
        return new TenantSettingsDto(settings.ageRule().name(), settings.maxPlayUpLevels(),
                settings.attendanceLateThresholdMinutes());
    }

    TenantSettings toDomain() {
        return new TenantSettings(AgeRule.valueOf(ageRule), maxPlayUpLevels,
                attendanceLateThresholdMinutes == null
                        ? TenantSettings.DEFAULT_LATE_THRESHOLD_MINUTES : attendanceLateThresholdMinutes);
    }
}
