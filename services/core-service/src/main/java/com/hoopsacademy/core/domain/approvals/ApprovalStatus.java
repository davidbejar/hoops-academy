package com.hoopsacademy.core.domain.approvals;

/** Lifecycle of an approval request; everything but PENDING is final. */
public enum ApprovalStatus {
    PENDING,
    APPROVED,
    REJECTED,
    CANCELLED
}
