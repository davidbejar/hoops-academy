package com.hoopsacademy.core.adapters.out.persistence;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hoopsacademy.core.application.port.OutboxEvent;
import com.hoopsacademy.core.application.port.OutboxWriter;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;

/** Appends to {@code core.outbox} in the caller's tenant-bound transaction. */
@ApplicationScoped
class JpaOutboxRepository implements OutboxWriter {

    private final EntityManager em;
    private final ObjectMapper json;

    JpaOutboxRepository(EntityManager em, ObjectMapper json) {
        this.em = em;
        this.json = OutboxRowRepository.payloadMapper(json);
    }

    @Override
    public void write(OutboxEvent event) {
        OutboxRowRepository.insert(em, json, event);
    }
}
