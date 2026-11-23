package com.hoopsacademy.common.replica;

import java.util.Optional;
import java.util.UUID;

/**
 * A record the replica refused (a contract violation, ADR-0037): its coordinates in the topic, its key and event id
 * when readable, and why; never its value (it stays readable in the topic at that offset until compaction replaces it).
 */
public record ParkedEvent(String topic, int partition, long offset, Optional<String> key, Optional<UUID> eventId,
        String reason) {}
