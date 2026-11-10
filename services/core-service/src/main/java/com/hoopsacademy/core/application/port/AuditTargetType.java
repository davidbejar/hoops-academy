package com.hoopsacademy.core.application.port;

import java.util.Arrays;
import java.util.Optional;

/** What an audit action is about (contract {@code AuditTargetType}); the target id is that row's id. */
public enum AuditTargetType {
    PERSON("person"),
    PLAYER("player"),
    TENANT("tenant"),
    APPROVAL_REQUEST("approval_request"),
    GUARDIAN_LINK("guardian_link"),
    TEAM("team");

    private final String wireName;

    AuditTargetType(String wireName) {
        this.wireName = wireName;
    }

    public String wireName() {
        return wireName;
    }

    public static Optional<AuditTargetType> fromWireName(String wireName) {
        return Arrays.stream(values()).filter(type -> type.wireName.equals(wireName)).findFirst();
    }
}
