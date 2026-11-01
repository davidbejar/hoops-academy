package com.hoopsacademy.core.domain.eligibility;

import java.util.Objects;
import java.util.UUID;

/** Identity of a eligibility case. */
public record EligibilityCaseId(UUID value) {

    public EligibilityCaseId {
        Objects.requireNonNull(value, "eligibility case id");
    }

    public static EligibilityCaseId random() {
        return new EligibilityCaseId(UUID.randomUUID());
    }
}
