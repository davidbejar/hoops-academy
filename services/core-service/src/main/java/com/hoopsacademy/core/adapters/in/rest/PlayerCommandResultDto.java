package com.hoopsacademy.core.adapters.in.rest;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.hoopsacademy.core.application.approvals.PlayerCommandResult;
import com.hoopsacademy.core.domain.identity.TemporaryPassword;

/** Contract {@code PlayerCommandResult}; {@code temporaryPassword} only when the command created the player's login. */
public record PlayerCommandResultDto(PlayerDto player, ApprovalRequestDto approvalRequest,
        @JsonInclude(JsonInclude.Include.NON_NULL) String temporaryPassword) {

    static PlayerCommandResultDto of(PlayerCommandResult result) {
        return new PlayerCommandResultDto(PlayerDto.of(result.player()), ApprovalRequestDto.of(result.approval()),
                result.temporaryPassword().map(TemporaryPassword::reveal).orElse(null));
    }

    @Override
    public String toString() {
        return "PlayerCommandResultDto[player=" + player + ", approvalRequest=" + approvalRequest
                + ", temporaryPassword=" + (temporaryPassword == null ? "none" : "***") + "]";
    }
}
