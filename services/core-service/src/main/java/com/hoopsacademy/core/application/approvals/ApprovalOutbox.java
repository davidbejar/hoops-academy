package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.core.application.port.AuditLog;
import com.hoopsacademy.core.application.port.AuditAction;
import com.hoopsacademy.core.application.port.AuditEvent;
import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.OutboxWriter;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.HashMap;
import java.util.Map;

/**
 * The integration events of the player lifecycle (player.requested / approved / rejected / withdrawn) — each also
 * recorded in the audit trail with the same action name. Notes are free text and stay out of both.
 */
@ApplicationScoped
public class ApprovalOutbox {

    private final TenantContext tenantContext;
    private final OutboxWriter outbox;
    private final AuditLog audit;

    public ApprovalOutbox(TenantContext tenantContext, OutboxWriter outbox, AuditLog audit) {
        this.tenantContext = tenantContext;
        this.outbox = outbox;
        this.audit = audit;
    }

    /** A requester withdrew their own PENDING request (audit only, no integration event). */
    public void cancelled(ApprovalRequest request) {
        audit.record(AuditEvent.of(AuditAction.APPROVAL_CANCELLED, request.id().value(), Map.of(
                "action", request.action().name(), "playerId", request.player().value().toString())));
    }

    public void requested(ApprovalRequest request) {
        write(AuditAction.PLAYER_REQUESTED, request);
    }

    /** An approval, including an ADMIN's auto-approved action. */
    public void approved(ApprovalRequest request) {
        write(AuditAction.PLAYER_APPROVED, request);
    }

    public void rejected(ApprovalRequest request) {
        write(AuditAction.PLAYER_REJECTED, request);
    }

    public void withdrawn(ApprovalRequest request) {
        write(AuditAction.PLAYER_WITHDRAWN, request);
    }

    private void write(AuditAction action, ApprovalRequest request) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("approvalRequestId", request.id().value().toString());
        payload.put("action", request.action().name());
        payload.put("playerId", request.player().value().toString());
        payload.put("status", request.status().name());
        payload.put("requestedBy", request.requestedBy().value().toString());
        if (request.decidedBy() != null) {
            payload.put("decidedBy", request.decidedBy().value().toString());
        }
        outbox.write(new OutboxEvent(tenantContext.requireTenantId(), action.wireName(), "player",
                request.player().value().toString(), payload));
        audit.record(AuditEvent.of(action, request.player().value(), payload));
    }
}
