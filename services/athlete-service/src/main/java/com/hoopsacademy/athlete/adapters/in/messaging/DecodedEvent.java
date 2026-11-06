package com.hoopsacademy.athlete.adapters.in.messaging;

import com.hoopsacademy.athlete.application.replica.RosterEvent;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/** A roster record after validation: an event to apply, or a contract violation to park. */
public sealed interface DecodedEvent {

    record Valid(RosterEvent event) implements DecodedEvent {}

    /** {@code eventId} when the record carried a readable one; {@code reason} without values from the record. */
    record Invalid(Optional<UUID> eventId, String reason) implements DecodedEvent {}

    /**
     * A valid event athlete does not apply (WP81): core publishes a removal for every aggregate, but the replica
     * soft-removes only staff entries and guardian links; persons, players, teams, assignments and tenants keep their
     * row until WP82. Counted {@code ignored}, never parked.
     */
    record Ignored(String type, Instant occurredAt) implements DecodedEvent {}
}
