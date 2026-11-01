package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.core.domain.roster.AgeCategory;
import java.util.UUID;

/** Contract {@code AgeCategory}; {@code maxAge} is always present ({@code null} = senior). */
public record AgeCategoryDto(UUID id, String code, String name,
        @JsonInclude(JsonInclude.Include.ALWAYS) Integer maxAge, int rank) {

    static AgeCategoryDto of(AgeCategory category) {
        return category == null ? null
                : new AgeCategoryDto(category.id().value(), category.code(), category.name(), category.maxAge(),
                        category.rank());
    }
}
