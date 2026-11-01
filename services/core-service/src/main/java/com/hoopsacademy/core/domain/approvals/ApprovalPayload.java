package com.hoopsacademy.core.domain.approvals;

import com.hoopsacademy.core.domain.roster.JerseyNumber;
import com.hoopsacademy.core.domain.roster.TeamId;

/** Parameters captured when the request was made (contract {@code ApprovalPayload}); every member is optional. */
public record ApprovalPayload(TeamId team, JerseyNumber jersey, String note, String reason) {

    public static ApprovalPayload empty() {
        return new ApprovalPayload(null, null, null, null);
    }

    public static ApprovalPayload reason(String reason) {
        return new ApprovalPayload(null, null, null, reason);
    }
}
