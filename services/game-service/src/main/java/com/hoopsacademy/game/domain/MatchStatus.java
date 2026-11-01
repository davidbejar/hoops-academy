package com.hoopsacademy.game.domain;

/** Lifecycle of a match: SCHEDULED to LIVE to FINISHED; CANCELLED from SCHEDULED or LIVE. */
public enum MatchStatus {
    SCHEDULED,
    LIVE,
    FINISHED,
    CANCELLED;

    public boolean isOpen() {
        return this == SCHEDULED || this == LIVE;
    }
}
