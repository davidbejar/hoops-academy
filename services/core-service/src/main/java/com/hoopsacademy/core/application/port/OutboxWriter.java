package com.hoopsacademy.core.application.port;

/** Appends events inside the current tenant-bound transaction (default datasource). Insert only; WP19 publishes. */
public interface OutboxWriter {

    void write(OutboxEvent event);
}
