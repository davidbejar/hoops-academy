package com.hoopsacademy.core.application.events;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

/**
 * The topics core publishes its roster aggregates to (ADR-0036, contracts {@code libs/contracts/events/<topic>.schema.json}):
 * {@code core.<aggregate>}, event types {@code <aggregate>.changed} and, where a record can disappear,
 * {@code <aggregate>.removed}.
 */
public enum EventTopic {
    PERSON("person", false),
    PLAYER("player", false),
    TEAM("team", false),
    TEAM_PLAYER("team-player", false),
    TEAM_STAFF("team-staff", true),
    GUARDIAN_LINK("guardian-link", true),
    TENANT("tenant", false);

    /** Major version of every topic's contract: the topics carry no {@code .v<n>} suffix yet. */
    public static final int VERSION = 1;

    private final String aggregate;
    private final boolean removable;

    EventTopic(String aggregate, boolean removable) {
        this.aggregate = aggregate;
        this.removable = removable;
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
        if (!removable) {
            throw new IllegalStateException(topic() + " has no removed events");
        }
        return aggregate + ".removed";
    }

    public boolean isRemovedType(String type) {
        return removable && removedType().equals(type);
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
