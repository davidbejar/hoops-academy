package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.core.application.port.AuditLog;
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
        audit.record(AuditEvent.of("approval.cancelled", "approval_request", request.id().value(), Map.of(
                "action", request.action().name(), "playerId", request.player().value().toString())));
    }

    public void requested(ApprovalRequest request) {
        write("player.requested", request);
    }

    /** An approval, including an ADMIN's auto-approved action. */
    public void approved(ApprovalRequest request) {
        write("player.approved", request);
    }

    public void rejected(ApprovalRequest request) {
        write("player.rejected", request);
    }

    public void withdrawn(ApprovalRequest request) {
        write("player.withdrawn", request);
    }

    private void write(String type, ApprovalRequest request) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("approvalRequestId", request.id().value().toString());
        payload.put("action", request.action().name());
        payload.put("playerId", request.player().value().toString());
        payload.put("status", request.status().name());
        payload.put("requestedBy", request.requestedBy().value().toString());
        if (request.decidedBy() != null) {
            payload.put("decidedBy", request.decidedBy().value().toString());
        }
        outbox.write(new OutboxEvent(tenantContext.requireTenantId(), type, "player",
                request.player().value().toString(), payload));
        audit.record(AuditEvent.of(type, "player", request.player().value(), payload));
    }
}
