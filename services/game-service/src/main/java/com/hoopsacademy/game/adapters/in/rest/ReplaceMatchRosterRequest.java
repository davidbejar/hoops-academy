package com.hoopsacademy.game.adapters.in.rest;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

public record ReplaceMatchRosterRequest(@NotNull @Size(max = 30) List<@Valid @NotNull Entry> entries) {

    public record Entry(
            @NotNull UUID playerId,
            @Pattern(regexp = "^[0-9]{1,2}$") String jerseyNumber,
            @NotNull Boolean isStarter) {}
}
