package com.hoopsacademy.core.application.port;

/** Appends tenant lifecycle events inside the current platform-datasource transaction (insert-only grant). */
public interface PlatformOutboxWriter {

    void write(OutboxEvent event);
}
