package com.hoopsacademy.core.domain.roster;

/** Which rule numbered a new assignment (contract {@code JerseySource}, ADR-0048). */
public enum JerseySource {
    /** The number given in the request. */
    REQUESTED,
    /** The player's preferred number, free on the team. */
    PREFERRED,
    /** The number of the player's most recent numbered assignment, free on the team. */
    PREVIOUS,
    /** No number. */
    NONE
}
