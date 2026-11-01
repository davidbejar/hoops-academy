package com.hoopsacademy.core.application.port;

/** Appends to the bound tenant's audit trail inside the current tenant transaction (default datasource). */
public interface AuditLog {

    void record(AuditEvent event);
}
