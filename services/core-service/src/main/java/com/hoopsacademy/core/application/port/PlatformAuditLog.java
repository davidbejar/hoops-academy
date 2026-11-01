package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantId;

/** Appends a tenant lifecycle action inside the current platform-datasource transaction (insert-only grant). */
public interface PlatformAuditLog {

    void record(TenantId tenant, AuditEvent event);
}
