package com.hoopsacademy.core.application.port;

/**
 * Starts the temporary password sweep in the background (ADR-0028). The events that call it — a temporary password
 * issued, an invitation accepted at the first sign-in — are infrequent; there is no scheduler.
 */
public interface TemporaryPasswordSweeps {

    /**
     * Asks for a sweep once the current transaction has committed (at once without a transaction; nothing after a
     * rollback). Never blocks and never throws: the request that triggers it neither waits for it nor fails with it.
     */
    void request();
}
