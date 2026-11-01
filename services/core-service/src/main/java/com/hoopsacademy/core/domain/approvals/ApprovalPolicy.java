package com.hoopsacademy.core.domain.approvals;

import com.hoopsacademy.common.problem.AccessDeniedException;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.util.Set;

/** Who may act directly and who must ask (plan §2 "Approvals"). */
public final class ApprovalPolicy {

    private ApprovalPolicy() {}

    /**
     * @return false when the caller acts directly (ADMIN, which wins over COACH), true when an ADMIN must approve (COACH)
     * @throws AccessDeniedException for every other role set: assistants, parents and players cannot request
     */
    public static boolean requiresApproval(Set<TenantRole> roles, ApprovalAction action) {
        if (roles.contains(TenantRole.ADMIN)) {
            return false;
        }
        if (roles.contains(TenantRole.COACH)) {
            return true;
        }
        throw new AccessDeniedException("Only ADMIN or COACH may " + action.name().toLowerCase().replace('_', ' '));
    }
}
