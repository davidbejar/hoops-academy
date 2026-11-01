package com.hoopsacademy.game.domain.events;

/** The event types of libs/contracts events/match-event.schema.json. */
public enum MatchEventType {
    PERIOD_START,
    PERIOD_END,
    SUB_IN,
    SUB_OUT,
    SHOT,
    ASSIST,
    REBOUND,
    TURNOVER,
    STEAL,
    BLOCK,
    FOUL,
    OPPONENT_SCORE,
    TIMEOUT,
    VOID,
    NOTE
}
