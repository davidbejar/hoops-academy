package com.hoopsacademy.game.application.replica;

import java.util.Optional;
import java.util.UUID;

/**
 * A record of a core topic that failed validation (ADR-0037): where it is in the topic and why it was rejected. The
 * value is not kept; it stays readable in the topic at that offset until compaction replaces it.
 *
 * @param eventId the record's event id, when it could be read
 */
public record ParkedRecord(String topic, int partition, long offset, String key, Optional<UUID> eventId, String reason) {}
