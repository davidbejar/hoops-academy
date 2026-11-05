package com.hoopsacademy.core.application.port;

import java.util.Map;
import java.util.Objects;

/**
 * One administrative action for the audit trail ({@code core.audit_event}, ADR-0017). The target type follows from
 * the action; the actor is filled in by the adapter from the authenticated caller. {@code metadata} must hold no
 * personal data: ids, role and enum names, the names of changed fields — never names, e-mails, phone numbers or
 * free-text notes. Names are resolved when the trail is read (WP34).
 */
public record AuditEvent(AuditAction action, String targetId, Map<String, Object> metadata) {

    public AuditEvent {
        Objects.requireNonNull(action, "action");
        Objects.requireNonNull(targetId, "targetId");
        metadata = Map.copyOf(metadata);
    }

    public static AuditEvent of(AuditAction action, Object targetId) {
        return new AuditEvent(action, String.valueOf(targetId), Map.of());
    }

    public static AuditEvent of(AuditAction action, Object targetId, Map<String, Object> metadata) {
        return new AuditEvent(action, String.valueOf(targetId), metadata);
    }

    public AuditTargetType targetType() {
        return action.targetType();
    }
}
