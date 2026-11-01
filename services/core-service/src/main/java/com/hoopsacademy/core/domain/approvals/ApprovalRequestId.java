package com.hoopsacademy.core.domain.approvals;

import java.util.Objects;
import java.util.UUID;

/** Identity of an approval request. */
public record ApprovalRequestId(UUID value) {

    public ApprovalRequestId {
        Objects.requireNonNull(value, "approval request id");
    }

    public static ApprovalRequestId random() {
        return new ApprovalRequestId(UUID.randomUUID());
    }
}
