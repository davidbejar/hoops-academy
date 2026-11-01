package com.hoopsacademy.game.adapters.in.rest;

import com.hoopsacademy.game.domain.HomeAway;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

public record CreateMatchRequest(
        @NotNull UUID teamId,
        @NotBlank @Size(max = 120) String opponentName,
        @NotNull HomeAway homeAway,
        @NotNull Instant scheduledAt,
        @Size(max = 200) String venue,
        @Min(1) @Max(8) Integer periodCount,
        @Min(1) @Max(60) Integer periodMinutes) {}
