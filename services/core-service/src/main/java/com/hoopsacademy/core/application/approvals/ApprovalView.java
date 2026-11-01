package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.core.domain.approvals.ApprovalRequest;

/** Contract {@code ApprovalRequest} with the display names it shows. */
public record ApprovalView(ApprovalRequest request, String playerName, String requesterName, String deciderName) {}
