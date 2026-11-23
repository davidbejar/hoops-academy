package com.hoopsacademy.common.replica;

import java.util.Optional;
import java.util.UUID;

/** A roster record after validation: an event to apply, or a contract violation to park. */
public sealed interface DecodedEvent<E> {

    record Valid<E>(EventEnvelope envelope, E event) implements DecodedEvent<E> {}

    /** {@code eventId} when the record carried a readable one; {@code reason} without values from the record. */
    record Invalid<E>(Optional<UUID> eventId, String reason) implements DecodedEvent<E> {}
}
