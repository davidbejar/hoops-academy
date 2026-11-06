package com.hoopsacademy.core.application.events;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

/**
 * The topics core publishes its roster aggregates to (ADR-0036, contracts {@code libs/contracts/events/<topic>.schema.json}):
 * {@code core.<aggregate>}, event types {@code <aggregate>.changed} and {@code <aggregate>.removed} (every aggregate,
 * WP81; a removal is followed by a tombstone).
 */
public enum EventTopic {
    PERSON("person"),
    PLAYER("player"),
    TEAM("team"),
    TEAM_PLAYER("team-player"),
    TEAM_STAFF("team-staff"),
    GUARDIAN_LINK("guardian-link"),
    TENANT("tenant");

    /** Major version of every topic's contract: the topics carry no {@code .v<n>} suffix yet. */
    public static final int VERSION = 1;

    private final String aggregate;

    EventTopic(String aggregate) {
        this.aggregate = aggregate;
    }

    public String topic() {
        return "core." + aggregate;
    }

    public String aggregate() {
        return aggregate;
    }

    public String changedType() {
        return aggregate + ".changed";
    }

    public String removedType() {
        return aggregate + ".removed";
    }

    public boolean isRemovedType(String type) {
        return removedType().equals(type);
    }

    public static EventTopic ofTopic(String topic) {
        for (EventTopic candidate : values()) {
            if (candidate.topic().equals(topic)) {
                return candidate;
            }
        }
        throw new IllegalArgumentException("Unknown topic: " + topic);
    }

    /**
     * The aggregate id of a team staff entry, which the table keys by team and person: the name-based (version 3) UUID
     * of {@code team-staff:<teamId>:<personId>} (the rule of the {@code core.team-staff} contract).
     */
    public static UUID teamStaffId(UUID team, UUID person) {
        return UUID.nameUUIDFromBytes(("team-staff:" + team + ":" + person).getBytes(StandardCharsets.UTF_8));
    }
}
