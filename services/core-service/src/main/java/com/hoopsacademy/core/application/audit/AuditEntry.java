package com.hoopsacademy.core.application.audit;

import com.hoopsacademy.core.application.port.AuditRecord;
import java.util.Optional;
import java.util.UUID;

/** One audit row with the names resolved at read time (absent when not resolvable or not shown). */
public record AuditEntry(AuditRecord record, Actor actor, Optional<String> targetName) {

    /** Who acted (contract {@code AuditActor}), as the caller may see it. */
    public record Actor(AuditActorKind kind, Optional<String> subject, Optional<UUID> person, Optional<String> name) {

        static Actor of(AuditRecord record, Optional<String> name) {
            return new Actor(AuditActorKind.of(record.actorSubject(), record.actorPerson()),
                    Optional.of(record.actorSubject()), record.actorPerson(), name);
        }

        /**
         * Decision 16 of 2026-11-06 (WP38): an academy sees that the platform acted, not which login did; members
         * and background jobs are shown as stored.
         */
        Actor maskedForAcademy() {
            return kind == AuditActorKind.PLATFORM
                    ? new Actor(kind, Optional.empty(), Optional.empty(), Optional.empty())
                    : this;
        }
    }
}
