package com.hoopsacademy.athlete.application.replica;

import java.util.Arrays;
import java.util.Optional;

/** The seven compacted topics core publishes its roster on (ADR-0036 section 4), one per aggregate. */
public enum RosterTopic {
    PERSON("core.person"),
    PLAYER("core.player"),
    TEAM("core.team"),
    TEAM_PLAYER("core.team-player"),
    TEAM_STAFF("core.team-staff"),
    GUARDIAN_LINK("core.guardian-link"),
    TENANT("core.tenant");

    private final String topicName;

    RosterTopic(String topicName) {
        this.topicName = topicName;
    }

    public String topicName() {
        return topicName;
    }

    public static Optional<RosterTopic> of(String topicName) {
        return Arrays.stream(values()).filter(topic -> topic.topicName.equals(topicName)).findFirst();
    }
}
