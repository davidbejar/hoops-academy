package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.core.application.port.ApprovalRepository;
import com.hoopsacademy.core.application.port.UsageCounter;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Map;

/** {@code pendingApprovals}: requests waiting for an ADMIN decision. */
@ApplicationScoped
public class ApprovalUsageCounter implements UsageCounter {

    private final ApprovalRepository approvals;

    public ApprovalUsageCounter(ApprovalRepository approvals) {
        this.approvals = approvals;
    }

    @Override
    public Map<String, Long> counters() {
        return Map.of("pendingApprovals", approvals.countPending());
    }
}
