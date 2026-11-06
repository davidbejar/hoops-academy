package com.hoopsacademy.core.application.port;

/** Sends records to the event broker (Redpanda, ADR-0036); every call blocks until the broker acknowledged it. */
public interface EventBroker {

    /** The broker did not acknowledge a record in time (down, unreachable, rejected). */
    class UnavailableException extends RuntimeException {
        public UnavailableException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    /** {@code value} is the record's value; null sends a tombstone. */
    void send(String topic, String key, String value);
}
