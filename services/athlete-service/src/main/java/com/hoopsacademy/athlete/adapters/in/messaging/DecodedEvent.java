package com.hoopsacademy.athlete.adapters.in.messaging;

import com.hoopsacademy.athlete.application.replica.RosterEvent;
import java.util.Optional;
import java.util.UUID;

/** A roster record after validation: an event to apply, or a contract violation to park. */
public sealed interface DecodedEvent {

    record Valid(RosterEvent event) implements DecodedEvent {}

    /** {@code eventId} when the record carried a readable one; {@code reason} without values from the record. */
    record Invalid(Optional<UUID> eventId, String reason) implements DecodedEvent {}
}
