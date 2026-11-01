package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.common.authz.RequiresTenantRole;
import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.players.PlayerAccess;
import com.hoopsacademy.core.domain.approvals.ApprovalPayload;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.approvals.ApprovalRequestId;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.transaction.Transactional;
import java.time.Clock;
import java.util.Optional;

/**
 * ADMIN approves a PENDING request and the action runs in the same transaction. ADD_PLAYER: the player becomes
 * ACTIVE and the optional team assignment goes through the eligibility-checked command — if that fails (422) the
 * whole transaction rolls back and the request stays PENDING. WITHDRAW_PLAYER: as the direct admin withdrawal.
 */
@ApplicationScoped
public class ApproveRequest {

    private final DecideRequest decisions;
    private final PlayerLifecycle lifecycle;
    private final ApprovalOutbox outbox;
    private final ApprovalViews views;
    private final PlayerAccess access;
    private final Clock clock;

    ApproveRequest(DecideRequest decisions, PlayerLifecycle lifecycle, ApprovalOutbox outbox, ApprovalViews views,
            PlayerAccess access, Clock clock) {
        this.decisions = decisions;
        this.lifecycle = lifecycle;
        this.outbox = outbox;
        this.views = views;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    @RequiresTenantRole(TenantRole.ADMIN)
    public ApprovalView handle(ApprovalRequestId id, String note) {
        ApprovalRequest decided = decisions.store(decisions.load(id).approve(access.person(), note, clock.instant()));
        ApprovalPayload payload = decided.payload();
        switch (decided.action()) {
            case ADD_PLAYER -> {
                lifecycle.admit(decided.player(), Optional.ofNullable(payload.team()),
                        Optional.ofNullable(payload.jersey()));
                outbox.approved(decided);
            }
            case WITHDRAW_PLAYER -> {
                lifecycle.withdraw(decided.player(), access.person());
                outbox.withdrawn(decided);
            }
        }
        return views.of(decided);
    }
}
