package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.core.application.port.ApprovalRepository;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.approvals.ApprovalRequestId;
import jakarta.enterprise.context.ApplicationScoped;

/** Loading and storing a decision; the version check turns a lost race into 409 {@code CONCURRENT_DECISION}. */
@ApplicationScoped
class DecideRequest {

    private final ApprovalRepository approvals;

    DecideRequest(ApprovalRepository approvals) {
        this.approvals = approvals;
    }

    ApprovalRequest load(ApprovalRequestId id) {
        return approvals.find(id).orElseThrow(() -> new NotFoundException("Approval request not found"));
    }

    ApprovalRequest store(ApprovalRequest decided) {
        approvals.update(decided);
        return decided;
    }
}
