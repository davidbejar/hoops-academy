package com.hoopsacademy.game.domain;

import java.util.Objects;

/** One player of a match roster with the name and jersey snapshot taken when the roster was stored. */
public record RosterEntry(PlayerId playerId, String displayName, JerseyNumber jerseyNumber, boolean starter) {

    public RosterEntry {
        Objects.requireNonNull(playerId, "playerId");
        Objects.requireNonNull(displayName, "displayName");
    }
}
