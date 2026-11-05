package com.hoopsacademy.core.application.audit;

import java.util.Optional;
import java.util.UUID;

/** Who acted (contract {@code AuditActorKind}), derived from how the row was written (ADR-0017, ADR-0029). */
public enum AuditActorKind {
    /** A member of the academy: the writer stored the caller's person. */
    PERSON,
    /** A login without a person in the academy: the super admin acting from the platform. */
    PLATFORM,
    /** A background job ({@code system}). */
    SYSTEM;

    static final String SYSTEM_SUBJECT = "system";

    static AuditActorKind of(String subject, Optional<UUID> person) {
        if (person.isPresent()) {
            return PERSON;
        }
        return SYSTEM_SUBJECT.equals(subject) ? SYSTEM : PLATFORM;
    }
}
