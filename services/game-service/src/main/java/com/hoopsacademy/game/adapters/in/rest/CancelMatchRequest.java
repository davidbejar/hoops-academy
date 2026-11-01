package com.hoopsacademy.game.adapters.in.rest;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CancelMatchRequest(@NotBlank @Size(max = 500) String reason) {}
