package com.hoopsacademy.core.application.port;

import java.util.List;

/**
 * Sends records to the event broker (Redpanda, ADR-0036). A call returns once the broker acknowledged every record it
 * was given; the records of a call are all handed to the producer first and their acknowledgements awaited together,
 * in order (the idempotent producer keeps that order per partition).
 */
public interface EventBroker {

    /** The broker did not acknowledge a record in time (down, unreachable, rejected). */
    class UnavailableException extends RuntimeException {
        public UnavailableException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    /** One record; a null {@code value} is a tombstone. */
    record Message(String topic, String key, String value) {}

    /**
     * Sends {@code messages} in this order.
     *
     * @throws UnavailableException when any of them was not acknowledged in time: the caller sends them all again
     */
    void sendAll(List<Message> messages);

    /** {@code value} is the record's value; null sends a tombstone. */
    default void send(String topic, String key, String value) {
        sendAll(List.of(new Message(topic, key, value)));
    }
}
