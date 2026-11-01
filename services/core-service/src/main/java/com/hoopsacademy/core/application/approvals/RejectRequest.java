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
 * ADMIN rejects a PENDING request. A rejected ADD_PLAYER leaves the pending player WITHDRAWN (the contract's
 * PlayerStatus has no REJECTED; the rows are kept for the audit trail); a rejected WITHDRAW_PLAYER changes nothing.
 */
@ApplicationScoped
public class RejectRequest {

    private final DecideRequest decisions;
    private final PlayerRepository players;
    private final ApprovalOutbox outbox;
    private final ApprovalViews views;
    private final PlayerAccess access;
    private final Clock clock;

    RejectRequest(DecideRequest decisions, PlayerRepository players, ApprovalOutbox outbox, ApprovalViews views,
            PlayerAccess access, Clock clock) {
        this.decisions = decisions;
        this.players = players;
        this.outbox = outbox;
        this.views = views;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public ApprovalView handle(ApprovalRequestId id, String note) {
        ApprovalRequest decided = decisions.store(decisions.load(id).reject(access.person(), note, clock.instant()));
        if (decided.action() == ApprovalAction.ADD_PLAYER) {
            players.updateStatus(decided.player(), PlayerStatus.REJECTED);
        }
        outbox.rejected(decided);
        return views.of(decided);
    }
}
