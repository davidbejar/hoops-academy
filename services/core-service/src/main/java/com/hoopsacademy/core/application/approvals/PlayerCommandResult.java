package com.hoopsacademy.core.application.approvals;

import com.hoopsacademy.core.application.players.PlayerView;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;
import java.util.Objects;
import java.util.Optional;

/**
 * Contract {@code PlayerCommandResult}; {@code approval.request().status()} tells APPROVED (done) from PENDING.
 * {@code temporaryPassword}: of the login this command created for the player (ADR-0024), shown once.
 */
public record PlayerCommandResult(PlayerView player, ApprovalView approval, Optional<TemporaryPassword> temporaryPassword) {

    public PlayerCommandResult {
        Objects.requireNonNull(temporaryPassword, "temporaryPassword");
    }

    public PlayerCommandResult(PlayerView player, ApprovalView approval) {
        this(player, approval, Optional.empty());
    }

    public boolean pending() {
        return approval.request().isPending();
    }
}
