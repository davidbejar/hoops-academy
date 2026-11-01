package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.approvals.PlayerCommandResult;

/** Contract {@code PlayerCommandResult}. */
public record PlayerCommandResultDto(PlayerDto player, ApprovalRequestDto approvalRequest) {

    static PlayerCommandResultDto of(PlayerCommandResult result) {
        return new PlayerCommandResultDto(PlayerDto.of(result.player()), ApprovalRequestDto.of(result.approval()));
    }
}
