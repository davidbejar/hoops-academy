package com.hoopsacademy.core.application.port;

import java.util.Map;
import java.util.Objects;

/**
 * One administrative action for the audit trail ({@code core.audit_event}, ADR-0017). The actor is filled in by the
 * adapter from the authenticated caller. {@code metadata} must hold no personal data: ids, role and enum names, the
 * names of changed fields — never names, e-mails, phone numbers or free-text notes.
 */
public record AuditEvent(String action, String targetType, String targetId, Map<String, Object> metadata) {

    public AuditEvent {
        Objects.requireNonNull(action, "action");
        Objects.requireNonNull(targetType, "targetType");
        Objects.requireNonNull(targetId, "targetId");
        metadata = Map.copyOf(metadata);
    }

    public static AuditEvent of(String action, String targetType, Object targetId) {
        return new AuditEvent(action, targetType, String.valueOf(targetId), Map.of());
    }

    public static AuditEvent of(String action, String targetType, Object targetId, Map<String, Object> metadata) {
        return new AuditEvent(action, targetType, String.valueOf(targetId), metadata);
    }
}
