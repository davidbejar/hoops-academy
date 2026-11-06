package com.hoopsacademy.athlete.application.replica;

import java.util.Optional;
import java.util.UUID;

/** A record the replica refused (contract violation): its coordinates in the topic and why, never its content. */
public record ParkedEvent(String topic, int partition, long offset, Optional<String> key, Optional<UUID> eventId,
        String reason) {}
