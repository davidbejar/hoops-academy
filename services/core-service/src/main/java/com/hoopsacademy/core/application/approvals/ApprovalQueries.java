package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.problem.NotFoundException;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.players.PlayerAccess;
import com.hoopsacademy.core.application.port.ApprovalRepository;
import com.hoopsacademy.core.application.port.ApprovalRepository.ApprovalFilter;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.approvals.ApprovalAction;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.approvals.ApprovalRequestId;
import com.hoopsacademy.core.domain.approvals.ApprovalStatus;
import com.hoopsacademy.core.domain.membership.PlayerId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.util.Optional;

/** Approval reads: ADMIN sees every request, a COACH only their own; anything else does not exist (404). */
@ApplicationScoped
public class ApprovalQueries {

    /** Contract query of {@code listApprovalRequests}. */
    public record Query(Optional<ApprovalStatus> status, Optional<ApprovalAction> action, Optional<PlayerId> player) {}

    private final ApprovalRepository approvals;
    private final ApprovalViews views;
    private final PlayerAccess access;

    public ApprovalQueries(ApprovalRepository approvals, ApprovalViews views, PlayerAccess access) {
        this.approvals = approvals;
        this.views = views;
        this.access = access;
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public PageResult<ApprovalView> list(Query query, PageRequest page) {
        PageResult<ApprovalRequest> found = approvals.list(new ApprovalFilter(query.status(), query.action(),
                query.player(), access.isAdmin() ? Optional.empty() : Optional.of(access.person())), page);
        return new PageResult<>(views.of(found.items()), page, found.totalElements());
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public ApprovalView get(ApprovalRequestId id) {
        return views.of(visible(id));
    }

    /** The request, or 404 when it does not exist or belongs to another requester. */
    ApprovalRequest visible(ApprovalRequestId id) {
        return approvals.find(id)
                .filter(request -> access.isAdmin() || request.requestedBy().equals(access.person()))
                .orElseThrow(() -> new NotFoundException("Approval request not found"));
    }
}
