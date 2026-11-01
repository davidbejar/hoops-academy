package com.hoopsacademy.game.domain.projection;

/** Inconsistencies the projector reports (contract: ProjectionWarning.code, an open set). */
public enum WarningCode {
    SUB_IN_PLAYER_ON_COURT,
    SUB_OUT_PLAYER_NOT_ON_COURT,
    PLAYER_NOT_ON_COURT,
    PLAYER_NOT_IN_ROSTER,
    TOO_MANY_PLAYERS_ON_COURT,
    EVENT_OUTSIDE_PERIOD,
    PERIOD_ALREADY_RUNNING,
    PERIOD_ALREADY_PLAYED,
    PERIOD_NOT_RUNNING,
    MISSING_PERIOD_END,
    CLOCK_OUT_OF_RANGE,
    VOID_TARGET_NOT_FOUND,
    VOID_OF_VOID
}
