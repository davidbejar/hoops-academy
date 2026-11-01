package com.hoopsacademy.athlete.application;

import com.hoopsacademy.athlete.domain.PlayerId;

/** Minimal player data from core-service. */
public record PlayerBrief(PlayerId playerId, String displayName, String status) {}
