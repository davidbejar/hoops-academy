package com.hoopsacademy.core.adapters.in.rest;

import com.hoopsacademy.core.application.roster.RolloverSeason.RolloverCommand;
import com.hoopsacademy.core.domain.roster.SeasonId;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** Contract {@code SeasonRolloverRequest}; both clone flags default to true. */
public record RolloverRequest(@NotNull UUID fromSeasonId, Boolean cloneStaff, Boolean clonePlayers) {

    RolloverCommand toCommand() {
        return new RolloverCommand(new SeasonId(fromSeasonId), !Boolean.FALSE.equals(cloneStaff),
                !Boolean.FALSE.equals(clonePlayers));
    }
}
