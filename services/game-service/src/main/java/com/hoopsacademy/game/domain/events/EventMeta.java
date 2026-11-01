package com.hoopsacademy.game.domain.events;

import java.time.Instant;
import java.util.Objects;

/**
 * Fields every event carries.
 *
 * @param clientSeq             per-device sequence, unique per (match, deviceId)
 * @param period                1-based; periods above the match's period count are overtimes
 * @param clockSecondsRemaining game clock at the event
 * @param recordedAtClient      device wall clock when the event was entered
 */
public record EventMeta(
        EventId id, String deviceId, long clientSeq, int period, int clockSecondsRemaining, Instant recordedAtClient) {

    public EventMeta {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(deviceId, "deviceId");
        Objects.requireNonNull(recordedAtClient, "recordedAtClient");
    }
}
