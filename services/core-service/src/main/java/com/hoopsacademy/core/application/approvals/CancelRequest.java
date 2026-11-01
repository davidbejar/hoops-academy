package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.players.PlayerAccess;
import com.hoopsacademy.core.application.port.PlayerRepository;
import com.hoopsacademy.core.domain.approvals.ApprovalAction;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.approvals.ApprovalRequestId;
import com.hoopsacademy.core.domain.membership.PlayerStatus;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;

/**
 * The requester withdraws their own PENDING request (someone else's request does not exist for them: 404; an ADMIN
 * who is not the requester gets 403). A cancelled ADD_PLAYER leaves the pending player WITHDRAWN, like a rejection.
 */
@ApplicationScoped
public class CancelRequest {

    private final ApprovalQueries queries;
    private final DecideRequest decisions;
    private final PlayerRepository players;
    private final ApprovalViews views;
    private final PlayerAccess access;
    private final Clock clock;

    CancelRequest(ApprovalQueries queries, DecideRequest decisions, PlayerRepository players, ApprovalViews views,
            PlayerAccess access, Clock clock) {
        this.queries = queries;
        this.decisions = decisions;
        this.players = players;
        this.views = views;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    @RequiresTenantRole({TenantRole.ADMIN, TenantRole.COACH})
    public ApprovalView handle(ApprovalRequestId id) {
        ApprovalRequest decided = decisions.store(queries.visible(id).cancel(access.person(), clock.instant()));
        if (decided.action() == ApprovalAction.ADD_PLAYER) {
            players.updateStatus(decided.player(), PlayerStatus.WITHDRAWN);
        }
        return views.of(decided);
    }
}
