package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;
import java.time.Instant;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** One stored audit row as read back ({@code core.audit_event}); names are resolved by the use cases. */
public record AuditRecord(UUID id, TenantId tenant, Instant at, AuditAction action, String actorSubject,
        Optional<UUID> actorPerson, AuditTargetType targetType, String targetId, Map<String, Object> metadata) {

    public AuditRecord {
        metadata = Collections.unmodifiableMap(new LinkedHashMap<>(metadata)); // JSON may hold nulls
    }

    /** The target id as a row id, when it is one (every target type keys its rows by uuid). */
    public Optional<UUID> targetUuid() {
        try {
            return Optional.of(UUID.fromString(targetId));
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }
}
