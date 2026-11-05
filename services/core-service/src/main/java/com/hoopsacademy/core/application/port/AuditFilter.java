package com.hoopsacademy.core.application.port;

import java.time.Instant;
import java.util.Optional;
import java.util.Set;

/** Which audit rows to read: {@code from} inclusive, {@code to} exclusive, any of {@code actions} (empty = all). */
public record AuditFilter(Optional<Instant> from, Optional<Instant> to, Set<AuditAction> actions) {

    public AuditFilter {
        actions = Set.copyOf(actions);
        if (from.isPresent() && to.isPresent() && !from.get().isBefore(to.get())) {
            throw new IllegalArgumentException("from must be before to");
        }
    }

    public static AuditFilter all() {
        return new AuditFilter(Optional.empty(), Optional.empty(), Set.of());
    }
}
