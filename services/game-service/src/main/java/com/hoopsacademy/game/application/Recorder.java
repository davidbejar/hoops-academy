package com.hoopsacademy.game.application;

import java.util.Objects;
import java.util.UUID;

/** The member who recorded an event (contract PersonRef); the name is the token's display name at ingest time. */
public record Recorder(UUID personId, String displayName) {

    public Recorder {
        Objects.requireNonNull(personId, "personId");
        Objects.requireNonNull(displayName, "displayName");
    }
}
