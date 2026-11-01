package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.core.application.players.PlayerView;

/** Contract {@code PlayerCommandResult}; {@code approval.request().status()} tells APPROVED (done) from PENDING. */
public record PlayerCommandResult(PlayerView player, ApprovalView approval) {

    public boolean pending() {
        return approval.request().isPending();
    }
}
