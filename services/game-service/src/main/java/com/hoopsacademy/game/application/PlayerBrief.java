package com.hoopsacademy.game.application;

import com.hoopsacademy.game.domain.PlayerId;

/** Minimal player data used for denormalisation. */
public record PlayerBrief(PlayerId playerId, String displayName) {}
