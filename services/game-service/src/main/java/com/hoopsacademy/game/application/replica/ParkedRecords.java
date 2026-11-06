package com.hoopsacademy.game.application.replica;

/** Where rejected records go (write-only for the service, ADR-0037). */
public interface ParkedRecords {

    void park(ParkedRecord record);
}
