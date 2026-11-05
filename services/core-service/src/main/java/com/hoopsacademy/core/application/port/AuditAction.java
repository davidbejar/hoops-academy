package com.hoopsacademy.core.application.port;

import static com.hoopsacademy.core.application.port.AuditTargetType.APPROVAL_REQUEST;
import static com.hoopsacademy.core.application.port.AuditTargetType.GUARDIAN_LINK;
import static com.hoopsacademy.core.application.port.AuditTargetType.PERSON;
import static com.hoopsacademy.core.application.port.AuditTargetType.PLAYER;
import static com.hoopsacademy.core.application.port.AuditTargetType.TENANT;

import java.util.Arrays;
import java.util.Optional;

/**
 * Every action of the audit trail (ADR-0017) and the type of row it is about — the one source of the action names:
 * {@link AuditEvent} only takes these, the contract's {@code AuditAction} enum and {@code docs/domain/audit-events.md}
 * are kept equal by {@code AuditActionCompletenessTest}. The wire name is also the outbox event type where an action
 * has one ({@code member.invited}, {@code player.*}, {@code tenant.*} lifecycle).
 */
public enum AuditAction {
    ADMIN_ADDED("admin.added", PERSON),
    ADMIN_REMOVED("admin.removed", PERSON),
    ADMIN_TEMPORARY_PASSWORD_ISSUED("admin.temporary_password_issued", PERSON),
    ADMIN_UPDATED("admin.updated", PERSON),
    APPROVAL_CANCELLED("approval.cancelled", APPROVAL_REQUEST),
    GUARDIAN_LINK_CREATED("guardian_link.created", GUARDIAN_LINK),
    GUARDIAN_LINK_REMOVED("guardian_link.removed", GUARDIAN_LINK),
    MEMBER_DEACTIVATED("member.deactivated", PERSON),
    MEMBER_INVITATION_ACCEPTED("member.invitation_accepted", PERSON),
    MEMBER_INVITED("member.invited", PERSON),
    MEMBER_LOGIN_EMAIL_CHANGED("member.login_email_changed", PERSON),
    MEMBER_ROLES_REPLACED("member.roles_replaced", PERSON),
    MEMBER_TEMPORARY_PASSWORD_EXPIRED("member.temporary_password_expired", PERSON),
    MEMBER_TEMPORARY_PASSWORD_ISSUED("member.temporary_password_issued", PERSON),
    MEMBER_UPDATED("member.updated", PERSON),
    PLAYER_APPROVED("player.approved", PLAYER),
    PLAYER_REJECTED("player.rejected", PLAYER),
    PLAYER_REQUESTED("player.requested", PLAYER),
    PLAYER_WITHDRAWN("player.withdrawn", PLAYER),
    TENANT_CREATED("tenant.created", TENANT),
    TENANT_LOGO_REMOVED("tenant.logo_removed", TENANT),
    TENANT_LOGO_REPLACED("tenant.logo_replaced", TENANT),
    TENANT_MASTER_DATA_CHANGED("tenant.master_data_changed", TENANT),
    TENANT_PROFILE_CHANGED("tenant.profile_changed", TENANT),
    TENANT_REACTIVATED("tenant.reactivated", TENANT),
    TENANT_SETTINGS_CHANGED("tenant.settings_changed", TENANT),
    TENANT_SUSPENDED("tenant.suspended", TENANT),
    TENANT_WITHDRAWN("tenant.withdrawn", TENANT);

    private final String wireName;
    private final AuditTargetType targetType;

    AuditAction(String wireName, AuditTargetType targetType) {
        this.wireName = wireName;
        this.targetType = targetType;
    }

    public String wireName() {
        return wireName;
    }

    public AuditTargetType targetType() {
        return targetType;
    }

    public static Optional<AuditAction> fromWireName(String wireName) {
        return Arrays.stream(values()).filter(action -> action.wireName.equals(wireName)).findFirst();
    }
}
