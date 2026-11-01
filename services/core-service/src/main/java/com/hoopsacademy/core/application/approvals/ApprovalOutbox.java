package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.common.tenancy.TenantContext;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.OutboxWriter;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.HashMap;
import java.util.Map;

/** The integration events of the player lifecycle: player.requested / approved / rejected / withdrawn. */
@ApplicationScoped
public class ApprovalOutbox {

    private final TenantContext tenantContext;
    private final OutboxWriter outbox;

    public ApprovalOutbox(TenantContext tenantContext, OutboxWriter outbox) {
        this.tenantContext = tenantContext;
        this.outbox = outbox;
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
    }
}
