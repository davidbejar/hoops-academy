package com.hoopsacademy.common.replica;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * A service's half of the decoder: what a valid core event means for its replica. It sees only records that match
 * their topic's schema, key and tenant rules ({@link CoreEventDecoder}).
 *
 * @param <E> the service's own event type
 */
@FunctionalInterface
public interface EventMapper<E> {

    /**
     * @param type the event type of the contract, e.g. {@code team.changed}
     * @throws IllegalArgumentException or {@link java.time.DateTimeException} for a value the schema allows but the
     *     service cannot read (an unknown time zone): the record is parked; any other exception is a bug and stops
     *     the consumer
     */
    E map(RosterTopic topic, EventEnvelope envelope, String type, JsonNode payload);
}
